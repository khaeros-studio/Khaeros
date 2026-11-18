class_name ArbitroDeFeedback
extends ConsumidorDeEventos
## Árbitro puro de Feedback de Combate (`ADR-0011`, `design/gdd/feedback-de-combate.md`).
## Consome os eventos do passo, consulta o `CatalogoDeRespostas`, aplica preempção,
## respeita o `LimitadorDeFlashes` (F6), seleciona o único `PedidoImpulso` de câmera,
## alimenta o `PoolDeNumeros` e a `DegradacaoDeVfx` sem mutar estado de jogo.

var _tuning: FeedbackTuning = FeedbackTuning.new()
var _catalogo: CatalogoDeRespostas = null
var _seletor_impulso: SeletorDeImpulso = SeletorDeImpulso.new()
var _pool_numeros: PoolDeNumeros = PoolDeNumeros.new()
var _degradacao: DegradacaoDeVfx = DegradacaoDeVfx.new()
var _respostas_vivas: RespostasVivas = RespostasVivas.new()
var _saida: PedidosDeFeedback.SaidaDoArbitro = PedidosDeFeedback.SaidaDoArbitro.new()

var _estado_visual: EstadoVisual = null
var _camera_impulsos: ImpulsosDeCamera = null
var _reduzir_flashes: bool = false
var _epoca_camera: int = 0
var _t_camera: float = 0.0


func _init(tuning: FeedbackTuning = null) -> void:
	configurar(tuning if tuning != null else FeedbackTuning.new())


func configurar(
	tuning: FeedbackTuning,
	estado_visual: EstadoVisual = null,
	camera_impulsos: ImpulsosDeCamera = null
) -> void:
	_tuning = tuning if tuning != null else FeedbackTuning.new()
	_catalogo = CatalogoDeRespostas.new(_tuning)
	_pool_numeros.configurar(_tuning.teto_numeros_simultaneos, _tuning.janela_soma_s)
	_degradacao.configurar(_tuning)
	_estado_visual = estado_visual
	_camera_impulsos = camera_impulsos


func configurar_acessibilidade(
	intensidade_tremor: float = 1.0,
	reduzir_flashes: bool = false,
	numeros_dano: StringName = &"ligado",
	reduzir_movimento: bool = false
) -> void:
	_reduzir_flashes = reduzir_flashes
	_seletor_impulso.configurar_acessibilidade(intensidade_tremor, reduzir_movimento)
	_pool_numeros.definir_modo_acessibilidade(numeros_dano)
	if _estado_visual != null:
		_estado_visual.configurar_acessibilidade(reduzir_flashes, reduzir_movimento)


func saida() -> PedidosDeFeedback.SaidaDoArbitro:
	return _saida


func pool_numeros() -> PoolDeNumeros:
	return _pool_numeros


func degradacao() -> DegradacaoDeVfx:
	return _degradacao


func respostas_vivas() -> RespostasVivas:
	return _respostas_vivas


func seletor_impulso() -> SeletorDeImpulso:
	return _seletor_impulso


## Implementação do contrato abstrato `ConsumidorDeEventos.consumir`.
func consumir(eventos: Array[EventoDoPasso]) -> void:
	var descritores: Array[Dictionary] = []
	for ev: EventoDoPasso in eventos:
		if ev == null:
			continue
		descritores.append(_converter_evento_do_passo(ev))
	processar_descritores(descritores, 0.0, _epoca_camera, _t_camera)


## Processa uma lista de descritores de eventos do passo de forma determinística.
## Cada descritor pode conter: `{"id": StringName, "alvo_id": int, "dano": int, "pos": Vector2,
## "direcao": Vector2, "critico": bool, "fonte_maldicao": bool, "status": bool, "slot_telegrafo": int, "area_norm": float}`.
func processar_descritores(
	eventos: Array[Dictionary],
	uso_orcamento: float = 0.0,
	epoca_camera: int = 0,
	t_camera: float = 0.0
) -> PedidosDeFeedback.SaidaDoArbitro:
	_epoca_camera = epoca_camera
	_t_camera = t_camera
	_saida.limpar()
	_seletor_impulso.limpar_passo()
	_degradacao.iniciar_passo(uso_orcamento)

	for ev: Dictionary in eventos:
		var id_ev: StringName = ev.get("id", &"")
		if id_ev == &"":
			continue
		_processar_um_evento(id_ev, ev)

	if uso_orcamento >= 1.0:
		_degradacao.cortar_ativos_no_teto(_respostas_vivas.vfx_ativos(), 2)

	_saida.pedido_impulso = _seletor_impulso.despachar_para_camera(_camera_impulsos, epoca_camera, t_camera)
	return _saida


