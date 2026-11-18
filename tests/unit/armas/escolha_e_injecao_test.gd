extends GdUnitTestSuite
## Stories armas-das-doutrinas-004, 005 e 007:
## - Story 004: Arma da run — estados, injeção e telemetria (AC-AR-06, 10, 14, 15, 21, 36, 51)
## - Story 005: Pré-seleção, confirmação e preferência `ultima_arma` (AC-AR-08, 09, 11, 39)
## - Story 007: Dados da tela de escolha de arma (AC-AR-12)


class _MovFalso:
	extends MovimentoParaCombate

	func em_esquiva(_player_id: int) -> bool:
		return false

	func deslocar(_player_id: int, _delta: Vector2) -> void:
		pass


class _MaldicoesDisponivel:
	extends MaldicoesParaCombate
	var chamados: Array[Dictionary] = []

	func chamado_disponivel(_player_id: int) -> bool:
		return true

	func pedir_chamado(player_id: int, ponto: Vector2, dano_golpe: float, m_chamado: float) -> void:
		chamados.append({
			&"player_id": player_id,
			&"ponto": ponto,
			&"dano_golpe": dano_golpe,
			&"m_chamado": m_chamado,
		})


func _tuning_mod() -> ModifiersTuning:
	var t := ModifiersTuning.new()
	t.piso_vida_jogador = 20
	t.teto_multiplicador_dano = 4.0
	t.teto_reducao_dano = 0.6
	t.fator_empurrao_chefe = 0.12
	return t


func test_ac_ar_06_e_36_injecao_no_comeco_da_run_e_arma_escolhida_luta() -> void:
	var t_mod: ModifiersTuning = _tuning_mod()
	for id_arma: StringName in [&"lamina", &"ressonancia", &"pactos"]:
		var w_cat: WeaponDef = FabricaDeArmas.por_id(id_arma)
		var vida_orig: int = w_cat.vida_max
		var eventos := EventosDoPasso.new()
		var arma_run := ArmaDaRun.new(eventos)
		assert_int(arma_run.estado()).is_equal(ArmaDaRun.Estado.ESCOLHENDO)
		assert_bool(arma_run.confirmar_para_run(w_cat, 0)).is_true()
		assert_int(arma_run.estado()).is_equal(ArmaDaRun.Estado.EQUIPADA)
		assert_bool(eventos.ha(EvArmaEquipada.TIPO)).is_true()

		var port: Portador = arma_run.criar_portador_do_jogador(1, 0, t_mod)
		assert_int(port.inteiro(Atributos.VIDA_MAX)).is_equal(vida_orig)
		assert_float(port.valor(Atributos.VELOCIDADE)).is_equal_approx(w_cat.velocidade, 1e-6)

		var deps := DependenciasDoCombate.new()
		deps.tuning = FabricaDeArmas.combat_tuning_padrao()
		deps.movimento = _MovFalso.new()
		deps.jogadores.append(ArmaDaRun.montar_jogador_para_combate(arma_run.arma(), port))
		var c: Combate = Combate.criar(deps)
		assert_object(c).is_not_null()
		assert_int(c.recursos(0).vida).is_equal(vida_orig)
		assert_str(String(c.ataque_do_slot(0, 0).forma)).is_equal(String(w_cat.ataque.forma))
		assert_str(String(c.ataque_do_slot(0, 1).forma)).is_equal(String(w_cat.especial.forma))

		# Aplicar bênção +10 Vida no portador não altera o WeaponDef do catálogo
		port.aplicar_fonte(FonteDeModificador.new(&"bencao:vida10", [
			Modificador.new(Atributos.VIDA_MAX, Modificador.Operacao.PLANO, 10.0)
		]))
		assert_int(port.inteiro(Atributos.VIDA_MAX)).is_equal(vida_orig + 10)
		assert_int(w_cat.vida_max).is_equal(vida_orig)


