class_name RoteadorDeFoco
extends RefCounted
## Controlador e auxiliar de foco único, navegação sem mouse e campo de texto em contexto Texto
## (GDD input-e-controle R9, R10, AC-33, AC-36; ADR-0006 §5; ADR-0012 §3).
##
## Responsabilidades:
## [br]- manter um único índice de foco autoritativo (inicial sempre definido ao abrir uma tela);
## [br]- espelhar o foco num `Control` opcional via `grab_focus()`, neutralizando o foco duplo do 4.6;
## [br]- em hover (`aplicar_hover`), mover o foco e chamar `grab_focus()` **exceto** em contexto `texto`
## e apenas quando `mouse_moveu` for verdadeiro (mouse parado na abertura não rouba o foco);
## [br]- navegar por `ui_navegar` a partir do controle atualmente focado (inclusive após hover),
## atalhos `ui_carta_1..3` (só focam, nunca confirmam) e confirmar no máximo uma vez por passo
## (respeitando travas de abertura/troca quando configuradas);
## [br]- operar o campo de texto de debug em contexto `texto` (AC-36): entrada apenas por bind de
## teclado de `ui_aceitar` ou clique no próprio campo (A do gamepad não entra em edição), digitação
## livre (Espaço, E, WASD, 1–3, R viram texto mesmo se `ui_aceitar`/`ui_voltar` forem remapeados),
## confirmação e cancelamento exclusivamente por `KEY_ENTER`/`KEY_KP_ENTER` e `KEY_ESCAPE` físicos
## fixos ou clique fora (que cancela sem acionar o vizinho clicado).
##
## Lógica pura em `RefCounted` (nós `Control` são opcionais para espelhamento de `grab_focus()`).
## Não lê `Input` nem `InputEvent` globalmente; não é thread-safe (uso na thread principal).
##
## Exemplo:
## [codeblock]
## var f := RoteadorDeFoco.new(roteador_de_contexto)
## f.configurar_tela(3, 1, false, [btn0, btn1, btn2])
## f.aplicar_hover(2, true) # move foco para 2 e chama btn2.grab_focus() fora de Texto
## [/codeblock]

## Política de clique fora de foco: confirma direto (Menu/Pausa) ou só move o foco (Tela de bênção).
enum PoliticaDeClique {
	CONFIRMAR_ALVO,
	SO_FOCAR_SE_NAO_FOCADO,
}

var _roteador_contexto: RoteadorDeContexto
var _quantidade: int = 0
var _focado: int = -1
var _da_volta: bool = true
var _politica_clique: PoliticaDeClique = PoliticaDeClique.CONFIRMAR_ALVO
var _controles: Array[Control] = []
var _vizinhos: Dictionary = {} # indice -> {direcao: indice_destino}
var _trava_restante_ms: float = 0.0

# --- Estado de campo de texto (contexto Texto, AC-36) ---
var _indice_campo_texto: int = -1
var _validador_texto: Callable = Callable() # func(texto: String) -> Dictionary {aceito: bool, mensagem: String}
var _ao_confirmar_texto: Callable = Callable() # func(texto: String) -> void
var _valor_confirmado: String = ""
var _buffer_edicao: String = ""
var _mensagem_erro_texto: String = ""
var _confirmacoes_no_passo: int = 0
var _ultima_acao_confirmada: int = -1
var _trocas_solicitadas: int = 0


func _init(roteador_contexto: RoteadorDeContexto = null) -> void:
	_roteador_contexto = roteador_contexto


## Configura os alvos focáveis de uma tela e aplica imediatamente o foco inicial.
## `controles` é opcional (para espelhar `grab_focus()` e configurar `MOUSE_FILTER_IGNORE`).
func configurar_tela(quantidade: int, foco_inicial: int = 0, da_volta: bool = true,
		controles: Array[Control] = [],
		politica_clique: PoliticaDeClique = PoliticaDeClique.CONFIRMAR_ALVO) -> void:
	_quantidade = maxi(0, quantidade)
	_da_volta = da_volta
	_politica_clique = politica_clique
	_controles = controles.duplicate()
	_vizinhos.clear()
	_trava_restante_ms = 0.0
	_confirmacoes_no_passo = 0
	_ultima_acao_confirmada = -1
	for ctrl: Control in _controles:
		if ctrl != null:
			ctrl.focus_mode = Control.FOCUS_ALL
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _quantidade > 0:
		_definir_foco(clampi(foco_inicial, 0, _quantidade - 1))
	else:
		_focado = -1