func _processar_um_evento(id_ev: StringName, ev: Dictionary) -> void:
	var resp: CatalogoDeRespostas.RespostaDeEvento = _catalogo.obter(id_ev)
	var alvo_id: int = int(ev.get("alvo_id", -1))
	var pos: Vector2 = ev.get("pos", Vector2.ZERO)
	var dir: Vector2 = ev.get("direcao", Vector2.RIGHT)
	var dano: int = int(ev.get("dano", 0))
	var critico: bool = bool(ev.get("critico", false))
	var fonte_maldicao: bool = bool(ev.get("fonte_maldicao", id_ev == &"maldicao_atacou"))
	var eh_status: bool = bool(ev.get("status", id_ev == &"tick_status"))

	# 1. Regras de marca do Virote e morte de inimigo (R15)
	if id_ev == &"virote_marcou":
		_respostas_vivas.registrar_marca_virote(alvo_id)
	elif id_ev == &"virote_expirou" or id_ev == &"inimigo_eliminado":
		_respostas_vivas.limpar_marca_virote_se_alvo(alvo_id)

	# 2. Números de dano flutuantes
	if dano > 0:
		_pool_numeros.registrar_dano(id_ev, alvo_id, dano, pos, critico, fonte_maldicao, eh_status)

	if resp == null:
		return

	# 3. Gancho de áudio (deduplicado por gancho no mesmo passo mantendo menor número de prioridade)
	if resp.gancho_som != &"":
		_adicionar_pedido_som_deduplicado(resp.gancho_som, resp.prioridade, alvo_id)

	# 4. Impulso de câmera (SeletorDeImpulso garante remetente único e ignora maldicao_atacou/atingida)
	if resp.preset_camera != &"" and resp.escala_camera > 0.0:
		_seletor_impulso.propor(id_ev, resp.preset_camera, resp.escala_camera, dir, resp.prioridade)

	# 5. Impact frame com consulta ao LimitadorDeFlashes (F6)
	if resp.modo_impacto > 0 and resp.duracao_impacto_passos > 0:
		var eh_chefe: bool = (resp.modo_impacto == 3)
		var eh_recusa: bool = (resp.modo_impacto == 1)
		var aceito_f6: bool = true
		if _reduzir_flashes:
			aceito_f6 = false
		elif _estado_visual != null:
			var dur_s: float = float(resp.duracao_impacto_passos) / 60.0
			aceito_f6 = _estado_visual.solicitar_impacto(dur_s, eh_chefe)
		if aceito_f6:
			if _saida.pedido_impacto == null or resp.modo_impacto > _saida.pedido_impacto.modo:
				_saida.pedido_impacto = PedidosDeFeedback.PedidoImpacto.new(
					resp.modo_impacto, resp.duracao_impacto_passos, eh_chefe, eh_recusa
				)

	# 6. Passe de tela (vinheta de dano/recusa ou passe obrigatório de morte)
	if resp.tipo_passe != &"":
		var obrig: bool = (resp.tipo_passe == &"morte")
		_saida.pedidos_passe.append(PedidosDeFeedback.PedidoPasse.new(resp.tipo_passe, 1.0, 0.35, obrig))

	# 7. Disparo de telégrafo com consulta ao LimitadorDeFlashes (F6)
	if id_ev == &"telegrafo_disparou":
		var slot_tel: int = int(ev.get("slot_telegrafo", 0))
		var area_norm: float = float(ev.get("area_norm", 0.12))
		var flash_ok: bool = not _reduzir_flashes
		if flash_ok and _estado_visual != null:
			flash_ok = _estado_visual.limitador_flashes().avaliar_pedido(0.20, area_norm, _t_camera) <= 0.20
		_saida.flashes_telegrafo.append(PedidosDeFeedback.PedidoFlashTelegrafo.new(slot_tel, area_norm, flash_ok))

	# 8. VFX de entidade / estrela de acerto com limitador de 20 passos para maldicao_atingida
	if id_ev == &"maldicao_atingida":
		if not _respostas_vivas.pode_emitir_flash_maldicao(alvo_id):
			return

	if _degradacao.aceita_vfx(resp.prioridade, resp.gera_estrela_acerto):
		var z_camada: int = PedidosDeFeedback.Z_ESTRELA_ACERTO if resp.gera_estrela_acerto else PedidosDeFeedback.Z_CORPO
		var pedido_vfx: PedidosDeFeedback.PedidoVfx = PedidosDeFeedback.PedidoVfx.new(
			id_ev,
			alvo_id,
			pos,
			resp.cor_vfx,
			resp.prioridade,
			resp.relogio,
			z_camada,
			0.18,
			resp.gera_estrela_acerto
		)
		_saida.pedidos_vfx.append(pedido_vfx)
		_respostas_vivas.adicionar_vfx(pedido_vfx)


func _adicionar_pedido_som_deduplicado(gancho: StringName, prio: int, alvo_id: int) -> void:
	for p: PedidoDeSom in _saida.pedidos_som:
		if p.gancho == gancho:
			if prio < p.prioridade:
				p.prioridade = prio
			return
	_saida.pedidos_som.append(PedidoDeSom.new(gancho, prio, alvo_id))


func _converter_evento_do_passo(ev: EventoDoPasso) -> Dictionary:
	var nome_classe: String = ev.get_script().get_global_name() if ev.get_script() != null else ""
	if nome_classe == "EvTelegrafoDisparado":
		return {"id": &"telegrafo_disparou"}
	if nome_classe == "EvTelegrafoQuebrado":
		return {"id": &"telegrafo_quebrado"}
	return {"id": StringName(nome_classe.to_snake_case())}
