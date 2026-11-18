extends GdUnitTestSuite
## Story movimento-007: AC-18..AC-26, AC-51, AC-41 (Corte da esquiva: alcance, ordem, teto, dano F6).

const Fab := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")
const OP := Modificador.Operacao
const COND := Modificador.Condicao
const ECO_RAIO: float = 24.0
const ECO_ID: int = 7


## Dublê espião que delega ao Portador real e guarda o último contexto de dano.
class PortadorEspiao extends ConsultaDeAtributos:
	var real: Portador
	var ultimo_ctx: ContextoDeDano = null

	func _init(p_real: Portador) -> void:
		real = p_real

	func valor(a: StringName) -> float:
		return real.valor(a)

	func inteiro(a: StringName) -> int:
		return real.inteiro(a)

	func congelar_dano(slot: Modificador.Slot, ctx: ContextoDeDano) -> DanoCongelado:
		return real.congelar_dano(slot, ctx)

	func multiplicador_de_dano(slot: Modificador.Slot, ctx: ContextoDeDano) -> float:
		ultimo_ctx = ctx
		return real.multiplicador_de_dano(slot, ctx)

	func gatilhos(tipo: StringName) -> ResumoDeGatilho:
		return real.gatilhos(tipo)


func _sim_fp_corte(cargas_max: int = 1) -> ApoioMovimento.Sim:
	var sim := ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), cargas_max)
	sim.atributos.resumo_corte = ApoioMovimento.resumo_fp_corte()
	return sim


func _portador(mods: Array[Modificador]) -> Portador:
	var extras: Dictionary[StringName, float] = {
		Atributos.CARGAS_ESQUIVA: 1.0, Atributos.VELOCIDADE: ApoioMovimento.VELOCIDADE_FP}
	var p: Portador = Fab.jogador(100.0, extras)
	var g: Array[GatilhoAtivo] = [GatilhoAtivo.new(MovimentoDoJogador.GATILHO_CORTE, 10.0,
			ApoioMovimento.params_fp_corte())]
	p.aplicar_fonte(FonteDeModificador.new(&"bencao:corte_fantasma", [], g))
	if not mods.is_empty():
		p.aplicar_fonte(FonteDeModificador.new(&"bencao:teste", mods))
	return p


func _sim_com_portador(c: ConsultaDeAtributos) -> ApoioMovimento.Sim:
	var obs: Array[ObstaculoCircular] = []
	return ApoioMovimento.Sim.new(ApoioMovimento.tuning_fp(), 1, obs, ApoioMovimento.ARENA_FP, c)


## Esquiva +x a partir do passo 0 (9 passos); devolve o passo de cada corte, na ordem.
func _passos_de_corte(sim: ApoioMovimento.Sim) -> Array[int]:
	var r: Array[int] = []
	for k in 9:
		var antes := sim.combate.cortes.size()
		sim.vivo(Vector2.RIGHT, k == 0)
		for i in sim.combate.cortes.size() - antes:
			r.append(k)
	return r


func _um_eco(sim: ApoioMovimento.Sim, pos: Vector2, raio: float = ECO_RAIO) -> void:
	var lista: Array[AlvoDoCorte] = [AlvoDoCorte.new(ECO_ID, pos, raio)]
	sim.alvos.lista = lista


func test_alcance_inclusivo_tabela_ac18() -> void:
	var casos: Array = [
		[Vector2(1042.5, 540), ECO_RAIO, [0]],
		[Vector2(1005, 600), ECO_RAIO, [1]],
		[Vector2(1005, 600.001), ECO_RAIO, []],
		[Vector2(1050, 607.5), 31.5, [3]],
	]
	for c: Array in casos:
		var sim := _sim_fp_corte()
		_um_eco(sim, c[0], c[1])
		assert_array(_passos_de_corte(sim)).is_equal(c[2])


