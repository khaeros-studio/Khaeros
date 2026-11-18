class_name ValidadorDeCatalogo
extends RefCounted
## Primeira passada da validação do catálogo (ADR-0004): compõe V1–V4, V6–V8, V10 e
## V11 (V5 e V9, só CI/debug, ficam na story 010; códigos dos donos e 2ª passada na
## story 006, por [method acrescentar]). Resultado igual em debug e release.
## Dependências injetadas: registros dos donos, textos e verificador de arte.
##
## Exemplo:
## [codeblock]
## var v := ValidadorDeCatalogo.new(registros, textos, VerificadorDeArte.new())
## var diags := v.validar(itens)
## [/codeblock]

var _regras: Array[ValidadorDeRegra] = []


func _init(registros: RegistrosDeChaves, textos: TabelaDeTextos, arte: VerificadorDeArte) -> void:
	_regras = [V1Estrutura.new(), V2Faixas.new(), V3Ids.new(), V4Referencias.new(registros),
		V6Textos.new(textos), V7Arte.new(arte), V8Pesos.new(), V10Descricoes.new(textos, registros),
		V11Efeitos.new()]


## Acrescenta um validador (regras dos donos; story 006).
func acrescentar(regra: ValidadorDeRegra) -> void:
	_regras.append(regra)


## Diagnósticos de todas as regras, na ordem das regras.
func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for r in _regras:
		out.append_array(r.validar(itens))
	return out
