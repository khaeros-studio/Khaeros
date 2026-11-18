class_name ProvedorDeEntrada
extends RefCounted
## Provedor de entrada por passo (GDD input-e-controle R2–R7; ADR-0006 §1–§4). Lógica pura, sem `Input`
## nem árvore: recebe o lote reduzido de uma fonte injetada (o `AdaptadorDeEntradaGodot.drenar` em produção,
## lotes roteirizados nos testes), o mapa de binds, os ajustes e as consultas de mira.
##
## Chamado exatamente uma vez por `passo_fisico`, inclusive fora de Jogo: `amostrar` drena o lote uma vez,
## resolve ações pelo contexto, aplica F1/F2, F5, a mira (F4) e F3, e devolve uma `AmostraDeEntrada`.
## Os consumidores de regra recebem `ComandosDoPasso`; a Apresentação recebe só a amostra.

var _fonte: Callable
var _indice: Dictionary = {}          # familia -> contexto -> chave_logica -> Array[StringName] (chaves)
var _dispositivo := DispositivoAtivo.new()
var _mira := Mira.new()
var _buffer := BufferDeComandos.new()
var _comandos: ComandosDoPasso = null

var _tem_ajustes: bool = false
var _zona_interna: float = 0.0
var _zona_externa: float = 0.0
var _limiar_mouse: float = 0.0
var _raio_mira: float = 0.0

var _janela_para_mundo: Callable = Callable()
var _consulta_alvos: Callable = Callable()
var _consulta_jogador: Callable = Callable()

var _contexto: StringName = &""
var _epoca: int = 0
var _barreira := BarreiraDeTroca.new()
var _tuning: Resource = null
var _aplicar_limiares: Callable = Callable()
var _retirar_limiares: Callable = Callable()
var _mapa := MapaDeBinds.padrao()
var _rotulos := RotulosDeAcao.new()
var _fisicos_por_acao: Dictionary = {} # acao -> Array[StringName] chaves físicas seguradas no passo anterior


## `fonte`: Callable sem argumentos que devolve `AdaptadorDeEntradaGodot.Lote`. `mapa`: mapa de binds
## (vazio = `BindsPadrao.mapa()`).
func _init(fonte: Callable, mapa: Dictionary = {}) -> void:
	_fonte = fonte
	if not mapa.is_empty():
		_mapa = MapaDeBinds.de_dicionario(mapa)
	configurar_mapa(_mapa.binds)


## Publica um mapa de binds já validado e indexa por família e contexto.
func configurar_mapa(mapa: Dictionary) -> void:
	_indice.clear()
	for familia: StringName in mapa:
		var por_contexto: Dictionary = {}
		var binds_familia: Dictionary = mapa[familia]
		for chave: StringName in binds_familia:
			for contexto: StringName in Acoes.contextos(Acoes.acao_da_chave(chave)):
				if not por_contexto.has(contexto):
					por_contexto[contexto] = {}
				var por_bind: Dictionary = por_contexto[contexto]
				for bind: Dictionary in binds_familia[chave]:
					var logica := DescritorDeEntrada.de_bind(bind).chave_logica()
					if not por_bind.has(logica):
						por_bind[logica] = [] as Array[StringName]
					(por_bind[logica] as Array).append(chave)
		_indice[familia] = por_contexto


## Ajustes do `InputTuning` (a leitura do recurso é da story 006): zonas mortas (F2), limiar do mouse
## (F5, px/passo), prazo do buffer (F3, passos) e raio da mira automática (F4, px, inclusivo).
func configurar_ajustes(zona_interna: float, zona_externa: float, limiar_mouse_px: float, buffer_passos: int,
		raio_mira_px: float) -> void:
	_zona_interna = zona_interna
	_zona_externa = zona_externa
	_limiar_mouse = limiar_mouse_px
	_raio_mira = raio_mira_px
	_buffer.configurar(buffer_passos)
	_tem_ajustes = true


## Retira os ajustes: só navegação digital, cliques e botões continuam (ADR-0006 §4).
func retirar_ajustes() -> void:
	_tem_ajustes = false
	_buffer.configurar(0)


