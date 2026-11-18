## Story RNG-003, AC-29: nenhum Autoload e nenhuma `static var` guarda instância de RNG.
## Lê project.godot e os .gd de src/ (integração: I/O real só de leitura).
extends GdUnitTestSuite

const TIPOS_DE_RNG: Array[String] = ["FonteDeFluxos", "FluxoRng", "RandomNumberGenerator",
	"AcessoAFluxos", "FluxosDe"]


func _scripts_em(pasta: String) -> Array[String]:
	var caminhos: Array[String] = []
	var dir := DirAccess.open(pasta)
	if dir == null:
		return caminhos
	for arquivo: String in dir.get_files():
		if arquivo.ends_with(".gd"):
			caminhos.append(pasta.path_join(arquivo))
	for sub: String in dir.get_directories():
		caminhos.append_array(_scripts_em(pasta.path_join(sub)))
	return caminhos


func _cita_rng(texto: String) -> bool:
	for tipo: String in TIPOS_DE_RNG:
		if texto.contains(tipo):
			return true
	return false


func test_autoloads_nao_contem_rng() -> void:
	var projeto := ConfigFile.new()
	assert_int(projeto.load("res://project.godot")).is_equal(OK)
	if not projeto.has_section("autoload"):
		return
	for nome: String in projeto.get_section_keys("autoload"):
		var caminho: String = str(projeto.get_value("autoload", nome)).trim_prefix("*")
		assert_bool(_cita_rng(nome)).override_failure_message(nome).is_false()
		if caminho.ends_with(".gd"):
			var texto: String = FileAccess.get_file_as_string(caminho)
			assert_bool(_cita_rng(texto)).override_failure_message(caminho).is_false()


func test_static_var_em_src_nao_guarda_rng() -> void:
	var achados: Array[String] = []
	for caminho: String in _scripts_em("res://src"):
		var linhas: PackedStringArray = FileAccess.get_file_as_string(caminho).split("\n")
		for i: int in linhas.size():
			var linha: String = linhas[i].strip_edges()
			if linha.begins_with("static var") and _cita_rng(linha):
				achados.append("%s:%d" % [caminho, i + 1])
	assert_array(achados).is_empty()