func test_ac_ar_10_estados_e_arma_fixa_durante_a_run() -> void:
	var armazem := ArmazemEmMemoria.new()
	var escolha := EscolhaDeArma.new(FabricaDeArmas.armas_mvp(), armazem, false)
	assert_int(escolha.estado()).is_equal(ArmaDaRun.Estado.ESCOLHENDO)
	assert_str(String(escolha.selecionada())).is_equal("lamina")

	assert_bool(escolha.selecionar(&"ressonancia")).is_true()
	assert_bool(escolha.confirmar()).is_true()
	assert_int(escolha.estado()).is_equal(ArmaDaRun.Estado.EQUIPADA)
	assert_str(String(escolha.confirmada())).is_equal("ressonancia")

	# Durante EQUIPADA, não é possível mudar a seleção nem reconfirmar, e gravar outra arma no disco não altera a equipada
	assert_bool(escolha.selecionar(&"lamina")).is_false()
	armazem.gravar_atomico(EscolhaDeArma.CAMINHO_PREFERENCIAS, "[armas]\nultima_arma=\"lamina\"\n")
	assert_str(String(escolha.confirmada())).is_equal("ressonancia")

	# Fim da run -> ENCERRADA; próxima run abre ESCOLHENDO com a última gravada
	escolha.encerrar_run()
	assert_int(escolha.estado()).is_equal(ArmaDaRun.Estado.ENCERRADA)
	escolha.abrir_escolha()
	assert_int(escolha.estado()).is_equal(ArmaDaRun.Estado.ESCOLHENDO)
	assert_str(String(escolha.selecionada())).is_equal("lamina")


func test_ac_ar_08_e_09_e_11_pre_selecao_confirmar_esc_e_uma_carta() -> void:
	var armas: Array[WeaponDef] = FabricaDeArmas.armas_mvp()

	# 1. Ausente -> lamina, 0 avisos, 0 gravações ao abrir
	var a1 := ArmazemEmMemoria.new()
	var e1 := EscolhaDeArma.new(armas, a1, false)
	assert_str(String(e1.selecionada())).is_equal("lamina")
	assert_array(Array(e1.avisos_debug())).is_empty()
	assert_int(e1.gravacoes_preferencias()).is_equal(0)

	# 2. ultima_arma = "ressonancia" -> ressonancia, 0 avisos
	var a2 := ArmazemEmMemoria.new()
	a2.gravar_atomico(EscolhaDeArma.CAMINHO_PREFERENCIAS, "[armas]\nultima_arma=\"ressonancia\"\n")
	var e2 := EscolhaDeArma.new(armas, a2, false)
	assert_str(String(e2.selecionada())).is_equal("ressonancia")
	assert_array(Array(e2.avisos_debug())).is_empty()

	# 3. Bytes inválidos (corrompido) -> lamina, 1 aviso; confirmar regrava
	var a3 := ArmazemEmMemoria.new()
	a3.gravar_atomico(EscolhaDeArma.CAMINHO_PREFERENCIAS, "<<<corrompido>>>")
	var e3 := EscolhaDeArma.new(armas, a3, false)
	assert_str(String(e3.selecionada())).is_equal("lamina")
	assert_int(e3.avisos_debug().size()).is_equal(1)
	e3.selecionar(&"ressonancia")
	assert_bool(e3.confirmar()).is_true()
	assert_int(e3.gravacoes_preferencias()).is_equal(1)
	var e3_reaberta := EscolhaDeArma.new(armas, a3, false)
	assert_str(String(e3_reaberta.selecionada())).is_equal("ressonancia")

	# 4. Arma fora do catálogo ("adagas_veu") e vazia ("") -> lamina, 1 aviso cada
	for invalida: String in ["adagas_veu", ""]:
		var ax := ArmazemEmMemoria.new()
		ax.gravar_atomico(EscolhaDeArma.CAMINHO_PREFERENCIAS, "[armas]\nultima_arma=\"%s\"\n" % invalida)
		var ex := EscolhaDeArma.new(armas, ax, false)
		assert_str(String(ex.selecionada())).is_equal("lamina")
		assert_int(ex.avisos_debug().size()).is_equal(1)

	# 5. AC-AR-09 Esc: mover seleção e apertar Esc não grava nem entra em EQUIPADA
	var a_esc := ArmazemEmMemoria.new()
	a_esc.gravar_atomico(EscolhaDeArma.CAMINHO_PREFERENCIAS, "[armas]\nultima_arma=\"lamina\"\n")
	var e_esc := EscolhaDeArma.new(armas, a_esc, false)
	e_esc.selecionar(&"ressonancia")
	e_esc.cancelar_esc()
	assert_int(e_esc.gravacoes_preferencias()).is_equal(0)
	assert_int(e_esc.estado()).is_equal(ArmaDaRun.Estado.ESCOLHENDO)
	assert_str(String(EscolhaDeArma.new(armas, a_esc, false).selecionada())).is_equal("lamina")

	# 6. AC-AR-11: catálogo só com 1 carta (lamina) -> 1 carta selecionada e confirmar funciona
	var e_uma := EscolhaDeArma.new([FabricaDeArmas.lamina()], ArmazemEmMemoria.new(), false)
	assert_int(e_uma.montar_cartas_para_tela().size()).is_equal(1)
	assert_bool(e_uma.confirmar()).is_true()


