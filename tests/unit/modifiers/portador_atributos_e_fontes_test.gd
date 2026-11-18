extends GdUnitTestSuite
## Story modificadores-001: Portador, atributos, piso/teto, F1 (AC-01..04, AC-15).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const OP := Modificador.Operacao


func test_portador_sem_modificadores_vida_130_devolve_130_m_1_e_gatilhos_vazio() -> void:
	var p := F.jogador(130.0)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(130)
	assert_float(p.valor(Atributos.VIDA_MAX)).is_equal_approx(130.0, F.TOL)
	assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(130.0))).is_equal_approx(1.0, F.TOL)
	assert_bool(p.gatilhos(&"recusas_morte").esta_vazio()).is_true()


func test_velocidade_pct_adicionar_e_remover_nao_muda_vida_atual() -> void:
	var j := JogadorRef.new(0, null)
	j.vida = 80.0
	j.portador = F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	var p: Portador = j.portador
	p.aplicar_fonte(F.velocidade_pct(&"bencao:fio", 0.12))
	p.remover_fonte(&"bencao:fio")
	assert_float(j.vida).is_equal_approx(80.0, F.TOL)


func test_f1_guardiao_muro_vigor_175_e_com_preco_165() -> void:
	var p := F.jogador(130.0)
	p.aplicar_fonte(F.muro_de_pedras())
	p.aplicar_fonte(F.vigor(20.0))
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(175)
	p.aplicar_fonte(F.preco_com_nome())
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(165)


func test_f1_base_25_menos_10_respeita_piso_20() -> void:
	var p := F.jogador(25.0)
	p.aplicar_fonte(F.preco_com_nome())
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(20)


func test_f1_muro_raro_167_5_arredonda_168() -> void:
	var p := F.jogador(130.0)
	p.aplicar_fonte(F.muro_de_pedras(37.5))
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(168)


func test_f1_velocidade_10_com_dois_12_pct_da_12_4() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.velocidade_pct(&"bencao:a", 0.12))
	p.aplicar_fonte(F.velocidade_pct(&"bencao:b", 0.12))
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(12.4, F.TOL)


func test_f1_plano_percentual_multiplicador_na_ordem_da_27() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.fonte(&"x:1", [F.mod(Atributos.VELOCIDADE, OP.MULTIPLICADOR, 1.5)]))
	p.aplicar_fonte(F.fonte(&"x:2", [F.mod(Atributos.VELOCIDADE, OP.PERCENTUAL, 0.2)]))
	p.aplicar_fonte(F.fonte(&"x:3", [F.mod(Atributos.VELOCIDADE, OP.PLANO, 5.0)]))
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(27.0, F.TOL)


func test_pisos_e_tetos_reducao_dano_0_9_vira_0_6_e_menos_0_1_vira_0() -> void:
	var p := F.jogador()
	p.aplicar_fonte(F.fonte(&"x:red", [F.mod(Atributos.REDUCAO_DANO, OP.PLANO, 0.9)]))
	assert_float(p.valor(Atributos.REDUCAO_DANO)).is_equal_approx(0.6, F.TOL)
	p.aplicar_fonte(F.fonte(&"x:red", [F.mod(Atributos.REDUCAO_DANO, OP.PLANO, -0.1)]))
	assert_float(p.valor(Atributos.REDUCAO_DANO)).is_equal_approx(0.0, F.TOL)


func test_pisos_cargas_1_menos_1_fica_1() -> void:
	var p := F.jogador(130.0, {Atributos.CARGAS_ESQUIVA: 1.0})
	p.aplicar_fonte(F.fonte(&"x:c", [F.mod(Atributos.CARGAS_ESQUIVA, OP.PLANO, -1.0)]))
	assert_int(p.inteiro(Atributos.CARGAS_ESQUIVA)).is_equal(1)


func test_pisos_velocidade_com_pct_menos_1_2_fica_0() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.velocidade_pct(&"x:v", -1.2))
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(0.0, F.TOL)


func test_pisos_inimigo_vida_10_menos_50_fica_1() -> void:
	var p := F.inimigo(10.0)
	p.aplicar_fonte(F.fonte(&"x:v", [F.mod(Atributos.VIDA_MAX, OP.PLANO, -50.0)]))
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(1)


func test_pisos_dois_negativos_nunca_viram_positivo() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 0.0})
	p.aplicar_fonte(F.fonte(&"x:v", [
		F.mod(Atributos.VELOCIDADE, OP.PLANO, -5.0), F.mod(Atributos.VELOCIDADE, OP.PERCENTUAL, -1.5)]))
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(0.0, F.TOL)


func test_muro_aplicado_duas_vezes_da_155_nao_180() -> void:
	var p := F.jogador(130.0)
	p.aplicar_fonte(F.muro_de_pedras())
	p.aplicar_fonte(F.muro_de_pedras())
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(155)


func test_vigor_nivel_3_e_uma_fonte_de_30() -> void:
	var p := F.jogador(130.0)
	p.aplicar_fonte(F.vigor(30.0))
	assert_int(p.ids_de_fontes().size()).is_equal(1)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(160)


func test_fonte_compartilhada_estado_por_instancia_e_definicao_intacta() -> void:
	var muro := F.muro_de_pedras()
	var a := F.jogador(130.0)
	var b := F.inimigo(30.0)
	a.aplicar_fonte(muro)
	b.aplicar_fonte(muro)
	a.remover_fonte(muro.id)
	assert_int(a.inteiro(Atributos.VIDA_MAX)).is_equal(130)
	assert_int(b.inteiro(Atributos.VIDA_MAX)).is_equal(55)
	assert_int(muro.modificadores.size()).is_equal(1)
	assert_float(muro.modificadores[0].valor).is_equal_approx(25.0, F.TOL)


func test_modificador_com_atributo_fora_da_r2_e_ignorado_e_relatado() -> void:
	var relator := RelatorAcumulador.new()
	var p := F.jogador(130.0, {}, null, relator)
	p.aplicar_fonte(F.fonte(&"x:bug", [F.mod(&"sorte", OP.PLANO, 5.0), F.mod(Atributos.VIDA_MAX, OP.PLANO, 5.0)]))
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(135)
	assert_int(relator.entradas.size()).is_equal(1)


func test_condicao_fora_de_dano_todo_e_recusada() -> void:
	var m := Modificador.new(Atributos.VELOCIDADE, OP.PERCENTUAL, 0.1, Modificador.Condicao.VIDA_ABAIXO, 0.5)
	assert_str(m.motivo_invalido()).is_not_empty()
