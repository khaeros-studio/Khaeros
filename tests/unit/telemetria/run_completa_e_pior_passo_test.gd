extends GdUnitTestSuite
## Story telemetria-local/010: leitura de fixture de 3 runs com cálculo de `dano_rel` (F2) e Restart Rate,
## run completa de 6 câmaras no Limiar (21 linhas de run na ordem da F3, AC-TL-28),
## run vencedora de Pactos de 7 câmaras no Limiar (28 linhas da F3-P < 12 KB, AC-TL-40)
## e pior passo com 5 linhas dentro do orçamento de 3 ms (`pior_passo_us <= 3000`, TR-telemetria-012).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _avisos: RelatorDeAvisosTelemetria
var _tel: TelemetriaLocal

const IMP_64 := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_avisos = RelatorDeAvisosTelemetria.new()
	_tel = TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "0123", true)
	_tel.iniciar_sessao()


func test_fixture_sessao_3_runs_calcula_dano_rel_por_camara_e_restart_rate_sem_o_jogo_ac_tl_27() -> void:
	# Arrange: gera uma sessão de 3 runs (1 vitória, 1 morte, 1 abandono) com câmaras de dano 20/80 (=0.25) e 28/80 (=0.35)
	for r in 3:
		var motivo := "vitoria" if r == 0 else ("morte" if r == 1 else "abandono")
		var dano := 20 if r != 1 else 28
		var lote: Array[EventoDoPasso] = [
			EventosDeTelemetria.EvRunIniciada.new("3F9A-07C%d" % r, IMP_64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}),
			EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 80, 80),
			EventosDeTelemetria.EvJogadorAtingido.new(dano, 0, 80 - dano),
			EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 80 - dano),
			EventosDeTelemetria.EvRunEncerrada.new({
				"motivo": motivo,
				"seed": "3F9A-07C%d · v0.1.0 · c0123" % r,
				"arma": "lamina",
				"camaras_limpas": 1,
				"bencoes_tomadas": [],
				"fragmentos_coletados": 0,
				"bonus_vitoria": 15 if motivo == "vitoria" else 0,
				"total_fragmentos": 15 if motivo == "vitoria" else 0,
				"abates": 3,
				"duracao_s": 15.0,
			}),
		]
		_tel.consumir(lote)
	_tel.encerrar_sessao()

	# Act: lê o arquivo apenas com o LeitorDeTesteTelemetria (sem o jogo)
	var texto_fixture := _armazem.texto_de(_tel.caminho_arquivo_atual())
	var lido := LeitorDeTesteTelemetria.ler_jsonl(texto_fixture)
	var danos_rel := LeitorDeTesteTelemetria.calcular_dano_rel_por_camara(lido.linhas)
	var restart_rate := TelemetriaLocal.calcular_restart_rate(lido.linhas)

	# Assert
	assert_int(danos_rel.size()).is_equal(3)
	assert_float(danos_rel[0]).is_equal_approx(0.25, 1e-6)
	assert_float(danos_rel[1]).is_equal_approx(0.35, 1e-6)
	assert_float(danos_rel[2]).is_equal_approx(0.25, 1e-6)
	assert_float(restart_rate).is_equal_approx(1.0 / 3.0, 1e-6)
	assert_float(_tel.taxa_reinicio_sessao()).is_equal_approx(1.0 / 3.0, 1e-6)


