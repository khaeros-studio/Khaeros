class_name FluxoEsquivaFragmentosFiosChefeTest
extends GdUnitTestSuite
## Testes unitários de Fluxo, Esquiva, Fragmentos, Fios de Inimigos, Porta e Barra de Chefe (`story-003` e `story-004`).


func test_estados_de_fluxo_tremor_esquiva_e_agregacao_de_fragmentos() -> void:
	var rec: ModeloRecursosEMundo = ModeloRecursosEMundo.new(HudTuning.new())
	rec.sincronizar_recursos(
		{"atual": 45.0, "max": 100.0, "custo": 40.0, "recarga_s": 0.0},
		{"cargas": 2, "max": 2, "progresso": 0.0},
		100
	)
	assert_that(rec.estado_fluxo()).is_equal(ModeloRecursosEMundo.ESTADO_FLUXO_PRONTO)
	assert_that(rec.fracao_marca_fluxo()).is_equal_approx(0.40, 0.001)
	assert_that(rec.ganho_agregado_formatado()).is_equal("")

	# Coleta +25 e depois +15 dentro da janela de 1.5s -> agrega "+40"
	rec.sincronizar_recursos(
		{"atual": 20.0, "max": 100.0, "custo": 40.0, "recarga_s": 0.0},
		{"cargas": 0, "max": 2, "progresso": 0.5},
		125
	)
	assert_that(rec.estado_fluxo()).is_equal(ModeloRecursosEMundo.ESTADO_FLUXO_SEM_FLUXO)
	rec.sincronizar_recursos(
		{"atual": 20.0, "max": 100.0, "custo": 40.0, "recarga_s": 0.0},
		{"cargas": 0, "max": 2, "progresso": 0.5},
		140
	)
	assert_that(rec.ganho_agregado_formatado()).is_equal("+40")

	rec.notificar_esquiva_sem_carga()
	assert_that(rec.tremor_esquiva_ativo()).is_true()
	rec.avancar(0.10)
	assert_that(rec.tremor_esquiva_ativo()).is_false()


func test_pool_de_9_fios_ignora_chefe_porta_111px_e_barra_chefe_divisor_50() -> void:
	var rec: ModeloRecursosEMundo = ModeloRecursosEMundo.new(HudTuning.new())
	var inimigos: Array[Dictionary] = []
	for i: int in range(12):
		inimigos.append({
			"id": i + 1,
			"vida_atual": 40,
			"vida_max": 100,
			"pos": Vector2(float(i * 20), 0.0),
			"eh_chefe": false
		})
	# Chefe na lista de inimigos feridos nunca entra nos fios comuns
	inimigos.append({
		"id": 999,
		"vida_atual": 400,
		"vida_max": 1000,
		"pos": Vector2(5.0, 0.0),
		"eh_chefe": true
	})

	rec.sincronizar_mundo(
		inimigos,
		{"destrancada": true, "distancia_px": 110.0, "chave_prompt": &"HUD_INTERAGIR_PORTA"},
		{"ativo": true, "vida_atual": 450, "vida_max": 1000, "chave_nome": &"HUD_CHEFE_SOBERANO"},
		Vector2.ZERO
	)
	assert_that(rec.fios_inimigos_ativos().size()).is_equal(9)
	assert_that(int(rec.fios_inimigos_ativos()[0]["id"])).is_equal(1)
	assert_that(rec.porta_interagivel_visivel()).is_true()
	assert_that(rec.chefe_visivel()).is_true()
	assert_that(rec.fracao_divisor_fase_2_chefe()).is_equal_approx(0.50, 0.001)
	assert_that(rec.fase_chefe()).is_equal(2)
