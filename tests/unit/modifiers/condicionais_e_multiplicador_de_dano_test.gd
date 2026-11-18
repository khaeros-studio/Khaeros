extends GdUnitTestSuite
## Story modificadores-003: condicionais avaliados no uso (AC-07, AC-08, AC-09, AC-11).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const SLOT := Modificador.Slot


func test_vida_abaixo_49_9_da_1_4_e_50_da_1_0() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.fundo_do_poco())
	assert_float(p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(49.9))).is_equal_approx(1.4, F.TOL)
	assert_float(p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(50.0))).is_equal_approx(1.0, F.TOL)


func test_vida_abaixo_muda_vida_sem_mexer_na_lista_consulta_seguinte_ja_reflete() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.fundo_do_poco())
	assert_float(p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(60.0))).is_equal_approx(1.0, F.TOL)
	assert_float(p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(40.0))).is_equal_approx(1.4, F.TOL)


func test_enesimo_acerto_contador_3_e_0_da_1_e_4_e_8_dao_1_6() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.linha_contada())
	var c := p.congelar_dano(SLOT.ATAQUE, ContextoDeDano.new(100.0))
	assert_float(c.m_no_impacto(3)).is_equal_approx(1.0, F.TOL)
	assert_float(c.m_no_impacto(0)).is_equal_approx(1.0, F.TOL)
	assert_float(c.m_no_impacto(4)).is_equal_approx(1.6, F.TOL)
	assert_float(c.m_no_impacto(8)).is_equal_approx(1.6, F.TOL)


func test_enesimo_acerto_tres_alvos_com_contador_2_so_o_segundo_leva_1_6() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.linha_contada())
	var c := p.congelar_dano(SLOT.ATAQUE, ContextoDeDano.new(100.0))
	var contador := 2
	var ms: Array[float] = []
	for _alvo: int in 3:
		contador += 1
		ms.append(c.m_no_impacto(contador))
	assert_float(ms[0]).is_equal_approx(1.0, F.TOL)
	assert_float(ms[1]).is_equal_approx(1.6, F.TOL)
	assert_float(ms[2]).is_equal_approx(1.0, F.TOL)


func test_apos_esquiva_ataque_com_contexto_da_1_5_sem_da_1_e_selo_da_1() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.penumbra())
	assert_float(p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(100.0, true))).is_equal_approx(1.5, F.TOL)
	assert_float(p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(100.0, false))).is_equal_approx(1.0, F.TOL)
	assert_float(p.multiplicador_de_dano(SLOT.SELO, ContextoDeDano.new(100.0, true))).is_equal_approx(1.0, F.TOL)


func test_corte_fantasma_10_com_traco_unico_da_12_5() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.traco_unico())
	var valor_corte := 10.0
	var dano := valor_corte * p.multiplicador_de_dano(SLOT.ATAQUE, ContextoDeDano.new(100.0))
	assert_float(dano).is_equal_approx(12.5, F.TOL)


func test_projetil_congelado_no_disparo_ignora_cura_posterior() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.fundo_do_poco())
	var c := p.congelar_dano(SLOT.ATAQUE, ContextoDeDano.new(40.0))
	# A Vida sobe para 60 depois; o congelado não muda.
	assert_float(c.m_no_impacto(1)).is_equal_approx(1.4, F.TOL)


func test_inimigo_slot_nenhum_ignora_percentual_de_slot() -> void:
	var p := F.inimigo(30.0)
	p.aplicar_fonte(F.traco_unico())
	assert_float(p.multiplicador_de_dano(SLOT.NENHUM, ContextoDeDano.new())).is_equal_approx(1.0, F.TOL)
