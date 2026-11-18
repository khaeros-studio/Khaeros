class_name TelaDeOpcoes
extends Control
## Modelo e Vista da Tela de Opções (`design/ux/pausa-e-opcoes.md`, `story-009`).
## - Categorias: `OPCOES_ABA_AUDIO`, `OPCOES_ABA_VIDEO`, `OPCOES_ABA_ACESSIBILIDADE`,
##   `OPCOES_ABA_CONTROLES`, `OPCOES_ABA_PERFIL`.
## - Remapeamento de controles com permuta automática em conflito (`INPUT_CONFLITO_TROCA`)
##   e bloqueio de ações reservadas de sistema (`pausar`).
## - Reset de perfil com 2 confirmações consecutivas, permitido apenas fora de `EstadoDeJogo.JOGO`,
##   emitindo avisos `PERFIL_RESET_SUCESSO` ou `PERFIL_RESET_BLOQUEADO_EM_JOGO`.

signal opcoes_alteradas(opcoes: OpcoesDoHud)
signal voltar_solicitado()
signal perfil_resetado()

const ABA_AUDIO: int = 0
const ABA_VIDEO: int = 1
const ABA_ACESSIBILIDADE: int = 2
const ABA_CONTROLES: int = 3
const ABA_PERFIL: int = 4
const TOTAL_ABAS: int = 5

const CHAVES_ABAS: Array[StringName] = [
	&"OPCOES_ABA_AUDIO",
	&"OPCOES_ABA_VIDEO",
	&"OPCOES_ABA_ACESSIBILIDADE",
	&"OPCOES_ABA_CONTROLES",
	&"OPCOES_ABA_PERFIL",
]

var _opcoes: OpcoesDoHud = OpcoesDoHud.new()
var _aba_atual: int = ABA_AUDIO
var _mapa_teclas: Dictionary = {
	&"atacar": KEY_J,
	&"golpe_pesado": KEY_K,
	&"esquivar": KEY_SPACE,
	&"habilidade": KEY_L,
	&"interagir": KEY_E,
	&"trocar_maldicao": KEY_Q,
	&"chamado_maldicao": KEY_R,
}
var _ultimo_aviso: StringName = &""
var _etapa_confirmacao_reset_perfil: int = 0
var _fila_sons_ui: FilaDeSonsDeInterface = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func configurar(opcoes: OpcoesDoHud, fila_sons_ui: FilaDeSonsDeInterface = null) -> void:
	if opcoes != null:
		_opcoes = opcoes
	_fila_sons_ui = fila_sons_ui


func opcoes() -> OpcoesDoHud:
	return _opcoes


func aba_atual() -> int:
	return _aba_atual


func mudar_aba(nova_aba: int) -> void:
	_aba_atual = posmod(nova_aba, TOTAL_ABAS)
	_etapa_confirmacao_reset_perfil = 0
	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_foco", 2)


func ultimo_aviso() -> StringName:
	return _ultimo_aviso


func tecla_da_acao(acao: StringName) -> int:
	return int(_mapa_teclas.get(acao, KEY_NONE))


## Remapeia uma ação de jogo. Se a nova tecla já pertencer a outra ação remapeável,
## permuta as duas teclas e registra `INPUT_CONFLITO_TROCA`. Tecla `KEY_ESCAPE` é reservada.
func remapear_acao(acao: StringName, nova_tecla: int) -> bool:
	if acao == &"pausar" or nova_tecla == KEY_ESCAPE or not _mapa_teclas.has(acao):
		_ultimo_aviso = &"INPUT_TECLA_RESERVADA"
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_negado", 2)
		return false

	var tecla_anterior: int = int(_mapa_teclas[acao])
	var acao_conflito: StringName = &""
	for k: StringName in _mapa_teclas.keys():
		if k != acao and int(_mapa_teclas[k]) == nova_tecla:
			acao_conflito = k
			break

	_mapa_teclas[acao] = nova_tecla
	if acao_conflito != &"":
		_mapa_teclas[acao_conflito] = tecla_anterior
		_ultimo_aviso = &"INPUT_CONFLITO_TROCA"
	else:
		_ultimo_aviso = &"INPUT_REMAPEADO_OK"

	if _fila_sons_ui != null:
		_fila_sons_ui.pedir(&"ui_confirmar", 1)
	return true


func restaurar_controles_padrao() -> void:
	_mapa_teclas = {
		&"atacar": KEY_J,
		&"golpe_pesado": KEY_K,
		&"esquivar": KEY_SPACE,
		&"habilidade": KEY_L,
		&"interagir": KEY_E,
		&"trocar_maldicao": KEY_Q,
		&"chamado_maldicao": KEY_R,
	}
	_ultimo_aviso = &"INPUT_PADROES_RESTAURADOS"


## Solicita apagamento de perfil: requer 2 confirmações consecutivas e nunca é permitido durante `JOGO`.
func solicitar_reset_perfil(estado_jogo_atual: int) -> bool:
	if estado_jogo_atual == EstadoDeJogo.Valor.JOGO or estado_jogo_atual == EstadoDeJogo.Valor.PAUSA or estado_jogo_atual == EstadoDeJogo.Valor.BENCAO:
		_etapa_confirmacao_reset_perfil = 0
		_ultimo_aviso = &"PERFIL_RESET_BLOQUEADO_EM_JOGO"
		if _fila_sons_ui != null:
			_fila_sons_ui.pedir(&"ui_negado", 2)
		return false

	_etapa_confirmacao_reset_perfil += 1
	if _etapa_confirmacao_reset_perfil < 2:
		_ultimo_aviso = &"PERFIL_CONFIRMAR_SEGUNDA_VEZ"
		return false

	_etapa_confirmacao_reset_perfil = 0
	_ultimo_aviso = &"PERFIL_RESET_SUCESSO"
	perfil_resetado.emit()
	return true


func atualizar_opcao(chave: String, valor: Variant, gravador: Callable = Callable()) -> bool:
	var d: Dictionary = {}
	d[chave] = valor
	_opcoes.aplicar_dicionario(d)
	var ok: bool = _opcoes.gravar_em(gravador)
	if not ok:
		_ultimo_aviso = _opcoes.ultimo_erro_gravacao()
	opcoes_alteradas.emit(_opcoes)
	return ok
