extends Node
## Raiz de composição do Khaeros (ADR-0001: Main fino na cena raiz, sem Autoload).
## Constrói os módulos na ordem de inicialização, injeta as dependências antes do
## [code]add_child[/code] dos nós de Apresentação e só repassa [code]_physics_process[/code] →
## [method OrquestradorDoPasso.passo_fisico] e [code]_process[/code] → [method OrquestradorDoPasso.quadro].
## A regra ainda é a fatia de 2026-11-14 ([code]GameSession[/code]), ligada por [AdaptadoresDaFatia]
## (stories orquestrador-006/007). A fatia segue dona do texto de estado e o orquestrador o
## espelha por pedidos válidos até os épicos donos assumirem.
##
## Exemplo: a cena [code]res://scenes/main.tscn[/code] tem este script na raiz; testes chamam
## [method activate] e [code]Main.erro_de_passo(30)[/code].

const Catalog = preload("res://src/foundation/session_catalog.gd")
const Session = preload("res://src/gameplay/game_session.gd")
const InputAdapter = preload("res://src/foundation/game_input.gd")
const Camera = preload("res://src/presentation/game_camera.gd")
const World = preload("res://src/presentation/world_view.gd")
const HUD = preload("res://src/presentation/game_hud.gd")

var catalog = Catalog.new()
var session = Session.new()
var controls = InputAdapter.new()
var camera = Camera.new()
var world = World.new()
var hud = HUD.new()
var selected := 0
var screen_age := 0.0
var context := ""
var last_sample: Dictionary = {}
var reduced_motion := false
var pending_pause := false
var capture_mode := ""
var capture_frames := 0
var capture_started := false
var ready_to_play := false
var data_error := ""
var observed_wave := -1
## Canal de eventos do passo (ADR-0002).
var eventos := EventosDoPasso.new()
## Consumidores na ordem fixa do ADR-0002/0016: Telemetria, HUD, Feedback, Telas, Áudio.
var consumidores: Array[ConsumidorDeEventos] = []
## Orquestrador do passo (ADR-0001); criado em [method _compor_passo].
var orquestrador: OrquestradorDoPasso = null
var _ctx: AdaptadoresDaFatia.Contexto = null
## Save da sessão (ADR-0013 §7): consumidor de eventos e ponto seguro no fim de cada passo.
## Perfil nulo até o épico vinculo-e-pactos trazer a [PortaDeSecao] do vínculo (ver story 006).
var save := Save.new()
## Relator de erros do RNG injetado na sessão (RNG story 006).
var relator_rng := AdaptadoresDaFatia.RelatorRngPorAviso.new()
## Avisos de perfil recebidos do Save (chaves); a tela que os mostra é do épico hud.
var avisos_de_perfil: Array[StringName] = []

## Mensagem de erro se [param ticks] (de [code]Engine.physics_ticks_per_second[/code]) diverge da
## constante única [constant OrquestradorDoPasso.PASSOS_POR_SEGUNDO]; vazio se confere.
static func erro_de_passo(ticks: int) -> String:
	if ticks == OrquestradorDoPasso.PASSOS_POR_SEGUNDO:
		return ""
	return "Main: physics_ticks_per_second = %d, mas o passo do jogo é de %d por segundo." % [
		ticks, OrquestradorDoPasso.PASSOS_POR_SEGUNDO]

## Injeta [code]app[/code] em [param no] (Apresentação) e só depois o põe na árvore, para que o
## [code]_ready()[/code] dele já veja as dependências (ADR-0001: configurar antes de add_child).
func compor_apresentacao(no: Node, pai: Node = self) -> void:
	no.set("app", self)
	pai.add_child(no)

