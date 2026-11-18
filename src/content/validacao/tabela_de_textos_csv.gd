class_name TabelaDeTextosCsv
extends TabelaDeTextos
## Implementação de [TabelaDeTextos] que carrega chaves e textos diretamente de um
## arquivo CSV de localização (ex.: [code]res://assets/i18n/conteudo.csv[/code]).
## Usada pelos validadores V5, V6 e V10 em testes de integração e CI (story 010).
##
## Exemplo:
## [codeblock]
## var t := TabelaDeTextosCsv.de_arquivo("res://assets/i18n/conteudo.csv")
## assert(t.tem("WEAPON_PACTOS_NAME"))
## [/codeblock]

const CAMINHO_PADRAO := "res://assets/i18n/conteudo.csv"

var _textos: Dictionary[String, String] = {}


func _init(mapa: Dictionary = {}) -> void:
	for k: Variant in mapa:
		_textos[String(k)] = String(mapa[k])


static func de_arquivo(caminho: String = CAMINHO_PADRAO, coluna_idioma: String = "pt_BR") -> TabelaDeTextosCsv:
	var inst := TabelaDeTextosCsv.new()
	if not FileAccess.file_exists(caminho):
		return inst
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return inst
	var cabecalho := f.get_csv_line()
	var idx_chave := 0
	var idx_texto := 1
	for i in cabecalho.size():
		var col := cabecalho[i].strip_edges()
		if col == "keys" or col == "key" or col == "id":
			idx_chave = i
		elif col == coluna_idioma or col == "pt":
			idx_texto = i
	while not f.eof_reached():
		var linha := f.get_csv_line()
		if linha.size() <= maxi(idx_chave, idx_texto):
			continue
		var chave := linha[idx_chave].strip_edges()
		if chave.is_empty():
			continue
		inst._textos[chave] = linha[idx_texto]
	return inst


func definir(chave: String, valor: String) -> void:
	_textos[chave] = valor


func tem(chave: String) -> bool:
	return _textos.has(chave) and not _textos[chave].strip_edges().is_empty()


func existe(chave: String) -> bool:
	return tem(chave)


func texto(chave: String) -> String:
	return _textos.get(chave, "")
