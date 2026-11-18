## Lint de CI contra RNG da engine no código de jogo (GDD rng-com-seed.md R1,
## AC-32; ADR-0005 "Seed, telemetria e fronteira da apresentação"; story RNG-006).
##
## Uso (raiz do projeto):
##   godot --headless --path . --script res://tools/ci/lint_rng.gd
## Saída: 0 = aprovado (arquivos varridos > 0 e 0 ocorrências); 1 = violação;
## 2 = NOT ASSESSED (nenhum arquivo varrido — nunca conta como aprovação).
##
## Escopo: `*.gd` e scripts embutidos (`script/source`) de `*.tscn`/`*.tres` sob
## `src/`, exceto `src/presentation/`. Comentários e literais de texto são
## apagados antes da busca, então só chamadas reais contam. Em
## `src/presentation/` a regra é outra: nenhuma referência à fonte de fluxos
## (aqui os literais contam, porque um `preload` é um texto; comentários não).
##
## Sem `class_name` e sem dependências: roda antes de qualquer import e os
## testes chamam as funções estáticas pelo `preload`.
extends SceneTree

## Raiz varrida.
const RAIZ := "res://src"
## Pasta da apresentação: fora da varredura de chamadas, dentro da de referências.
const APRESENTACAO := "res://src/presentation"
## Única exceção: o ponto de entropia da criação da run (R2, story RNG-004).
const ISENTOS: Array[String] = ["res://src/foundation/rng/fonte_de_entropia_do_sistema.gd"]
## Extensões varridas.
const EXTENSOES: Array[String] = ["gd", "tscn", "tres"]

## Padrões do AC-32. `seed(` é a função global da engine: método/propriedade
## (`.seed(`) e declaração (`func seed(`) não contam — ver [method _eh_seed_global].
const PADROES: Array[String] = [
	"\\brandf\\(", "\\brandi\\(", "randf_range", "randi_range", "randfn", "rand_from_seed",
	"\\brandomize\\(", "(?<![.\\w])seed\\s*\\(", "RandomNumberGenerator", "\\.shuffle\\(",
	"\\.pick_random\\(", "hex_to_int",
]
## Referências proibidas em `src/presentation/` (tipos e caminhos da fonte de fluxos).
const REFERENCIAS_DA_FONTE: Array[String] = [
	"FonteDeFluxos", "FluxoRng", "AcessoAFluxos", "\\bFluxosDe[A-Z]\\w*", "foundation/rng/",
	"fonte_de_fluxos", "fluxo_rng",
]


func _init() -> void:
	var resultado := varrer_projeto()
	for linha: String in resultado.violacoes:
		printerr("lint_rng: VIOLACAO ", linha)
	print("lint_rng: arquivos_varridos=%d violacoes=%d isentos=%d apresentacao_varridos=%d" % [
		resultado.arquivos_varridos, resultado.violacoes.size(), resultado.isentos,
		resultado.apresentacao_varridos])
	var codigo := 0
	if resultado.arquivos_varridos == 0:
		print("lint_rng: NOT ASSESSED (nenhum arquivo varrido)")
		codigo = 2
	elif not resultado.violacoes.is_empty():
		codigo = 1
	else:
		print("lint_rng: OK")
	quit(codigo)


## Varre o projeto real com as regras do AC-32. Devolve
## {arquivos_varridos, isentos, apresentacao_varridos, violacoes: Array[String]}.
static func varrer_projeto() -> Dictionary:
	return varrer(RAIZ, APRESENTACAO, ISENTOS)


## Varre `raiz` (menos `apresentacao`) atrás de chamadas proibidas e
## `apresentacao` atrás de referências à fonte de fluxos. `isentos` são caminhos
## exatos fora da varredura de chamadas (contados em `isentos`).
static func varrer(raiz: String, apresentacao: String, isentos: Array[String]) -> Dictionary:
	var violacoes: Array[String] = []
	var varridos := 0
	var n_isentos := 0
	var de_apresentacao := 0
	for caminho: String in listar_arquivos(raiz):
		var texto := FileAccess.get_file_as_string(caminho)
		if apresentacao != "" and caminho.begins_with(apresentacao + "/"):
			de_apresentacao += 1
			for v: String in referencias_a_fonte(texto, caminho.get_extension()):
				violacoes.append("%s: %s" % [caminho, v])
			continue
		if isentos.has(caminho):
			n_isentos += 1
			continue
		varridos += 1
		for v: String in violacoes_no_arquivo(texto, caminho.get_extension()):
			violacoes.append("%s: %s" % [caminho, v])
	return {"arquivos_varridos": varridos, "isentos": n_isentos,
		"apresentacao_varridos": de_apresentacao, "violacoes": violacoes}


