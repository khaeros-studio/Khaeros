extends GdUnitTestSuite
## Story modificadores-004: aplicar/remover/avancar, cache e duração (AC-12..14, AC-17, AC-18).

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const PASSOS_2S: int = 120


func test_adicionar_remover_expirar_proxima_consulta_ja_reflete() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.velocidade_pct(&"x:v", 0.5, 1))
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(15.0, F.TOL)
	p.avancar(1)
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(10.0, F.TOL)
	p.aplicar_fonte(F.muro_de_pedras())
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(155)
	p.remover_fonte(&"bencao:muro_de_pedras")
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(130)


func test_remover_preco_com_nome_retira_os_2_modificadores_e_os_gatilhos() -> void:
	var g: Array[GatilhoAtivo] = [GatilhoAtivo.new(&"cura_ao_abater", 2.0)]
	var preco := FonteDeModificador.new(&"bencao:preco_com_nome", F.preco_com_nome().modificadores, g)
	var p := F.jogador(130.0)
	p.aplicar_fonte(preco)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(120)
	assert_float(p.gatilhos(&"cura_ao_abater").total).is_equal_approx(2.0, F.TOL)
	p.remover_fonte(preco.id)
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(130)
	assert_float(p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new(130.0))).is_equal_approx(1.0, F.TOL)
	assert_bool(p.gatilhos(&"cura_ao_abater").esta_vazio()).is_true()


func test_remover_duas_vezes_fonte_inexistente_nada_muda_sem_log() -> void:
	var relator := RelatorAcumulador.new()
	var espiao := F.Espiao.new()
	var p := F.jogador(130.0, {}, null, relator, espiao)
	p.remover_fonte(&"bencao:nao_existe")
	p.remover_fonte(&"bencao:nao_existe")
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(130)
	assert_int(relator.entradas.size()).is_equal(0)
	assert_int(espiao.chamadas.size()).is_equal(0)


func test_duracao_120_passos_avancar_60_e_pausa_continua_ativo_e_mais_60_expira() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.velocidade_pct(&"x:v", 0.5, PASSOS_2S))
	p.avancar(60)
	# pausa/hitstop: ninguém chama avancar
	assert_bool(p.tem_fonte(&"x:v")).is_true()
	p.avancar(60)
	assert_bool(p.tem_fonte(&"x:v")).is_false()
	assert_float(p.valor(Atributos.VELOCIDADE)).is_equal_approx(10.0, F.TOL)


func test_duracao_120_chamadas_de_avancar_1_expira_exatamente_na_120a() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.velocidade_pct(&"x:v", 0.5, PASSOS_2S))
	for i: int in PASSOS_2S - 1:
		p.avancar(1)
	assert_bool(p.tem_fonte(&"x:v")).is_true()
	p.avancar(1)
	assert_bool(p.tem_fonte(&"x:v")).is_false()


func test_reaplicar_usa_max_do_restante_e_da_nova() -> void:
	var p := F.jogador(130.0, {Atributos.VELOCIDADE: 10.0})
	p.aplicar_fonte(F.velocidade_pct(&"x:v", 0.5, PASSOS_2S))
	p.avancar(90)
	p.aplicar_fonte(F.velocidade_pct(&"x:v", 0.5, PASSOS_2S))
	assert_int(p.duracao_restante(&"x:v")).is_equal(120)
	p.avancar(20)
	p.aplicar_fonte(F.velocidade_pct(&"x:v", 0.5, 30))
	assert_int(p.duracao_restante(&"x:v")).is_equal(100)


func test_duracao_restante_permanente_menos_1_e_inexistente_0() -> void:
	var p := F.jogador()
	p.aplicar_fonte(F.muro_de_pedras())
	assert_int(p.duracao_restante(&"bencao:muro_de_pedras")).is_equal(-1)
	assert_int(p.duracao_restante(&"x:nada")).is_equal(0)


func test_ouvinte_avisado_uma_vez_por_inteiro_que_mudou() -> void:
	var espiao := F.Espiao.new()
	var p := F.jogador(130.0, {}, null, null, espiao)
	p.aplicar_fonte(F.muro_de_pedras())
	assert_int(espiao.chamadas.size()).is_equal(1)
	assert_array(espiao.chamadas[0]).is_equal([1, 0, Atributos.VIDA_MAX, 130, 155])


func test_portador_de_inimigo_descartado_com_modificadores_zero_avisos_e_sem_vazamento() -> void:
	var espiao := F.Espiao.new()
	var inimigo := InimigoRef.new(7, null)
	inimigo.portador = F.inimigo(30.0, espiao)
	(inimigo.portador as Portador).aplicar_fonte(F.velocidade_pct(&"elite", 0.2, PASSOS_2S))
	var chamadas_antes := espiao.chamadas.size()
	var ref_portador: WeakRef = weakref(inimigo.portador)
	var ref_inimigo: WeakRef = weakref(inimigo)
	inimigo = null
	assert_object(ref_inimigo.get_ref()).is_null()
	assert_object(ref_portador.get_ref()).is_null()
	assert_int(espiao.chamadas.size()).is_equal(chamadas_antes)