## Nomes dos consumidores na ordem registrada.
func ordem_dos_consumidores() -> Array[StringName]:
	var r: Array[StringName] = []
	for c: ConsumidorDeEventos in consumidores:
		r.append(&"save" if c is Save else c.get("nome"))
	return r

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# Input por passo (ADR-0006): use_accumulated_input = false é feito pela camada de Input
	# (game_input.gd no _ready); a varredura do épico input proíbe ler Input fora dela.
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	compor_apresentacao(hud, canvas)
	if not catalog.load_file("res://data/integration/gameplay.json"):
		data_error = "\n".join(catalog.errors)
		push_error(data_error)
		return
	data_error = erro_de_passo(Engine.physics_ticks_per_second)
	if data_error != "":
		push_error(data_error)
		return
	session.configure(catalog.data, 0x4B484145, relator_rng)
	# Save: depois do catálogo, antes da escolha de arma (persistencia story 006).
	get_tree().set_auto_accept_quit(false)
	save.configurar(PerfilNulo.new(), func(chave: StringName) -> void: avisos_de_perfil.append(chave))
	save.carregar(true)
	controls.configure(catalog.data.input)
	add_child(controls)
	if controls.has_signal("device_disconnected"):
		controls.connect("device_disconnected", _on_device_disconnected)
	camera.configure(catalog.data.camera, Rect2(0, 0, catalog.data.arena.largura, catalog.data.arena.altura))
	camera.resize(get_window())
	camera.cut(Vector2(catalog.data.jogador.spawn[0], catalog.data.jogador.spawn[1]))
	get_window().size_changed.connect(_on_resize)
	compor_apresentacao(world)
	_compor_passo()
	ready_to_play = true
	sync_context()
	if OS.is_debug_build():
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--qa-capture="):
				capture_mode = arg.trim_prefix("--qa-capture=")
		if capture_mode != "" and capture_mode != "menu":
			activate(0)
			if capture_mode in ["pausa", "bencao", "morte", "vitoria"]:
				session.state = capture_mode
				sync_context()

func _physics_process(_delta: float) -> void:
	if not ready_to_play:
		return
	_espelhar_estado()
	var estado_antes: String = session.state
	orquestrador.passo_fisico()
	# Ponto seguro do Save: fim do passo, depois da entrega (persistencia story 007).
	save.gravar_se_pendente(orquestrador.estado())
	if estado_antes != "jogo":
		_handle_ui(last_sample)
	_espelhar_estado()
	sync_context()

## Constrói canal, consumidores e orquestrador com os adaptadores da fatia.
func _compor_passo() -> void:
	consumidores.clear()
	consumidores.append(AdaptadoresDaFatia.ConsumidorNulo.new(&"telemetria"))
	consumidores.append(AdaptadoresDaFatia.ConsumidorNulo.new(&"hud"))
	consumidores.append(AdaptadoresDaFatia.FeedbackDaFatia.new(camera))
	consumidores.append(AdaptadoresDaFatia.ConsumidorNulo.new(&"telas"))
	consumidores.append(AdaptadoresDaFatia.ConsumidorNulo.new(&"audio"))
	consumidores.append(save)
	orquestrador = OrquestradorDoPasso.new(eventos, consumidores)
	_ctx = AdaptadoresDaFatia.Contexto.new(session, eventos, _amostrar, controls.consume)
	orquestrador.configurar_passo(AdaptadoresDaFatia.Fonte.new(_ctx),
		AdaptadoresDaFatia.HitstopDaFatia.new(_ctx), AdaptadoresDaFatia.modulos(_ctx))
	orquestrador.configurar_quadro(AdaptadoresDaFatia.PipelineDaFatia.new(_ctx),
		AdaptadoresDaFatia.acoes_da_troca(),
		float(catalog.data.get("presentation", {}).get("delta_max", 0.1)))
	_espelhar_estado()

## Item 1 do passo: amostra o Input legado; um pedido de pausa em jogo pausa antes da regra.
func _amostrar() -> Dictionary:
	if not session.player.is_empty():
		controls.player_position = session.player.pos
	controls.targets = session.enemies
	last_sample = controls.sample(session.hitstop > 0, camera)
	if session.state == "jogo" and (pending_pause or last_sample.pressed.get("pausar", false)):
		pending_pause = false
		session.pause()
	return last_sample

func _espelhar_estado() -> void:
	if orquestrador != null:
		AdaptadoresDaFatia.espelhar(orquestrador, AdaptadoresDaFatia.estado_de(session.state))

