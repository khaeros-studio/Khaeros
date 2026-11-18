class_name Catalogo
extends RefCounted
## Catálogo publicado (ADR-0004; GDD de Conteúdo R10). Índice por (tipo, id) e lista
## por tipo na ordem do manifesto. Recebido por injeção; nunca Autoload.
## Não é thread-safe; só leitura depois de publicado pelo [CarregadorDeCatalogo].
##
## [method obter] com id ausente devolve [code]null[/code] e entrega tipo, id e
## solicitante ao [RelatorDeErros] injetado; [method existe] não registra nada.
## Listas devolvidas são cópias (mutá-las não altera o catálogo); as definições
## seguem o contrato de só leitura: para alterar, use [method copiar_mutavel].
## Consulta por id é O(1) (índice); listar/filtrar seguem a ordem do manifesto.
##
## Exemplo:
## [codeblock]
## var cat := Catalogo.new(RelatorAcumulador.new())
## cat.adicionar(&"weapon", arma)
## var a := cat.obter(&"weapon", &"lamina", "run") as WeaponDef
## [/codeblock]

var _relator: RelatorDeErros
var _ordem_tipos: Array[StringName] = []
## tipo -> Array[DefinicaoBase] na ordem do manifesto.
var _listas: Dictionary[StringName, Array] = {}
## tipo -> (id -> DefinicaoBase).
var _indice: Dictionary[StringName, Dictionary] = {}
var _impressao_completa: String = ""


func _init(relator: RelatorDeErros) -> void:
	_relator = relator


## Acrescenta uma definição no fim da lista do tipo (uso do carregador e das fábricas
## de teste). Não valida: quem publica é o carregador.
func adicionar(tipo: StringName, definicao: DefinicaoBase) -> void:
	if not _listas.has(tipo):
		_ordem_tipos.append(tipo)
		_listas[tipo] = []
		_indice[tipo] = {}
	_listas[tipo].append(definicao)
	_indice[tipo][definicao.id] = definicao


## Definição por (tipo, id), inclusive obsoleta. Ausente: [code]null[/code] e uma
## entrada no relator com [param solicitante].
func obter(tipo: StringName, id: StringName, solicitante: String) -> DefinicaoBase:
	if _indice.has(tipo) and _indice[tipo].has(id):
		return _indice[tipo][id]
	_relator.relatar(RelatorDeErros.Entrada.new(tipo, id, solicitante))
	return null


## [code]true[/code] se (tipo, id) existe; nunca registra erro.
func existe(tipo: StringName, id: StringName) -> bool:
	return _indice.has(tipo) and _indice[tipo].has(id)


## Definições do tipo na ordem do manifesto (cópia da lista; obsoletas só com
## [param incluir_obsoletos]).
func listar(tipo: StringName, incluir_obsoletos: bool = false) -> Array[DefinicaoBase]:
	var out: Array[DefinicaoBase] = []
	if not _listas.has(tipo):
		return out
	for d: DefinicaoBase in _listas[tipo]:
		if incluir_obsoletos or not d.obsoleto:
			out.append(d)
	return out


## Definições do tipo, na ordem do manifesto, para as quais
## [code]predicado.call(def) -> bool[/code] é verdadeiro (obsoletas só com
## [param incluir_obsoletos]). Devolve uma lista nova.
func filtrar(tipo: StringName, predicado: Callable, incluir_obsoletos: bool = false) -> Array[DefinicaoBase]:
	var out: Array[DefinicaoBase] = []
	for d in listar(tipo, incluir_obsoletos):
		if predicado.call(d):
			out.append(d)
	return out


## Cópia mutável e independente de [param definicao], fora do catálogo:
## [code]duplicate_deep(Resource.DEEP_DUPLICATE_ALL)[/code] duplica também
## sub-recursos externos (ADR-0004 §Imutabilidade; confirmado no 4.7 pelo teste da
## story 002). A cópia não entra no índice.
static func copiar_mutavel(definicao: DefinicaoBase) -> DefinicaoBase:
	return definicao.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as DefinicaoBase


## Grava a impressão canônica calculada pelo carregador ao publicar (story 008).
func definir_impressao(completa: String) -> void:
	_impressao_completa = completa


## SHA-256 completo (64 hex minúsculos) da serialização canônica; vazio antes de
## publicado pelo carregador.
func impressao_completa() -> String:
	return _impressao_completa


## Forma curta: os 4 primeiros hex da completa em maiúsculas.
func impressao_curta() -> String:
	return _impressao_completa.substr(0, 4).to_upper()


## Tipos presentes, na ordem do manifesto.
func tipos() -> Array[StringName]:
	return _ordem_tipos.duplicate()
