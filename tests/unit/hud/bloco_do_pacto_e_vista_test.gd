class_name BlocoDoPactoEVistaTest
extends GdUnitTestSuite
## Testes unitários do `ModeloDoBlocoDoPacto`, `OpcoesDoHud` e `VistaDoHud` (`story-005`, `story-006` e `story-007`).


func test_bloco_do_pacto_visivel_apenas_em_pactos_sem_magenta_e_anel_regeneracao() -> void:
	var pacto: ModeloDoBlocoDoPacto = ModeloDoBlocoDoPacto.new()
	pacto.sincronizar({"doutrina": &"sangue", "ativa": {"id": &"brasas", "vida_atual": 50, "vida_max": 50}})
	assert_that(pacto.visivel()).is_false()

	pacto.sincronizar({
		"doutrina": &"pactos",
		"ativa": {"id": &"brasas", "vida_atual": 45, "vida_max": 60, "exaurida": false},
		"reserva": {
			"id": &"eco",
			"vida_atual": 0,
			"vida_max": 50,
			"exaurida": true,
			"regeneracao_restante_s": 2.5,
			"regeneracao_total_s": 10.0
		},
		"troca_recarga_restante_s": 0.0,
		"troca_recarga_total_s": 3.0,
		"chamado_recarga_restante_s": 0.0,
		"chamado_recarga_total_s": 8.0,
		"fluxo_suficiente_chamado": true,
	})
	assert_that(pacto.visivel()).is_true()
	assert_that(pacto.tem_reserva()).is_true()
	assert_that(pacto.tamanho_bloco_100()).is_equal(Vector2(332.0, 88.0))
	assert_that(pacto.cor_silhueta_ativa()).is_equal(ModeloDoBlocoDoPacto.COR_SILHUETA_OSSO)
	assert_that(pacto.progresso_regeneracao_reserva()).is_equal_approx(0.75, 0.001)
	assert_that(pacto.estado_chamado()).is_equal(ModeloDoBlocoDoPacto.CHAMADO_BLOQUEADO)

	pacto.notificar_troca_indisponivel()
	assert_that(pacto.pulso_borda_indisponivel_ativo()).is_true()
	pacto.configurar_acessibilidade(true)
	assert_that(pacto.deslocamento_sacudida_px()).is_equal_approx(0.0, 0.001)


func test_vista_do_hud_respeita_margem_segura_fixa_48px_e_escala_80_a_150() -> void:
	var duble: ModeloEVidaHudTest.LeituraDuble = ModeloEVidaHudTest.LeituraDuble.new()
	duble.v_pacto = {
		"doutrina": &"pactos",
		"ativa": {"id": &"brasas", "vida_atual": 60, "vida_max": 60},
		"reserva": {"id": &"eco", "vida_atual": 50, "vida_max": 50},
	}
	var modelo: ModeloDoHud = ModeloDoHud.new(duble, HudTuning.new())
	var opcoes: OpcoesDoHud = OpcoesDoHud.new()
	opcoes.escala_hud = 1.25
	modelo.aplicar_opcoes(opcoes)

	var vista: VistaDoHud = auto_free(VistaDoHud.new())
	vista.vincular_modelo(modelo)
	vista.atualizar_vista(Vector2(1920.0, 1080.0))

	var rect_jg: Rect2 = vista.grupo_jogador_rect()
	var rect_pacto: Rect2 = vista.bloco_pacto_rect()
	# Margem esquerda fixa em 48 px mesmo com escala 1.25
	assert_that(rect_jg.position.x).is_equal_approx(48.0, 0.01)
	assert_that(rect_jg.position.y + rect_jg.size.y).is_equal_approx(1080.0 - 48.0, 0.01)
	assert_that(vista.bloco_pacto_visivel()).is_true()
	# Bloco do pacto fica 12 * 1.25 = 15 px acima do topo do grupo do jogador
	assert_that(rect_jg.position.y - (rect_pacto.position.y + rect_pacto.size.y)).is_equal_approx(15.0, 0.01)
