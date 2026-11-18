## Lista de eventos do passo (ADR-0002): append-only dentro do passo, esvaziada
## uma vez por [code]passo_fisico()[/code] pelo orquestrador.
##
## Criada pelo [code]Main[/code] e injetada nos módulos. Módulos de regra emitem e
## leem só eventos de itens anteriores ao seu ([method do_tipo]); a reação a um
## produtor do mesmo item ou posterior é chamada direta, nunca leitura da lista.
##
## Uso (orquestrador, final comum do passo):
## [codeblock]
## var eventos := EventosDoPasso.new()
## # ... itens do passo chamam eventos.emitir(...)
## eventos.entregar(eventos.esvaziar(), consumidores)  # Telemetria, HUD, Feedback, Telas, Áudio
## [/codeblock]
## Uso (módulo de regra, item posterior):
## [codeblock]
## for e: EventoDoPasso in eventos.do_tipo(&"acerto_de_arma"):
##     var a := e as EvAcertoDeArma
## [/codeblock]
## Não é seguro entre threads: só a thread principal o usa.
class_name EventosDoPasso
extends RefCounted

## Limite provisório de eventos por passo acima do qual sai um alerta em debug.
## Provisório até a medição de alocação (ADR-0002, "Performance Implications");
## a estimativa do pior caso de Pactos é "dezenas por passo".
const LIMITE_ALERTA_PADRAO: int = 128

## Mensagem do [code]assert[/code] de [method emitir] durante a entrega.
const ERRO_EMITIR_NA_ENTREGA: String = "EventosDoPasso.emitir() chamado durante a entrega à Apresentação"

## Formato do alerta de excesso: [quantidade, passo, limite].
const ALERTA_EXCESSO: String = "EventosDoPasso: %d eventos no passo %d (limite provisório %d)"

var _lista: Array[EventoDoPasso] = []
var _entregando: bool = false
var _n_passo: int = 0
var _limite_alerta: int
var _alertou: bool = false


## [param limite_alerta]: limite do alerta de excesso em debug (injeção para teste).
func _init(limite_alerta: int = LIMITE_ALERTA_PADRAO) -> void:
	_limite_alerta = limite_alerta


## Anexa [param e] à lista do passo e preenche [member EventoDoPasso.n_passo].
## Válido durante o passo ou numa chamada de UI entre passos (entregue no passo
## seguinte). Em debug, falha por [code]assert[/code] se chamado durante [method entregar];
## em release a chamada é ignorada.
func emitir(e: EventoDoPasso) -> void:
	assert(not _entregando, ERRO_EMITIR_NA_ENTREGA)
	if _entregando or e == null:
		return
	e.n_passo = _n_passo
	_lista.append(e)
	# Só em debug: assert é removido no release, e a lógica não pode ler OS.
	assert(_verificar_excesso())


## [code]true[/code] se já houve, neste passo, um evento do [param tipo].
func ha(tipo: StringName) -> bool:
	for e: EventoDoPasso in _lista:
		if e.tipo() == tipo:
			return true
	return false


## Cópia nova, na ordem de emissão, dos eventos já emitidos do [param tipo].
## Mutar o resultado não altera a lista; eventos emitidos depois não aparecem nele.
func do_tipo(tipo: StringName) -> Array[EventoDoPasso]:
	var r: Array[EventoDoPasso] = []
	for e: EventoDoPasso in _lista:
		if e.tipo() == tipo:
			r.append(e)
	return r


## Cópia nova de todos os eventos já emitidos, na ordem de emissão.
func todos() -> Array[EventoDoPasso]:
	var r: Array[EventoDoPasso] = []
	r.append_array(_lista)
	return r


## Só o orquestrador, uma vez por [code]passo_fisico()[/code]: devolve o array antigo
## (íntegro) e passa a usar um array novo; avança o número do passo.
func esvaziar() -> Array[EventoDoPasso]:
	var antigo: Array[EventoDoPasso] = _lista
	var novo: Array[EventoDoPasso] = []
	_lista = novo
	_n_passo += 1
	_alertou = false
	return antigo


## Entrega [param lote] (o retorno de [method esvaziar]) a cada consumidor, na ordem
## de [param consumidores]. O lote fica somente leitura; durante a entrega,
## [method emitir] falha em debug.
func entregar(lote: Array[EventoDoPasso], consumidores: Array[ConsumidorDeEventos]) -> void:
	lote.make_read_only()
	_entregando = true
	for c: ConsumidorDeEventos in consumidores:
		c.consumir(lote)
	_entregando = false


## [code]true[/code] enquanto [method entregar] está em curso.
func entregando() -> bool:
	return _entregando


## Número do passo (base 0) cuja lista está aberta: o que os eventos emitidos agora recebem.
func passo_atual() -> int:
	return _n_passo


## Limite do alerta de excesso em uso.
func limite_alerta() -> int:
	return _limite_alerta


func _verificar_excesso() -> bool:
	if not _alertou and _lista.size() > _limite_alerta:
		_alertou = true
		push_warning(ALERTA_EXCESSO % [_lista.size(), _n_passo, _limite_alerta])
	return true