## Lista recursiva (ordem estável) dos arquivos com extensão de [constant EXTENSOES].
static func listar_arquivos(pasta: String) -> Array[String]:
	var caminhos: Array[String] = []
	var dir := DirAccess.open(pasta)
	if dir == null:
		return caminhos
	var arquivos := Array(dir.get_files())
	arquivos.sort()
	for arquivo: String in arquivos:
		if EXTENSOES.has(arquivo.get_extension()):
			caminhos.append(pasta.path_join(arquivo))
	var pastas := Array(dir.get_directories())
	pastas.sort()
	for sub: String in pastas:
		caminhos.append_array(listar_arquivos(pasta.path_join(sub)))
	return caminhos


## Violações de um arquivo: `.gd` direto; `.tscn`/`.tres` só nos scripts embutidos.
static func violacoes_no_arquivo(texto: String, extensao: String) -> Array[String]:
	if extensao == "gd":
		return violacoes_no_codigo(texto)
	var achadas: Array[String] = []
	var i := 0
	for fonte: String in scripts_embutidos(texto):
		for v: String in violacoes_no_codigo(fonte):
			achadas.append("script embutido %d, %s" % [i, v])
		i += 1
	return achadas


## Violações num código GDScript: "linha N: padrão". Comentários e literais
## de texto não contam.
static func violacoes_no_codigo(codigo: String) -> Array[String]:
	var limpo := limpar_codigo(codigo, false)
	var achadas: Array[String] = []
	var linhas := limpo.split("\n")
	for padrao: String in PADROES:
		var regex := RegEx.create_from_string(padrao)
		for n in linhas.size():
			for m: RegExMatch in regex.search_all(linhas[n]):
				if padrao.contains("seed") and not _eh_seed_global(linhas[n], m.get_start()):
					continue
				achadas.append("linha %d: %s" % [n + 1, padrao])
	return achadas


## Referências à fonte de fluxos (regra de `src/presentation/`).
static func referencias_a_fonte(texto: String, extensao: String) -> Array[String]:
	# Em .tscn/.tres o texto inteiro conta (um ext_resource com o caminho já é referência).
	var limpo := limpar_codigo(texto, true) if extensao == "gd" else texto
	var linhas := limpo.split("\n")
	var achadas: Array[String] = []
	for padrao: String in REFERENCIAS_DA_FONTE:
		var regex := RegEx.create_from_string(padrao)
		for n in linhas.size():
			if regex.search(linhas[n]) != null:
				achadas.append("linha %d: referencia a fonte de fluxos (%s)" % [n + 1, padrao])
	return achadas


## Extrai e desescapa os `script/source = "..."` de um `.tscn`/`.tres`.
static func scripts_embutidos(texto: String) -> Array[String]:
	var fontes: Array[String] = []
	var marcador := "script/source = \""
	var inicio := texto.find(marcador)
	while inicio != -1:
		var i := inicio + marcador.length()
		var bruto := ""
		while i < texto.length():
			var c := texto[i]
			if c == "\\" and i + 1 < texto.length():
				bruto += c + texto[i + 1]
				i += 2
				continue
			if c == "\"":
				break
			bruto += c
			i += 1
		fontes.append(bruto.c_unescape())
		inicio = texto.find(marcador, i)
	return fontes


## Troca comentários (sempre) e o conteúdo dos literais de texto (se
## `manter_textos` for falso) por espaços, preservando as quebras de linha.
## Reconhece "", '', """ """, ''' ''', escapes e os prefixos r, & e ^.
static func limpar_codigo(codigo: String, manter_textos: bool) -> String:
	var saida := PackedStringArray()
	var i := 0
	var n := codigo.length()
	while i < n:
		var c := codigo[i]
		if c == "#":
			while i < n and codigo[i] != "\n":
				saida.append(" ")
				i += 1
			continue
		if c == "\"" or c == "'":
			var cru := i > 0 and codigo[i - 1] == "r" and (i < 2 or not _eh_palavra(codigo[i - 2]))
			var triplo := codigo.substr(i, 3) == c + c + c
			var delim := c + c + c if triplo else c
			for k in delim.length():
				saida.append(delim[k])
			i += delim.length()
			while i < n:
				if codigo.substr(i, delim.length()) == delim:
					break
				var d := codigo[i]
				if d == "\\" and not cru and i + 1 < n:
					saida.append(d if manter_textos else " ")
					var e := codigo[i + 1]
					saida.append(e if manter_textos or e == "\n" else " ")
					i += 2
					continue
				if not triplo and d == "\n":
					break  # literal não fechado: não engole o resto do arquivo
				saida.append(d if manter_textos or d == "\n" else " ")
				i += 1
			if i < n and codigo.substr(i, delim.length()) == delim:
				for k in delim.length():
					saida.append(delim[k])
				i += delim.length()
			continue
		saida.append(c)
		i += 1
	return "".join(saida)


static func _eh_palavra(c: String) -> bool:
	return c == "_" or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")


## `seed(` só conta como a função global: não depois de `func ` (declaração de
## método próprio, ex.: `FonteDeFluxos.seed()`).
static func _eh_seed_global(linha: String, inicio: int) -> bool:
	var antes := linha.substr(0, inicio).strip_edges(false, true)
	return not antes.ends_with("func") and not antes.ends_with("static func")
