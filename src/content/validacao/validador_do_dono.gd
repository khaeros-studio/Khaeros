@abstract
class_name ValidadorDoDono
extends ValidadorDeRegra
## Contrato das regras de um dono (ML, VP, CH, HU, TB, RN, AV, WV...; GDD de Conteúdo
## R9/R9-P; ADR-0004 emenda Pactos). Cada dono entrega um validador com o prefixo do
## seu código; os códigos e níveis vivem no GDD do dono. Roda na 1ª passada (pelo
## [ValidadorDeCatalogo], via [method ValidadorDeCatalogo.acrescentar]) e, se
## [method precisa_da_segunda_passada], de novo na [SegundaPassada], com o catálogo
## já carregado. Nenhuma regra de dono fica no carregador.
##
## Exemplo:
## [codeblock]
## validador.acrescentar(RegrasRn.new())
## var diags := SegundaPassada.new([RegrasRn.new()]).validar(itens, catalogo)
## [/codeblock]


## Prefixo do código do dono (ex.: [code]&"RN"[/code]).
@abstract func prefixo() -> StringName


## [code]true[/code] se o dono tem regras que só rodam com dados já carregados
## (ex.: ML7/ML8).
func precisa_da_segunda_passada() -> bool:
	return false


## Regras da 2ª passada (catálogo publicado disponível). Padrão: nenhuma.
func validar_segunda_passada(_itens: Array[ItemDoCatalogo], _catalogo: Catalogo) -> Array[Diagnostico]:
	return []


## Itens de um tipo do manifesto.
static func itens_do_tipo(itens: Array[ItemDoCatalogo], tipo: StringName) -> Array[ItemDoCatalogo]:
	var out: Array[ItemDoCatalogo] = []
	for i in itens:
		if i.tipo == tipo:
			out.append(i)
	return out


## Primeiro item cuja definição é da classe [param classe] (por nome global).
static func primeiro_da_classe(itens: Array[ItemDoCatalogo], classe: String) -> ItemDoCatalogo:
	for i in itens:
		if i.definicao.nome_da_classe() == classe:
			return i
	return null