## Define vizinhos explícitos para um índice: `{Acoes.DIRECAO_CIMA: 0, ...}`.
func definir_vizinhos(indice: int, mapa_direcoes: Dictionary) -> void:
	_vizinhos[indice] = mapa_direcoes.duplicate()


## Configura trava de confirmação em milissegundos (ex.: 500 ms ao abrir Bênção, 300 ms ao trocar).
func armar_trava_ms(ms: float) -> void:
	_trava_restante_ms = maxf(0.0, ms)


## Avança o tempo da trava em milissegundos.
func avancar_trava_ms(delta_ms: float) -> void:
	_trava_restante_ms = maxf(0.0, _trava_restante_ms - maxf(0.0, delta_ms))


## Verdadeiro se a confirmação está travada no momento.
func trava_ativa() -> bool:
	return _trava_restante_ms > 0.0


## Índice atualmente em foco (-1 se a tela não tiver controles).
func focado() -> int:
	return _focado


## Quantidade de controles focáveis registrados na tela.
func quantidade() -> int:
	return _quantidade


## Quantas confirmações ocorreram no último passo processado (guardrail: <= 1).
func confirmacoes_no_passo() -> int:
	return _confirmacoes_no_passo


## Último índice confirmado no passo (-1 se nenhum).
func ultima_confirmacao() -> int:
	return _ultima_acao_confirmada


## Contador de pedidos de `ui_trocar_ofertas` aceitos na tela.
func trocas_solicitadas() -> int:
	return _trocas_solicitadas


## Verdadeiro se o roteador está em contexto `texto` (edição ativa).
func em_edicao_de_texto() -> bool:
	return _contexto_atual() == Acoes.CONTEXTO_TEXTO


## Hover de mouse sobre `indice`: fora de `texto` e com `mouse_moveu == true`, move o foco único
## e chama `grab_focus()` no controle correspondente. Em `texto`, não move o foco (R9/R10, AC-36).
func aplicar_hover(indice: int, mouse_moveu: bool = true) -> bool:
	if not mouse_moveu or em_edicao_de_texto():
		return false
	if indice < 0 or indice >= _quantidade:
		return false
	_definir_foco(indice)
	return true


## Navega um passo na `direcao` (`cima`, `baixo`, `esquerda`, `direita`) a partir do foco atual.
## Ignorado em contexto `texto`.
func navegar(direcao: StringName) -> int:
	if em_edicao_de_texto() or _quantidade <= 0:
		return _focado
	if _vizinhos.has(_focado) and (_vizinhos[_focado] as Dictionary).has(direcao):
		var dest: int = int((_vizinhos[_focado] as Dictionary)[direcao])
		if dest >= 0 and dest < _quantidade:
			_definir_foco(dest)
			return _focado
	var delta := 0
	if direcao == Acoes.DIRECAO_BAIXO or direcao == Acoes.DIRECAO_DIREITA:
		delta = 1
	elif direcao == Acoes.DIRECAO_CIMA or direcao == Acoes.DIRECAO_ESQUERDA:
		delta = -1
	if delta == 0:
		return _focado
	var novo := _focado + delta
	if _da_volta:
		novo = posmod(novo, _quantidade)
	else:
		novo = clampi(novo, 0, _quantidade - 1)
	_definir_foco(novo)
	return _focado


## Atalhos de carta 1..3 na Tela de bênção: apenas movem o foco para a carta (0..2) sem confirmar (AC-33).
func focar_carta(numero_1_a_3: int) -> bool:
	if em_edicao_de_texto():
		return false
	var idx := numero_1_a_3 - 1
	if idx < 0 or idx >= _quantidade:
		return false
	_definir_foco(idx)
	return true


