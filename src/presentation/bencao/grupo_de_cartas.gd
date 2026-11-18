class_name GrupoDeCartas
extends RefCounted
## Máquina de 8 estados da fileira de até 3 cartas (`ADR-0012 §5`, `story-002` e `story-003`):
## `Fechada`, `Entrando`, `Travada`, `Livre`, `Trocando`, `Confirmando`, `Saindo`, `Pausada`.
## - F1: largura da fileira `n * 320 + (n - 1) * 40` e escala efetiva `min(escala_ui, 1824.0 / largura(n))`.
## - F2: foco inicial (`1` quando `n == 3`, `0` quando `n <= 2`, ou explícito para modo `arma`).
## - F3: trava de entrada de `500 ms` após pousar na abertura (`trava_abertura_s`) e
##   `300 ms` após trocar ofertas ou retornar de pausa (`trava_troca_s`), durante a qual
##   foco se move livremente mas confirmação e troca são ignoradas.
## - Ordem no mesmo passo: `trocar` é testado antes de `aceitar`.

enum Estado {
	FECHADA = 0,
	ENTRANDO = 1,
	TRAVADA = 2,
	LIVRE = 3,
	TROCANDO = 4,
	CONFIRMANDO = 5,
	SAINDO = 6,
	PAUSADA = 7,
}

const LARGURA_UTIL_TELA_PX: float = 1824.0 # 1920 - 2 * 48

var _tuning: TelaBencaoTuning = TelaBencaoTuning.new()
var _foco: ModeloDeFoco = ModeloDeFoco.new()
var _porta: PortasDaBencao.PortaDaBencao = null
var _fila_sons_ui: FilaDeSonsDeInterface = null

var _estado: Estado = Estado.FECHADA
var _estado_antes_da_pausa: Estado = Estado.LIVRE
var _modo: StringName = &"bencao" # &"bencao", &"arma", &"maldicao"
var _cartas: Array[DadosDaCarta] = []
var _trocas_restantes: int = 0
var _reduzir_movimento: bool = false

var _tempo_fase_restante_s: float = 0.0
var _carta_confirmada_indice: int = -1
var _preco_revelado_emitido: bool = false
var _tela_fechada_emitida: bool = false
var _sacudida_sem_troca_s: float = 0.0


func _init(tuning: TelaBencaoTuning = null, fila_sons_ui: FilaDeSonsDeInterface = null) -> void:
	if tuning != null:
		_tuning = tuning
	_fila_sons_ui = fila_sons_ui


func configurar(
	tuning: TelaBencaoTuning,
	porta: PortasDaBencao.PortaDaBencao = null,
	fila_sons_ui: FilaDeSonsDeInterface = null,
	reduzir_movimento: bool = false
) -> void:
	if tuning != null:
		_tuning = tuning
	_porta = porta
	if fila_sons_ui != null:
		_fila_sons_ui = fila_sons_ui
	_reduzir_movimento = reduzir_movimento


func abrir(
	cartas: Array[DadosDaCarta],
	modo: StringName = &"bencao",
	trocas_iniciais: int = 0,
	foco_inicial_explicito: int = -1,
	retangulos_cartas: Array[Rect2] = [],
	retangulo_trocar: Rect2 = Rect2()
) -> void:
	_modo = modo
	_cartas = cartas.duplicate()
	if _cartas.size() > 3:
		_cartas.resize(3)
	_trocas_restantes = maxi(0, trocas_iniciais) if modo == &"bencao" else 0
	_carta_confirmada_indice = -1
	_preco_revelado_emitido = false
	_tela_fechada_emitida = false
	_sacudida_sem_troca_s = 0.0

	var n: int = maxi(1, _cartas.size())
	var tem_trocar: bool = (modo == &"bencao" and _trocas_restantes > 0)
	_foco.configurar(n, foco_inicial_explicito, tem_trocar, retangulos_cartas, retangulo_trocar)

	var dur_entrada: float = _calcular_duracao_entrada_total(n)
	if dur_entrada <= 0.0001:
		_estado = Estado.TRAVADA
		_tempo_fase_restante_s = _tuning.trava_abertura_s
	else:
		_estado = Estado.ENTRANDO
		_tempo_fase_restante_s = dur_entrada


func estado() -> Estado:
	return _estado


func modo() -> StringName:
	return _modo


func foco() -> ModeloDeFoco:
	return _foco


func cartas() -> Array[DadosDaCarta]:
	return _cartas


func trocas_restantes() -> int:
	return _trocas_restantes


func carta_confirmada_indice() -> int:
	return _carta_confirmada_indice


func preco_revelado_emitido() -> bool:
	return _preco_revelado_emitido


func tela_fechada_emitida() -> bool:
	return _tela_fechada_emitida


func sacudida_sem_troca_ativa() -> bool:
	return _sacudida_sem_troca_s > 0.0


## F1 — Largura base da fileira a 100% (`n * 320 + (n - 1) * 40`).
static func largura_fileira_100_px(n: int) -> float:
	var qtd: int = clampi(n, 1, 3)
	return float(qtd) * DadosDaCarta.LARGURA_CARTA_100_PX + float(qtd - 1) * DadosDaCarta.ESPACAMENTO_CARTAS_100_PX


## F1 — Escala efetiva da fileira (`min(escala_ui, 1824.0 / largura(n))`).
static func escala_efetiva_fileira(n: int, escala_ui: float) -> float:
	var larg: float = largura_fileira_100_px(n)
	return minf(clampf(escala_ui, 0.80, 1.50), LARGURA_UTIL_TELA_PX / maxf(1.0, larg))


