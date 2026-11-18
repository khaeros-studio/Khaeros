## Story persistencia/002: plano puro de recuperação de sobras (ADR-0013 §4).
extends GdUnitTestSuite


func test_planejar_destino_existe_apaga_sobras() -> void:
	var acoes := RecuperacaoDeGravacao.planejar(true, true, true)
	assert_array(acoes).is_equal([RecuperacaoDeGravacao.APAGAR_OLD, RecuperacaoDeGravacao.APAGAR_TMP])


func test_planejar_destino_ausente_com_old_restaura_old() -> void:
	var acoes := RecuperacaoDeGravacao.planejar(false, true, false)
	assert_array(acoes).is_equal([RecuperacaoDeGravacao.RESTAURAR_OLD])


func test_planejar_tmp_sozinho_nunca_promovido_so_apagado() -> void:
	var acoes := RecuperacaoDeGravacao.planejar(false, false, true)
	assert_array(acoes).is_equal([RecuperacaoDeGravacao.APAGAR_TMP])


func test_planejar_nada_a_recuperar_sem_acoes() -> void:
	assert_array(RecuperacaoDeGravacao.planejar(true, false, false)).is_empty()
	assert_array(RecuperacaoDeGravacao.planejar(false, false, false)).is_empty()
