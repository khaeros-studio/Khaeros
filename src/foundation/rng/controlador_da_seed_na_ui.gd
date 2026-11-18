class_name ControladorDaSeedNaUi
extends RefCounted
## Controlador puro de exibição, cópia para a área de transferência e edição debug da seed
## (GDD rng-com-seed.md R8, F9, UI Requirements, AC-22; ADR-0005; ADR-0012 §11).
##
## A interface (pausa, morte, vitória e overlay de debug) recebe o texto pronto
## (`XXXX-XXXX · vX.Y.Z · cXXXX`) por injeção e não lê `Input` nem a `FonteDeFluxos`
## diretamente. A cópia chama um `Callable` injetado (em produção, `DisplayServer.clipboard_set`;
## nos testes, um dublê em memória). O campo de debug valida por `TextoDaSeed.interpretar`:
## entrada inválida mantém o texto digitado no campo e exibe a mensagem que cita o valor.
##
## Exemplo:
## [codeblock]
## var ctrl := ControladorDaSeedNaUi.new(func(t: String) -> void: DisplayServer.clipboard_set(t))
## ctrl.atualizar_da_seed(0x3F9A07C2, "0.1.0", "1B4E")
## assert(ctrl.rotulo_visivel() == "3F9A-07C2 · v0.1.0 · c1B4E")
## ctrl.copiar_seed()
## [/codeblock]

## Chave de tradução do botão de cópia (ADR-0012 §11).
const CHAVE_COPIAR_SEED: StringName = &"PAUSA_COPIAR_SEED"
## Chave de tradução do aviso discreto de confirmação de cópia (ADR-0012 §11).
const CHAVE_SEED_COPIADA: StringName = &"SEED_COPIADA"
## Escala mínima e máxima de UI suportadas sem truncamento do rótulo (guardrail 85–150%).
const ESCALA_UI_MIN: float = 0.85
const ESCALA_UI_MAX: float = 1.50
## Largura base estimada por caractere tabular a 100% (px lógicos) para garantir ausência de corte.
const LARGURA_CARACTERE_TABULAR_PX: float = 11.0

var _copiar_callback: Callable
var _rotulo: String = TextoDaSeed.TEXTO_SEM_SEED
var _texto_campo_debug: String = ""
var _mensagem_erro_debug: String = ""
var _ultima_seed_aceita: int = FonteDeFluxos.SEM_SEED
var _tem_seed_aceita: bool = false
var _copias_realizadas: int = 0
var _ultimo_aviso_ui: StringName = &""


## `copiar_para_area_de_transferencia`: `func(texto: String) -> void` injetado.
func _init(copiar_para_area_de_transferencia: Callable = Callable()) -> void:
	_copiar_callback = copiar_para_area_de_transferencia


## Define o texto pronto já formatado (injeção direta para a UI).
func definir_rotulo_pronto(texto_pronto: String) -> void:
	_rotulo = texto_pronto if not texto_pronto.is_empty() else TextoDaSeed.TEXTO_SEM_SEED


## Atualiza o rótulo a partir de `seed_da_run`, `versao` e `impressao_curta` (4 hex).
func atualizar_da_seed(seed_da_run: int, versao: String, impressao_curta: String) -> void:
	_rotulo = TextoDaSeed.rotulo(seed_da_run, versao, impressao_curta)
	_texto_campo_debug = TextoDaSeed.formatar(seed_da_run)
	_mensagem_erro_debug = ""


## Atualiza o rótulo a partir da `FonteDeFluxos` (em Sem run exibe `"sem seed"`).
func atualizar_da_fonte(fonte: FonteDeFluxos, versao: String, impressao_curta: String) -> void:
	_rotulo = TextoDaSeed.rotulo_da_fonte(fonte, versao, impressao_curta)
	if fonte != null and fonte.tem_seed():
		_texto_campo_debug = TextoDaSeed.formatar(fonte.seed())
	else:
		_texto_campo_debug = ""
	_mensagem_erro_debug = ""


## Texto completo visível nas telas de pausa, morte, vitória e debug (`XXXX-XXXX · vX.Y.Z · cXXXX`).
func rotulo_visivel() -> String:
	return _rotulo


## Copia o rótulo visível para a área de transferência injetada (R8, UI Requirements).
## Em Sem run (`"sem seed"`), não copia e devolve `false`.
func copiar_seed() -> bool:
	if _rotulo.is_empty() or _rotulo == TextoDaSeed.TEXTO_SEM_SEED:
		return false
	if _copiar_callback.is_valid():
		_copiar_callback.call(_rotulo)
	_copias_realizadas += 1
	_ultimo_aviso_ui = CHAVE_SEED_COPIADA
	return true


## Quantas vezes `copiar_seed()` foi executado com sucesso.
func copias_realizadas() -> int:
	return _copias_realizadas


## Última chave de aviso emitida para a UI (`SEED_COPIADA` após copiar).
func ultimo_aviso_ui() -> StringName:
	return _ultimo_aviso_ui


## Edita o texto do campo de debug (sem submeter).
func digitar_no_campo_debug(texto: String) -> void:
	_texto_campo_debug = texto


## Submete o texto atual do campo de debug ao parse estrito F9 (`TextoDaSeed.interpretar`).
## Se válido: limpa a mensagem de erro, guarda a seed u32 aceita, formata o campo em `XXXX-XXXX` e devolve `true`.
## Se inválido: **mantém o texto digitado no campo**, preenche `mensagem_erro_debug()` e devolve `false` (AC-22).
func submeter_campo_debug(versao: String = "", impressao_curta: String = "") -> bool:
	var res: TextoDaSeed.ResultadoDoParse = TextoDaSeed.interpretar(_texto_campo_debug)
	if not res.aceito:
		_mensagem_erro_debug = res.mensagem
		return false
	_ultima_seed_aceita = res.valor
	_tem_seed_aceita = true
	_mensagem_erro_debug = ""
	_texto_campo_debug = TextoDaSeed.formatar(res.valor)
	if not versao.is_empty() and not impressao_curta.is_empty():
		_rotulo = TextoDaSeed.rotulo(res.valor, versao, impressao_curta)
	return true


## Texto atualmente no campo de debug (preservado mesmo quando inválido).
func texto_campo_debug() -> String:
	return _texto_campo_debug


## Mensagem de erro do parse F9 (vazia quando a última entrada foi aceita).
func mensagem_erro_debug() -> String:
	return _mensagem_erro_debug


## Verdadeiro se alguma seed de debug já foi submetida e aceita.
func tem_seed_debug_aceita() -> bool:
	return _tem_seed_aceita


## Última seed u32 aceita pelo campo de debug.
func seed_debug_aceita() -> int:
	return _ultima_seed_aceita


## Largura mínima recomendada da caixa do rótulo (em px na vista lógica) para a escala `escala_ui`
## (85% a 150%), garantindo que o texto completo da seed nunca seja cortado (guardrail).
func largura_minima_sem_corte_px(escala_ui: float) -> float:
	var s := clampf(escala_ui, ESCALA_UI_MIN, ESCALA_UI_MAX)
	return float(_rotulo.length()) * LARGURA_CARACTERE_TABULAR_PX * s


## Verifica se `largura_disponivel_px` comporta o rótulo sem truncar na `escala_ui` dada.
func cabe_sem_corte(largura_disponivel_px: float, escala_ui: float) -> bool:
	return largura_disponivel_px + 1e-4 >= largura_minima_sem_corte_px(escala_ui)
