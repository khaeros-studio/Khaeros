extends GdUnitTestSuite
## Story telemetria-local/004: falhas absorvidas (`TL1`, `PARADA_POR_FALHA`, sem nova tentativa),
## pasta inexistente criada ou `TL1`, campo ausente (`null` e `TL3` uma vez por tipo)
## e orçamento por linha (`TL2` quando > 1 ms, gravação continua)
## (AC-TL-18, AC-TL-19, AC-TL-24, AC-TL-25, AC-TL-31).

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


func test_falha_ao_abrir_ou_criar_pasta_registra_um_tl1_e_descarta_eventos_posteriores_ac_tl_18_e_31() -> void:
	# Arrange: falha ao garantir pasta
	_armazem.programar_falha(&"garantir_pasta", 1)
	var tel_pasta := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)

	# Act
	assert_bool(tel_pasta.iniciar_sessao()).is_false()
	assert_int(tel_pasta.estado()).is_equal(TelemetriaLocal.Estado.PARADA_POR_FALHA)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL1)).is_equal(1)

	# Arrange 2: pasta criada com sucesso, mas falha ao abrir escritor
	_armazem.limpar_falhas()
	_avisos.limpar()
	_armazem.programar_falha(&"criar_escritor_de_linhas", 1)
	var tel_abrir := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	assert_bool(tel_abrir.iniciar_sessao()).is_false()
	assert_int(tel_abrir.estado()).is_equal(TelemetriaLocal.Estado.PARADA_POR_FALHA)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL1)).is_equal(1)
	assert_bool(_armazem.existe("user://telemetria")).is_true()

	# Eventos posteriores são descartados sem erro e sem novo TL1
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 80),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 80),
	]
	tel_abrir.consumir(lote)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL1)).is_equal(1)
	assert_int(_armazem.contar(&"escrever_linha")).is_equal(0)


func test_falha_na_decima_linha_para_de_gravar_sem_nova_tentativa_ac_tl_19() -> void:
	# Arrange: falha na 10ª chamada de escrever_linha (linha n = 9)
	_armazem.programar_falha(&"escrever_linha", 10)
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	tel.iniciar_sessao() # linha 1 (n=0)

	# Act: envia 12 portas (cada uma tenta gravar 1 linha)
	for i in 12:
		var lote: Array[EventoDoPasso] = [
			EventosDeTelemetria.EvPortaEscolhida.new(i, &"bencao", [&"bencao", &"fragmentos"])
		]
		tel.consumir(lote)

	# Assert: gravou 9 linhas com sucesso, falhou na 10ª, parou em PARADA_POR_FALHA com 1 TL1 e não tentou a 11ª
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.PARADA_POR_FALHA)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL1)).is_equal(1)
	assert_int(_armazem.contar(&"escrever_linha")).is_equal(10)
	assert_int(tel.numero_linha_atual()).is_equal(9)


func test_campo_ausente_sai_null_e_conta_tl3_uma_vez_por_tipo_ac_tl_24() -> void:
	# Arrange
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	tel.iniciar_sessao()

	# Act: duas portas com tipo_escolhido vazio
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPortaEscolhida.new(0, &"", [&"bencao"]),
		EventosDeTelemetria.EvPortaEscolhida.new(1, &"", [&"cura"]),
	]
	tel.consumir(lote)

	# Assert: ambas as linhas foram escritas com "tipo": null, mas TL3 contou só 1 vez para (porta, tipo)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL3)).is_equal(1)
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(tel.caminho_arquivo_atual()))
	assert_int(lido.linhas.size()).is_equal(3)
	assert_that(lido.linhas[1]["tipo"]).is_null()
	assert_that(lido.linhas[2]["tipo"]).is_null()


func test_escritor_que_demora_4_ms_por_linha_conta_tl2_e_continua_gravando_ac_tl_25() -> void:
	# Arrange: cada linha consome 4 000 us (4 ms > 1 ms de orcamento_linha_ms)
	_relogio.passo_auto_us = 4000
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)

	# Act
	tel.iniciar_sessao()
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPortaEscolhida.new(0, &"bencao", [&"bencao"])
	]
	tel.consumir(lote)

	# Assert: gravou normalmente e registrou TL2
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.ABERTA)
	assert_int(tel.numero_linha_atual()).is_equal(2)
	assert_int(tel.pior_linha_us()).is_equal(4000)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL2)).is_greater_equal(2)
