extends GdUnitTestSuite
## Story telemetria-local/001: abertura da sessão, arquivo `.jsonl`, campos comuns (`t`, `n`, `ms`, `run`, `schema`),
## descarga após cada linha e sufixo `-2` em nomes repetidos no mesmo segundo (AC-TL-01, AC-TL-02, AC-TL-03, AC-TL-23).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _avisos: RelatorDeAvisosTelemetria
var _tuning: TelemetriaTuning


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_avisos = RelatorDeAvisosTelemetria.new()
	_tuning = TelemetriaTuning.new()
	_tuning.max_bytes_sessao = 2097152
	_tuning.max_sessoes = 20
	_tuning.orcamento_linha_ms = 1.0
	_tuning.orcamento_passo_ms = 3.0
	_tuning.casas_decimais_duracao = 2


func test_abertura_cria_arquivo_jsonl_utc_e_linha_zero_sessao_iniciada_ac_tl_01() -> void:
	# Arrange
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos, "0.1.0", "1B4E", true)

	# Act
	var abriu := tel.iniciar_sessao()

	# Assert
	assert_bool(abriu).is_true()
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.ABERTA)
	assert_str(tel.caminho_arquivo_atual()).is_equal("user://telemetria/sessao-20261118-120000.jsonl")
	assert_bool(_armazem.tem_arquivo(tel.caminho_arquivo_atual())).is_true()

	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(tel.caminho_arquivo_atual()))
	assert_int(lido.linhas.size()).is_equal(1)
	var l0 := lido.linhas[0]
	assert_str(String(l0["t"])).is_equal("sessao_iniciada")
	assert_int(int(l0["n"])).is_equal(0)
	assert_int(int(l0["ms"])).is_equal(0)
	assert_int(int(l0["run"])).is_equal(0)
	assert_int(int(l0["schema"])).is_equal(TelemetriaLocal.SCHEMA_ATUAL)
	assert_str(String(l0["versao"])).is_equal("0.1.0")
	assert_str(String(l0["impressao"])).is_equal("1B4E")
	assert_str(String(l0["os"])).is_equal("windows")
	assert_str(String(l0["data_utc"])).is_equal("2026-11-18T12:00:00Z")


func test_campos_comuns_sequenciais_ms_nao_decrescente_e_schema_so_na_linha_zero_ac_tl_02_e_03() -> void:
	# Arrange
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos, "0.1.0", "1B4E", true)
	tel.iniciar_sessao()

	# Act
	_relogio.avancar_ms(50)
	var lote1: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", "a".repeat(64), "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []})
	]
	tel.consumir(lote1)

	_relogio.avancar_ms(120)
	var lote2: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 100),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 100),
	]
	tel.consumir(lote2)

	_relogio.avancar_ms(10)
	tel.encerrar_sessao()

	# Assert: 4 linhas (sessao_iniciada, run_iniciada, camara, sessao_encerrada)
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(tel.caminho_arquivo_atual()))
	assert_int(lido.linhas.size()).is_equal(4)
	assert_bool(lido.sessao_abrupta).is_false()

	var ms_ant := -1
	for i in lido.linhas.size():
		var linha := lido.linhas[i]
		assert_bool(linha.has("t")).is_true()
		assert_int(int(linha["n"])).is_equal(i)
		var ms_i := int(linha["ms"])
		assert_int(ms_i).is_greater_equal(ms_ant)
		ms_ant = ms_i
		assert_bool(linha.has("run")).is_true()
		if i == 0:
			assert_bool(linha.has("schema")).is_true()
		else:
			assert_bool(linha.has("schema")).is_false()

	# AC-TL-03: uma descarga depois de cada linha escrita
	assert_int(_armazem.contar(&"escrever_linha")).is_equal(4)
	assert_int(_armazem.contar(&"descarregar")).is_equal(4)


func test_duas_sessoes_no_mesmo_segundo_segunda_ganha_sufixo_menos_2_ac_tl_23() -> void:
	# Arrange / Act
	var tel1 := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos, "0.1.0", "1B4E", true)
	tel1.iniciar_sessao()

	var tel2 := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos, "0.1.0", "1B4E", true)
	tel2.iniciar_sessao()

	var tel3 := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos, "0.1.0", "1B4E", true)
	tel3.iniciar_sessao()

	# Assert
	assert_str(tel1.caminho_arquivo_atual()).is_equal("user://telemetria/sessao-20261118-120000.jsonl")
	assert_str(tel2.caminho_arquivo_atual()).is_equal("user://telemetria/sessao-20261118-120000-2.jsonl")
	assert_str(tel3.caminho_arquivo_atual()).is_equal("user://telemetria/sessao-20261118-120000-3.jsonl")