func test_eco_no_alcance_passos_0_a_5_gera_um_pedido_com_payload() -> void:
	var sim := _sim_fp_corte()
	_um_eco(sim, Vector2(1042.5, 540))
	assert_array(_passos_de_corte(sim)).is_equal([0])
	var c: Array = sim.combate.cortes[0]
	assert_int(c[0]).is_equal(ECO_ID)
	assert_float(c[1]).is_equal_approx(10.0, 0.001)
	assert_vector(c[2]).is_equal(Vector2.RIGHT)
	assert_float(c[3]).is_equal(360.0)
	assert_float(c[4]).is_equal(1.0)


func test_sem_gatilho_ou_total_zero_nenhum_pedido() -> void:
	var sim := _sim_fp_corte()
	sim.atributos.resumo_corte = ApoioMovimento.resumo_fp_corte(0.0)
	_um_eco(sim, Vector2(1042.5, 540))
	assert_array(_passos_de_corte(sim)).is_empty()
	var sem := _sim_fp_corte()
	sem.atributos.resumo_corte = null
	_um_eco(sem, Vector2(1042.5, 540))
	assert_array(_passos_de_corte(sem)).is_empty()


func test_gatilho_some_antes_do_passo_3_nao_corta() -> void:
	var sim := _sim_fp_corte()
	_um_eco(sim, Vector2(1050, 600))
	sim.vivo(Vector2.RIGHT, true)
	sim.vivo()
	sim.vivo()
	sim.atributos.resumo_corte = null
	for i in 6:
		sim.vivo()
	assert_int(sim.combate.cortes.size()).is_equal(0)


func test_andar_atraves_do_eco_nao_corta() -> void:
	var sim := _sim_fp_corte()
	_um_eco(sim, Vector2(1000, 540))
	for i in 20:
		sim.vivo(Vector2.RIGHT)
	assert_int(sim.combate.cortes.size()).is_equal(0)


func test_corte_antes_da_colisao_na_parede() -> void:
	var sim := _sim_fp_corte()
	sim.mov.iniciar(Vector2(1890, 540))
	_um_eco(sim, Vector2(1912.5, 600))
	sim.vivo(Vector2.RIGHT, true)
	assert_int(sim.combate.cortes.size()).is_equal(1)
	assert_vector(sim.mov.posicao()).is_equal_approx(Vector2(1893, 540), Vector2(0.001, 0.001))


func test_ordem_da_lista_e_teto_de_alvos() -> void:
	var lista: Array[AlvoDoCorte] = [AlvoDoCorte.new(2, Vector2(982.5, 500), ECO_RAIO),
			AlvoDoCorte.new(1, Vector2(982.5, 580), ECO_RAIO), AlvoDoCorte.new(3, Vector2(982.5, 540), ECO_RAIO)]
	var sim := _sim_fp_corte()
	sim.alvos.lista = lista
	sim.vivo(Vector2.RIGHT, true)
	assert_array(sim.combate.pedidos.slice(3)).is_equal(["corte:2", "corte:1", "corte:3"])
	var t := ApoioMovimento.tuning_fp()
	t.alvos_max_corte = 2
	var com_teto := ApoioMovimento.Sim.new(t)
	com_teto.atributos.resumo_corte = ApoioMovimento.resumo_fp_corte()
	com_teto.alvos.lista = lista
	for k in 9:
		com_teto.vivo(Vector2.RIGHT, k == 0)
	assert_array(com_teto.combate.pedidos.slice(3)).is_equal(["corte:2", "corte:1"])


func test_esquivas_seguidas_cortam_de_novo_com_lista_limpa() -> void:
	var sim := _sim_fp_corte(2)
	_um_eco(sim, Vector2(1042.5, 540))
	var passos: Array[int] = []
	for k in 14:
		var antes := sim.combate.cortes.size()
		var mover := Vector2.LEFT if k >= 9 else Vector2.RIGHT
		sim.vivo(mover, k == 0 or k == 4)
		if k == 9:
			assert_int(sim.mov.cortados_nesta_esquiva()).is_equal(0)
		if sim.combate.cortes.size() > antes:
			passos.append(k)
	assert_array(passos).is_equal([0, 11])


