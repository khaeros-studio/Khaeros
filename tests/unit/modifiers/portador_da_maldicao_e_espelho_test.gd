extends GdUnitTestSuite
## Story modificadores-008: portador da Maldição e espelho (AC-33..40).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const SEM := Modificador.Slot.NENHUM


func _baluarte() -> CurseDef:
	var c := CurseDef.new()
	c.vida_max = 135.0
	c.velocidade = 360.0
	c.raio_px = 30.0
	return c


func _especie() -> FonteDeModificador:
	return F.fonte(&"especie:baluarte_de_cinza", [F.mod(Atributos.REDUCAO_DANO, F.OP.PLANO, 0.15)])


func _m(p: Portador) -> float:
	return p.multiplicador_de_dano(SEM, ContextoDeDano.new())


func test_baluarte_criado_com_base_do_cursedef_e_passiva() -> void:
	var p := PortadorDaMaldicao.criar(20, 0, _baluarte(), F.tuning(), _especie(), null, null)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(135)
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(360.0, F.TOL)
	assert_float(p.valor(Atributos.RAIO)).is_equal_approx(30.0, F.TOL)
	assert_float(p.valor(Atributos.REDUCAO_DANO)).is_equal_approx(0.15, F.TOL)
	assert_float(_m(p)).is_equal_approx(1.0, F.TOL)
	assert_bool(p.gatilhos(&"recusas_morte").esta_vazio()).is_true()


func test_atributo_fora_da_lista_da_maldicao_vai_ao_relator_e_e_ignorado() -> void:
	var relator := RelatorAcumulador.new()
	var p := PortadorDaMaldicao.criar(20, 0, _baluarte(), F.tuning(), null, null, null, relator)
	p.aplicar_fonte(F.fonte(&"vinculo:baluarte", [F.mod(Atributos.CARGAS_ESQUIVA, F.OP.PLANO, 1.0)]))
	assert_int(relator.entradas.size()).is_equal(1)


func test_espelho_de_preco_e_impeto_m_135_vida_nao_muda_e_remover_preco_115() -> void:
	var t := F.tuning()
	var jogador := F.jogador(130.0)
	var esp := EspelhoDeFontes.new(jogador, t)
	var vulto := PortadorDaMaldicao.criar(21, 0, _baluarte(), t, null, null, esp)
	var base := vulto.inteiro(Atributos.VIDA_MAX)
	esp.aplicar_fonte_do_jogador(F.preco_com_nome())
	esp.aplicar_fonte_do_jogador(F.impeto())
	assert_float(_m(vulto)).is_equal_approx(1.35, F.TOL)
	assert_int(vulto.inteiro(Atributos.VIDA_MAX)).is_equal(base)
	assert_bool(vulto.tem_fonte(&"espelho:bencao:preco_com_nome")).is_true()
	assert_bool(vulto.tem_fonte(&"espelho:oficina:impeto")).is_true()
	esp.remover_fonte_do_jogador(&"bencao:preco_com_nome")
	assert_float(_m(vulto)).is_equal_approx(1.15, F.TOL)


func test_traco_fundo_linha_penumbra_e_gatilhos_nao_propagam() -> void:
	var t := F.tuning()
	var jogador := F.jogador(100.0)
	var esp := EspelhoDeFontes.new(jogador, t)
	var m := PortadorDaMaldicao.criar(21, 0, _baluarte(), t, null, null, esp)
	for f: FonteDeModificador in [F.traco_unico(), F.fundo_do_poco(), F.linha_contada(), F.penumbra()]:
		esp.aplicar_fonte_do_jogador(f)
	var g: Array[GatilhoAtivo] = [GatilhoAtivo.new(&"cura_ao_abater", 2.0), GatilhoAtivo.new(&"refletir_dano", 3.0)]
	esp.aplicar_fonte_do_jogador(FonteDeModificador.new(&"bencao:g", [], g))
	assert_float(m.congelar_dano(SEM, ContextoDeDano.new(40.0, true)).m_no_impacto(4)).is_equal_approx(1.0, F.TOL)
	assert_bool(m.gatilhos(&"cura_ao_abater").esta_vazio()).is_true()
	assert_bool(m.gatilhos(&"refletir_dano").esta_vazio()).is_true()
	assert_int(m.ids_de_fontes().size()).is_equal(0)


