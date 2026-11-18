## Story RNG-004: texto da seed (F9) — formatação, parse estrito e rótulo R8.
extends GdUnitTestSuite


func test_formatar_vetores_f9() -> void:
	assert_str(TextoDaSeed.formatar(1067059138)).is_equal("3F9A-07C2")
	assert_str(TextoDaSeed.formatar(0)).is_equal("0000-0000")
	assert_str(TextoDaSeed.formatar(4294967295)).is_equal("FFFF-FFFF")


func test_parse_aceita_lista_do_f9() -> void:
	var aceitos: Dictionary[String, int] = {"3F9A-07C2": 1067059138, "3f9a07c2": 1067059138,
		"7C2": 1986, "0": 0, "FFFF-FFFF": 4294967295}
	for texto: String in aceitos:
		var resultado: TextoDaSeed.ResultadoDoParse = TextoDaSeed.interpretar(texto)
		assert_bool(resultado.aceito).override_failure_message(texto).is_true()
		assert_int(resultado.valor).is_equal(aceitos[texto])
		assert_str(resultado.mensagem).is_empty()


func test_parse_recusa_lista_do_f9_com_mensagem_que_cita_o_texto() -> void:
	var recusados: Array[String] = ["", "123456789", "3F9A-07C", "3F9A--07C2", " 3F9A07C2",
		"0x3F9A07C2", "-1", "+1", "G123", "3F9A_07C2", "12-34", "3F9A07C2 "]
	for texto: String in recusados:
		var resultado: TextoDaSeed.ResultadoDoParse = TextoDaSeed.interpretar(texto)
		assert_bool(resultado.aceito).override_failure_message("aceitou: [%s]" % texto).is_false()
		assert_str(resultado.mensagem).contains("\"%s\"" % texto)


func test_rotulo_seed_versao_e_impressao_curta() -> void:
	assert_str(TextoDaSeed.rotulo(0x3F9A07C2, "0.1.0", "1B4E")).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")


func test_rotulo_da_fonte_sem_run_devolve_sem_seed() -> void:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	assert_str(TextoDaSeed.rotulo_da_fonte(fonte, "0.1.0", "1B4E")).is_equal(TextoDaSeed.TEXTO_SEM_SEED)
	fonte.iniciar_run(0x3F9A07C2, false)
	assert_str(TextoDaSeed.rotulo_da_fonte(fonte, "0.1.0", "1B4E")).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")