func test_run_completa_6_camaras_no_limiar_gera_21_linhas_na_ordem_f3_ac_tl_28() -> void:
	# Arrange / Act: F3 — 1 run_iniciada + 6 camara (0..5, santuário no 3) + 4 oferta (0, 1, 2, 4)
	# + 4 bencao (0, 1, 2, 4) + 5 porta (depois de 0, 1, 2, 3, 4) + 1 run_encerrada = 21 linhas de run.
	var tipos_camara: Array[StringName] = [&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate"]
	var indices_com_oferta: Array[int] = [0, 1, 2, 4]

	_tel.consumir([
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []})
	])

	for i in 6:
		var p_idx := mini(i, 4)
		_tel.consumir([
			EventosDeTelemetria.EvCamaraEntrou.new(i, p_idx, tipos_camara[i], 100),
			EvPassoVivo.new(i * 600),
			EventosDeTelemetria.EvCamaraLimpa.new(p_idx, tipos_camara[i], 100),
		])
		if indices_com_oferta.has(i):
			_tel.consumir([
				EvOfertaAberta.new([&"corte_fantasma", &"traco_unico", &"fundo_do_poco"], [1, 1, 2], 1),
				EvBencaoTomada.new(&"corte_fantasma", 1, 1),
			])
		if i < 5:
			_tel.consumir([
				EventosDeTelemetria.EvPortaEscolhida.new(i, &"bencao", [&"bencao", &"fragmentos"])
			])

	_tel.consumir([
		EventosDeTelemetria.EvRunEncerrada.new({
			"motivo": "vitoria",
			"seed": "3F9A-07C2 · v0.1.0 · c0123",
			"arma": "lamina",
			"camaras_limpas": 6,
			"bencoes_tomadas": ["corte_fantasma", "corte_fantasma", "corte_fantasma", "corte_fantasma"],
			"fragmentos_coletados": 0,
			"bonus_vitoria": 15,
			"total_fragmentos": 15,
			"abates": 18,
			"duracao_s": 90.0,
		})
	])

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	# 1 sessao_iniciada + 21 linhas da run = 22 linhas no total
	assert_int(lido.linhas.size()).is_equal(22)

	var contagem_por_tipo: Dictionary = {}
	for idx in range(1, lido.linhas.size()):
		var t := String(lido.linhas[idx]["t"])
		contagem_por_tipo[t] = int(contagem_por_tipo.get(t, 0)) + 1

	assert_int(int(contagem_por_tipo.get("run_iniciada", 0))).is_equal(1)
	assert_int(int(contagem_por_tipo.get("camara", 0))).is_equal(6)
	assert_int(int(contagem_por_tipo.get("oferta", 0))).is_equal(4)
	assert_int(int(contagem_por_tipo.get("bencao", 0))).is_equal(4)
	assert_int(int(contagem_por_tipo.get("porta", 0))).is_equal(5)
	assert_int(int(contagem_por_tipo.get("run_encerrada", 0))).is_equal(1)

	var l_fim := lido.linhas[21]
	assert_str(String(l_fim["t"])).is_equal("run_encerrada")
	for campo: String in LinhasDeRun.CAMPOS_RESUMO_10:
		assert_bool(l_fim.has(campo)).is_true()


func test_run_pactos_completa_7_camaras_f3_p_28_linhas_e_abaixo_de_12_kb_ac_tl_40() -> void:
	# Arrange / Act: F3-P — 1ª run de Pactos vencedora com 7 câmaras (0..6, chefe na 6) e 6 portas:
	# 1 pacto(primeiro, run=0) + 1 run_iniciada + 7 camara + 4 oferta + 4 bencao + 6 porta
	# + 1 encontro_pacto + 1 pacto(encontro) + 1 pacto(chefe) + 1 run_encerrada + 1 vinculo_fim_run = 28 linhas.
	var tipos_camara: Array[StringName] = [&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"]
	var indices_com_oferta: Array[int] = [0, 1, 2, 4]

	# 1. Primeiro pacto na escolha de arma (run = 0)
	_tel.consumir([EventosDeTelemetria.EvPactoRegistrado.new(&"vulto_mudo", &"primeiro")])

	# 2. run_iniciada de Pactos
	_tel.consumir([
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {
			"arma": "pactos",
			"doutrina": "pactos",
			"oficina": [],
			"dupla": ["vulto_mudo", ""],
			"pactos": {
				"especies": [{"id": "vulto_mudo", "nivel": 1}],
				"encontro_pendente": [],
				"primeiro_encontro_visto": false,
				"runs_pactos_sem_encontro": 0,
			},
		})
	])

	for i in 7:
		var p_idx := mini(i, 4)
		_tel.consumir([
			EventosDeTelemetria.EvCamaraEntrou.new(i, p_idx, tipos_camara[i], 90),
			EvPassoVivo.new(i * 600),
		])
		if i == 6:
			# Pactuar com o chefe antes de camara_limpa(4, chefe) e run_encerrada
			_tel.consumir([EventosDeTelemetria.EvPactoRegistrado.new(&"soberano_do_limiar", &"chefe")])
		_tel.consumir([
			EventosDeTelemetria.EvCamaraLimpa.new(p_idx, tipos_camara[i], 90),
		])
		if indices_com_oferta.has(i):
			_tel.consumir([
				EvOfertaAberta.new([&"os_que_ficam", &"traco_unico", &"fundo_do_poco"], [1, 1, 2], 1),
				EvBencaoTomada.new(&"os_que_ficam", 1, 1),
			])
		if i == 1:
			# Encontro de pacto na câmara 1 resolvido antes da porta abrir
			_tel.consumir([
				EventosDeTelemetria.EvEncontroPacto.new(1, &"espreitador_da_fenda", &"pactuada", 37),
				EventosDeTelemetria.EvPactoRegistrado.new(&"espreitador_da_fenda", &"encontro"),
			])
		if i < 6:
			var t_porta: StringName = &"chefe" if i == 5 else &"bencao"
			_tel.consumir([
				EventosDeTelemetria.EvPortaEscolhida.new(i, t_porta, [t_porta])
			])

	# Fim da run + consolidação do vínculo
	_tel.consumir([
		EventosDeTelemetria.EvRunEncerrada.new({
			"motivo": "vitoria",
			"seed": "3F9A-07C2 · v0.1.0 · c0123",
			"arma": "pactos",
			"camaras_limpas": 7,
			"bencoes_tomadas": ["os_que_ficam", "os_que_ficam", "os_que_ficam", "os_que_ficam"],
			"fragmentos_coletados": 6,
			"bonus_vitoria": 15,
			"total_fragmentos": 21,
			"abates": 28,
			"duracao_s": 115.0,
			"desfecho_chefe": "pactuado",
			"dupla": ["vulto_mudo", "espreitador_da_fenda"],
		}),
		EventosDeTelemetria.EvVinculoAtualizado.new([
			{"id": "vulto_mudo", "pontos_run": 30, "vinculo_pontos": 30, "nivel": 2, "subiu_nivel": true},
			{"id": "espreitador_da_fenda", "pontos_run": 24, "vinculo_pontos": 24, "nivel": 2, "subiu_nivel": true},
		]),
	])

	# Assert: 1 sessao_iniciada + 28 linhas de F3-P = 29 linhas, e tamanho do arquivo < 12 KB (12 288 B)
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	assert_int(lido.linhas.size()).is_equal(29)
	assert_int(_tel.bytes_escritos()).is_less(12288)
	assert_str(String(lido.linhas[27]["t"])).is_equal("run_encerrada")
	assert_str(String(lido.linhas[28]["t"])).is_equal("vinculo_fim_run")