func avancar(dt_ui: float) -> Dictionary:
	var eventos_sinal: Dictionary = {"preco_revelado": false, "tela_fechada": false}
	if dt_ui <= 0.0 or _estado == Estado.FECHADA or _estado == Estado.PAUSADA:
		return eventos_sinal

	if _sacudida_sem_troca_s > 0.0:
		_sacudida_sem_troca_s = maxf(0.0, _sacudida_sem_troca_s - dt_ui)

	if _estado == Estado.ENTRANDO:
		_tempo_fase_restante_s -= dt_ui
		if _tempo_fase_restante_s <= 0.0:
			var sobra: float = -_tempo_fase_restante_s
			_estado = Estado.TRAVADA
			_tempo_fase_restante_s = maxf(0.0, _tuning.trava_abertura_s - sobra)
			if _tempo_fase_restante_s <= 0.0:
				_estado = Estado.LIVRE
	elif _estado == Estado.TRAVADA:
		_tempo_fase_restante_s -= dt_ui
		if _tempo_fase_restante_s <= 0.0:
			_estado = Estado.LIVRE
			_tempo_fase_restante_s = 0.0
	elif _estado == Estado.TROCANDO:
		_tempo_fase_restante_s -= dt_ui
		if _tempo_fase_restante_s <= 0.0:
			_estado = Estado.TRAVADA
			_tempo_fase_restante_s = _tuning.trava_troca_s
	elif _estado == Estado.CONFIRMANDO:
		_tempo_fase_restante_s -= dt_ui
		if _tempo_fase_restante_s <= 0.0:
			if not _preco_revelado_emitido:
				_preco_revelado_emitido = true
				eventos_sinal["preco_revelado"] = true
			_estado = Estado.SAINDO
			_tempo_fase_restante_s = 0.05 if _reduzir_movimento else _tuning.saida_duracao_s
	elif _estado == Estado.SAINDO:
		_tempo_fase_restante_s -= dt_ui
		if _tempo_fase_restante_s <= 0.0:
			_estado = Estado.FECHADA
			if not _tela_fechada_emitida:
				_tela_fechada_emitida = true
				eventos_sinal["tela_fechada"] = true

	return eventos_sinal


func processar_comandos(cmd: ComandosDeTela) -> Dictionary:
	var resultado: Dictionary = {
		"mudou_foco": false,
		"trocou_oferta": false,
		"confirmou_indice": -1,
		"abriu_pausa": false,
	}
	if cmd == null or _estado == Estado.FECHADA or _estado == Estado.CONFIRMANDO or _estado == Estado.SAINDO:
		return resultado

	if cmd.pausar and _estado != Estado.PAUSADA:
		_estado_antes_da_pausa = _estado
		_estado = Estado.PAUSADA
		resultado["abriu_pausa"] = true
		return resultado

	if _estado == Estado.PAUSADA:
		return resultado

	var permite_confirmar: bool = (_estado == Estado.LIVRE)
	# Em ENTRANDO, TRAVADA ou TROCANDO, o foco se move livremente mas não confirma
	var res_foco: ModeloDeFoco.ResultadoFoco = _foco.processar(cmd, permite_confirmar)
	if res_foco.mudou_foco:
		resultado["mudou_foco"] = true
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_foco", 2)

	# Se tentar trocar quando trocas == 0 no estado LIVRE -> sacudida e som negado
	if permite_confirmar and cmd.trocar and _modo == &"bencao" and _trocas_restantes <= 0:
		_sacudida_sem_troca_s = 0.15
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_negado", 2)
		return resultado

	if res_foco.acionar_trocar and permite_confirmar:
		if _executar_troca_de_oferta():
			resultado["trocou_oferta"] = true
		return resultado

	if res_foco.confirmar_carta >= 0 and permite_confirmar:
		var idx: int = res_foco.confirmar_carta
		if idx < _cartas.size() and not _cartas[idx].desabilitada:
			if _executar_confirmacao(idx):
				resultado["confirmou_indice"] = idx
		elif _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_negado", 2)

	return resultado


func retomar_da_pausa() -> void:
	if _estado != Estado.PAUSADA:
		return
	# Ao voltar da pausa sobre a Bênção, aplica trava de segurança de 300 ms
	_estado = Estado.TRAVADA
	_tempo_fase_restante_s = _tuning.trava_troca_s


func _executar_troca_de_oferta() -> bool:
	if _modo != &"bencao" or _trocas_restantes <= 0:
		_sacudida_sem_troca_s = 0.15
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_negado", 2)
		return false
	if _porta != null:
		if not _porta.trocar_oferta():
			return false
		_cartas = _porta.cartas_atuais().duplicate()
		_trocas_restantes = _porta.trocas_restantes()
	else:
		_trocas_restantes -= 1

	var n: int = maxi(1, _cartas.size())
	_foco.configurar(n, -1, _trocas_restantes > 0)
	_estado = Estado.TROCANDO
	_tempo_fase_restante_s = 0.05 if _reduzir_movimento else (_tuning.troca_saida_s + _tuning.troca_entrada_s)
	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_trocar_oferta", 1)
	return true


func _executar_confirmacao(indice: int) -> bool:
	if _porta != null:
		if not _porta.escolher_carta(indice):
			return false
	_carta_confirmada_indice = indice
	_estado = Estado.CONFIRMANDO
	_tempo_fase_restante_s = 0.05 if _reduzir_movimento else _tuning.confirmacao_duracao_s
	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_confirmar", 1)
	return true


func _calcular_duracao_entrada_total(n: int) -> float:
	if _reduzir_movimento:
		return 0.0
	return _tuning.entrada_duracao_s + float(maxi(0, n - 1)) * _tuning.entrada_atraso_carta_s
