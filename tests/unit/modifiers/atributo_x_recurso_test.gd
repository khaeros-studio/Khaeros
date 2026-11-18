extends GdUnitTestSuite
## Story modificadores-007: atributo × recurso, cargas, elite e profundidade (AC-20, 21, 23).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")



func _regras_elite() -> EliteRules:
	var r := EliteRules.new()
	r.mult_vida = 2.4
	r.mult_dano = 1.25
	r.mult_raio = 1.2
	r.resistencia_empurrao = 0.4
	return r


func test_f4_oraculos() -> void:
	assert_float(NotificadorDeAtributo.vida_apos_mudar_max(80.0, 130, 155)).is_equal_approx(105.0, F.TOL)
	assert_float(NotificadorDeAtributo.vida_apos_mudar_max(150.0, 155, 145)).is_equal_approx(145.0, F.TOL)
	assert_float(NotificadorDeAtributo.vida_apos_mudar_max(100.0, 155, 145)).is_equal_approx(100.0, F.TOL)
	assert_float(NotificadorDeAtributo.vida_apos_mudar_max(25.0, 25, 20)).is_equal_approx(20.0, F.TOL)
	assert_float(NotificadorDeAtributo.vida_no_comeco_da_run(150)).is_equal_approx(150.0, F.TOL)


func test_vida_max_muda_notifica_antigo_e_novo_pelo_despachante() -> void:
	var espiao := F.Espiao.new()
	var n := NotificadorDeAtributo.new()
	n.registrar(Atributos.VIDA_MAX, espiao)
	var p := F.jogador(130.0, {}, null, null, n)
	p.aplicar_fonte(F.muro_de_pedras())
	assert_int(espiao.chamadas.size()).is_equal(1)
	assert_array(espiao.chamadas[0]).is_equal([1, 0, Atributos.VIDA_MAX, 130, 155])


func test_cargas_sobe_ganha_desce_corta_e_recusa_a_mais() -> void:
	assert_int(NotificadorDeAtributo.restantes_apos_mudar_max(2, 2, 3)).is_equal(3)
	assert_int(NotificadorDeAtributo.restantes_apos_mudar_max(3, 3, 2)).is_equal(2)
	assert_int(NotificadorDeAtributo.restantes_apos_mudar_max(0, 1, 2)).is_equal(1)


func test_elite_base_30_vida_72_dano_125_raio_12_empurrao_04() -> void:
	var e := F.inimigo(30.0)
	e.aplicar_fonte(AplicadorDeEfeitos.fonte_elite(_regras_elite()))
	assert_int(e.inteiro(Atributos.VIDA_MAX)).is_equal(72)
	assert_float(e.multiplicador_de_dano(Modificador.Slot.NENHUM, ContextoDeDano.new())).is_equal_approx(1.25, F.TOL)
	assert_float(e.valor(Atributos.RAIO)).is_equal_approx(12.0, F.TOL)
	assert_float(e.valor(Atributos.FATOR_EMPURRAO)).is_equal_approx(0.4, F.TOL)


func test_elite_base_46_profundidade_7_vida_149() -> void:
	var e := F.inimigo(46.0)
	e.aplicar_fonte(AplicadorDeEfeitos.fonte_profundidade(0.35))
	e.aplicar_fonte(AplicadorDeEfeitos.fonte_elite(_regras_elite()))
	assert_int(e.inteiro(Atributos.VIDA_MAX)).is_equal(149)


func test_chefe_700_sem_profundidade_empurrao_012_e_remover_volta_a_1() -> void:
	var c := F.inimigo(700.0)
	c.aplicar_fonte(AplicadorDeEfeitos.fonte_chefe(F.tuning()))
	assert_int(c.inteiro(Atributos.VIDA_MAX)).is_equal(700)
	assert_float(c.valor(Atributos.FATOR_EMPURRAO)).is_equal_approx(0.12, F.TOL)
	c.remover_fonte(&"chefe")
	assert_float(c.valor(Atributos.FATOR_EMPURRAO)).is_equal_approx(1.0, F.TOL)