## Injeta o `InputTuning` do catálogo validado (story 006; ADR-0006 §4, ADR-0004); `null` retira os ajustes.
## Campos lidos por nome: `zona_morta_interna`, `zona_morta_externa`, `limiar_mouse_px`, `buffer_passos`,
## `raio_mira_px`, `gatilho_aperta`, `gatilho_solta`. Injetar ou retirar limpa resíduos analógicos (na fonte,
## pelos Callables de `vincular_limiares`) e aplica a barreira de contexto antes de voltar a admitir ações.
## O recurso é tratado como imutável; a validação (`zm + ze < 1`, V2) é do catálogo.
func configurar_tuning(tuning: Resource) -> void:
	_tuning = tuning
	if _retirar_limiares.is_valid():
		_retirar_limiares.call()
	if tuning == null:
		retirar_ajustes()
	else:
		configurar_ajustes(_campo(tuning, &"zona_morta_interna"), _campo(tuning, &"zona_morta_externa"),
				_campo(tuning, &"limiar_mouse_px"), int(_campo(tuning, &"buffer_passos")),
				_campo(tuning, &"raio_mira_px"))
		if _aplicar_limiares.is_valid():
			_aplicar_limiares.call(_campo(tuning, &"zona_morta_interna"), _campo(tuning, &"gatilho_aperta"),
					_campo(tuning, &"gatilho_solta"))
	aplicar_barreira()


## Tuning injetado (ou `null`).
func tuning() -> Resource:
	return _tuning


## Liga a injeção do tuning aos limiares da fonte: `aplicar(zona_morta, gatilho_aperta, gatilho_solta)` e
## `retirar()` (em produção, `AdaptadorDeEntradaGodot.configurar_limiares` e `retirar_limiares`).
func vincular_limiares(aplicar: Callable, retirar: Callable) -> void:
	_aplicar_limiares = aplicar
	_retirar_limiares = retirar


## Publica um mapa de binds já validado pela transação (story 007) e aplica a barreira de contexto, para não
## converter entradas já seguradas em novos comandos (ADR-0006 §6).
func publicar_mapa(mapa: MapaDeBinds) -> void:
	_mapa = mapa.copia()
	configurar_mapa(_mapa.binds)
	aplicar_barreira()


## Mapa de binds ativo (cópia).
func mapa() -> MapaDeBinds:
	return _mapa.copia()


## Formatador de rótulos (injete um com o rótulo de tecla do layout ativo e o relator de avisos).
func configurar_rotulos(rotulos: RotulosDeAcao) -> void:
	_rotulos = rotulos


## `{texto, glifo}` do bind primário atual de `acao` em `dispositivo` (`teclado`/`gamepad`); inválidos
## devolvem rótulo vazio e um aviso (GDD input-e-controle, Interactions; ADR-0006 §6).
func rotulo_acao(acao: StringName, dispositivo: StringName) -> Dictionary:
	return _rotulos.rotulo(_mapa, acao, dispositivo)


## Barreira sem mudar de contexto: nova época, capacidade inválida, buffer vazio e entradas seguradas
## bloqueadas até a soltura (troca de mapa, injeção/retirada de tuning, perda de foco).
func aplicar_barreira() -> void:
	_epoca += 1
	if _comandos != null:
		_comandos.invalidar()
	_buffer.esvaziar()
	var chaves: Array[StringName] = []
	for lista: Array in _fisicos_por_acao.values():
		for chave: StringName in lista:
			chaves.append(chave)
	_barreira.armar(chaves)


## Consultas da mira, injetadas como valores (ADR-0006 §4, ADR-0007): `janela_para_mundo(Vector2) -> Vector2`
## (snapshot da Cena, base `pos`), `consulta_alvos() -> Array[{pos, surgindo}]` em ordem de spawn e
## `consulta_jogador() -> {pos: Vector2, olhar: Vector2}`.
func configurar_mira(janela_para_mundo: Callable, consulta_alvos: Callable, consulta_jogador: Callable) -> void:
	_janela_para_mundo = janela_para_mundo
	_consulta_alvos = consulta_alvos
	_consulta_jogador = consulta_jogador


