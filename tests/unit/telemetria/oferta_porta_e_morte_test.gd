extends GdUnitTestSuite
## Story telemetria-local/008: linhas `oferta`, `oferta_trocada`, `bencao`, `porta` e `morte`
## (com `causa` preenchida ou `null` sem `TL3`, e `recusou_morte` sem linha `morte` nem desconto no dano)
## (AC-TL-08, AC-TL-09, AC-TL-10).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _avisos: RelatorDeAvisosTelemetria
var _tel: TelemetriaLocal


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_avisos = RelatorDeAvisosTelemetria.new()
	_tel = TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "1B4E", true)
	_tel.iniciar_sessao()
	var lote_ini: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", "a".repeat(64), "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []})
	]
	_tel.consumir(lote_ini)


func test_oferta_aberta_oferta_trocada_e_bencao_tomada_ac_tl_08() -> void:
	# Arrange / Act
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(1, 1, &"combate", 80),
		EventosDeTelemetria.EvCamaraLimpa.new(1, &"combate", 80),
		EvOfertaAberta.new([&"corte_fantasma", &"traco_unico", &"fundo_do_poco"], [1, 2, 3], 2),
		EvOfertaTrocada.new([&"linha_contada", &"materia_residual", &"os_que_ficam"], [1, 1, 2], 1),
		EvBencaoTomada.new(&"os_que_ficam", 2, 1),
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_of := lido.linhas[3]
	assert_str(String(l_of["t"])).is_equal("oferta")
	assert_int(int(l_of["indice_camara"])).is_equal(1)
	assert_int(int(l_of["trocas"])).is_equal(2)
	var cartas_of: Array = l_of["cartas"]
	assert_int(cartas_of.size()).is_equal(3)
	assert_str(String((cartas_of[0] as Dictionary)["id"])).is_equal("corte_fantasma")
	assert_int(int((cartas_of[0] as Dictionary)["raridade"])).is_equal(1)

	var l_ot := lido.linhas[4]
	assert_str(String(l_ot["t"])).is_equal("oferta_trocada")
	assert_int(int(l_ot["trocas"])).is_equal(1)
	assert_int((l_ot["cartas"] as Array).size()).is_equal(3)

	var l_bn := lido.linhas[5]
	assert_str(String(l_bn["t"])).is_equal("bencao")
	assert_str(String(l_bn["id"])).is_equal("os_que_ficam")
	assert_int(int(l_bn["raridade"])).is_equal(2)
	assert_int(int(l_bn["trocas_restantes"])).is_equal(1)


func test_porta_escolhida_grava_indice_tipo_e_opcoes_ac_tl_09() -> void:
	# Arrange / Act
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPortaEscolhida.new(1, &"fragmentos", [&"bencao", &"fragmentos", &"cura"])
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_pt := lido.linhas[2]
	assert_str(String(l_pt["t"])).is_equal("porta")
	assert_int(int(l_pt["indice_camara"])).is_equal(1)
	assert_str(String(l_pt["tipo"])).is_equal("fragmentos")
	assert_array(l_pt["opcoes"] as Array).is_equal(["bencao", "fragmentos", "cura"])


func test_morte_com_e_sem_causa_sem_tl3_e_recusou_morte_nao_grava_morte_nem_desconta_recuperacao_ac_tl_10() -> void:
	# Arrange / Act 1: golpe de 50 causa recusa de morte (recupera para 40), seguido de golpe de 15 e câmara limpa
	var lote_recusa: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 80, 50),
		EventosDeTelemetria.EvJogadorAtingido.new(50, 0, 0, true),
		EventosDeTelemetria.EvRecusouMorte.new(40, 40),
		EventosDeTelemetria.EvJogadorAtingido.new(15, 0, 25),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 25),
	]
	_tel.consumir(lote_recusa)

	# Act 2: na câmara 1 morre com causa fornecida; depois outra morte sem causa fornecida
	var lote_morte_com_causa: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(1, 1, &"combate", 80, 25),
		EventosDeTelemetria.EvJogadorMorreu.new(1, 80, &"espreitador_da_fenda", &"salto_perfurante"),
	]
	_tel.consumir(lote_morte_com_causa)

	var lote_morte_sem_causa: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvJogadorMorreu.new(2, 80),
	]
	_tel.consumir(lote_morte_sem_causa)

	# Assert
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL3)).is_equal(0)
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))

	# Câmara 0: nenhuma linha "morte" da recusa, e dano_recebido = 50 + 15 = 65 (sem descontar os 40 recuperados)
	var l_cam0 := lido.linhas[2]
	assert_str(String(l_cam0["t"])).is_equal("camara")
	assert_int(int(l_cam0["dano_recebido"])).is_equal(65)
	assert_int(int(l_cam0["vida_fim"])).is_equal(25)

	# Morte com causa (linha 4, após camara 1 fechada com morte na linha 3)
	var l_m1 := lido.linhas[4]
	assert_str(String(l_m1["t"])).is_equal("morte")
	assert_int(int(l_m1["indice"])).is_equal(1)
	assert_int(int(l_m1["vida_max"])).is_equal(80)
	var causa_1: Dictionary = l_m1["causa"]
	assert_str(String(causa_1["tipo_inimigo"])).is_equal("espreitador_da_fenda")
	assert_str(String(causa_1["ataque"])).is_equal("salto_perfurante")

	# Morte sem causa (linha 5): causa == null e 0 TL3
	var l_m2 := lido.linhas[5]
	assert_str(String(l_m2["t"])).is_equal("morte")
	assert_that(l_m2["causa"]).is_null()