func test_dano_f6_com_portador_real_tabela_ac24() -> void:
	var completos: Array[Modificador] = [
		Modificador.new(Atributos.DANO_TODO, OP.PERCENTUAL, 0.2),
		Modificador.new(Atributos.DANO_TODO, OP.PERCENTUAL, 0.4, COND.VIDA_ABAIXO, 0.5),
		Modificador.new(Atributos.DANO_ATAQUE, OP.PERCENTUAL, 0.25),
		Modificador.new(Atributos.DANO_TODO, OP.PERCENTUAL, 0.5, COND.APOS_ESQUIVA, 1.5),
		Modificador.new(Atributos.DANO_TODO, OP.MULTIPLICADOR, 1.6, COND.ENESIMO_ACERTO, 4.0),
	]
	var nenhum: Array[Modificador] = []
	var zero: Array[Modificador] = [Modificador.new(Atributos.DANO_ATAQUE, OP.PERCENTUAL, -1.0)]
	var cinco: Array[Modificador] = [Modificador.new(Atributos.DANO_TODO, OP.MULTIPLICADOR, 5.0)]
	var casos: Array = [[completos, 40.0, 18.5], [completos, 60.0, 14.5], [nenhum, 100.0, 10.0],
			[zero, 100.0, 0.0], [cinco, 100.0, 40.0]]
	for c: Array in casos:
		var mods: Array[Modificador] = c[0]
		var sim := _sim_com_portador(_portador(mods))
		sim.combate.vida = c[1]
		_um_eco(sim, Vector2(1042.5, 540))
		sim.vivo(Vector2.RIGHT, true)
		assert_int(sim.combate.cortes.size()).is_equal(1)
		assert_float(sim.combate.cortes[0][1]).is_equal_approx(c[2], 0.001)
		assert_float(sim.combate.cortes[0][3]).is_equal(360.0)
		assert_float(sim.combate.cortes[0][4]).is_equal(1.0)


func test_lista_filtrada_pela_ia_inimigo_surgindo() -> void:
	var sim := _sim_fp_corte()
	sim.vivo(Vector2.RIGHT, true)
	sim.vivo()
	_um_eco(sim, Vector2(1042.5, 540))
	sim.vivo()
	assert_int(sim.combate.cortes.size()).is_equal(1)
	var ausente := _sim_fp_corte()
	assert_array(_passos_de_corte(ausente)).is_empty()


func test_corte_nao_e_golpe_so_aplicar_corte() -> void:
	var sim := _sim_fp_corte()
	_um_eco(sim, Vector2(1042.5, 540))
	_passos_de_corte(sim)
	assert_array(sim.combate.pedidos).is_equal(["cancelar", "inv:12", "iniciada", "corte:%d" % ECO_ID])


func test_contexto_do_dano_sem_apos_esquiva_mesmo_com_janela_aberta() -> void:
	var penumbra: Array[Modificador] = [
		Modificador.new(Atributos.DANO_TODO, OP.PERCENTUAL, 0.5, COND.APOS_ESQUIVA, 1.5)]
	var espiao := PortadorEspiao.new(_portador(penumbra))
	var sim := _sim_com_portador(espiao)
	sim.combate.vida = 60.0
	_um_eco(sim, Vector2(1042.5, 540))
	sim.vivo(Vector2.RIGHT, true)
	assert_bool(sim.combate.janela_apos_esquiva).is_true()  # AC-41: aberta no passo 0
	assert_float(sim.combate.cortes[0][1]).is_equal_approx(10.0, 0.001)
	assert_bool(espiao.ultimo_ctx.apos_esquiva).is_false()
	assert_float(espiao.ultimo_ctx.vida_atual).is_equal(60.0)


func test_uma_esquiva_iniciada_por_esquiva_nos_passos_0_e_9() -> void:
	var sim := _sim_fp_corte(2)
	for k in 19:
		sim.vivo(Vector2.RIGHT, k == 0 or k == 4)
	assert_array(sim.inicios).is_equal([0, 9])
	assert_int(sim.combate.pedidos.count("iniciada")).is_equal(2)