func test_pior_passo_com_5_linhas_dentro_de_3_ms_tr_telemetria_012() -> void:
	# Arrange: F4-P — morte com encontro de pacto em aberto:
	# camara(morte) + encontro_pacto(abandonado) + morte + run_encerrada + vinculo_fim_run = 5 linhas no mesmo passo.
	# Simula 150 us por linha (~90-211 us medidos em E-P1) -> 5 linhas ~ 750 us <= 3 000 us (3 ms).
	_relogio.passo_auto_us = 100
	_tel.consumir([
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": []}),
		EventosDeTelemetria.EvCamaraEntrou.new(1, 1, &"combate", 90, 20),
	])
	_avisos.limpar()

	var lote_pior_passo: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvEncontroPacto.new(1, &"espreitador_da_fenda", &"abandonado", 30),
		EventosDeTelemetria.EvJogadorMorreu.new(1, 90, &"eco_perdido", &"golpe"),
		EventosDeTelemetria.EvRunEncerrada.new({
			"motivo": "morte",
			"seed": "3F9A-07C2 · v0.1.0 · c0123",
			"arma": "pactos",
			"camaras_limpas": 1,
			"bencoes_tomadas": [],
			"fragmentos_coletados": 0,
			"bonus_vitoria": 0,
			"total_fragmentos": 0,
			"abates": 3,
			"duracao_s": 18.0,
			"desfecho_chefe": "nenhum",
			"dupla": ["vulto_mudo", ""],
		}),
		EventosDeTelemetria.EvVinculoAtualizado.new([
			{"id": "vulto_mudo", "pontos_run": 5, "vinculo_pontos": 5, "nivel": 1, "subiu_nivel": false},
		]),
	]

	# Act
	var linhas_antes := _tel.numero_linha_atual()
	_tel.consumir(lote_pior_passo)
	var linhas_gravadas_no_passo := _tel.numero_linha_atual() - linhas_antes

	# Assert: gravou exatamente 5 linhas no mesmo passo e ficou dentro de 3 000 us (3 ms), com 0 avisos TL2
	assert_int(linhas_gravadas_no_passo).is_equal(5)
	assert_int(_tel.ultimo_passo_us()).is_less_equal(3000)
	assert_int(_tel.pior_passo_us()).is_less_equal(3000)
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL2)).is_equal(0)
