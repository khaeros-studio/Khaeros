class_name ModeloDoHud
extends ConsumidorDeEventos
## Modelo reativo central do HUD (`ADR-0012 §2`, `story-001` a `story-007`).
## Consulta `LeituraDoHud` na construção e ao final de cada `consumir(eventos)`,
## avança os submodelos pelo `RelogioDeInterface` (`t_ui`) e emite sons de UI na
## `FilaDeSonsDeInterface`.

var _leitura: LeituraDoHud = null
var _tuning: HudTuning = HudTuning.new()
var _relogio: RelogioDeInterface = RelogioDeInterface.new()
var _opcoes: OpcoesDoHud = OpcoesDoHud.new()
var _fila_sons_ui: FilaDeSonsDeInterface = null

var _vida: ModeloDaVida = null
var _recursos_mundo: ModeloRecursosEMundo = null
var _bloco_pacto: ModeloDoBlocoDoPacto = null
var _versao_suja: int = 0


func _init(
	leitura: LeituraDoHud = null,
	tuning: HudTuning = null,
	fila_sons_ui: FilaDeSonsDeInterface = null
) -> void:
	configurar(leitura, tuning, fila_sons_ui)


func configurar(
	leitura: LeituraDoHud,
	tuning: HudTuning = null,
	fila_sons_ui: FilaDeSonsDeInterface = null
) -> void:
	_leitura = leitura
	_tuning = tuning if tuning != null else HudTuning.new()
	_fila_sons_ui = fila_sons_ui
	_vida = ModeloDaVida.new(_tuning)
	_recursos_mundo = ModeloRecursosEMundo.new(_tuning)
	_bloco_pacto = ModeloDoBlocoDoPacto.new()
	sincronizar_da_leitura()


func vida_modelo() -> ModeloDaVida:
	return _vida


func recursos_mundo_modelo() -> ModeloRecursosEMundo:
	return _recursos_mundo


func bloco_pacto_modelo() -> ModeloDoBlocoDoPacto:
	return _bloco_pacto


func relogio() -> RelogioDeInterface:
	return _relogio


func opcoes() -> OpcoesDoHud:
	return _opcoes


func versao_suja() -> int:
	return _versao_suja


func aplicar_opcoes(novas_opcoes: OpcoesDoHud) -> void:
	if novas_opcoes == null:
		return
	_opcoes = novas_opcoes
	_bloco_pacto.configurar_acessibilidade(_opcoes.reduzir_movimento)
	_versao_suja += 1


func consumir(eventos: Array[EventoDoPasso]) -> void:
	for ev: EventoDoPasso in eventos:
		if ev == null:
			continue
		var nome_ev: String = ev.get_script().get_global_name() if ev.get_script() != null else ""
		_notificar_evento_por_id(StringName(nome_ev.to_snake_case()))
	sincronizar_da_leitura()


func notificar_eventos_ids(ids: Array[StringName]) -> void:
	for id_ev: StringName in ids:
		_notificar_evento_por_id(id_ev)
	sincronizar_da_leitura()


func notificar_preco_revelado() -> void:
	_vida.notificar_preco_revelado()
	_versao_suja += 1


func avancar_quadro(delta_real: float) -> void:
	var estado: int = _leitura.estado_de_jogo() if _leitura != null else EstadoDeJogo.Valor.JOGO
	var pausado: bool = (estado == EstadoDeJogo.Valor.PAUSA)
	var hitstop: bool = _leitura.hitstop_ativo() if _leitura != null else false
	_relogio.avancar(delta_real, pausado)
	var dt_ui: float = _relogio.dt_ui()
	_vida.avancar(dt_ui, hitstop)
	_recursos_mundo.avancar(dt_ui)
	_bloco_pacto.avancar(dt_ui)


func sincronizar_da_leitura() -> void:
	if _leitura == null:
		return
	var estado: int = _leitura.estado_de_jogo()
	var em_bencao: bool = (estado == EstadoDeJogo.Valor.BENCAO)
	_vida.sincronizar(
		_leitura.vida(),
		_leitura.escudo(),
		_leitura.recusas(),
		_leitura.limiar_fundo_do_poco(),
		em_bencao
	)
	_recursos_mundo.sincronizar_recursos(
		_leitura.fluxo(),
		_leitura.esquiva(),
		_leitura.saldo()
	)
	_recursos_mundo.sincronizar_mundo(
		_leitura.inimigos_feridos(),
		_leitura.porta_interagivel(),
		_leitura.chefe()
	)
	_bloco_pacto.sincronizar(_leitura.estado_pacto())
	_versao_suja += 1


func _notificar_evento_por_id(id_ev: StringName) -> void:
	if id_ev == &"sem_fluxo":
		_recursos_mundo.notificar_sem_fluxo()
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_sem_fluxo", 2)
	elif id_ev == &"esquiva_sem_carga":
		_recursos_mundo.notificar_esquiva_sem_carga()
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_sem_esquiva", 2)
	elif id_ev == &"troca_feita":
		_bloco_pacto.notificar_troca_feita()
	elif id_ev == &"troca_indisponivel":
		_bloco_pacto.notificar_troca_indisponivel()
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_negado", 2)
