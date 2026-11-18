class_name SomDefAudioTuningEPedidosTest
extends GdUnitTestSuite
## Testes unitários de `SomDef`, `AudioTuning`, `PedidoDeSom` e `FilaDeSonsDeInterface` (story-001).


func test_som_def_round_robin_e_validacao_de_faixas() -> void:
	var som: SomDef = SomDef.new()
	som.id = &"sfx_golpe_leve"
	som.caminho_stream = "res://assets/audio/sfx/golpe_1.wav"
	som.variacoes = [
		"res://assets/audio/sfx/golpe_2.wav",
		"res://assets/audio/sfx/golpe_3.wav"
	]
	assert_that(som.validar_faixas().is_empty()).is_true()
	assert_that(som.resolver_caminho_stream(0)).is_equal("res://assets/audio/sfx/golpe_1.wav")
	assert_that(som.resolver_caminho_stream(1)).is_equal("res://assets/audio/sfx/golpe_2.wav")
	assert_that(som.resolver_caminho_stream(2)).is_equal("res://assets/audio/sfx/golpe_3.wav")
	assert_that(som.resolver_caminho_stream(3)).is_equal("res://assets/audio/sfx/golpe_1.wav")

	som.pitch_min = 0.0
	assert_that(som.validar_faixas()).contains([&"AU_PITCH_MIN_FORA_DA_FAIXA"])


func test_audio_tuning_padroes_e_validacao() -> void:
	var tuning: AudioTuning = AudioTuning.new()
	assert_that(tuning.vozes_max_gancho).is_equal(4)
	assert_that(tuning.vozes_max_total).is_equal(16)
	assert_that(tuning.vozes_interface).is_equal(4)
	assert_that(tuning.teto_tons_telegrafo).is_equal(3)
	assert_that(tuning.validar_faixas().is_empty()).is_true()

	tuning.tom_pitch_max = 0.5
	tuning.tom_pitch_min = 1.2
	assert_that(tuning.validar_faixas()).contains([&"AU6_TOM_PITCH_MAX_INVALIDO"])


func test_fila_de_sons_de_interface_drena_em_ordem_sem_alocar_no_passo() -> void:
	var fila: FilaDeSonsDeInterface = FilaDeSonsDeInterface.new(8)
	assert_that(fila.pedir(&"ui_foco", 2)).is_true()
	assert_that(fila.pedir(&"ui_confirmar", 1)).is_true()
	assert_that(fila.quantidade_pendente()).is_equal(2)

	var drenados: Array[PedidoDeSom] = []
	var n: int = fila.drenar_para(drenados)
	assert_that(n).is_equal(2)
	assert_that(fila.quantidade_pendente()).is_equal(0)
	assert_that(drenados[0].gancho).is_equal(&"ui_foco")
	assert_that(drenados[1].gancho).is_equal(&"ui_confirmar")
