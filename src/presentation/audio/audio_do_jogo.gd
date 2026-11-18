class_name AudioDoJogo
extends Node
## Nó único dono de todos os `AudioStreamPlayer` do jogo (ADR-0016 §1–§4).
## Pré-aloca 25 players em `_ready()`:
## - 16 de Efeitos (`Efeitos`)
## - 3 de Tons de Telégrafo (`Efeitos`)
## - 4 de Interface (`Interface`)
## - 2 de Música (`Musica`)

const VOZES_EFEITOS: int = 16
const VOZES_TONS: int = 3
const VOZES_INTERFACE: int = 4
const VOZES_MUSICA: int = 2
const TOTAL_PLAYERS: int = VOZES_EFEITOS + VOZES_TONS + VOZES_INTERFACE + VOZES_MUSICA

var _tuning: AudioTuning = AudioTuning.new()
var _mixador: MixadorDeVozes = MixadorDeVozes.new()
var _definicoes: Dictionary = {} # StringName -> SomDef
var _streams_carregados: Dictionary = {} # StringName -> AudioStream
var _ganchos_sem_som_avisados: Dictionary = {} # StringName -> bool
var _avisos_fb2: Array[StringName] = []
var _contador_rr_por_gancho: Dictionary = {} # StringName -> int

var _players_efeitos: Array[AudioStreamPlayer] = []
var _players_tons: Array[AudioStreamPlayer] = []
var _players_interface: Array[AudioStreamPlayer] = []
var _players_musica: Array[AudioStreamPlayer] = []

var _cursor_interface: int = 0
var _estado_anterior: int = EstadoDeJogo.Valor.JOGO
var _volumes_lineares: Dictionary = {
	BarramentosDeAudio.MASTER: 1.0,
	BarramentosDeAudio.EFEITOS: 1.0,
	BarramentosDeAudio.MUSICA: 1.0,
	BarramentosDeAudio.INTERFACE: 1.0,
}

var _slots_tons_buf: PackedInt32Array = PackedInt32Array()
var _pitches_tons_buf: PackedFloat32Array = PackedFloat32Array()
var _faccoes_tons_buf: PackedInt32Array = PackedInt32Array()
var _comandos_buf: Array[ComandoDeVoz] = []
var _pedidos_passo_buf: Array[PedidoDeSom] = []
var _tons_ativos_ultimo_passo: int = 0


func _ready() -> void:
	BarramentosDeAudio.garantir_barramentos_no_servidor()
	_inicializar_pools_se_necessario()


func configurar(tuning: AudioTuning, definicoes_som: Array[SomDef] = []) -> void:
	if tuning != null:
		_tuning = tuning
	_mixador.configurar(_tuning.vozes_max_gancho, _tuning.vozes_max_total)
	_slots_tons_buf.resize(_tuning.teto_tons_telegrafo)
	_pitches_tons_buf.resize(_tuning.teto_tons_telegrafo)
	_faccoes_tons_buf.resize(_tuning.teto_tons_telegrafo)
	_inicializar_pools_se_necessario()
	registrar_definicoes(definicoes_som)


func registrar_definicoes(definicoes_som: Array[SomDef]) -> void:
	for d: SomDef in definicoes_som:
		if d == null or d.id == &"":
			continue
		_definicoes[d.id] = d
		if d.caminho_stream != "" and ResourceLoader.exists(d.caminho_stream):
			var s: Resource = ResourceLoader.load(d.caminho_stream)
			if s is AudioStream:
				_streams_carregados[d.id] = s


func registrar_stream_em_memoria(id_gancho: StringName, stream: AudioStream, ganho_db: float = 0.0) -> void:
	var def: SomDef = SomDef.new()
	def.id = id_gancho
	def.ganho_db = ganho_db
	_definicoes[id_gancho] = def
	if stream != null:
		_streams_carregados[id_gancho] = stream


func iniciar_nova_run() -> void:
	_ganchos_sem_som_avisados.clear()
	_avisos_fb2.clear()
	_contador_rr_por_gancho.clear()


func avisos_fb2_emitidos() -> Array[StringName]:
	return _avisos_fb2.duplicate()


func mixador() -> MixadorDeVozes:
	return _mixador


func total_players_alocados() -> int:
	_inicializar_pools_se_necessario()
	return (
		_players_efeitos.size()
		+ _players_tons.size()
		+ _players_interface.size()
		+ _players_musica.size()
	)


func tons_ativos_no_ultimo_passo() -> int:
	return _tons_ativos_ultimo_passo


