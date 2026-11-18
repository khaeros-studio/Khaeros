class_name FeedbackTuningECatalogoTest
extends GdUnitTestSuite
## Testes unitários de `FeedbackTuning`, `CatalogoDeRespostas` e validação `FB1–FB3` (story-001).


func test_catalogo_contem_eventos_r3_r10_e_13_eventos_de_maldicoes_r15() -> void:
	var tuning: FeedbackTuning = FeedbackTuning.new()
	var catalogo: CatalogoDeRespostas = CatalogoDeRespostas.new(tuning)
	assert_that(catalogo.validar(tuning).is_empty()).is_true()

	var eventos_maldicoes: Array[StringName] = [
		&"maldicao_atacou",
		&"maldicao_atingida",
		&"maldicao_exaurida",
		&"maldicao_regenerada",
		&"troca_feita",
		&"troca_indisponivel",
		&"chamado_disparado",
		&"chamado_pouso",
		&"tecnica_combinada",
		&"virote_marcou",
		&"virote_expirou",
		&"pacto_firmado",
		&"pacto_recusado",
		&"chefe_subjugado",
		&"chefe_exorcizado",
	]
	for id_ev: StringName in eventos_maldicoes:
		assert_that(catalogo.contem(id_ev)).is_true()


func test_validacao_fb1_fb3_detecta_faixas_e_histerese_invalidas() -> void:
	var tuning: FeedbackTuning = FeedbackTuning.new()
	var catalogo: CatalogoDeRespostas = CatalogoDeRespostas.new(tuning)

	tuning.janela_soma_s = 0.05
	tuning.sair_nivel_1 = 0.92
	tuning.entrar_nivel_1 = 0.85
	var erros: Array[StringName] = catalogo.validar(tuning)
	assert_that(erros).contains([&"FB1_JANELA_SOMA_FORA_DA_FAIXA", &"FB3_HISTERESE_DEGRADACAO_INVALIDA"])
