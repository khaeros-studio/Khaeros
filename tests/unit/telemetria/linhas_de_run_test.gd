extends GdUnitTestSuite
## Story telemetria-local/006: linhas de run (`run_iniciada`, `run_encerrada` com os 10 campos do resumo
## da Run R7, `caminho` e `fragmentos_por_origem`), abandono na câmara 2, nova run no mesmo passo
## (`run` 1 -> 2) e `ms_inicio` da 1ª câmara (AC-TL-04, AC-TL-11, AC-TL-12, AC-TL-13, AC-TL-33).

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


func _resumo_base(motivo: String, limpas: int = 6, coletados: int = 7, bonus: int = 15) -> Dictionary:
	return {
		"motivo": motivo,
		"seed": "3F9A-07C2 · v0.1.0 · c0123",
		"arma": "lamina",
		"camaras_limpas": limpas,
		"bencoes_tomadas": ["corte_fantasma", "traco_unico"],
		"fragmentos_coletados": coletados,
		"bonus_vitoria": bonus,
		"total_fragmentos": coletados + bonus,
		"abates": 24,
		"duracao_s": 95.40,
	}


func test_run_iniciada_grava_seed_impressao_64_regiao_estado_inicial_e_ms_inicio_da_1a_camara_ac_tl_04_e_33() -> void:
	# Arrange / Act: clique em "Jogar" em ms = 500 cria a run; 1ª câmara abre em ms = 1 250 (750 ms depois)
	_relogio.ms_atual = 500
	var lote_ini: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new(
			"3F9A-07C2", IMP_64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}
		)
	]
	_tel.consumir(lote_ini)

	_relogio.ms_atual = 1250
	var lote_cam0: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvCamaraEntrou.new(0, 0, &"combate", 100),
		EventosDeTelemetria.EvCamaraLimpa.new(0, &"combate", 100),
	]
	_tel.consumir(lote_cam0)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_run := lido.linhas[1]
	assert_str(String(l_run["t"])).is_equal("run_iniciada")
	assert_int(int(l_run["run"])).is_equal(1)
	assert_str(String(l_run["seed"])).is_equal("3F9A-07C2")
	assert_str(String(l_run["impressao"])).is_equal(IMP_64)
	assert_int(String(l_run["impressao"]).length()).is_equal(64)
	assert_str(String(l_run["regiao"])).is_equal("limiar")
	var est: Dictionary = l_run["estado_inicial"]
	assert_str(String(est["arma"])).is_equal("lamina")
	assert_str(String(est["doutrina"])).is_equal("lamina")
	assert_array(est["oficina"] as Array).is_empty()

	# AC-TL-33: ms_inicio da 1ª câmara - ms(run_iniciada) = 1250 - 500 = 750 ms (<= 3000 ms)
	var l_cam := lido.linhas[2]
	assert_str(String(l_cam["t"])).is_equal("camara")
	assert_int(int(l_cam["ms_inicio"])).is_equal(1250)
	assert_int(int(l_cam["ms_inicio"]) - int(l_run["ms"])).is_equal(750)


func test_run_encerrada_vitoria_morte_e_abandono_com_10_campos_caminho_e_fragmentos_por_origem_ac_tl_11() -> void:
	# Arrange / Act: Run 1 (vitória) com créditos de porta e vitória e gasto (ignorado em fragmentos_por_origem)
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}),
		EventosDeTelemetria.EvPortaEscolhida.new(0, &"bencao", [&"bencao", &"fragmentos"]),
		EvBencaoTomada.new(&"corte_fantasma", 1, 1),
		EvSaldoMudou.new(2, 2, &"porta"),
		EvSaldoMudou.new(5, 3, &"porta"),
		EvSaldoMudou.new(3, -2, &"gasto_oficina"), # negativo: não entra na soma de origens positivas
		EvSaldoMudou.new(18, 15, &"vitoria"),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_base("vitoria", 6, 5, 15)),
	]
	_tel.consumir(lote)

	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_fim := lido.linhas[lido.linhas.size() - 1]
	assert_str(String(l_fim["t"])).is_equal("run_encerrada")
	for campo: String in LinhasDeRun.CAMPOS_RESUMO_10:
		assert_bool(l_fim.has(campo)).is_true()
		assert_that(l_fim[campo]).is_not_null()

	var f_orig: Dictionary = l_fim["fragmentos_por_origem"]
	assert_int(int(f_orig.get("porta", 0))).is_equal(5)
	assert_int(int(f_orig.get("vitoria", 0))).is_equal(15)
	assert_bool(f_orig.has("gasto_oficina")).is_false()

	var cam_arr: Array = l_fim["caminho"]
	assert_int(cam_arr.size()).is_equal(2)
	assert_str(String((cam_arr[0] as Dictionary)["tipo"])).is_equal("porta")
	assert_str(String((cam_arr[1] as Dictionary)["tipo"])).is_equal("bencao")


func test_abandono_na_camara_2_fecha_camara_com_abandono_antes_de_run_encerrada_e_nova_run_incrementa_run_ac_tl_12_e_13() -> void:
	# Arrange: Run 1 entra na câmara 2 e é abandonada; Run 2 começa no mesmo passo
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("1111-1111", IMP_64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}),
		EventosDeTelemetria.EvCamaraEntrou.new(2, 2, &"combate", 100),
		EvPassoVivo.new(120),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_base("abandono", 2, 2, 0)),
		EventosDeTelemetria.EvRunIniciada.new("2222-2222", IMP_64, "limiar", {"arma": "ressonancia", "doutrina": "ressonancia", "oficina": []}),
	]

	# Act
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	# Linhas: 0=sessao_iniciada, 1=run_iniciada(1), 2=camara(abandono, run=1), 3=run_encerrada(abandono, run=1), 4=run_iniciada(2)
	assert_int(lido.linhas.size()).is_equal(5)
	var l_cam := lido.linhas[2]
	assert_str(String(l_cam["t"])).is_equal("camara")
	assert_int(int(l_cam["indice"])).is_equal(2)
	assert_str(String(l_cam["resultado"])).is_equal("abandono")
	assert_int(int(l_cam["run"])).is_equal(1)

	var l_fim := lido.linhas[3]
	assert_str(String(l_fim["t"])).is_equal("run_encerrada")
	assert_str(String(l_fim["motivo"])).is_equal("abandono")
	assert_int(int(l_fim["run"])).is_equal(1)

	var l_nova := lido.linhas[4]
	assert_str(String(l_nova["t"])).is_equal("run_iniciada")
	assert_int(int(l_nova["run"])).is_equal(2)
	assert_float(_tel.taxa_reinicio_sessao()).is_equal_approx(1.0, 1e-6)
