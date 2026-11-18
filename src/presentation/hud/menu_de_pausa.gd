class_name MenuDePausa
extends Control
## Modelo e Vista do Menu de Pausa (`design/ux/pausa-e-opcoes.md`, `story-008`).
## - Ações: `PAUSA_CONTINUAR`, `PAUSA_OPCOES`, `PAUSA_COPIAR_SEED`, `PAUSA_ABANDONAR`.
## - `PAUSA_ABANDONAR` exige confirmação modal cujo foco inicial é sempre `PAUSA_CONFIRMAR_NAO` (Cancelar)
##   e fica desabilitado quando a pausa foi aberta sobre `EstadoDeJogo.BENCAO`.
## - Barreira de retorno ao ganhar foco de janela: exige soltar `pausar`/`aceitar` antes de aceitar comando.
## - Cópia de seed via porta injetável (`Callable` / `DisplayServer.clipboard_set`) com aviso `PAUSA_SEED_COPIADA`.

signal continuar_solicitado()
signal opcoes_solicitado()
signal abandonar_confirmado()

const ACAO_CONTINUAR: int = 0
const ACAO_OPCOES: int = 1
const ACAO_COPIAR_SEED: int = 2
const ACAO_ABANDONAR: int = 3
const TOTAL_ACOES: int = 4

const CHAVES_ACOES: Array[StringName] = [
	&"PAUSA_CONTINUAR",
	&"PAUSA_OPCOES",
	&"PAUSA_COPIAR_SEED",
	&"PAUSA_ABANDONAR",
]

var _aberto: bool = false
var _aberto_sobre_bencao: bool = false
var _foco_indice: int = ACAO_CONTINUAR
var _confirmacao_abandono_aberta: bool = false
var _foco_confirmacao_sim: bool = false # false = Cancelar (padrão seguro), true = Confirmar abandono
var _barreira_retorno_ativa: bool = false

var _seed_texto: String = ""
var _aviso_seed_restante_s: float = 0.0
var _copiador_area_transferencia: Callable = Callable()
var _fila_sons_ui: FilaDeSonsDeInterface = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func configurar(
	seed_texto: String,
	fila_sons_ui: FilaDeSonsDeInterface = null,
	copiador_clipboard: Callable = Callable()
) -> void:
	_seed_texto = seed_texto
	_fila_sons_ui = fila_sons_ui
	_copiador_area_transferencia = copiador_clipboard


func abrir(sobre_bencao: bool = false, com_barreira_foco_janela: bool = false) -> void:
	_aberto = true
	_aberto_sobre_bencao = sobre_bencao
	_foco_indice = ACAO_CONTINUAR
	_confirmacao_abandono_aberta = false
	_foco_confirmacao_sim = false
	_barreira_retorno_ativa = com_barreira_foco_janela
	_aviso_seed_restante_s = 0.0
	visible = true
	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_pausa_abrir", 1)


func fechar() -> void:
	_aberto = false
	_confirmacao_abandono_aberta = false
	_barreira_retorno_ativa = false
	visible = false
	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_pausa_fechar", 1)


func esta_aberto() -> bool:
	return _aberto


func confirmacao_abandono_aberta() -> bool:
	return _confirmacao_abandono_aberta


func foco_confirmacao_eh_cancelar() -> bool:
	return not _foco_confirmacao_sim


func indice_foco() -> int:
	return _foco_indice


func abandonar_habilitado() -> bool:
	return not _aberto_sobre_bencao


func seed_copiada_visivel() -> bool:
	return _aviso_seed_restante_s > 0.0


func chave_aviso_seed() -> StringName:
	return &"PAUSA_SEED_COPIADA" if _aviso_seed_restante_s > 0.0 else &""


func avancar_tempo_real(dt_real: float) -> void:
	if _aviso_seed_restante_s > 0.0 and dt_real > 0.0:
		_aviso_seed_restante_s = maxf(0.0, _aviso_seed_restante_s - dt_real)


func liberar_barreira_retorno() -> void:
	_barreira_retorno_ativa = false


func processar_entrada(
	mover_vertical: int,
	mover_horizontal: int,
	aceitar: bool,
	voltar_ou_pausar: bool
) -> void:
	if not _aberto:
		return
	if _barreira_retorno_ativa:
		if not aceitar and not voltar_ou_pausar and mover_vertical == 0 and mover_horizontal == 0:
			_barreira_retorno_ativa = false
		return

	if _confirmacao_abandono_aberta:
		if voltar_ou_pausar:
			_confirmacao_abandono_aberta = false
			_foco_confirmacao_sim = false
			if _fila_sons_ui != null:
				_fila_sons_ui.pedir(&"ui_voltar", 2)
			return
		if mover_horizontal != 0 or mover_vertical != 0:
			_foco_confirmacao_sim = not _foco_confirmacao_sim
			if _fila_sons_ui != null:
				_fila_sons_ui.pedir(&"ui_foco", 2)
		if aceitar:
			if _foco_confirmacao_sim:
				fechar()
				abandonar_confirmado.emit()
			else:
				_confirmacao_abandono_aberta = false
				if _fila_sons_ui != null:
					_fila_sons_ui.pedir(&"ui_voltar", 2)
		return

	if voltar_ou_pausar:
		fechar()
		continuar_solicitado.emit()
		return

	if mover_vertical != 0:
		var passo: int = 1 if mover_vertical > 0 else -1
		_foco_indice = posmod(_foco_indice + passo, TOTAL_ACOES)
		if _foco_indice == ACAO_ABANDONAR and not abandonar_habilitado():
			_foco_indice = posmod(_foco_indice + passo, TOTAL_ACOES)
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_foco", 2)

	if aceitar:
		_executar_acao_focada()


func _executar_acao_focada() -> void:
	if _foco_indice == ACAO_CONTINUAR:
		fechar()
		continuar_solicitado.emit()
	elif _foco_indice == ACAO_OPCOES:
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_confirmar", 1)
		opcoes_solicitado.emit()
	elif _foco_indice == ACAO_COPIAR_SEED:
		if _copiador_area_transferencia.is_valid():
			_copiador_area_transferencia.call(_seed_texto)
		else:
			DisplayServer.clipboard_set(_seed_texto)
		_aviso_seed_restante_s = 2.0
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_confirmar", 1)
	elif _foco_indice == ACAO_ABANDONAR:
		if not abandonar_habilitado():
			if _fila_sons_ui != null:
				_fila_sons_ui.pedir(&"ui_negado", 2)
			return
		_confirmacao_abandono_aberta = true
		_foco_confirmacao_sim = false # foco inicial sempre em Cancelar
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_confirmar", 1)
