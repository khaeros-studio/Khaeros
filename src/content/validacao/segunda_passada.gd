class_name SegundaPassada
extends RefCounted
## Segunda passada da validação (ADR-0004): executa as regras cruzadas dos donos que
## precisam dos dados já carregados ([method ValidadorDoDono.validar_segunda_passada]).
## Erro bloqueia a run; aviso não. Thread principal.
##
## Exemplo:
## [codeblock]
## var diags := SegundaPassada.new(donos).validar(itens, catalogo)
## [/codeblock]

var _donos: Array[ValidadorDoDono] = []


func _init(donos: Array[ValidadorDoDono]) -> void:
	_donos = donos.duplicate()


## Diagnósticos da 2ª passada de todos os donos que a pedem, na ordem de registro.
func validar(itens: Array[ItemDoCatalogo], catalogo: Catalogo) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for d in _donos:
		if d.precisa_da_segunda_passada():
			out.append_array(d.validar_segunda_passada(itens, catalogo))
	return out
