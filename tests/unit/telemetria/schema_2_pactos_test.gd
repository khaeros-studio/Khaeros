extends GdUnitTestSuite
## Story telemetria-local/009: Schema 2 — `run_iniciada` de Pactos com `dupla` e `pactos`,
## resumo de 12 campos em `run_encerrada` (`desfecho_chefe` e `dupla`),
## `encontro_pacto` (com `TL3` uma vez para resultado fora da lista),
## `pacto` (`primeiro` com `run = 0` antes de `run_iniciada`, ou descartado em Armada; `encontro` e `chefe` antes de `run_encerrada`),
## `vinculo_fim_run` após `run_encerrada` com o mesmo `run`, e ausência das linhas novas em Lâmina/Ressonância
## (AC-TL-34, AC-TL-35, AC-TL-36, AC-TL-37, AC-TL-38, AC-TL-39).

var _armazem: ArmazemEmMemoria
var _relogio: RelogioDeSessaoFalso
var _avisos: RelatorDeAvisosTelemetria
var _tel: TelemetriaLocal

const IMP_64 := "a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90"


func before_test() -> void:
	_armazem = ArmazemEmMemoria.new()
	_relogio = RelogioDeSessaoFalso.new("2026-11-18T12:00:00Z", "windows")
	_avisos = RelatorDeAvisosTelemetria.new()
	_tel = TelemetriaLocal.new(_armazem, _relogio, null, _avisos, "0.1.0", "A1B2", true)
	_tel.iniciar_sessao()


func _resumo_12(motivo: String, desfecho_chefe: String, dupla: Array) -> Dictionary:
	return {
		"motivo": motivo,
		"seed": "3F9A-07C2 · v0.1.0 · cA1B2",
		"arma": "pactos",
		"camaras_limpas": 7 if motivo == "vitoria" else 3,
		"bencoes_tomadas": ["os_que_ficam"],
		"fragmentos_coletados": 10,
		"bonus_vitoria": 15 if motivo == "vitoria" else 0,
		"total_fragmentos": 25 if motivo == "vitoria" else 10,
		"abates": 30,
		"duracao_s": 120.0,
		"desfecho_chefe": desfecho_chefe,
		"dupla": dupla,
	}


func test_run_iniciada_pactos_traz_dupla_e_pactos_e_lamina_traz_dupla_vazia_e_pactos_null_schema_2_ac_tl_34() -> void:
	# Arrange / Act: Run 1 de Pactos e Run 2 de Lâmina
	var estado_pactos := {
		"arma": "pactos",
		"doutrina": "pactos",
		"oficina": [],
		"dupla": ["vulto_mudo", "espreitador_da_fenda"],
		"pactos": {
			"especies": [{"id": "vulto_mudo", "nivel": 2}, {"id": "espreitador_da_fenda", "nivel": 1}],
			"encontro_pendente": [],
			"primeiro_encontro_visto": true,
			"runs_pactos_sem_encontro": 1,
		},
	}
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", estado_pactos),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_12("vitoria", "pactuado", ["vulto_mudo", "espreitador_da_fenda"])),
		EventosDeTelemetria.EvRunIniciada.new("1111-2222", IMP_64, "limiar", {"arma": "lamina", "doutrina": "lamina", "oficina": []}),
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	assert_int(int(lido.linhas[0]["schema"])).is_equal(2)

	var est_1: Dictionary = lido.linhas[1]["estado_inicial"]
	assert_array(est_1["dupla"] as Array).is_equal(["vulto_mudo", "espreitador_da_fenda"])
	var pac_1: Dictionary = est_1["pactos"]
	assert_bool(bool(pac_1["primeiro_encontro_visto"])).is_true()
	assert_int(int(pac_1["runs_pactos_sem_encontro"])).is_equal(1)
	var esp_1: Array = pac_1["especies"]
	assert_int(esp_1.size()).is_equal(2)
	assert_str(String((esp_1[0] as Dictionary)["id"])).is_equal("vulto_mudo")
	assert_int(int((esp_1[0] as Dictionary)["nivel"])).is_equal(2)

	var est_2: Dictionary = lido.linhas[3]["estado_inicial"]
	assert_array(est_2["dupla"] as Array).is_empty()
	assert_that(est_2["pactos"]).is_null()


