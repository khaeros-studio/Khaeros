class_name V4Referencias
extends ValidadorDeRegra
## V4: toda referência resolve (GDD de Conteúdo R9, R8, R9-P): ids de outros tipos do
## catálogo e chaves dos registros dos donos (ativas ou reservadas). Registro não
## entregue gera "registro de chaves ausente". Inclui a V4 ampliada da fonte
## [code]vinculo:<curse_id>[/code] ([method validar_fonte_vinculo]).
##
## Exemplo:
## [codeblock]
## var diags := V4Referencias.new(registros).validar(itens)
## [/codeblock]

## Registro com os atributos aceitos pelo portador da Maldição (Modificadores R14).
const REGISTRO_ATRIBUTOS_MALDICAO := &"atributos_portador_maldicao"

var _registros: RegistrosDeChaves


func _init(registros: RegistrosDeChaves) -> void:
	_registros = registros


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var ids: Dictionary[StringName, Array] = {}
	for item in itens:
		if not ids.has(item.tipo):
			ids[item.tipo] = []
		ids[item.tipo].append(item.definicao.id)
	var ausentes_avisados: Array[StringName] = []
	for item in itens:
		EsquemaDeDefinicao.percorrer(item.definicao, func(r: EsquemaDeDefinicao.RegraDeCampo, valor: Variant, caminho: String, _d: DadoDeConteudo) -> void:
			if r.ref_tipo == &"" and r.ref_registro == &"":
				return
			if r.ref_registro != &"" and not _registros.tem_registro(r.ref_registro):
				if not ausentes_avisados.has(r.ref_registro):
					ausentes_avisados.append(r.ref_registro)
					out.append(Diagnostico.de_item(item, &"V4", caminho, r.ref_registro, "registro de chaves ausente: %s" % r.ref_registro))
				return
			for v: Variant in como_lista(valor):
				var chave := StringName(str(v))
				if chave == &"":
					continue
				if r.ref_tipo != &"" and not (ids.has(r.ref_tipo) and ids[r.ref_tipo].has(chave)):
					out.append(Diagnostico.de_item(item, &"V4", caminho, chave, "%s: %s %s não existe (%s)" % [rotulo(item), caminho, chave, r.ref_tipo]))
				elif r.ref_registro != &"" and not _registros.resolve(r.ref_registro, chave):
					out.append(Diagnostico.de_item(item, &"V4", caminho, chave, "%s: %s %s fora do registro %s" % [rotulo(item), caminho, chave, r.ref_registro])))
	return out


## V4 ampliada (R9-P, AC-59): cada atributo declarado pela fonte
## [code]vinculo:<curse_id>[/code] tem de estar na lista do portador da Maldição.
static func validar_fonte_vinculo(fonte: StringName, atributos: Array[StringName], registros: RegistrosDeChaves) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	if not registros.tem_registro(REGISTRO_ATRIBUTOS_MALDICAO):
		out.append(Diagnostico.novo(&"V4", String(fonte), REGISTRO_ATRIBUTOS_MALDICAO, "registro de chaves ausente: %s" % REGISTRO_ATRIBUTOS_MALDICAO))
		return out
	for a in atributos:
		if not registros.resolve(REGISTRO_ATRIBUTOS_MALDICAO, a):
			out.append(Diagnostico.novo(&"V4", String(fonte), a, "vinculo: atributo %s fora da lista do portador da Maldição" % a))
	return out