## Troca de contexto: nova época, capacidade corrente inválida, buffer vazio e barreira física na próxima
## amostra (entradas seguradas bloqueadas até a soltura; toques do intervalo descartados).
func trocar_contexto(contexto: StringName) -> void:
	_contexto = contexto
	aplicar_barreira()


## Amostra única do passo. Um contexto diferente do corrente aplica `trocar_contexto` antes.
func amostrar(id_passo: int, contexto: StringName, hitstop: bool) -> AmostraDeEntrada:
	if _comandos != null:
		_comandos.invalidar()
	if _contexto == &"":
		# Primeiro contexto da sessão: nada foi roteado antes, então não há barreira a aplicar.
		_contexto = contexto
		_epoca += 1
	elif contexto != _contexto:
		trocar_contexto(contexto)
	var lote: AdaptadorDeEntradaGodot.Lote = _fonte.call()

	var fisicos: Dictionary = {}
	for descritor: DescritorDeEntrada in lote.segurados:
		fisicos[descritor.chave_fisica()] = descritor
	var bordas := _barreira.filtrar(fisicos, lote.bordas)

	var teclado_mouse := lote.ordem_teclado_mouse() >= 0
	if _tem_ajustes and DispositivoAtivo.mouse_significativo(lote.deslocamento_mouse, _limiar_mouse):
		teclado_mouse = true
	_dispositivo.atualizar(teclado_mouse, lote.gamepads_significativos)

	# Ações seguradas (por entrada física não bloqueada) e chaves direcionais seguradas.
	var segurados: Array[StringName] = []
	var chaves_seguradas: Dictionary = {}
	var fisicos_por_acao: Dictionary = {}
	for chave_fisica: StringName in fisicos:
		if _barreira.bloqueado(chave_fisica):
			continue
		var descritor: DescritorDeEntrada = fisicos[chave_fisica]
		for chave: StringName in _chaves_de(descritor, contexto):
			chaves_seguradas[chave] = true
			var acao := Acoes.acao_da_chave(chave)
			if not segurados.has(acao):
				segurados.append(acao)
			if not fisicos_por_acao.has(acao):
				fisicos_por_acao[acao] = [] as Array[StringName]
			(fisicos_por_acao[acao] as Array).append(chave_fisica)

	# Apertados: uma vez por ação, em ordem de chegada. Uma borda não conta se outra entrada física da mesma
	# ação já estava segurada no passo anterior e continua segurada (segundo bind não rearma).
	var apertados: Array[StringName] = []
	for borda: AdaptadorDeEntradaGodot.Borda in bordas:
		var chave_fisica := borda.descritor.chave_fisica()
		if _barreira.bloqueado(chave_fisica):
			continue
		for chave: StringName in _chaves_de(borda.descritor, contexto):
			var acao := Acoes.acao_da_chave(chave)
			if apertados.has(acao) or _outro_bind_continuo(acao, chave_fisica, fisicos):
				continue
			apertados.append(acao)
	_fisicos_por_acao = fisicos_por_acao

	var em_jogo := contexto == Acoes.CONTEXTO_JOGO
	var mover := Vector2.ZERO
	var direito := Vector2.ZERO
	if em_jogo:
		var teclado := MovimentoF1F2.teclado(
				chaves_seguradas.has(Acoes.chave_direcional(Acoes.MOVER, Acoes.DIRECAO_CIMA)),
				chaves_seguradas.has(Acoes.chave_direcional(Acoes.MOVER, Acoes.DIRECAO_BAIXO)),
				chaves_seguradas.has(Acoes.chave_direcional(Acoes.MOVER, Acoes.DIRECAO_ESQUERDA)),
				chaves_seguradas.has(Acoes.chave_direcional(Acoes.MOVER, Acoes.DIRECAO_DIREITA)))
		var esquerdo := Vector2.ZERO
		if _tem_ajustes and lote.analogicos.has(_dispositivo.gamepad):
			var eixos: Vector4 = lote.analogicos[_dispositivo.gamepad]
			esquerdo = MovimentoF1F2.zona_morta_radial(Vector2(eixos.x, eixos.y), _zona_interna, _zona_externa)
			direito = MovimentoF1F2.zona_morta_radial(Vector2(eixos.z, eixos.w), _zona_interna, _zona_externa)
		mover = MovimentoF1F2.combinar(teclado, esquerdo)
		if _tem_ajustes:
			_calcular_mira(lote, mover, direito)
		_buffer.atualizar(apertados, id_passo, _epoca, hitstop)
	else:
		_buffer.esvaziar()

	var amostra := AmostraDeEntrada.new(segurados, apertados, _buffer.visao())
	amostra.id_passo = id_passo
	amostra.epoca_contexto = _epoca
	amostra.contexto = contexto
	amostra.mover = mover
	amostra.mirar = _mira.mirar
	amostra.fonte_mira = _mira.fonte_mira
	amostra.intensidade_mira = _mira.intensidade_mira
	amostra.ponto_mira = _mira.ponto_mira
	amostra.tem_ponto_mira = _mira.tem_ponto_mira and em_jogo and _tem_ajustes
	amostra.dispositivo_ativo = _dispositivo.atual
	amostra.prazo_buffer = _buffer.prazo()
	_comandos = ComandosDoPasso.new(_buffer, segurados, id_passo, _epoca)
	return amostra