func test_resumo_de_12_campos_em_vitoria_com_desfecho_pactuado_e_morte_com_nenhum_ac_tl_35() -> void:
	# Arrange / Act
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": [], "dupla": ["vulto_mudo", ""]}),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_12("vitoria", "pactuado", ["vulto_mudo", ""])),
		EventosDeTelemetria.EvRunIniciada.new("2222-3333", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": [], "dupla": ["vulto_mudo", ""]}),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_12("morte", "nenhum", ["vulto_mudo", ""])),
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var fim_vitoria := lido.linhas[2]
	for campo: String in LinhasDeRun.CAMPOS_RESUMO_12:
		assert_bool(fim_vitoria.has(campo)).is_true()
	assert_str(String(fim_vitoria["desfecho_chefe"])).is_equal("pactuado")

	var fim_morte := lido.linhas[4]
	assert_str(String(fim_morte["desfecho_chefe"])).is_equal("nenhum")


func test_encontro_pacto_grava_4_campos_e_resultado_fora_da_lista_conta_tl3_uma_vez_ac_tl_36() -> void:
	# Arrange / Act
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": []}),
		EventosDeTelemetria.EvEncontroPacto.new(1, &"espreitador_da_fenda", &"pactuada", 37),
		EventosDeTelemetria.EvEncontroPacto.new(2, &"baluarte_de_cinza", &"resultado_invalido", 10),
		EventosDeTelemetria.EvEncontroPacto.new(2, &"baluarte_de_cinza", &"outro_invalido", 5),
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	var l_enc := lido.linhas[2]
	assert_str(String(l_enc["t"])).is_equal("encontro_pacto")
	assert_int(int(l_enc["indice_camara"])).is_equal(1)
	assert_str(String(l_enc["especie"])).is_equal("espreitador_da_fenda")
	assert_str(String(l_enc["resultado"])).is_equal("pactuada")
	assert_int(int(l_enc["vida_restante"])).is_equal(37)

	var l_inv := lido.linhas[3]
	assert_str(String(l_inv["resultado"])).is_equal("resultado_invalido")
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL3)).is_equal(1)


func test_pacto_primeiro_com_run_0_encontro_e_chefe_antes_de_run_encerrada_e_armada_descarta_primeiro_ac_tl_37() -> void:
	# Arrange / Act 1: sessão aberta -> pacto(primeiro, run=0) antes de run_iniciada, depois pacto(encontro) e pacto(chefe) antes de run_encerrada
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPactoRegistrado.new(&"vulto_mudo", &"primeiro"),
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": []}),
		EventosDeTelemetria.EvPactoRegistrado.new(&"espreitador_da_fenda", &"encontro"),
		EventosDeTelemetria.EvPactoRegistrado.new(&"soberano_do_limiar", &"chefe"),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_12("vitoria", "pactuado", ["vulto_mudo", ""])),
	]
	_tel.consumir(lote)

	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	assert_str(String(lido.linhas[1]["t"])).is_equal("pacto")
	assert_str(String(lido.linhas[1]["origem"])).is_equal("primeiro")
	assert_int(int(lido.linhas[1]["run"])).is_equal(0)

	assert_str(String(lido.linhas[2]["t"])).is_equal("run_iniciada")
	assert_int(int(lido.linhas[2]["run"])).is_equal(1)

	assert_str(String(lido.linhas[3]["t"])).is_equal("pacto")
	assert_str(String(lido.linhas[3]["origem"])).is_equal("encontro")
	assert_int(int(lido.linhas[3]["run"])).is_equal(1)

	assert_str(String(lido.linhas[4]["t"])).is_equal("pacto")
	assert_str(String(lido.linhas[4]["origem"])).is_equal("chefe")
	assert_int(int(lido.linhas[4]["run"])).is_equal(1)

	assert_str(String(lido.linhas[5]["t"])).is_equal("run_encerrada")

	# Act 2: com a Telemetria Armada (desligou e religou), pacto(primeiro) antes de run_iniciada não é gravado e nada falha
	_tel.definir_ligada(false)
	_tel.definir_ligada(true)
	assert_int(_tel.estado()).is_equal(TelemetriaLocal.Estado.ARMADA)

	_relogio.data_utc = "2026-11-18T12:10:00Z"
	var lote_armada: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvPactoRegistrado.new(&"vulto_mudo", &"primeiro"),
		EventosDeTelemetria.EvRunIniciada.new("4444-5555", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": []}),
	]
	_tel.consumir(lote_armada)
	var lido_2 := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	assert_int(lido_2.linhas.size()).is_equal(2) # sessao_iniciada + run_iniciada (sem o pacto primeiro)
	assert_str(String(lido_2.linhas[0]["t"])).is_equal("sessao_iniciada")
	assert_str(String(lido_2.linhas[1]["t"])).is_equal("run_iniciada")
	assert_int(_avisos.contagem(RelatorDeAvisosTelemetria.TL3)).is_equal(0)


