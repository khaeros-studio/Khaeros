## Relator injetado para avisos internos da Telemetria local (`TL1`, `TL2`, `TL3`)
## (GDD telemetria-local.md R8, R9, F4; ADR-0013 §5).
##
## Avisos de telemetria nunca são erros de jogo e nunca interrompem a execução:
## - `TL1`: falha de arquivo (abrir, gravar, descarregar, garantir pasta, apagar);
## - `TL2`: custo de gravação acima do orçamento (`orcamento_linha_ms` ou `orcamento_passo_ms`);
## - `TL3`: campo ausente ou valor desconhecido num evento, **uma vez por chave `(tipo, campo)`** na sessão.
##
## Exemplo:
## [codeblock]
## var av := RelatorDeAvisosTelemetria.new()
## av.registrar_tl3(&"encontro_pacto", "resultado=invalido")
## assert(av.contagem(&"TL3") == 1)
## [/codeblock]
class_name RelatorDeAvisosTelemetria
extends RefCounted

const TL1: StringName = &"TL1"
const TL2: StringName = &"TL2"
const TL3: StringName = &"TL3"

var _contagens: Dictionary = {
	TL1: 0,
	TL2: 0,
	TL3: 0,
}
var _mensagens: Array[Dictionary] = []
var _tl3_vistos: Dictionary = {} # chave "tipo:detalhe" -> true
var _emitir_push_warning: bool = false


func _init(emitir_no_log_do_motor: bool = false) -> void:
	_emitir_push_warning = emitir_no_log_do_motor


## Registra um aviso `TL1` (erro de arquivo/disco).
func registrar_tl1(detalhe: String) -> void:
	_registrar(TL1, detalhe)


## Registra um aviso `TL2` (orçamento de linha ou de passo excedido).
func registrar_tl2(detalhe: String) -> void:
	_registrar(TL2, detalhe)


## Registra um aviso `TL3` (campo ausente ou valor fora da lista), no máximo **uma vez por `(tipo_evento, campo)`** na sessão.
func registrar_tl3(tipo_evento: StringName, campo: String) -> void:
	var chave := "%s:%s" % [String(tipo_evento), campo]
	if _tl3_vistos.has(chave):
		return
	_tl3_vistos[chave] = true
	_registrar(TL3, chave)


## Quantidade de avisos registrados para `codigo` (`TL1`, `TL2` ou `TL3`).
func contagem(codigo: StringName) -> int:
	return int(_contagens.get(codigo, 0))


## Lista de todos os avisos registrados (`{codigo: StringName, detalhe: String}`).
func avisos() -> Array[Dictionary]:
	return _mensagens.duplicate(true)


## Limpa contadores e histórico (útil em preparação de teste).
func limpar() -> void:
	_contagens[TL1] = 0
	_contagens[TL2] = 0
	_contagens[TL3] = 0
	_mensagens.clear()
	_tl3_vistos.clear()


func _registrar(codigo: StringName, detalhe: String) -> void:
	_contagens[codigo] = int(_contagens.get(codigo, 0)) + 1
	_mensagens.append({"codigo": codigo, "detalhe": detalhe})
	if _emitir_push_warning:
		push_warning("%s: %s" % [String(codigo), detalhe])
