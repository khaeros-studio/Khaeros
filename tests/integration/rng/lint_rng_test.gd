## Story RNG-006, AC-32: lint de CI contra RNG da engine (tools/ci/lint_rng.gd).
## Integração: lê a fixture e os arquivos reais de src/ (I/O só de leitura).
extends GdUnitTestSuite

const Lint = preload("res://tools/ci/lint_rng.gd")
const FIXTURE := "res://tests/integration/rng/fixtures/violacao_plantada.gd"
const MARCA_DA_FIXTURE := "VIOLACAO_PLANTADA"
const GAME_SESSION := "res://src/gameplay/game_session.gd"


func _linha_da_marca(texto: String) -> int:
	var linhas := texto.split("\n")
	for n in linhas.size():
		if linhas[n].contains(MARCA_DA_FIXTURE + "\r") or linhas[n].ends_with(MARCA_DA_FIXTURE):
			return n + 1
	return -1


func test_fixture_com_violacao_plantada_detecta_so_a_chamada_real() -> void:
	# Arrange
	var texto := FileAccess.get_file_as_string(FIXTURE)
	var linha := _linha_da_marca(texto)
	# Act
	var violacoes: Array[String] = Lint.violacoes_no_arquivo(texto, "gd")
	# Assert: as iscas em comentário e literais não contam.
	assert_int(linha).is_greater(0)
	assert_array(violacoes).has_size(1)
	assert_str(violacoes[0]).contains("linha %d:" % linha)


func test_projeto_real_varre_arquivos_e_nao_tem_ocorrencias() -> void:
	# Act
	var resultado: Dictionary = Lint.varrer_projeto()
	# Assert: varredura de zero arquivos seria NOT ASSESSED, não aprovação.
	assert_int(resultado.arquivos_varridos).is_greater(0)
	assert_int(resultado.apresentacao_varridos).is_greater(0)
	assert_int(resultado.isentos).is_equal(1)
	assert_array(resultado.violacoes).override_failure_message(str(resultado.violacoes)).is_empty()


func test_script_embutido_em_cena_com_chamada_real_e_detectado() -> void:
	# Arrange: um .tscn com GDScript embutido (aspas e quebras escapadas).
	var cena := "[gd_scene format=3]\n\n[sub_resource type=\"GDScript\" id=\"x\"]\n" \
		+ "script/source = \"extends Node\n# randf() so no comentario\nvar t := \\\"randi()\\\"\nfunc f() -> float:\n\treturn randf()\n\"\n"
	# Act
	var violacoes: Array[String] = Lint.violacoes_no_arquivo(cena, "tscn")
	# Assert
	assert_array(violacoes).has_size(1)
	assert_str(violacoes[0]).contains("linha 5:")


func test_recurso_sem_script_embutido_nao_gera_ocorrencia() -> void:
	var recurso := "[gd_resource type=\"Resource\" format=3]\n\n[resource]\nnome = \"randi() pick_random\"\n"
	assert_array(Lint.violacoes_no_arquivo(recurso, "tres")).is_empty()


func test_seed_global_conta_e_metodo_proprio_seed_nao_conta() -> void:
	# Arrange
	var metodo := "func seed() -> int:\n\treturn 1\nvar s := fonte.seed()\n"
	var global := "func f() -> void:\n\tseed(42)\n"
	# Act / Assert
	assert_array(Lint.violacoes_no_codigo(metodo)).is_empty()
	assert_array(Lint.violacoes_no_codigo(global)).has_size(1)


func test_cada_padrao_proibido_em_codigo_e_detectado() -> void:
	var chamadas: Array[String] = ["randf()", "randi()", "randf_range(a, b)", "randi_range(a, b)",
		"randfn(a, b)", "rand_from_seed(x)", "randomize()", "seed(x)", "RandomNumberGenerator.new()",
		"lista.shuffle()", "lista.pick_random()", "texto.hex_to_int()"]
	for chamada: String in chamadas:
		var codigo := "func f() -> void:\n\tvar v = %s\n" % chamada
		assert_array(Lint.violacoes_no_codigo(codigo)).override_failure_message(chamada).is_not_empty()


func test_apresentacao_com_referencia_a_fonte_e_detectada() -> void:
	var com_preload := "const F = preload(\"res://src/foundation/rng/fonte_de_fluxos.gd\")\n"
	var com_tipo := "var fluxo: FluxoRng\n"
	var so_comentario := "# a FonteDeFluxos nunca entra aqui\nvar x := 1\n"
	assert_array(Lint.referencias_a_fonte(com_preload, "gd")).is_not_empty()
	assert_array(Lint.referencias_a_fonte(com_tipo, "gd")).is_not_empty()
	assert_array(Lint.referencias_a_fonte(so_comentario, "gd")).is_empty()


func test_game_session_tira_a_espera_da_ia_do_fluxo_ia() -> void:
	# Arrange: a fatia não guarda mais gerador próprio; usa a interface de IA.
	var texto := FileAccess.get_file_as_string(GAME_SESSION)
	# Assert
	assert_bool(texto.contains("FluxosDeIa")).is_true()
	assert_bool(texto.contains("_rng_state")).is_false()
	assert_array(Lint.violacoes_no_arquivo(texto, "gd")).is_empty()