func aplicar_volumes(master: float, sfx: float, musica: float, ui: float) -> void:
	_volumes_lineares[BarramentosDeAudio.MASTER] = clampf(master, 0.0, 1.0)
	_volumes_lineares[BarramentosDeAudio.EFEITOS] = clampf(sfx, 0.0, 1.0)
	_volumes_lineares[BarramentosDeAudio.MUSICA] = clampf(musica, 0.0, 1.0)
	_volumes_lineares[BarramentosDeAudio.INTERFACE] = clampf(ui, 0.0, 1.0)
	BarramentosDeAudio.aplicar_volume_barramento(BarramentosDeAudio.MASTER, master)
	BarramentosDeAudio.aplicar_volume_barramento(BarramentosDeAudio.EFEITOS, sfx)
	BarramentosDeAudio.aplicar_volume_barramento(BarramentosDeAudio.MUSICA, musica)
	BarramentosDeAudio.aplicar_volume_barramento(BarramentosDeAudio.INTERFACE, ui)


func volume_linear_barramento(nome: StringName) -> float:
	var canon: StringName = BarramentosDeAudio.normalizar_nome_barramento(nome)
	return float(_volumes_lineares.get(canon, 1.0))


func parar_tudo() -> void:
	_inicializar_pools_se_necessario()
	for p: AudioStreamPlayer in _players_efeitos:
		p.stream_paused = false
		p.stop()
	for p: AudioStreamPlayer in _players_tons:
		p.stream_paused = false
		p.stop()
	for p: AudioStreamPlayer in _players_interface:
		p.stream_paused = false
		p.stop()
	_mixador.zerar()
	_tons_ativos_ultimo_passo = 0


## Verifica se um `AudioStreamPlayer` está efetivamente livre (ADR-0016 §4:
## nunca usar apenas `not player.playing`, pois voz pausada tem `playing == false`).
static func player_esta_livre(player: AudioStreamPlayer) -> bool:
	if player == null:
		return true
	return (not player.playing) and (not player.stream_paused)


func consumir_passo(
	estado_jogo: int,
	pedidos_feedback: Array[PedidoDeSom],
	fila_ui: FilaDeSonsDeInterface,
	vistas_telegrafos: Array[VistaDeTelegrafo],
	quantas_vistas: int
) -> void:
	_inicializar_pools_se_necessario()
	_aplicar_transicao_de_estado(estado_jogo)

	# Sincroniza slots livres no mixador (apenas quando não pausado)
	if estado_jogo != EstadoDeJogo.Valor.PAUSA:
		for i: int in range(_players_efeitos.size()):
			if _mixador.slot_ocupado(i) and player_esta_livre(_players_efeitos[i]):
				_mixador.liberar(i)

	# 1. Sons de Interface (ui_*) tocam mesmo em PAUSA e BENCAO
	_pedidos_passo_buf.clear()
	if fila_ui != null:
		fila_ui.drenar_para(_pedidos_passo_buf)
	for ped_ui: PedidoDeSom in _pedidos_passo_buf:
		_tocar_pedido_interface(ped_ui)

	# 2. Sons de Efeitos (sfx_*)
	if estado_jogo != EstadoDeJogo.Valor.TRANSICAO:
		var validos_sfx: Array[PedidoDeSom] = []
		for ped: PedidoDeSom in pedidos_feedback:
			if ped == null or ped.gancho == &"":
				continue
			if String(ped.gancho).begins_with("ui_"):
				_tocar_pedido_interface(ped)
			elif _validar_gancho_registrado(ped.gancho):
				validos_sfx.append(ped)

		_mixador.resolver(validos_sfx, _comandos_buf)
		for cmd: ComandoDeVoz in _comandos_buf:
			_executar_comando_sfx(cmd)

	# 3. Tons ascendentes dos telégrafos (congelam/silenciam fora de JOGO)
	if estado_jogo == EstadoDeJogo.Valor.JOGO:
		if _slots_tons_buf.size() < _tuning.teto_tons_telegrafo:
			_slots_tons_buf.resize(_tuning.teto_tons_telegrafo)
			_pitches_tons_buf.resize(_tuning.teto_tons_telegrafo)
			_faccoes_tons_buf.resize(_tuning.teto_tons_telegrafo)
		var n_tons: int = SeletorDeTons.selecionar(
			vistas_telegrafos,
			quantas_vistas,
			_tuning.teto_tons_telegrafo,
			_slots_tons_buf,
			_pitches_tons_buf,
			_tuning,
			_faccoes_tons_buf
		)
		_tons_ativos_ultimo_passo = n_tons
		for k: int in range(_players_tons.size()):
			var pt: AudioStreamPlayer = _players_tons[k]
			if k < n_tons:
				pt.pitch_scale = clampf(_pitches_tons_buf[k], 0.25, 4.0)
				if not pt.playing and pt.stream != null:
					pt.play()
			else:
				if pt.playing or pt.stream_paused:
					pt.stream_paused = false
					pt.stop()
	elif estado_jogo != EstadoDeJogo.Valor.PAUSA:
		_tons_ativos_ultimo_passo = 0
		for pt: AudioStreamPlayer in _players_tons:
			pt.stream_paused = false
			pt.stop()


