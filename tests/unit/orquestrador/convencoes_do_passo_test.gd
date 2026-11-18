## Lint das convenções do passo (story orquestrador-008; ADR-0001 §Implementation Guidelines,
## ADR-0002). Varre os [code].gd[/code] de [code]res://src/[/code] como texto (leitura de CI, não do
## jogo) e o [code]project.godot[/code]. Pastas novas de lógica em [code]src/[/code] devem entrar em
## [constant PASTAS_DE_LOGICA].
extends GdUnitTestSuite

## Pastas de lógica pura (sem tempo real, pausa da árvore, sinais ou ganchos da engine).
const PASTAS_DE_LOGICA: PackedStringArray = [
	"res://src/foundation/", "res://src/gameplay/", "res://src/content/",
]
## Padrões proibidos na lógica (regex, linha sem comentário).
const PROIBIDOS: Dictionary = {
	"SceneTree.paused": "SceneTree\\.paused",
	"get_tree().paused": "get_tree\\(\\)\\.paused",
	"Time.": "\\bTime\\.",
	"OS.": "\\bOS\\.",
	"Engine.time_scale": "Engine\\.time_scale",
	"Timer": "\\bTimer\\b",
	"create_timer": "create_timer",
	"signal": "^\\s*signal\\s",
	"_physics_process": "func\\s+_physics_process\\b",
	"_process": "func\\s+_process\\b",
}
## Exceções explícitas por arquivo → padrões liberados, com o motivo.
const EXCECOES: Dictionary = {
	# Legado da fatia: sai quando o provedor do épico input substituir game_input.gd (story 007).
	"res://src/foundation/game_input.gd": ["signal", "OS.", "Time.", "_process"],
	# Conversão pura de keycode em texto do rótulo; não lê tempo nem estado da plataforma.
	"res://src/foundation/input/rotulos_de_acao.gd": ["OS."],
	# Entropia real da seed (RNG story 004): única fonte do sistema, injetada pelo Main.
	"res://src/foundation/rng/fonte_de_entropia_do_sistema.gd": ["OS.", "Time."],
}
## Únicos arquivos com ganchos de quadro/passo fora da Apresentação.
const MAIN: String = "res://src/app/main.gd"


## Violações de [param texto] (conteúdo de [param caminho]) como "caminho:linha:padrão".
static func violacoes(caminho: String, texto: String) -> PackedStringArray:
	var r := PackedStringArray()
	var liberados: Array = EXCECOES.get(caminho, [])
	var logica := false
	for pasta: String in PASTAS_DE_LOGICA:
		if caminho.begins_with(pasta):
			logica = true
	var apresentacao := caminho.begins_with("res://src/presentation/")
	var linhas := texto.split("\n")
	for i: int in linhas.size():
		var linha: String = linhas[i]
		if linha.strip_edges().begins_with("#"):
			continue
		for nome: String in PROIBIDOS:
			if liberados.has(nome):
				continue
			var re := RegEx.create_from_string(PROIBIDOS[nome])
			if re.search(linha) == null:
				continue
			var proibido := logica
			if nome == "_physics_process":
				proibido = caminho != MAIN
			elif nome == "_process":
				proibido = not apresentacao and caminho != MAIN
			if proibido:
				r.append("%s:%d:%s" % [caminho, i + 1, nome])
	return r


func _arquivos(dir: String, saida: PackedStringArray) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			saida.append(dir.path_join(f))
	for sub: String in d.get_directories():
		_arquivos(dir.path_join(sub), saida)


func test_convencoes_src_inteiro_sem_violacoes() -> void:
	var arquivos := PackedStringArray()
	_arquivos("res://src", arquivos)
	assert_bool(arquivos.size() > 0).is_true()
	var todas := PackedStringArray()
	for caminho: String in arquivos:
		todas.append_array(violacoes(caminho, FileAccess.get_file_as_string(caminho)))
	assert_array(Array(todas)).is_empty()


func test_project_godot_sem_autoload_nenhuma_secao() -> void:
	var texto := FileAccess.get_file_as_string("res://project.godot")
	assert_bool(texto.contains("[autoload]")).is_false()


func test_mutacao_cada_padrao_em_logica_e_detectado() -> void:
	var amostras: Dictionary = {
		"SceneTree.paused": "\tvar p = SceneTree.paused",
		"get_tree().paused": "\tget_tree().paused = true",
		"Time.": "\tvar t := Time.get_ticks_msec()",
		"OS.": "\tvar d := OS.is_debug_build()",
		"Engine.time_scale": "\tEngine.time_scale = 0.5",
		"Timer": "\tvar x := Timer.new()",
		"create_timer": "\tawait tree.create_timer(1.0).timeout",
		"signal": "signal morreu",
		"_physics_process": "func _physics_process(d: float) -> void:",
		"_process": "func _process(d: float) -> void:",
	}
	for nome: String in amostras:
		var v := violacoes("res://src/gameplay/temporario_mutacao.gd", "extends RefCounted\n" + amostras[nome])
		assert_array(Array(v)).contains([("res://src/gameplay/temporario_mutacao.gd:2:%s" % nome)])


func test_mutacao_comentario_e_apresentacao_nao_acusam() -> void:
	assert_array(Array(violacoes("res://src/gameplay/x.gd", "## usa Time. e OS. só no texto"))).is_empty()
	assert_array(Array(violacoes("res://src/presentation/x.gd", "signal a\nfunc _process(d):"))).is_empty()
	assert_array(Array(violacoes(MAIN, "func _physics_process(d):\nfunc _process(d):"))).is_empty()
	assert_array(Array(violacoes("res://src/presentation/x.gd", "func _physics_process(d):"))).is_not_empty()
