extends GdUnitTestSuite
## Story telemetria-local/007: linha `camara` — contadores de dano (ignorando escudo) e abates,
## duração em passos vivos de Jogo (incluindo hitstop e excluindo pausa e Bênção),
## santuário (dano 0, abates 0) e precedência de morte sobre `camara_limpa` no mesmo passo
## (AC-TL-05, AC-TL-06, AC-TL-07, AC-TL-29).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _tel: TelemetriaLocal


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_tel = TelemetriaLocal.new(_armazem, _relogio, null, null, "0.1.0", "1B4E", true)
	_tel.iniciar_sessao()
	var lote_ini: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", "a".repeat(64), "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []})
	]
	_tel.consumir(lote_ini)


func test_camara_soma_vida_perdida_ignora_escudo_e_conta_abates_ac_tl_05() -> void:
	# Arrange: câmara com Vida perdida 8 e 12, um golpe de 6 todo absorvido pelo escudo (vida_perdida = 0) e 3 inimigo_morreu
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 80, 80),
		EventosDeTelemetria.EvJogadorAtingido.new(8, 0, 72),
		EventosDeTelemetria.EvJogadorAtingido.new(0, 6, 72), # 6 absorvido pelo escudo
		EventosDeTelemetria.EvJogadorAtingido.new(12, 2, 60),
		EventosDeTelemetria.EvInimigoMorreu.new(1),
		EventosDeTelemetria.EvInimigoMorreu.new(2),
		EventosDeTelemetria.EvInimigoMorreu.new(3),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 60),
	]

	# Act
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_cam := lido.linhas[2]
	assert_str(String(l_cam["t"])).is_equal("camara")
	assert_int(int(l_cam["dano_recebido"])).is_equal(20)
	assert_int(int(l_cam["abates"])).is_equal(3)
	assert_int(int(l_cam["vida_max"])).is_equal(80)
	assert_int(int(l_cam["vida_fim"])).is_equal(60)
	assert_str(String(l_cam["resultado"])).is_equal("limpa")


func test_duracao_1044_passos_vivos_em_jogo_com_30_hitstop_600_pausa_e_120_bencao_da_17_40_s_ac_tl_06() -> void:
	# Arrange: entra na câmara
	var lote_entrada: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(1, 1, &"combate", 80)
	]
	_tel.consumir(lote_entrada)

	# Act: 1014 passos vivos normais + 30 passos de hitstop (em JOGO o orquestrador emite EvPassoVivo) = 1044 passos em JOGO;
	# 600 passos em PAUSA e 120 em BENCAO não emitem EvPassoVivo (mas o relógio ms avança).
	var lote_jogo: Array[EventoDoPasso] = []
	for i in 1044:
		lote_jogo.append(EvPassoVivo.new(i))
	_tel.consumir(lote_jogo)

	# Simula 600 passos de pausa + 120 de Bênção (entregas vazias de EvPassoVivo, com avanço de ms)
	_relogio.avancar_ms((600 + 120) * 16)
	var vazio: Array[EventoDoPasso] = []
	_tel.consumir(vazio)

	var lote_fim: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraLimpa.new(1, &"combate", 80)
	]
	_tel.consumir(lote_fim)

	# Assert: 1044 / 60 = 17.40 s
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_cam := lido.linhas[2]
	assert_float(float(l_cam["duracao_s"])).is_equal_approx(17.40, 1e-4)


func test_santuario_grava_tipo_santuario_dano_zero_e_abates_zero_ac_tl_07() -> void:
	# Arrange / Act
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(3, 2, &"santuario", 80),
		EvPassoVivo.new(1),
		EventosDeTelemetria.EvCamaraLimpa.new(2, &"santuario", 80),
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_cam := lido.linhas[2]
	assert_str(String(l_cam["tipo"])).is_equal("santuario")
	assert_int(int(l_cam["dano_recebido"])).is_equal(0)
	assert_int(int(l_cam["abates"])).is_equal(0)
	assert_str(String(l_cam["resultado"])).is_equal("limpa")


func test_jogador_morreu_e_camara_limpa_no_mesmo_passo_gera_uma_so_camara_com_morte_ac_tl_29() -> void:
	# Arrange: câmara aberta; no mesmo passo chegam camara_limpa e jogador_morreu
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(2, 2, &"combate", 80, 15),
		EventosDeTelemetria.EvJogadorAtingido.new(15, 0, 0),
		EventosDeTelemetria.EvCamaraLimpa.new(2, &"combate", 0),
		EventosDeTelemetria.EvJogadorMorreu.new(2, 80, &"eco_perdido", &"investida"),
	]

	# Act
	_tel.consumir(lote)

	# Assert: apenas UMA linha "camara", e com resultado = "morte"
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var camaras: Array[Dictionary] = []
	for l: Dictionary in lido.linhas:
		if String(l["t"]) == "camara":
			camaras.append(l)
	assert_int(camaras.size()).is_equal(1)
	assert_str(String(camaras[0]["resultado"])).is_equal("morte")
	assert_int(int(camaras[0]["vida_fim"])).is_equal(0)