## Processa os comandos de um passo fora de edição de texto (ou de um clique).
## Garante o guardrail de no máximo 1 confirmação por passo.
## `origem_aceitar`: `DescritorDeEntrada.ORIGEM_TECLADO`, `ORIGEM_GAMEPAD` ou `ORIGEM_MOUSE`.
## `alvo_clique`: índice sob o clique (-1 se não houve clique neste passo).
func processar_passo_ui(amostra: AmostraDeEntrada, direcao_navegacao: StringName = &"",
		origem_aceitar: StringName = DescritorDeEntrada.ORIGEM_TECLADO,
		alvo_clique: int = -1, trava_troca_ms: float = 300.0) -> int:
	_confirmacoes_no_passo = 0
	_ultima_acao_confirmada = -1

	if em_edicao_de_texto():
		# Clique fora do campo em contexto Texto sai da edição sem acionar o controle clicado (AC-36).
		if alvo_clique >= 0 and alvo_clique != _indice_campo_texto:
			cancelar_edicao_texto()
		return -1

	if direcao_navegacao != &"":
		navegar(direcao_navegacao)

	if amostra != null:
		if amostra.foi_apertado(Acoes.UI_CARTA_1):
			focar_carta(1)
		elif amostra.foi_apertado(Acoes.UI_CARTA_2):
			focar_carta(2)
		elif amostra.foi_apertado(Acoes.UI_CARTA_3):
			focar_carta(3)

		# Trocar ofertas tem precedência sobre aceitar no mesmo passo (ADR-0012 §11).
		if amostra.foi_apertado(Acoes.UI_TROCAR_OFERTAS) and not trava_ativa():
			_trocas_solicitadas += 1
			armar_trava_ms(trava_troca_ms)
			return -1

		if amostra.foi_apertado(Acoes.UI_ACEITAR):
			return _tentar_confirmar(_focado, origem_aceitar)

	if alvo_clique >= 0 and alvo_clique < _quantidade:
		if alvo_clique == _indice_campo_texto:
			_definir_foco(alvo_clique)
			entrar_edicao_texto(DescritorDeEntrada.ORIGEM_MOUSE)
			return -1
		if _politica_clique == PoliticaDeClique.SO_FOCAR_SE_NAO_FOCADO and alvo_clique != _focado:
			_definir_foco(alvo_clique)
			return -1
		_definir_foco(alvo_clique)
		return _tentar_confirmar(alvo_clique, DescritorDeEntrada.ORIGEM_MOUSE)

	return -1


# --- Campo de texto (contexto Texto, AC-36) ---

## Registra qual índice da tela é o campo de texto (ex.: seed de debug), seu valor inicial e validador.
## `validador(texto: String) -> Dictionary {aceito: bool, mensagem: String}`.
func configurar_campo_texto(indice: int, valor_inicial: String, validador: Callable,
		ao_confirmar: Callable = Callable()) -> void:
	_indice_campo_texto = indice
	_valor_confirmado = valor_inicial
	_buffer_edicao = valor_inicial
	_mensagem_erro_texto = ""
	_validador_texto = validador
	_ao_confirmar_texto = ao_confirmar


## Tenta entrar em edição do campo de texto. Só teclado ou clique entram; A do gamepad é recusado (AC-36).
func entrar_edicao_texto(origem: StringName) -> bool:
	if _indice_campo_texto < 0 or _focado != _indice_campo_texto:
		return false
	if origem == DescritorDeEntrada.ORIGEM_GAMEPAD:
		return false
	_buffer_edicao = _valor_confirmado
	_mensagem_erro_texto = ""
	if _roteador_contexto != null and _roteador_contexto.contexto() != Acoes.CONTEXTO_TEXTO:
		_roteador_contexto.abrir(Acoes.CONTEXTO_TEXTO)
	return true


