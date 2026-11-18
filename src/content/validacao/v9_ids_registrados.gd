class_name V9IdsRegistrados
extends ValidadorDeRegra
## V9: todo par (tipo, id) do registro acumulativo [code]ids_registrados.csv[/code]
## continua presente no catálogo (mesmo com [code]obsoleto = true[/code]), nenhuma
## linha do registro do ramo principal foi removida, e todo item do catálogo está
## registrado (GDD de Conteúdo R11, R9; story 010 AC-17, AC-48).
##
## Exemplo:
## [codeblock]
## var v9 := V9IdsRegistrados.de_arquivo("res://assets/data/canon/ids_registrados.csv")
## var diags := v9.validar(itens)
## [/codeblock]

const CAMINHO_PADRAO := "res://assets/data/canon/ids_registrados.csv"

## Lista ordenada de pares `"tipo,id"` do arquivo atual.
var _registrados: PackedStringArray = PackedStringArray()
## Lista opcional de pares `"tipo,id"` do ramo principal (para detectar remoção no CSV).
var _registro_base: PackedStringArray = PackedStringArray()


func _init(
	registrados: PackedStringArray = PackedStringArray(),
	registro_base: PackedStringArray = PackedStringArray()
) -> void:
	_registrados = registrados.duplicate()
	_registro_base = registro_base.duplicate()


## Carrega o validador V9 a partir de um arquivo CSV (`tipo,id`).
static func de_arquivo(
	caminho: String = CAMINHO_PADRAO,
	registro_base: PackedStringArray = PackedStringArray()
) -> V9IdsRegistrados:
	var pares := ler_pares_csv(caminho)
	return V9IdsRegistrados.new(pares, registro_base)


## Lê os pares `"tipo,id"` de um arquivo CSV.
static func ler_pares_csv(caminho: String) -> PackedStringArray:
	var out := PackedStringArray()
	if not FileAccess.file_exists(caminho):
		return out
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return out
	var primeira := true
	while not f.eof_reached():
		var linha := f.get_csv_line()
		if linha.size() < 2:
			continue
		var t := linha[0].strip_edges()
		var id_str := linha[1].strip_edges()
		if primeira and t == "tipo" and id_str == "id":
			primeira = false
			continue
		primeira = false
		if t.is_empty() or id_str.is_empty():
			continue
		out.append("%s,%s" % [t, id_str])
	return out


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var set_atual: Dictionary[String, bool] = {}
	for par in _registrados:
		set_atual[par] = true

	# 1. Nenhuma linha do ramo principal pode ter sido removida de ids_registrados.csv.
	for par_base in _registro_base:
		if not set_atual.has(par_base):
			var partes := par_base.split(",")
			var d := Diagnostico.novo(
				&"V9",
				"ids_registrados",
				par_base,
				"par (%s) removido de ids_registrados.csv (ids são permanentes; use obsoleto = true)" % par_base
			)
			d.arquivo = CAMINHO_PADRAO
			if partes.size() >= 2:
				d.tipo = StringName(partes[0])
				d.id = StringName(partes[1])
			out.append(d)

	# 2. Mapa dos itens presentes no catálogo (ativos OU obsoletos).
	var no_catalogo: Dictionary[String, ItemDoCatalogo] = {}
	for item in itens:
		var chave := "%s,%s" % [item.tipo, item.definicao.id]
		no_catalogo[chave] = item

	# 3. Todo (tipo, id) registrado precisa existir no catálogo (mesmo obsoleto = true).
	for par in _registrados:
		if not no_catalogo.has(par):
			var partes := par.split(",")
			var d := Diagnostico.novo(
				&"V9",
				"id",
				par,
				"id registrado (%s) foi removido do catálogo (mantenha o recurso com obsoleto = true)" % par
			)
			d.arquivo = CAMINHO_PADRAO
			if partes.size() >= 2:
				d.tipo = StringName(partes[0])
				d.id = StringName(partes[1])
			out.append(d)

	# 4. Todo (tipo, id) do catálogo deve constar em ids_registrados.csv.
	for chave: String in no_catalogo:
		if not set_atual.has(chave):
			var item := no_catalogo[chave]
			out.append(Diagnostico.de_item(
				item,
				&"V9",
				"id",
				item.definicao.id,
				"%s: par (%s) ausente em ids_registrados.csv" % [rotulo(item), chave]
			))

	return out