func _aplicar_transicao_de_estado(novo_estado: int) -> void:
	if novo_estado == _estado_anterior:
		return
	if novo_estado == EstadoDeJogo.Valor.PAUSA:
		for p: AudioStreamPlayer in _players_efeitos:
			if p.playing:
				p.stream_paused = true
		for p: AudioStreamPlayer in _players_tons:
			if p.playing:
				p.stream_paused = true
	elif _estado_anterior == EstadoDeJogo.Valor.PAUSA and novo_estado == EstadoDeJogo.Valor.JOGO:
		for p: AudioStreamPlayer in _players_efeitos:
			if p.stream_paused:
				p.stream_paused = false
		for p: AudioStreamPlayer in _players_tons:
			if p.stream_paused:
				p.stream_paused = false
	elif novo_estado == EstadoDeJogo.Valor.BENCAO:
		for p: AudioStreamPlayer in _players_tons:
			p.stream_paused = false
			p.stop()
		_tons_ativos_ultimo_passo = 0
	elif novo_estado == EstadoDeJogo.Valor.TRANSICAO:
		for p: AudioStreamPlayer in _players_efeitos:
			p.stream_paused = false
			p.stop()
		for p: AudioStreamPlayer in _players_tons:
			p.stream_paused = false
			p.stop()
		_mixador.zerar()
		_tons_ativos_ultimo_passo = 0
	_estado_anterior = novo_estado


func _validar_gancho_registrado(gancho: StringName) -> bool:
	if _definicoes.has(gancho):
		return true
	if not _ganchos_sem_som_avisados.has(gancho):
		_ganchos_sem_som_avisados[gancho] = true
		_avisos_fb2.append(gancho)
	return false


func _tocar_pedido_interface(pedido: PedidoDeSom) -> void:
	if not _validar_gancho_registrado(pedido.gancho):
		return
	if _players_interface.is_empty():
		return
	var idx: int = _cursor_interface % _players_interface.size()
	_cursor_interface = (_cursor_interface + 1) % _players_interface.size()
	var player: AudioStreamPlayer = _players_interface[idx]
	_configurar_e_tocar_player(player, pedido.gancho, true)


func _executar_comando_sfx(cmd: ComandoDeVoz) -> void:
	if cmd.slot < 0 or cmd.slot >= _players_efeitos.size():
		return
	var player: AudioStreamPlayer = _players_efeitos[cmd.slot]
	_configurar_e_tocar_player(player, cmd.gancho, cmd.parar_antes)


func _configurar_e_tocar_player(player: AudioStreamPlayer, gancho: StringName, parar_antes: bool) -> void:
	var def: SomDef = _definicoes.get(gancho, null)
	if def == null:
		return
	if parar_antes:
		player.stream_paused = false
		player.stop()
	var rr: int = int(_contador_rr_por_gancho.get(gancho, 0))
	_contador_rr_por_gancho[gancho] = rr + 1
	player.volume_db = def.ganho_db
	player.pitch_scale = clampf(def.pitch_min, 0.25, 4.0)
	var stream: AudioStream = _streams_carregados.get(gancho, null)
	if stream != null:
		player.stream = stream
		player.play()


func _inicializar_pools_se_necessario() -> void:
	if not _players_efeitos.is_empty():
		return
	for i: int in range(VOZES_EFEITOS):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SfxVoice_%d" % i
		p.bus = BarramentosDeAudio.EFEITOS
		add_child(p)
		_players_efeitos.append(p)
	for i: int in range(VOZES_TONS):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "TelegraphTone_%d" % i
		p.bus = BarramentosDeAudio.EFEITOS
		add_child(p)
		_players_tons.append(p)
	for i: int in range(VOZES_INTERFACE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "UiVoice_%d" % i
		p.bus = BarramentosDeAudio.INTERFACE
		add_child(p)
		_players_interface.append(p)
	for i: int in range(VOZES_MUSICA):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "MusicVoice_%d" % i
		p.bus = BarramentosDeAudio.MUSICA
		add_child(p)
		_players_musica.append(p)