func _process(delta: float) -> void:
	if not ready_to_play:
		hud.queue_redraw()
		return
	var presentation_delta := minf(delta, 0.1)
	screen_age += presentation_delta
	orquestrador.quadro(delta)
	session.advance_presentation(presentation_delta)
	_espelhar_estado()
	if session.wave_index != observed_wave and not session.player.is_empty():
		observed_wave = session.wave_index
		camera.cut(session.player.pos)
	sync_context()
	if not session.player.is_empty():
		camera.reduced_motion = reduced_motion
		camera.aim_intensity = last_sample.get("aim_intensity", 0.0)
		camera.update(presentation_delta, session.player.prev, session.player.pos,
			Engine.get_physics_interpolation_fraction(), last_sample.get("aim", Vector2.UP),
			last_sample.get("source", "mouse"), last_sample.get("cursor", Vector2(camera.width / 2, 540)),
			session.state != "jogo")
	get_viewport().canvas_transform = camera.transform
	world.queue_redraw()
	hud.queue_redraw()
	if capture_mode != "" and not capture_started:
		capture_frames += 1
		if capture_frames >= 90:
			capture_started = true
			_capture()

## Applies context barriers exactly when a screen changes.
func sync_context() -> void:
	if context == session.state:
		return
	context = session.state
	selected = 0
	screen_age = 0
	controls.set_context(context)

## Executes the selected visible UI action; also used by integration tests.
func activate(index: int) -> void:
	if not ready_to_play:
		return
	match session.state:
		"menu":
			if index == 0:
				session.start()
				observed_wave = -1
				camera.cut(session.player.pos)
			elif index == 1:
				reduced_motion = not reduced_motion
		"pausa":
			if index == 0:
				session.resume()
			elif index == 1:
				reduced_motion = not reduced_motion
			elif index == 2:
				session.state = "menu"
		"bencao":
			if screen_age >= float(catalog.data.blessing_lock_s):
				session.choose_blessing(index)
		"morte", "vitoria":
			if index == 0:
				session.start()
				observed_wave = -1
				camera.cut(session.player.pos)
			else:
				session.state = "menu"
	_espelhar_estado()
	sync_context()

func _handle_ui(sample: Dictionary) -> void:
	var pressed: Dictionary = sample.get("pressed", {})
	if session.state in ["pausa", "bencao"] and pressed.get("pausar", false):
		if session.state == "pausa":
			session.resume()
		else:
			session.pause()
		return
	var boxes: Array[Rect2] = hud.action_rects()
	if boxes.is_empty():
		return
	var old_selected := selected
	if pressed.get("ui_right", false) or pressed.get("ui_down", false):
		selected = (selected + 1) % boxes.size()
	if pressed.get("ui_left", false) or pressed.get("ui_up", false):
		selected = posmod(selected - 1, boxes.size())
	for i in range(3):
		if session.state == "bencao" and pressed.get("ui_carta_" + str(i + 1), false):
			selected = i
	# Mouse motion updates the same focus; an idle cursor never steals key focus.
	if sample.get("mouse_moved", false):
		for i in boxes.size():
			if boxes[i].has_point(sample.cursor):
				selected = i
	if sample.get("mouse_click", false):
		for i in boxes.size():
			if boxes[i].has_point(sample.get("click_cursor", sample.cursor)):
				selected = i
				activate(i)
				return
	if pressed.get("ui_aceitar", false):
		activate(selected)
	elif pressed.get("ui_voltar", false) and session.state == "pausa":
		# B does not close the pause root; Esc/Start use pausar above.
		selected = old_selected

func _on_resize() -> void:
	if ready_to_play:
		camera.resize(get_window())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_sair()
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and ready_to_play:
		controls.clear()
		# Perda de foco em JOGO ou BENCAO vira PAUSA (ADR-0001, EX-0001-5); MENU não muda.
		if session.state in ["jogo", "bencao"]:
			session.pause()
		elif session.state == "transicao":
			pending_pause = true
		_espelhar_estado()
		sync_context()

func _on_device_disconnected(_id: int = -1) -> void:
	if session.state in ["jogo", "bencao"]:
		session.pause()
	elif session.state == "transicao":
		pending_pause = true
	_espelhar_estado()
	sync_context()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var path := "res://production/qa/evidence/integracao-jogavel/" + capture_mode + ".png"
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", path, " result=", error)
	get_tree().quit(0 if error == OK else 1)

## Fechamento da janela (persistencia story 008, EX-0013-P7): grava pelo Save e sai.
## Sem o épico vinculo-e-pactos não há [code]consolidar_abandono[/code]; sem a tela
## PERFIL_SAIR_SEM_SALVAR (épico hud) a falha é avisada e a saída segue.
func _sair() -> void:
	if save.pedir_saida(Callable()) != OK:
		push_warning("Main: perfil não gravado na saída (PERFIL_SAIR_SEM_SALVAR).")
	get_tree().quit()
