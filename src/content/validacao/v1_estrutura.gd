class_name V1Estrutura
extends ValidadorDeRegra
## V1: campo obrigatório presente e do tipo certo (GDD de Conteúdo R9). Em runtime
## verifica a estrutura do recurso carregado (tipo da definição contra o tipo do
## manifesto, sub-recurso obrigatório nulo, texto/lista obrigatórios vazios). A
## presença de campo gravado × default do script é verificada quando o item traz
## os campos gravados (etapa de preparo, story 010).
##
## Exemplo:
## [codeblock]
## var d := V1Estrutura.verificar_tipo(&"weapon", caminho, 3, recurso)  # null = ok
## [/codeblock]


## Erro V1 quando [param recurso] não é uma definição do tipo [param tipo]; null se ok.
static func verificar_tipo(tipo: StringName, caminho: String, posicao: int, recurso: Resource) -> Diagnostico:
	var def := recurso as DefinicaoBase
	if def != null and def.tipo_do_catalogo() == tipo:
		return null
	var achado := "nada"
	if def != null:
		achado = "%s (%s)" % [def.nome_da_classe(), def.tipo_do_catalogo()]
	elif recurso != null:
		achado = recurso.get_class()
	var d := Diagnostico.novo(&"V1", "", achado, "listado como %s, mas é %s" % [tipo, achado])
	d.arquivo = caminho
	d.tipo = tipo
	d.posicao = posicao
	if def != null:
		d.id = def.id
	return d


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for item in itens:
		var ja: PackedStringArray = []
		if item.presenca_conhecida:
			for campo in item.definicao.esquema().campos_ausentes(item.campos_gravados):
				ja.append(campo)
				out.append(Diagnostico.de_item(item, &"V1", campo, null, "%s: %s ausente" % [rotulo(item), campo]))
		EsquemaDeDefinicao.percorrer(item.definicao, func(r: EsquemaDeDefinicao.RegraDeCampo, valor: Variant, caminho: String, _d: DadoDeConteudo) -> void:
			if not r.obrigatorio or ja.has(caminho):
				return
			if _vazio(valor):
				out.append(Diagnostico.de_item(item, &"V1", caminho, valor, "%s: %s ausente" % [rotulo(item), caminho])))
	return out


static func _vazio(valor: Variant) -> bool:
	match typeof(valor):
		TYPE_NIL:
			return true
		TYPE_OBJECT:
			return valor == null
		TYPE_STRING, TYPE_STRING_NAME:
			return String(valor).is_empty()
		TYPE_ARRAY, TYPE_DICTIONARY:
			return valor.is_empty()
	if typeof(valor) >= TYPE_PACKED_BYTE_ARRAY and typeof(valor) <= TYPE_PACKED_VECTOR4_ARRAY:
		return valor.is_empty()
	return false
