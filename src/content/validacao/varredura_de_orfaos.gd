class_name VarreduraDeOrfaos
extends RefCounted
## Varredura de preparo/CI sobre [code]assets/data/[/code] (GDD de Conteúdo R4, R9;
## story 010 AC-04, AC-09, AC-AR-01):
## 1. Todo arquivo [code].tres[/code] em [code]assets/data/[/code] (exceto o próprio
##    manifesto e [code]assets/data/canon/[/code]) deve estar listado em
##    [code]content_catalog.tres[/code] — caso contrário é reportado como órfão (AC-04).
## 2. O texto de cada [code].tres[/code] não pode omitir campos obrigatórios sem
##    [code]default_permitido[/code] (AC-09) nem conter propriedades desconhecidas que
##    não existem no [EsquemaDeDefinicao] da classe (AC-AR-01).
##
## Exemplo:
## [codeblock]
## var diags := VarreduraDeOrfaos.verificar_orfaos(manifesto, arquivos_em_disco)
## [/codeblock]

const REGRA_ORFAO := &"ORFAO"
const CAMINHO_MANIFESTO := "res://assets/data/content_catalog.tres"
const PASTA_DADOS := "res://assets/data"
const PASTA_CANON := "res://assets/data/canon"


## Compara a lista de caminhos [code].tres[/code] encontrados em [code]assets/data/[/code]
## contra o [param manifesto] e retorna um erro por arquivo órfão (AC-04).
static func verificar_orfaos(
	manifesto: ManifestoDoCatalogo,
	arquivos_tres_em_disco: PackedStringArray
) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var listados: Dictionary[String, bool] = {}
	listados[CAMINHO_MANIFESTO] = true
	if manifesto != null:
		for c in manifesto.caminhos:
			listados[c] = true
	var ordenados := arquivos_tres_em_disco.duplicate()
	ordenados.sort()
	for caminho in ordenados:
		if caminho.begins_with(PASTA_CANON + "/"):
			continue
		if not caminho.ends_with(".tres"):
			continue
		if not listados.has(caminho):
			var d := Diagnostico.novo(
				REGRA_ORFAO,
				"caminhos",
				caminho,
				"arquivo .tres órfão em assets/data fora do manifesto: %s" % caminho
			)
			d.arquivo = caminho
			out.append(d)
	return out


## Lista recursivamente todos os arquivos [code].tres[/code] sob [param pasta_raiz].
static func listar_tres_em_disco(pasta_raiz: String = PASTA_DADOS) -> PackedStringArray:
	var out := PackedStringArray()
	_varrer_pasta(pasta_raiz, out)
	out.sort()
	return out


static func _varrer_pasta(pasta: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	dir.list_dir_begin()
	var nome := dir.get_next()
	while not nome.is_empty():
		if nome != "." and nome != "..":
			var completo := pasta.path_join(nome)
			if dir.current_is_dir():
				if completo != PASTA_CANON:
					_varrer_pasta(completo, out)
			elif nome.ends_with(".tres"):
				out.append(completo)
		nome = dir.get_next()
	dir.list_dir_end()


## Verifica o texto bruto de um [code].tres[/code] contra o [EsquemaDeDefinicao] de
## [param definicao]: detecta campos obrigatórios omitidos no texto (AC-09) e
## propriedades desconhecidas (AC-AR-01).
static func verificar_texto_tres(
	texto_tres: String,
	definicao: DefinicaoBase,
	caminho: String = "",
	posicao: int = 0
) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	if definicao == null:
		return out
	var item := ItemDoCatalogo.new(definicao.tipo_do_catalogo(), caminho, posicao, definicao)
	var gravados := EsquemaDeDefinicao.campos_gravados_no_texto(texto_tres)
	var esquema := definicao.esquema()
	var rot := "%s (%s)" % [esquema.nome_da_classe, definicao.id]

	# 1. Propriedades desconhecidas gravadas na seção [resource] (AC-AR-01).
	for nome_gravado in gravados:
		if esquema.regra(StringName(nome_gravado)) == null:
			out.append(Diagnostico.de_item(
				item,
				&"V1",
				nome_gravado,
				nome_gravado,
				"%s: propriedade desconhecida '%s' no arquivo .tres" % [rot, nome_gravado]
			))

	# 2. Campos obrigatórios ausentes no texto (mesmo se o script tiver default; AC-09).
	for ausente in esquema.campos_ausentes(gravados):
		out.append(Diagnostico.de_item(
			item,
			&"V1",
			ausente,
			null,
			"%s: %s ausente no arquivo .tres" % [rot, ausente]
		))

	return out
