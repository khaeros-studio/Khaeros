extends GdUnitTestSuite
## Story telemetria-local/003: opção `telemetria_ligada` (Desligada, Armada, religar após Parada por falha)
## e "Apagar dados" (apaga só `sessao-*.jsonl` após confirmação, preserva arquivo aberto e ignora falha com TL1)
## (AC-TL-15, AC-TL-16, AC-TL-26, AC-TL-32).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _avisos: RelatorDeAvisosTelemetria


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_avisos = RelatorDeAvisosTelemetria.new()


func _ev_run(seed_txt: String = "3F9A-07C2") -> EventosDeTelemetria.EvRunIniciada:
	return EventosDeTelemetria.EvRunIniciada.new(
		seed_txt, "a".repeat(64), "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}
	)


func test_desligada_nao_cria_nem_abre_arquivo_na_sessao_inteira_ac_tl_15() -> void:
	# Arrange
	var tel := TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "1B4E", false)

	# Act
	assert_bool(tel.iniciar_sessao()).is_false()
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.DESLIGADA)
	var lote: Array[EventoDoPasso] = [
		_ev_run(),
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 100),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 100),
	]
	tel.consumir(lote)
	tel.encerrar_sessao()

	# Assert
	assert_int(_armazem.contar(&"criar_escritor_de_linhas")).is_equal(0)
	assert_int(_armazem.contar(&"escrever_linha")).is_equal(0)


func test_desligar_com_run_em_curso_fecha_arquivo_e_ligar_vai_a_armada_ate_proxima_run_ac_tl_16() -> void:
	# Arrange
	var tel := TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "1B4E", true)
	tel.iniciar_sessao()
	var arq_1 := tel.caminho_arquivo_atual()

	# Run 1 começa
	var lote_r1: Array[EventoDoPasso] = [_ev_run("1111-1111")]
	tel.consumir(lote_r1)
	assert_int(tel.indice_run_atual()).is_equal(1)

	# Act 1: Desliga com a run 1 em curso -> grava sessao_encerrada("desligada") e vai a DESLIGADA
	tel.definir_ligada(false)
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.DESLIGADA)
	var lido_1 := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(arq_1))
	assert_int(lido_1.linhas.size()).is_equal(3) # sessao_iniciada, run_iniciada, sessao_encerrada
	assert_str(String(lido_1.linhas[2]["t"])).is_equal("sessao_encerrada")
	assert_str(String(lido_1.linhas[2]["motivo"])).is_equal("desligada")

	# Act 2: Ligar novamente vai a ARMADA, sem abrir arquivo antes da próxima run_iniciada
	tel.definir_ligada(true)
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.ARMADA)
	var lote_meio: Array[EventoDoPasso] = [EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 100)]
	tel.consumir(lote_meio)
	assert_int(_armazem.contar(&"criar_escritor_de_linhas")).is_equal(1)

	# Act 3: Próxima run_iniciada (run 2) abre arquivo novo com sessao_iniciada (n=0, schema 2) e run = 2
	_relogio.data_utc = "2026-11-18T12:05:00Z"
	var lote_r2: Array[EventoDoPasso] = [_ev_run("2222-2222")]
	tel.consumir(lote_r2)
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.ABERTA)
	var arq_2 := tel.caminho_arquivo_atual()
	assert_bool(arq_2 != arq_1).is_true()

	var lido_2 := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(arq_2))
	assert_int(lido_2.linhas.size()).is_equal(2)
	assert_str(String(lido_2.linhas[0]["t"])).is_equal("sessao_iniciada")
	assert_int(int(lido_2.linhas[0]["n"])).is_equal(0)
	assert_int(int(lido_2.linhas[0]["schema"])).is_equal(TelemetriaLocal.SCHEMA_ATUAL)
	assert_str(String(lido_2.linhas[1]["t"])).is_equal("run_iniciada")
	assert_int(int(lido_2.linhas[1]["n"])).is_equal(1)
	assert_int(int(lido_2.linhas[1]["run"])).is_equal(2)


func test_apos_parada_por_falha_religar_nao_abre_arquivo_ac_tl_16() -> void:
	# Arrange
	_armazem.programar_falha(&"criar_escritor_de_linhas", 1)
	var tel := TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "1B4E", true)
	assert_bool(tel.iniciar_sessao()).is_false()
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.PARADA_POR_FALHA)

	# Act: desligar e ligar não tira de PARADA_POR_FALHA
	tel.definir_ligada(false)
	tel.definir_ligada(true)
	var lote: Array[EventoDoPasso] = [_ev_run()]
	tel.consumir(lote)

	# Assert
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.PARADA_POR_FALHA)
	assert_int(_armazem.contar(&"criar_escritor_de_linhas")).is_equal(1)


func test_apagar_dados_preserva_sessao_em_curso_outros_arquivos_e_ignora_falha_com_tl1_ac_tl_26_e_32() -> void:
	# Arrange
	_armazem.colocar_texto("user://telemetria/sessao-20261110-100000.jsonl", "{}\n")
	_armazem.colocar_texto("user://telemetria/sessao-20261111-100000.jsonl", "{}\n")
	_armazem.colocar_texto("user://telemetria/outro.txt", "nao apagar")
	var tel := TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "1B4E", true)
	tel.iniciar_sessao()
	var atual := tel.caminho_arquivo_atual()

	# Sem confirmação não apaga nada
	assert_int(tel.apagar_dados(false)).is_equal(0)
	assert_bool(_armazem.tem_arquivo("user://telemetria/sessao-20261110-100000.jsonl")).is_true()

	# Programa falha ao apagar o 1º arquivo antigo (ex.: aberto por outra instância, AC-TL-32)
	_armazem.programar_falha(&"apagar", 1)

	# Act
	var apagados := tel.apagar_dados(true)

	# Assert: 1 falhou com TL1, 1 foi apagado, o arquivo da sessão atual e outro.txt permanecem, e a gravação segue
	assert_int(apagados).is_equal(1)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL1)).is_equal(1)
	assert_bool(_armazem.tem_arquivo("user://telemetria/sessao-20261110-100000.jsonl")).is_true()
	assert_bool(_armazem.tem_arquivo("user://telemetria/sessao-20261111-100000.jsonl")).is_false()
	assert_bool(_armazem.tem_arquivo("user://telemetria/outro.txt")).is_true()
	assert_bool(_armazem.tem_arquivo(atual)).is_true()
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.ABERTA)

	var lote: Array[EventoDoPasso] = [_ev_run()]
	tel.consumir(lote)
	assert_int(tel.numero_linha_atual()).is_equal(2)
