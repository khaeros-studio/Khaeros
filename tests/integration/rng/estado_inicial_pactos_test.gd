## Story RNG-005, AC-40: estado inicial ampliado em runs de Pactos (R7-P).
extends GdUnitTestSuite

const SEED_REF: int = 0x3F9A07C2
const VERSAO: String = "0.1.0"
const IMPRESSAO_CURTA: String = "1B4E"


func _impressao_completa() -> String:
	return "1b4e" + "a".repeat(60)


func _perfil() -> EstadoInicialDaRun.PerfilDeVinculo:
	var perfil := EstadoInicialDaRun.PerfilDeVinculo.new()
	perfil.especies_pactuadas = [&"vulto_mudo", &"espreitador_da_fenda"]
	perfil.niveis = [2, 1]
	perfil.encontro_pendente = true
	perfil.primeiro_encontro_visto = true
	perfil.runs_pactos_sem_encontro = 3
	return perfil


func _estado(doutrina: StringName) -> EstadoInicialDaRun:
	return EstadoInicialDaRun.new(SEED_REF, VERSAO, _impressao_completa(), IMPRESSAO_CURTA,
		&"besta_do_vinculo", doutrina, [&"vida"] as Array[StringName], [1] as Array[int])


func test_pactos_estado_inicial_traz_dupla_em_ordem_e_perfil() -> void:
	var estado: EstadoInicialDaRun = _estado(&"pactos")
	estado.definir_pactos(&"vulto_mudo", &"espreitador_da_fenda", _perfil())
	var sinks: Array[Dictionary] = [estado.para_inicio_de_run(),
		estado.para_relatorio_de_erro(EstadoInicialDaRun.CaminhoDaRun.new())]
	for dados: Dictionary in sinks:
		var inicial: Dictionary = dados["estado_inicial"]
		assert_str(inicial["arma"]).is_equal("besta_do_vinculo")
		assert_str(inicial["doutrina"]).is_equal("pactos")
		assert_array(inicial["dupla"]).is_equal(["vulto_mudo", "espreitador_da_fenda"])
		var perfil: Dictionary = inicial["perfil_vinculo"]
		assert_array(perfil["especies_pactuadas"]).is_equal([
			{"especie": "vulto_mudo", "nivel": 2}, {"especie": "espreitador_da_fenda", "nivel": 1}])
		assert_bool(perfil["encontro_pendente"]).is_true()
		assert_bool(perfil["primeiro_encontro_visto"]).is_true()
		assert_int(perfil["runs_pactos_sem_encontro"]).is_equal(3)


func test_ressonancia_dupla_vazia_sem_perfil_e_texto_da_seed_igual() -> void:
	var pactos: EstadoInicialDaRun = _estado(&"pactos")
	pactos.definir_pactos(&"vulto_mudo", &"espreitador_da_fenda", _perfil())
	var ressonancia: EstadoInicialDaRun = _estado(&"ressonancia")
	ressonancia.definir_pactos(&"vulto_mudo", &"espreitador_da_fenda", _perfil())
	var inicial: Dictionary = ressonancia.para_inicio_de_run()["estado_inicial"]
	assert_array(inicial["dupla"]).is_empty()
	assert_bool(inicial.has("perfil_vinculo")).is_false()
	assert_str(ressonancia.texto_da_seed()).is_equal(pactos.texto_da_seed())
	assert_str(pactos.texto_da_seed()).is_equal("3F9A-07C2 · v0.1.0 · c1B4E")