## Digita caracteres no campo quando em contexto Texto; não move o foco nem dispara ações vizinhas.
func digitar_texto(caracteres: String) -> bool:
	if not em_edicao_de_texto():
		return false
	_buffer_edicao += caracteres
	return true


## Substitui o texto em edição (quando o `LineEdit` nativo edita).
func definir_texto_em_edicao(novo_texto: String) -> bool:
	if not em_edicao_de_texto():
		return false
	_buffer_edicao = novo_texto
	return true


## Processa uma tecla física durante a edição de texto (R10, AC-36):
## - só `KEY_ENTER`/`KEY_KP_ENTER` confirmam;
## - só `KEY_ESCAPE` cancela (sem abrir Pausa);
## - qualquer outra tecla (inclusive binds remapeados de `ui_aceitar`/`ui_voltar` como F1/F2, Espaço, E)
##   não confirma nem cancela, e se tiver `unicode` imprimível vira texto.
func processar_tecla_em_texto(physical_keycode: int, unicode_char: String = "") -> bool:
	if not em_edicao_de_texto():
		return false
	if physical_keycode == KEY_ENTER or physical_keycode == KEY_KP_ENTER:
		return confirmar_edicao_texto()
	if physical_keycode == KEY_ESCAPE:
		cancelar_edicao_texto()
		return true
	if not unicode_char.is_empty():
		_buffer_edicao += unicode_char
	return false


## Enter físico no campo de texto: valida; se aceito, grava valor e fecha o contexto Texto;
## se recusado, mantém o texto digitado, registra a mensagem e continua em Texto (AC-36).
func confirmar_edicao_texto() -> bool:
	if not em_edicao_de_texto():
		return false
	if _validador_texto.is_valid():
		var res: Dictionary = _validador_texto.call(_buffer_edicao)
		if not bool(res.get("aceito", false)):
			_mensagem_erro_texto = String(res.get("mensagem", ""))
			return false
	_valor_confirmado = _buffer_edicao
	_mensagem_erro_texto = ""
	if _roteador_contexto != null and _roteador_contexto.contexto() == Acoes.CONTEXTO_TEXTO:
		_roteador_contexto.fechar()
	if _ao_confirmar_texto.is_valid():
		_ao_confirmar_texto.call(_valor_confirmado)
	return true


## Esc físico ou clique num controle vizinho: sai de Texto sem mudar `_valor_confirmado` e sem abrir Pausa.
func cancelar_edicao_texto() -> void:
	if not em_edicao_de_texto():
		return
	_buffer_edicao = _valor_confirmado
	_mensagem_erro_texto = ""
	if _roteador_contexto != null and _roteador_contexto.contexto() == Acoes.CONTEXTO_TEXTO:
		_roteador_contexto.fechar()


## Valor confirmado do campo de texto.
func valor_confirmado_texto() -> String:
	return _valor_confirmado


## Texto atualmente visível no campo (o buffer durante a edição, ou o valor confirmado fora dela).
func texto_atual_do_campo() -> String:
	return _buffer_edicao if em_edicao_de_texto() else _valor_confirmado


## Última mensagem de erro de validação do campo de texto (vazia se válido).
func mensagem_erro_texto() -> String:
	return _mensagem_erro_texto


func _tentar_confirmar(indice: int, origem: StringName) -> int:
	if _confirmacoes_no_passo >= 1 or trava_ativa() or indice < 0 or indice >= _quantidade:
		return -1
	if indice == _indice_campo_texto:
		entrar_edicao_texto(origem)
		return -1
	_confirmacoes_no_passo += 1
	_ultima_acao_confirmada = indice
	return indice


func _definir_foco(indice: int) -> void:
	_focado = indice
	if indice >= 0 and indice < _controles.size():
		var ctrl: Control = _controles[indice]
		if ctrl != null and ctrl.is_inside_tree():
			ctrl.grab_focus()


func _contexto_atual() -> StringName:
	if _roteador_contexto == null:
		return Acoes.CONTEXTO_MENU
	return _roteador_contexto.contexto()
