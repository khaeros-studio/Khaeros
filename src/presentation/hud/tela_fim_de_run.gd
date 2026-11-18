class_name TelaFimDeRun
extends Control
## Modelo e Vista da Tela de Fim de Run (`design/ux/tela-fim-de-run.md`, `story-010`).
## - Exibe desfecho (`RUN_FIM_VITORIA`, `RUN_FIM_DERROTA`, `RUN_FIM_ABANDONO`),
##   os 12 campos de `ResumoDaRun` formatados, painel de Vínculo da Doutrina de Pactos,
##   cópia de seed e trava de entrada de `500 ms` na abertura.
## - Botões de ação: `RUN_JOGAR_NOVAMENTE` (foco inicial) e `RUN_MENU_PRINCIPAL`.

signal jogar_novamente_solicitado()
signal menu_principal_solicitado()

const TRAVA_ABERTURA_S: float = 0.50
const BOTAO_JOGAR_NOVAMENTE: int = 0
const BOTAO_MENU_PRINCIPAL: int = 1
const BOTAO_COPIAR_SEED: int = 2

class ResumoDaRun extends RefCounted:
	var desfecho: StringName = &"derrota" # &"vitoria", &"derrota", &"abandono"
	var tempo_run_s: float = 0.0
	var salas_limpas: int = 0
	var inimigos_derrotados: int = 0
	var dano_total_causado: int = 0
	var dano_total_recebido: int = 0
	var fragmentos_coletados: int = 0
	var bencaos_obtidas: Array[StringName] = []
	var arma_id: StringName = &"lamina"
	var doutrina_id: StringName = &"nenhuma"
	var causa_morte_id: StringName = &""
	var seed_texto: String = ""
	# Painel de Vínculo (Doutrina de Pactos)
	var pactos_firmados: Array[StringName] = []
	var chefe_destino_pacto: StringName = &"" # &"", &"pactuado", &"exorcizado"


var _resumo: ResumoDaRun = null
var _trava_restante_s: float = 0.0
var _foco_botao: int = BOTAO_JOGAR_NOVAMENTE
var _aviso_seed_copiada: bool = false
var _copiador_clipboard: Callable = Callable()
var _fila_sons_ui: FilaDeSonsDeInterface = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func abrir(
	resumo: ResumoDaRun,
	fila_sons_ui: FilaDeSonsDeInterface = null,
	copiador_clipboard: Callable = Callable()
) -> void:
	_resumo = resumo if resumo != null else ResumoDaRun.new()
	_fila_sons_ui = fila_sons_ui
	_copiador_clipboard = copiador_clipboard
	_trava_restante_s = TRAVA_ABERTURA_S
	_foco_botao = BOTAO_JOGAR_NOVAMENTE
	_aviso_seed_copiada = false
	visible = true


func fechar() -> void:
	visible = false


func travada_para_confirmacao() -> bool:
	return _trava_restante_s > 0.0


func foco_botao() -> int:
	return _foco_botao


func aviso_seed_copiada() -> bool:
	return _aviso_seed_copiada


func chave_titulo_desfecho() -> StringName:
	if _resumo == null:
		return &"RUN_FIM_DERROTA"
	if _resumo.desfecho == &"vitoria":
		return &"RUN_FIM_VITORIA"
	if _resumo.desfecho == &"abandono":
		return &"RUN_FIM_ABANDONO"
	return &"RUN_FIM_DERROTA"


func painel_vinculo_visivel() -> bool:
	if _resumo == null:
		return false
	return _resumo.doutrina_id == &"pactos" or not _resumo.pactos_firmados.is_empty()


func estatisticas_formatadas() -> Dictionary:
	var r: ResumoDaRun = _resumo if _resumo != null else ResumoDaRun.new()
	return {
		"tempo": FormatoNumerico.formatar_tempo_mm_ss(r.tempo_run_s),
		"salas": FormatoNumerico.formatar_inteiro(r.salas_limpas),
		"inimigos": FormatoNumerico.formatar_inteiro(r.inimigos_derrotados),
		"dano_causado": FormatoNumerico.formatar_inteiro(r.dano_total_causado),
		"dano_recebido": FormatoNumerico.formatar_inteiro(r.dano_total_recebido),
		"fragmentos": FormatoNumerico.formatar_inteiro(r.fragmentos_coletados),
		"bencaos_total": FormatoNumerico.formatar_inteiro(r.bencaos_obtidas.size()),
		"arma_id": r.arma_id,
		"doutrina_id": r.doutrina_id,
		"causa_morte_id": r.causa_morte_id,
		"seed": r.seed_texto,
		"chefe_destino_pacto": r.chefe_destino_pacto,
	}


func avancar_tempo(dt_ui: float) -> void:
	if dt_ui > 0.0 and _trava_restante_s > 0.0:
		_trava_restante_s = maxf(0.0, _trava_restante_s - dt_ui)


func processar_entrada(mover: int, aceitar: bool, copiar_seed_atalho: bool = false) -> void:
	if not visible:
		return
	if mover != 0:
		var dir: int = 1 if mover > 0 else -1
		_foco_botao = posmod(_foco_botao + dir, 3)
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_foco", 2)

	if copiar_seed_atalho:
		_executar_copiar_seed()
		return

	if aceitar:
		if travada_para_confirmacao():
			return
		if _foco_botao == BOTAO_JOGAR_NOVAMENTE:
			if _fila_sons_ui != null:
				_fila_sons_ui.pedir(&"ui_confirmar", 1)
			jogar_novamente_solicitado.emit()
		elif _foco_botao == BOTAO_MENU_PRINCIPAL:
			if _fila_sons_ui != null:
				_fila_sons_ui.pedir(&"ui_confirmar", 1)
			menu_principal_solicitado.emit()
		elif _foco_botao == BOTAO_COPIAR_SEED:
			_executar_copiar_seed()


func _executar_copiar_seed() -> void:
	var texto: String = _resumo.seed_texto if _resumo != null else ""
	if _copiador_clipboard.is_valid():
		_copiador_clipboard.call(texto)
	else:
		DisplayServer.clipboard_set(texto)
	_aviso_seed_copiada = true
	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_confirmar", 1)