func test_fio_invisivel_epico_velocidade_e_knobs() -> void:
	var t := F.tuning()
	var jogador := F.jogador(130.0, {Atributos.VELOCIDADE: 382.5})
	var esp := EspelhoDeFontes.new(jogador, t)
	var b := PortadorDaMaldicao.criar(20, 0, _baluarte(), t, null, null, esp)
	esp.aplicar_fonte_do_jogador(F.velocidade_pct(&"bencao:fio_invisivel", 0.24))
	assert_float(b.valor(Atributos.VELOCIDADE)).is_equal_approx(446.4, 1e-4)
	assert_float(jogador.valor(Atributos.VELOCIDADE)).is_equal_approx(474.3, 1e-4)
	t.fator_propagacao_maldicao = 0.5
	esp.aplicar_fonte_do_jogador(F.velocidade_pct(&"bencao:fio_invisivel", 0.24))
	assert_float(b.valor(Atributos.VELOCIDADE)).is_equal_approx(403.2, 1e-4)
	t.fator_propagacao_maldicao = 1.0
	t.tipos_propagados_maldicao = [&"dano_todo_pct"]
	esp.aplicar_fonte_do_jogador(F.velocidade_pct(&"bencao:fio_invisivel", 0.24))
	assert_float(b.valor(Atributos.VELOCIDADE)).is_equal_approx(360.0, F.TOL)


func test_espelhos_p_todo_45_respeita_teto_4_e_menos_15_da_0() -> void:
	var t := F.tuning()
	var jogador := F.jogador()
	var esp := EspelhoDeFontes.new(jogador, t)
	var m := PortadorDaMaldicao.criar(20, 0, _baluarte(), t, null, null, esp)
	esp.aplicar_fonte_do_jogador(F.impeto(4.5))
	assert_float(_m(m)).is_equal_approx(4.0, F.TOL)
	esp.aplicar_fonte_do_jogador(F.impeto(-1.5))
	assert_float(_m(m)).is_equal_approx(0.0, F.TOL)


func test_vinculo_mais_10_vida_120_e_base_15_piso_20() -> void:
	var c := _baluarte()
	c.vida_max = 110.0
	var vinc := F.fonte(&"vinculo:vulto_mudo", [F.mod(Atributos.VIDA_MAX, F.OP.PLANO, 10.0)])
	var p := PortadorDaMaldicao.criar(21, 0, c, F.tuning(), null, vinc, null)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(120)
	assert_float(NotificadorDeAtributo.vida_no_comeco_da_run(p.inteiro(Atributos.VIDA_MAX))).is_equal_approx(120.0, F.TOL)
	c.vida_max = 15.0
	var q := PortadorDaMaldicao.criar(22, 0, c, F.tuning(), null, null, null)
	assert_int(q.inteiro(Atributos.VIDA_MAX)).is_equal(20)


func test_espelho_120_passos_reserva_60_vivos_e_30_hitstop_resta_60() -> void:
	var t := F.tuning()
	var jogador := F.jogador()
	var esp := EspelhoDeFontes.new(jogador, t)
	var m := PortadorDaMaldicao.criar(20, 0, _baluarte(), t, null, null, esp)
	esp.aplicar_fonte_do_jogador(F.velocidade_pct(&"bencao:v", 0.1, 120))
	m.avancar(60)  # 30 de hitstop: ninguém chama avancar
	assert_int(m.duracao_restante(&"espelho:bencao:v")).is_equal(60)


func test_espelho_some_quando_original_expira_no_jogador() -> void:
	var t := F.tuning()
	var jogador := F.jogador()
	var esp := EspelhoDeFontes.new(jogador, t)
	var m := PortadorDaMaldicao.criar(20, 0, _baluarte(), t, null, null, esp)
	esp.aplicar_fonte_do_jogador(F.velocidade_pct(&"bencao:v", 0.1, 10))
	jogador.avancar(10)
	esp.sincronizar()
	assert_bool(m.tem_fonte(&"espelho:bencao:v")).is_false()


func test_criacao_no_pacto_monta_tudo_e_dupla_cheia_nao_cria() -> void:
	var t := F.tuning()
	var jogador := F.jogador()
	var esp := EspelhoDeFontes.new(jogador, t)
	esp.aplicar_fonte_do_jogador(F.preco_com_nome())
	esp.aplicar_fonte_do_jogador(F.velocidade_pct(&"bencao:v", 0.1, 200))
	jogador.avancar(80)
	var vinc := F.fonte(&"vinculo:baluarte_de_cinza", [F.mod(Atributos.VELOCIDADE, F.OP.PERCENTUAL, 0.0)])
	var p := PortadorDaMaldicao.criar_no_pacto(1, 2, 30, 0, _baluarte(), t, _especie(), vinc, esp)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(135)
	assert_float(PortadorDaMaldicao.vida_ao_nascer_no_pacto(50.0, p.inteiro(Atributos.VIDA_MAX))).is_equal_approx(50.0, F.TOL)
	assert_float(p.valor(Atributos.REDUCAO_DANO)).is_equal_approx(0.15, F.TOL)
	assert_bool(p.tem_fonte(&"vinculo:baluarte_de_cinza")).is_true()
	assert_int(p.duracao_restante(&"espelho:bencao:preco_com_nome")).is_equal(FonteDeModificador.PERMANENTE)
	assert_int(p.duracao_restante(&"espelho:bencao:v")).is_equal(120)
	assert_object(PortadorDaMaldicao.criar_no_pacto(2, 2, 31, 0, _baluarte(), t, _especie(), vinc, esp)).is_null()