func test_vinculo_fim_run_sai_depois_de_run_encerrada_com_mesmo_run_e_antes_de_nova_run_ac_tl_38() -> void:
	# Arrange / Act: fim da run 1 + vinculo_fim_run + início da run 2 no mesmo passo
	var especies_vinc: Array[Dictionary] = [
		{"id": "vulto_mudo", "pontos_run": 31, "vinculo_pontos": 50, "nivel": 3, "subiu_nivel": true},
		{"id": "espreitador_da_fenda", "pontos_run": 18, "vinculo_pontos": 18, "nivel": 1, "subiu_nivel": false},
	]
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": []}),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_12("vitoria", "pactuado", ["vulto_mudo", "espreitador_da_fenda"])),
		EventosDeTelemetria.EvVinculoAtualizado.new(especies_vinc),
		EventosDeTelemetria.EvRunIniciada.new("7777-8888", IMP_64, "limiar", {"arma": "pactos", "doutrina": "pactos", "oficina": []}),
	]
	_tel.consumir(lote)

	# Assert: ordem run_encerrada(run=1) -> vinculo_fim_run(run=1) -> run_iniciada(run=2)
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	assert_str(String(lido.linhas[2]["t"])).is_equal("run_encerrada")
	assert_int(int(lido.linhas[2]["run"])).is_equal(1)

	var l_vf := lido.linhas[3]
	assert_str(String(l_vf["t"])).is_equal("vinculo_fim_run")
	assert_int(int(l_vf["run"])).is_equal(1)
	var esps: Array = l_vf["especies"]
	assert_int(esps.size()).is_equal(2)
	var e0: Dictionary = esps[0]
	assert_str(String(e0["id"])).is_equal("vulto_mudo")
	assert_int(int(e0["pontos_run"])).is_equal(31)
	assert_int(int(e0["vinculo_pontos"])).is_equal(50)
	assert_int(int(e0["nivel"])).is_equal(3)
	assert_bool(bool(e0["subiu_nivel"])).is_true()

	assert_str(String(lido.linhas[4]["t"])).is_equal("run_iniciada")
	assert_int(int(lido.linhas[4]["run"])).is_equal(2)


func test_run_de_ressonancia_nao_grava_encontro_pacto_pacto_nem_vinculo_fim_run_ac_tl_39() -> void:
	# Arrange / Act: run de Ressonância
	var lote: Array[EventoDoPasso] = [
		EventosDeTelemetria.EvRunIniciada.new("3F9A-07C2", IMP_64, "limiar", {"arma": "ressonancia", "doutrina": "ressonancia", "oficina": []}),
		EventosDeTelemetria.EvEncontroPacto.new(1, &"vulto_mudo", &"pactuada", 40),
		EventosDeTelemetria.EvPactoRegistrado.new(&"vulto_mudo", &"encontro"),
		EventosDeTelemetria.EvRunEncerrada.new(_resumo_12("vitoria", "abatido", [])),
		EventosDeTelemetria.EvVinculoAtualizado.new([]),
	]
	_tel.consumir(lote)

	# Assert
	var lido := LeitorDeTesteTelemetria.ler_jsonl(_armazem.texto_de(_tel.caminho_arquivo_atual()))
	for l: Dictionary in lido.linhas:
		var t := String(l["t"])
		assert_bool(t == "encontro_pacto" or t == "pacto" or t == "vinculo_fim_run").is_false()
