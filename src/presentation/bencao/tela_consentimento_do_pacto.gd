class_name TelaDeConsentimentoDoPacto
extends Control
## Modelo e Vista da Tela de Consentimento do Pacto (`design/ux/tela-consentimento-do-pacto.md`, `story-009`).
## - Opera em `EstadoDeJogo.BENCAO` com trava de entrada de `500 ms` (`trava_abertura_s`).
## - Dois modos de encontro:
##   1. `MODO_ENCONTRO` (Maldição Acuada em encontro):
##      - Opção 0 (foco inicial): `PACTO_OFERECER_VINCULO` (`Pactuar`)
##      - Opção 1: `PACTO_DEIXAR_IR` (ou `PACTO_ELA_VOLTARA` na 1ª aparição da espécie)
##   2. `MODO_CHEFE_SUBJUGADO` (Soberano do Limiar Subjugado):
##      - Opção 0 (foco inicial): `PACTO_OFERECER_VINCULO` (`Pactuar`)
##      - Opção 1: `PACTO_EXORCIZAR_CHEFE` (`Exorcizar`, concede `+6` Fragmentos)
## - `B` / `voltar` **nunca** resolve a escolha; `Esc` / `pausar` abre o Menu de Pausa com
##   "Abandonar run" desabilitado.
## - Emite `decisao_tomada(pactuar: bool, fragmento_bonus: int)` e `tela_fechada()`.

signal decisao_tomada(pactuar: bool, fragmentos_bonus: int)
signal abrir_pausa_sobre_consentimento()
signal tela_fechada()

const MODO_ENCONTRO: StringName = &"encontro"
const MODO_CHEFE_SUBJUGADO: StringName = &"chefe_subjugado"

const OPCAO_PACTUAR: int = 0
const OPCAO_RECUSAR_OU_EXORCIZAR: int = 1
const BONUS_FRAGMENTOS_EXORCIZAR_CHEFE: int = 6

var _tuning: TelaBencaoTuning = TelaBencaoTuning.new()
var _modo: StringName = MODO_ENCONTRO
var _id_especie: StringName = &""
var _primeira_aparicao: bool = false
var _foco_opcao: int = OPCAO_PACTUAR
var _trava_restante_s: float = 0.50
var _confirmada: bool = false
var _fila_sons_ui: FilaDeSonsDeInterface = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func abrir(
	id_especie: StringName,
	modo_encontro: StringName = MODO_ENCONTRO,
	primeira_aparicao: bool = false,
	tuning: TelaBencaoTuning = null,
	fila_sons_ui: FilaDeSonsDeInterface = null
) -> void:
	if tuning != null:
		_tuning = tuning
	_fila_sons_ui = fila_sons_ui
	_id_especie = id_especie
	_modo = modo_encontro
	_primeira_aparicao = primeira_aparicao
	_foco_opcao = OPCAO_PACTUAR
	_trava_restante_s = _tuning.trava_abertura_s
	_confirmada = false
	visible = true


func foco_opcao() -> int:
	return _foco_opcao


func travada() -> bool:
	return _trava_restante_s > 0.0


func chave_opcao_esquerda() -> StringName:
	return &"PACTO_OFERECER_VINCULO"


func chave_opcao_direita() -> StringName:
	if _modo == MODO_CHEFE_SUBJUGADO:
		return &"PACTO_EXORCIZAR_CHEFE"
	if _primeira_aparicao:
		return &"PACTO_ELA_VOLTARA"
	return &"PACTO_DEIXAR_IR"


func caminho_retrato() -> String:
	if _id_especie == &"":
		return ""
	return "res://assets/art/ui/maldicoes/%s_retrato.png" % String(_id_especie)


func avancar_tempo(dt_ui: float) -> void:
	if dt_ui > 0.0 and _trava_restante_s > 0.0:
		_trava_restante_s = maxf(0.0, _trava_restante_s - dt_ui)


func processar_comandos(cmd: ComandosDeTela) -> Dictionary:
	var res: Dictionary = {
		"mudou_foco": false,
		"confirmou": false,
		"pactuou": false,
		"fragmentos_bonus": 0,
		"abriu_pausa": false,
	}
	if not visible or _confirmada or cmd == null:
		return res

	# B / voltar nunca resolve a escolha de consentimento do pacto
	if cmd.pausar:
		res["abriu_pausa"] = true
		abrir_pausa_sobre_consentimento.emit()
		return res

	if cmd.navegar.x != 0:
		var novo: int = clampi(_foco_opcao + (1 if cmd.navegar.x > 0 else -1), 0, 1)
		if novo != _foco_opcao:
			_foco_opcao = novo
			res["mudou_foco"] = true
			if _fila_sons_ui != null:
				_fila_sons_ui.pedir(&"ui_foco", 2)

	if cmd.aceitar and not travada() and cmd.aperto_apos_abertura:
		_confirmada = true
		var pactuar: bool = (_foco_opcao == OPCAO_PACTUAR)
		var bonus: int = BONUS_FRAGMENTOS_EXORCIZAR_CHEFE if (not pactuar and _modo == MODO_CHEFE_SUBJUGADO) else 0
		res["confirmou"] = true
		res["pactuou"] = pactuar
		res["fragmentos_bonus"] = bonus
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_confirmar", 1)
		visible = false
		decisao_tomada.emit(pactuar, bonus)
		tela_fechada.emit()

	return res