## Capacidade de consumo do passo corrente; para outro passo devolve uma capacidade já inválida.
func comandos_do_passo(id_passo: int) -> ComandosDoPasso:
	if _comandos != null and _comandos.id_passo() == id_passo and _comandos.valida():
		return _comandos
	var invalida := ComandosDoPasso.new(_buffer, [] as Array[StringName], id_passo, _epoca)
	invalida.invalidar()
	return invalida


## Fim do passo: invalida a capacidade do passo.
func encerrar_passo(id_passo: int) -> void:
	if _comandos != null and _comandos.id_passo() == id_passo:
		_comandos.invalidar()


## Dispositivo ativo (R3).
func dispositivo_ativo() -> StringName:
	return _dispositivo.atual


## Gamepad corrente (último significativo); -1 se nenhum.
func gamepad_ativo() -> int:
	return _dispositivo.gamepad


## Época corrente do contexto.
func epoca() -> int:
	return _epoca


## Complemento ADR-0008 (repasse do buffer): toques de esquiva feitos durante hitstop.
func drenar_esquivas_congeladas() -> int:
	return _buffer.drenar_esquivas_congeladas()


func _campo(tuning: Resource, nome: StringName) -> float:
	var valor: Variant = tuning.get(nome)
	if valor == null:
		push_warning("InputTuning sem o campo %s" % nome)
		return 0.0
	return float(valor)


func _chaves_de(descritor: DescritorDeEntrada, contexto: StringName) -> Array:
	var familia := descritor.familia()
	if familia == Acoes.DISPOSITIVO_GAMEPAD and descritor.dispositivo != _dispositivo.gamepad:
		return []
	var por_contexto: Dictionary = _indice.get(familia, {})
	var por_bind: Dictionary = por_contexto.get(contexto, {})
	return por_bind.get(descritor.chave_logica(), [])


func _outro_bind_continuo(acao: StringName, chave_fisica: StringName, fisicos: Dictionary) -> bool:
	for anterior: StringName in _fisicos_por_acao.get(acao, []):
		if anterior != chave_fisica and fisicos.has(anterior) and not _barreira.bloqueado(anterior):
			return true
	return false


func _calcular_mira(lote: AdaptadorDeEntradaGodot.Lote, mover: Vector2, direito: Vector2) -> void:
	var jogador: Dictionary = _consulta_jogador.call() if _consulta_jogador.is_valid() else {}
	var pos_jogador: Vector2 = jogador.get("pos", Vector2.ZERO)
	var olhar: Vector2 = jogador.get("olhar", Vector2.ZERO)
	if _dispositivo.atual == Acoes.DISPOSITIVO_TECLADO:
		var tem_cursor := lote.tem_cursor and _janela_para_mundo.is_valid()
		var cursor_mundo: Vector2 = _janela_para_mundo.call(lote.cursor_janela) if tem_cursor else Vector2.ZERO
		_mira.calcular_mouse(cursor_mundo, tem_cursor, pos_jogador)
	else:
		var alvos: Array = _consulta_alvos.call() if _consulta_alvos.is_valid() else []
		_mira.calcular_gamepad(direito, alvos, pos_jogador, _raio_mira, mover, olhar)