func test_ac_ar_39_build_de_playtest_zero_leituras_e_gravacoes() -> void:
	var armazem := ArmazemEmMemoria.new()
	armazem.gravar_atomico(EscolhaDeArma.CAMINHO_PREFERENCIAS, "[armas]\nultima_arma=\"ressonancia\"\n")
	var escolha := EscolhaDeArma.new(FabricaDeArmas.armas_mvp(), armazem, true)

	assert_str(String(escolha.selecionada())).is_empty()
	assert_int(escolha.leituras_preferencias()).is_equal(0)
	assert_array(Array(escolha.avisos_debug())).is_empty()
	assert_bool(escolha.confirmar()).is_false()
	assert_int(escolha.estado()).is_equal(ArmaDaRun.Estado.ESCOLHENDO)

	assert_bool(escolha.selecionar(&"lamina")).is_true()
	assert_bool(escolha.confirmar()).is_true()
	assert_int(escolha.estado()).is_equal(ArmaDaRun.Estado.EQUIPADA)
	assert_int(escolha.gravacoes_preferencias()).is_equal(0)

	escolha.encerrar_run()
	escolha.abrir_escolha()
	assert_str(String(escolha.selecionada())).is_empty()


func test_ac_ar_12_e_14_e_15_e_51_cartas_da_tela_e_bencaos_de_slot() -> void:
	# AC-AR-12: 3 cartas, velocidade "média" nas 3, aviso na Besta quando sem Maldição
	var escolha := EscolhaDeArma.new(FabricaDeArmas.armas_mvp(), ArmazemEmMemoria.new(), false)
	var cartas_com := escolha.montar_cartas_para_tela(true)
	var cartas_sem := escolha.montar_cartas_para_tela(false)
	assert_int(cartas_com.size()).is_equal(3)
	for c: Dictionary in cartas_com:
		assert_str(String(c[&"velocidade_rotulo"])).is_equal("média")
		assert_bool(String(c[&"ataque_desc"]).is_empty()).is_false()
		assert_bool(String(c[&"especial_desc"]).is_empty()).is_false()
	assert_str(String(cartas_com[2][&"aviso_texto"])).is_empty()
	assert_str(String(cartas_sem[2][&"aviso_texto"])).is_equal("sem Maldição: o Chamado não responde")

	# AC-AR-15: a arma não restringe o pool de bênçãos
	var ar := ArmaDaRun.new()
	ar.confirmar_para_run(FabricaDeArmas.lamina())
	assert_int(ar.filtrar_pool_bencaos(FixtureBn.boons()).size()).is_equal(18)

	# AC-AR-14 e AC-AR-51: bênçãos de slot (+0,25 ataque / +0,25 especial) valem para Lâmina, Ressonância e Besta
	var t_mod: ModifiersTuning = _tuning_mod()
	for par: Array in [
		[FabricaDeArmas.lamina(), 17.5, 32.5],
		[FabricaDeArmas.ressonancia(), 15.0, 37.5],
		[FabricaDeArmas.pactos(), 12.5, 21.25],
	]:
		var w: WeaponDef = par[0]
		var port := Portador.new(1, 0, Atributos.Especie.JOGADOR, {
			Atributos.VIDA_MAX: float(w.vida_max),
			Atributos.VELOCIDADE: w.velocidade,
		}, t_mod)
		port.aplicar_fonte(FonteDeModificador.new(&"b:atk", [
			Modificador.new(Atributos.DANO_ATAQUE, Modificador.Operacao.PERCENTUAL, 0.25)
		]))
		port.aplicar_fonte(FonteDeModificador.new(&"b:esp", [
			Modificador.new(Atributos.DANO_ESPECIAL, Modificador.Operacao.PERCENTUAL, 0.25)
		]))
		var ctx := ContextoDeDano.new(float(w.vida_max), false)
		var m_atk: float = port.multiplicador_de_dano(Modificador.Slot.ATAQUE, ctx)
		var m_esp: float = port.multiplicador_de_dano(Modificador.Slot.ESPECIAL, ctx)
		assert_float(w.ataque.dano * m_atk).is_equal_approx(float(par[1]), 0.001)
		assert_float(w.especial.dano * m_esp).is_equal_approx(float(par[2]), 0.001)
