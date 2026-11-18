extends GdUnitTestSuite
## Story modificadores-005: ResumoDeGatilho e semântica do executor único (AC-25, 26, 29–31).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")


func _ef(tipo: StringName, v: float, params: Dictionary[StringName, float] = {}, escala: bool = true) -> EffectDef:
	var e := EffectDef.new()
	e.tipo = tipo
	e.valor = v
	e.escala_com_raridade = escala
	e.params = params
	return e


func test_gatilhos_8_tipos_listam_entradas_por_fonte_em_ordem_canonica() -> void:
	var p := F.jogador()
	var tipos := TabelaDeEfeitos.tipos_de_gatilho()
	assert_int(tipos.size()).is_equal(8)
	for t: StringName in tipos:
		var efs: Array[EffectDef] = [_ef(t, 1.0, {&"k": 2.0})]
		p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(StringName("bencao:z_" + t), efs, 1.0))
		p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(StringName("bencao:a_" + t), efs, 1.0))
	for t: StringName in tipos:
		var r := p.gatilhos(t)
		assert_int(r.entradas.size()).is_equal(2)
		assert_str(String(r.entradas[0].fonte)).is_equal("bencao:a_" + t)
		assert_str(String(r.entradas[1].fonte)).is_equal("bencao:z_" + t)
		assert_float(r.total).is_equal_approx(2.0, F.TOL)
		assert_float(r.params[&"k"]).is_equal_approx(2.0, F.TOL)


func test_tipo_de_atributo_nao_aparece_em_gatilhos_e_recusas_morte_aparece_nos_dois() -> void:
	var p := F.jogador()
	var efs: Array[EffectDef] = [_ef(&"dano_todo_pct", 0.2), _ef(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4}, false)]
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:x", efs, 1.0))
	assert_bool(p.gatilhos(&"dano_todo_pct").esta_vazio()).is_true()
	assert_int(p.inteiro(Atributos.RECUSAS_MORTE)).is_equal(1)
	assert_float(p.gatilhos(&"recusas_morte").total).is_equal_approx(1.0, F.TOL)


func test_os_que_ficam_e_recusa_dos_que_ficam_total_2_params_nao_escalam() -> void:
	var p := F.jogador()
	var pr: Dictionary[StringName, float] = {&"vida_ao_voltar": 0.4, &"invuln_s": 2.0}
	var a: Array[EffectDef] = [_ef(&"recusas_morte", 1.0, pr, false)]
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"oficina:os_que_ficam", a, 1.0))
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:recusa_dos_que_ficam", a, 2.0))
	var r := p.gatilhos(&"recusas_morte")
	assert_float(r.total).is_equal_approx(2.0, F.TOL)
	assert_float(r.params[&"vida_ao_voltar"]).is_equal_approx(0.4, F.TOL)
	assert_int(p.inteiro(Atributos.RECUSAS_MORTE)).is_equal(2)


func test_gatilho_escala_valor_mas_nao_params() -> void:
	var p := F.jogador()
	var a: Array[EffectDef] = [_ef(&"refletir_dano", 3.0, {&"x": 1.0})]
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:fardo", a, 2.0))
	assert_float(p.gatilhos(&"refletir_dano").total).is_equal_approx(6.0, F.TOL)
	assert_float(p.gatilhos(&"refletir_dano").params[&"x"]).is_equal_approx(1.0, F.TOL)


func test_resumo_e_somente_leitura_para_o_executor() -> void:
	var p := F.jogador()
	var a: Array[EffectDef] = [_ef(&"cura_ao_abater", 2.0)]
	p.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:c", a, 1.0))
	assert_bool(p.gatilhos(&"cura_ao_abater").entradas.is_read_only()).is_true()
	assert_bool(p.gatilhos(&"cura_ao_abater").params.is_read_only()).is_true()


func test_projetil_congelado_no_disparo_ignora_cura_e_avalia_4o_acerto_no_impacto() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.fundo_do_poco())
	p.aplicar_fonte(F.linha_contada())
	var congelado := p.congelar_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(40.0))
	# Vida curada a 60 depois do disparo: o congelado não muda.
	assert_float(congelado.m_no_impacto(3)).is_equal_approx(1.4, F.TOL)
	assert_float(congelado.m_no_impacto(4)).is_equal_approx(1.4 * 1.6, F.TOL)


func test_investida_com_penumbra_e_fundo_do_poco_congela_2_1() -> void:
	var p := F.jogador(100.0)
	p.aplicar_fonte(F.fundo_do_poco())
	p.aplicar_fonte(F.penumbra())
	var congelado := p.congelar_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(40.0, true))
	assert_float(congelado.m_no_impacto(1)).is_equal_approx(2.1, F.TOL)


func test_abalo_no_disparo_projetil_10_vira_7_mesmo_se_abalo_expira() -> void:
	var t := F.tuning()
	var inimigo := F.inimigo(30.0)
	inimigo.aplicar_fonte(F.abalo())
	var congelado := inimigo.congelar_dano(Modificador.Slot.NENHUM, ContextoDeDano.new())
	inimigo.remover_fonte(&"status:abalo")
	var d := FormulasDeModificadores.dano_recebido(10.0 * congelado.m_no_impacto(0), 0.0, t.teto_reducao_dano, 1.0)
	assert_int(d).is_equal(7)


func test_abalo_fonte_unica_reaplicar_nao_acumula_nem_encurta() -> void:
	var inimigo := F.inimigo(30.0)
	inimigo.aplicar_fonte(F.fonte(&"status:abalo", F.abalo().modificadores, 180))
	inimigo.aplicar_fonte(F.fonte(&"status:abalo", F.abalo().modificadores, 30))
	assert_int(inimigo.duracao_restante(&"status:abalo")).is_equal(180)
	assert_float(inimigo.multiplicador_de_dano(Modificador.Slot.NENHUM, ContextoDeDano.new())).is_equal_approx(0.7, F.TOL)
