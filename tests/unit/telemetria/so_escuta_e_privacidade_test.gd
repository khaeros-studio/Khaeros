extends GdUnitTestSuite
## Story telemetria-local/002: só escuta (não chama escrita de nenhum sistema, roda sem disco),
## privacidade (sem caminho absoluto, nome de usuário, IP, fuso local; UTC termina em Z; seed/impressão hex)
## e varredura estática provando que o módulo nunca lê `.jsonl` (AC-TL-14, AC-TL-17, AC-TL-30).

const PASTA_MODULO := "res://src/foundation/telemetria"


func test_so_escuta_nao_altera_eventos_nem_emite_no_canal_ac_tl_14() -> void:
	# Arrange
	var armazem := ArmazemEmMemoria.new()
	var relogio := RelogioDeSessaoFalso.new("2026-11-18T15:30:00", "linux") # sem Z: deve normalizar para Z
	var canal := EventosDoPasso.new()
	var tel := TelemetriaLocal.new(armazem, relogio, null, null, "0.1.0", "1B4E", true)
	tel.iniciar_sessao()

	var ev_run := EventosDeTelemetria.EvRunIniciada.new(
		"3F9A-07C2",
		"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"limiar",
		{"arma": "lamina", "doutrina": "lamina", "oficina": []}
	)
	canal.emitir(ev_run)
	var lote := canal.esvaziar()

	# Act: entrega pelo canal real (se a Telemetria tentasse emitir durante a entrega, falharia por assert)
	var consumidores: Array[ConsumidorDeEventos] = [tel]
	canal.entregar(lote, consumidores)

	# Assert
	assert_int(canal.todos().size()).is_equal(0)
	assert_str(ev_run.seed_texto).is_equal("3F9A-07C2")
	assert_int(tel.indice_run_atual()).is_equal(1)


func test_privacidade_sem_caminho_absoluto_usuario_ou_fuso_e_data_utc_termina_em_z_ac_tl_17() -> void:
	# Arrange
	var armazem := ArmazemEmMemoria.new()
	var relogio := RelogioDeSessaoFalso.new("2026-11-18T20:15:09", "windows")
	var tel := TelemetriaLocal.new(armazem, relogio, null, null, "0.1.0", "1B4E", true)
	tel.iniciar_sessao()

	var imp64 := "a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90"
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", imp64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}),
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 100),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 100),
	]
	tel.consumir(lote)
	tel.encerrar_sessao()

	# Act
	var texto := armazem.texto_de(tel.caminho_arquivo_atual())
	var lido := LeitorDeTesteTelemetria.ler_jsonl(texto)

	# Assert: nenhuma linha contém caminho absoluto (C:/, /Users/, user://), IP ou fuso local (-03:00)
	assert_bool(texto.contains("C:/") or texto.contains("C:\\")).is_false()
	assert_bool(texto.contains("/Users/") or texto.contains("lucas")).is_false()
	assert_bool(texto.contains("user://")).is_false()
	assert_bool(texto.contains("127.0.0.1") or texto.contains("192.168.")).is_false()
	assert_bool(texto.contains("-03:00") or texto.contains("+00:00")).is_false()

	var l0 := lido.linhas[0]
	assert_bool(String(l0["data_utc"]).ends_with("Z")).is_true()
	var re_hex4 := RegEx.create_from_string("^[0-9A-Fa-f]{4}$")
	assert_object(re_hex4.search(String(l0["impressao"]))).is_not_null()

	var l1 := lido.linhas[1]
	var re_seed := RegEx.create_from_string("^[0-9A-F]{4}-[0-9A-F]{4}$")
	var re_hex64 := RegEx.create_from_string("^[0-9a-fA-F]{64}$")
	assert_object(re_seed.search(String(l1["seed"]))).is_not_null()
	assert_object(re_hex64.search(String(l1["impressao"]))).is_not_null()


func test_varredura_modulo_telemetria_nunca_chama_simbolos_de_leitura_de_arquivo_ac_tl_30() -> void:
	# Arrange
	var dir := DirAccess.open(PASTA_MODULO)
	assert_object(dir).is_not_null()
	var proibidos: PackedStringArray = [
		"ler_texto(",
		"get_line(",
		"get_as_text(",
		"get_file_as_string(",
		"FileAccess.READ",
		"JSON.parse_string(",
	]
	var arquivos_varridos := 0
	var violacoes: Array[String] = []

	# Act
	for f: String in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		arquivos_varridos += 1
		var caminho := PASTA_MODULO.path_join(f)
		var linhas := FileAccess.get_file_as_string(caminho).split("\n")
		for idx in linhas.size():
			var l := linhas[idx].strip_edges()
			if l.begins_with("#"):
				continue
			for p: String in proibidos:
				if l.contains(p):
					violacoes.append("%s:%d (%s)" % [caminho, idx + 1, p])

	# Assert
	assert_int(arquivos_varridos).is_greater_equal(7)
	assert_array(violacoes).is_empty()
