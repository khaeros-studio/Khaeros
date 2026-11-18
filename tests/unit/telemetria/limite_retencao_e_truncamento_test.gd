extends GdUnitTestSuite
## Story telemetria-local/005: limite de bytes com reserva de 512 B (`PARADA_POR_LIMITE`),
## retenção das últimas `max_sessoes` (20) sessões preservando arquivos não-sessão
## e tolerância do leitor à última linha truncada / sessão abrupta (AC-TL-20, AC-TL-21, AC-TL-22).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _avisos: RelatorDeAvisosTelemetria
var _tuning: TelemetriaTuning


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_avisos = RelatorDeAvisosTelemetria.new()
	_tuning = TelemetriaTuning.new()
	_tuning.max_bytes_sessao = 4096
	_tuning.max_sessoes = 20
	_tuning.orcamento_linha_ms = 1.0
	_tuning.orcamento_passo_ms = 3.0
	_tuning.casas_decimais_duracao = 2


func test_limite_de_4_kb_com_reserva_de_512_b_fecha_com_sessao_encerrada_limite_ac_tl_20() -> void:
	# Arrange: max_bytes_sessao = 4 096 B
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	tel.iniciar_sessao()

	# Act: emite dezenas de eventos até atingir o limite
	for i in 60:
		var lote: Array[EventoDoPasso] = [
			EventosDeTelemetria.EvPortaEscolhida.new(i, &"bencao", [&"bencao", &"fragmentos", &"cura"])
		]
		tel.consumir(lote)

	# Assert: estado PARADA_POR_LIMITE, tamanho final <= 4 096 B e última linha é sessao_encerrada("limite")
	assert_int(tel.estado()).is_equal(TelemetriaLocal.Estado.PARADA_POR_LIMITE)
	var bytes_finais := _armazem.bytes_de(tel.caminho_arquivo_atual()).size()
	assert_int(bytes_finais).is_less_equal(4096)
	assert_int(tel.bytes_escritos()).is_equal(bytes_finais)

	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(tel.caminho_arquivo_atual()))
	assert_bool(lido.sessao_abrupta).is_false()
	var ultima := lido.linhas[lido.linhas.size() - 1]
	assert_str(String(ultima["t"])).is_equal("sessao_encerrada")
	assert_str(String(ultima["motivo"])).is_equal("limite")

	# Eventos seguintes não escrevem nenhuma linha depois
	var n_antes := lido.linhas.size()
	var lote_extra: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPortaEscolhida.new(99, &"bencao", [&"bencao"])
	]
	tel.consumir(lote_extra)
	var lido_depois := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(tel.caminho_arquivo_atual()))
	assert_int(lido_depois.linhas.size()).is_equal(n_antes)


func test_retencao_com_20_arquivos_apaga_o_mais_antigo_com_12_nao_apaga_e_preserva_outro_txt_ac_tl_21() -> void:
	# Arrange 1: 12 arquivos existentes + outro.txt com max_sessoes = 20 -> apaga 0
	_armazem.colocar_texto("user://telemetria/outro.txt", "fixo")
	for i in 12:
		var nome := "user://telemetria/sessao-202611%02d-100000.jsonl" % (i + 1)
		_armazem.colocar_texto(nome, "{}\n")

	var tel_12 := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	tel_12.iniciar_sessao()
	assert_int(_armazem.contar(&"apagar")).is_equal(0)
	assert_bool(_armazem.tem_arquivo("user://telemetria/outro.txt")).is_true()

	# Arrange 2: completa até 20 arquivos existentes antes de uma nova sessão -> deve apagar o mais antigo (dia 01)
	for i in range(12, 19):
		var nome := "user://telemetria/sessao-202611%02d-100000.jsonl" % (i + 1)
		_armazem.colocar_texto(nome, "{}\n")
	# Agora há 19 dos dias 01..19 + 1 da tel_12 (dia 18 12:00:00) = 20 sessões existentes
	_relogio.data_utc = "2026-11-25T12:00:00Z"
	var tel_20 := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	tel_20.iniciar_sessao()

	# Assert: apagou exatamente 1 (o mais antigo: sessao-20261101-100000.jsonl), mantendo 20 no total + outro.txt
	assert_bool(_armazem.tem_arquivo("user://telemetria/sessao-20261101-100000.jsonl")).is_false()
	assert_bool(_armazem.tem_arquivo("user://telemetria/sessao-20261102-100000.jsonl")).is_true()
	assert_bool(_armazem.tem_arquivo("user://telemetria/outro.txt")).is_true()
	var sessoes_finais := RetencaoDeSessoes.listar_sessoes_ordenadas(_armazem, "user://telemetria")
	assert_int(sessoes_finais.size()).is_equal(20)


func test_ultima_linha_truncada_ignorada_pelo_leitor_e_sessao_sem_encerramento_e_abrupta_ac_tl_22() -> void:
	# Arrange
	var tel := TelemetriaLocal.new(_armazem, _relogio, _tuning, _avisos)
	tel.iniciar_sessao()
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPortaEscolhida.new(0, &"bencao", [&"bencao", &"cura"])
	]
	tel.consumir(lote)

	var texto_valido := _armazem.texto_de(tel.caminho_arquivo_atual())
	var texto_truncado := texto_valido + "{\"t\":\"camara\",\"n\":2,\"ms\":50"

	# Act
	var res := LeitorDeTesteTelemetria.ler_jsonl(texto_truncado)

	# Assert
	assert_int(res.linhas.size()).is_equal(2)
	assert_int(res.linhas_truncadas_ignoradas).is_equal(1)
	assert_bool(res.sessao_abrupta).is_true()
	assert_str(String(res.linhas[0]["t"])).is_equal("sessao_iniciada")
	assert_str(String(res.linhas[1]["t"])).is_equal("porta")
