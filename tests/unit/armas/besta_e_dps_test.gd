extends GdUnitTestSuite
## Stories armas-das-doutrinas-006 e 008:
## - Story 006: Besta do Vínculo — Virote, evento `acerto_virote`, Chamado e recusa (AC-AR-43 a AC-AR-46)
## - Story 008: Verificação de fogo contínuo do Pulso (AC-AR-21) e DPS medido em run de 600 passos (AC-AR-35)


class _MovFalso:
	extends MovimentoParaCombate

	func posicao(_player_id: int) -> Vector2:
		return Vector2(960.0, 540.0)

	func em_esquiva(_player_id: int) -> bool:
		return false

	func raio(_player_id: int) -> float:
		return 27.0

	func deslocar(_player_id: int, _delta: Vector2) -> void:
		pass


class _MaldicoesDuble:
	extends MaldicoesParaCombate
	var disponivel: bool = true
	var pedidos: Array[Dictionary] = []

	func chamado_disponivel(_player_id: int) -> bool:
		return disponivel

	func pedir_chamado(player_id: int, ponto: Vector2, dano_golpe: float, m_chamado: float) -> void:
		pedidos.append({
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


func _criar_combate(arma: WeaponDef, mald: MaldicoesParaCombate = null) -> Combate:
	var port := Portador.new(1, 0, Atributos.Especie.JOGADOR, {
		Atributos.VIDA_MAX: float(arma.vida_max),
		Atributos.VELOCIDADE: arma.velocidade,
	}, _tuning_mod())
	var deps := DependenciasDoCombate.new()
	deps.tuning = FabricaDeArmas.combat_tuning_padrao()
	deps.movimento = _MovFalso.new()
	deps.maldicoes = mald
	deps.jogadores.append(DependenciasDoCombate.Jogador.new(port, arma.ataque, arma.especial))
	return Combate.criar(deps)


func test_ac_ar_43_e_44_virote_sem_hitstop_e_evento_acerto_virote() -> void:
	var besta: WeaponDef = FabricaDeArmas.pactos()
	# AC-AR-43: Virote é golpe de arma sem hitstop, empurrão 360 (< 630 parede, < 900 pesado)
	assert_float(FormulasDeArmas.hitstop_medio_golpe(besta.ataque)).is_equal(0.0)
	assert_bool(besta.ataque.atravessa).is_false()
	assert_float(besta.ataque.dano).is_equal(10.0)

	# AC-AR-44: filtro acerto_virote emite para alvos 5 (normal), 2 (M = 0) e 7 (abate),
	# e nunca para o Chamado (id 9, de_arma falso, slot Especial) nem para a Lâmina
	var eventos := EventosDoPasso.new()
	assert_bool(BestaDoVinculo.registrar_impacto_para_marca(&"pactos", RecursosDoJogador.SLOT_ATAQUE, true, 5, 0, 10, eventos)).is_true()
	assert_bool(BestaDoVinculo.registrar_impacto_para_marca(&"pactos", RecursosDoJogador.SLOT_ATAQUE, true, 2, 0, 11, eventos)).is_true()
	assert_bool(BestaDoVinculo.registrar_impacto_para_marca(&"pactos", RecursosDoJogador.SLOT_ATAQUE, true, 7, 0, 12, eventos)).is_true()
	assert_bool(BestaDoVinculo.registrar_impacto_para_marca(&"pactos", RecursosDoJogador.SLOT_ESPECIAL, false, 9, 0, 13, eventos)).is_false()
	assert_bool(BestaDoVinculo.registrar_impacto_para_marca(&"lamina", RecursosDoJogador.SLOT_ATAQUE, true, 5, 0, 14, eventos)).is_false()

	var emitidos: Array[EventoDoPasso] = eventos.do_tipo(EvAcertoVirote.TIPO)
	assert_int(emitidos.size()).is_equal(3)
	assert_int((emitidos[0] as EvAcertoVirote).alvo).is_equal(5)
	assert_int((emitidos[1] as EvAcertoVirote).alvo).is_equal(2)
	assert_int((emitidos[2] as EvAcertoVirote).alvo).is_equal(7)


func test_ac_ar_45_e_46_chamado_dispara_salto_e_recusa_nao_gasta_recarga() -> void:
	var mald := _MaldicoesDuble.new()
	var c: Combate = _criar_combate(FabricaDeArmas.pactos(), mald)
	var buffer := BufferDeComandos.new(10)

	# AC-AR-45: cursor em (1460, 540) a 500 px de (960, 540) -> ponto alvo limitado a 420 px = (1380, 540)
	var ponto_alvo: Vector2 = BestaDoVinculo.calcular_ponto_chamado(Vector2(960.0, 540.0), Vector2.RIGHT, Vector2(1460.0, 540.0), true, 420.0)
	assert_float(ponto_alvo.x).is_equal_approx(1380.0, 0.01)
	assert_float(ponto_alvo.y).is_equal_approx(540.0, 0.01)
	# Gamepad com mira (0, 1) -> (960, 960)
	var ponto_pad: Vector2 = BestaDoVinculo.calcular_ponto_chamado(Vector2(960.0, 540.0), Vector2.DOWN, Vector2.ZERO, false, 420.0)
	assert_float(ponto_pad.x).is_equal_approx(960.0, 0.01)
	assert_float(ponto_pad.y).is_equal_approx(960.0, 0.01)

	c.definir_mira(0, Vector2.RIGHT, ponto_alvo)
	buffer.atualizar([Acoes.ESPECIAL], 0, 0, false)
	c.golpe_do_jogador([ComandosDoPasso.new(buffer, [Acoes.ESPECIAL], 0, 0)])
	assert_int(mald.pedidos.size()).is_equal(1)
	assert_int(c.recursos(0).recarga[1]).is_equal(120)
	assert_int(c.hitstop_restante()).is_equal(0)

	# AC-AR-46: sem Maldição em campo (ou Saltando), o Chamado é recusado:
	# recarga fica 0, recuperação fica 0, sai 1 chamado_indisponivel por toque novo, e o Virote sai no mesmo passo!
	var mald_indisp := _MaldicoesDuble.new()
	mald_indisp.disponivel = false
	var c_rec: Combate = _criar_combate(FabricaDeArmas.pactos(), mald_indisp)
	var buf_rec := BufferDeComandos.new(10)
	var eventos := EventosDoPasso.new()
	buf_rec.atualizar([Acoes.ESPECIAL], 0, 0, false)
	c_rec.golpe_do_jogador([ComandosDoPasso.new(buf_rec, [Acoes.ESPECIAL, Acoes.ATAQUE], 0, 0)])
	assert_int(BestaDoVinculo.emitir_recusas_do_passo(c_rec, eventos)).is_equal(1)
	assert_int(c_rec.recursos(0).recarga[1]).is_equal(0)
	# Virote disparou no mesmo passo (recarga do Ataque foi a 15)
	assert_int(c_rec.recursos(0).recarga[0]).is_equal(15)

	# Segurar Especial por mais 5 passos sem novo toque não repete chamado_indisponivel
	for p: int in range(1, 6):
		c_rec.inicio_do_passo()
		buf_rec.atualizar([], p, 0, false)
		c_rec.golpe_do_jogador([ComandosDoPasso.new(buf_rec, [Acoes.ESPECIAL], p, 0)])
		assert_int(BestaDoVinculo.emitir_recusas_do_passo(c_rec, eventos)).is_equal(0)


func test_ac_ar_21_e_35_fogo_continuo_pulso_e_dps_medido_600_passos() -> void:
	# AC-AR-21: em fogo contínuo do Pulso (540 px/s, R = 14), a velocidade sustentada nunca atinge parede_vel_min (630)
	var emp: Dictionary = FormulasDeArmas.empurrao_efetivo(540.0, 1.0, 14)
	assert_bool(float(emp[&"v_sust"]) < 630.0).is_true()
	var emp_650: Dictionary = FormulasDeArmas.empurrao_efetivo(650.0, 1.0, 14)
	assert_bool(float(emp_650[&"v_sust"]) >= 630.0).is_true()

	# AC-AR-35: simulação discreta de 600 passos do roteiro "jogador perfeito" (Lâmina e Ressonância)
	var res_lam: Dictionary = _simular_dps_600_passos(FabricaDeArmas.lamina())
	var res_res: Dictionary = _simular_dps_600_passos(FabricaDeArmas.ressonancia())
	assert_int(int(res_lam[&"especiais"])).is_equal(6)
	assert_int(int(res_res[&"especiais"])).is_equal(6)
	assert_float(float(res_lam[&"dps"])).is_equal_approx(66.28, 1.0)
	assert_float(float(res_res[&"dps"])).is_equal_approx(67.20, 1.0)


func _simular_dps_600_passos(arma: WeaponDef) -> Dictionary:
	var c: Combate = _criar_combate(arma)
	var ct: CombatTuning = FabricaDeArmas.combat_tuning_padrao()
	var h_leve: int = Unidades.duracao_para_passos(ct.hitstop_leve_s)
	var h_pesado: int = Unidades.duracao_para_passos(ct.hitstop_pesado_s)
	var buffer := BufferDeComandos.new(10)
	var dano_total: float = 0.0
	var especiais: int = 0
	var ultimo_vivo_teve_ataque: bool = false

	for p: int in 600:
		if c.hitstop_ativo():
			c.passo_congelado_do_combate()
			continue
		c.inicio_do_passo()
		var r: RecursosDoJogador = c.recursos(0)
		var quer_esp: bool = (r.recarga[1] == 0) and ultimo_vivo_teve_ataque and (r.investida == 0)
		var apertados: Array[StringName] = []
		var segurados: Array[StringName] = [Acoes.ATAQUE]
		if quer_esp:
			apertados.append(Acoes.ESPECIAL)
			segurados.append(Acoes.ESPECIAL)
		buffer.atualizar(apertados, p, 0, false)
		var cmd := ComandosDoPasso.new(buffer, segurados, p, 0)
		c.golpe_do_jogador([cmd])
		ultimo_vivo_teve_ataque = false
		for d: EstadoDeGolpe in c.disparos_do_passo():
			dano_total += d.dano_golpe
			if d.slot == RecursosDoJogador.SLOT_ESPECIAL:
				especiais += 1
				c._pedir_hitstop(h_pesado)
			else:
				ultimo_vivo_teve_ataque = true
				if d.ataque.forma != AtaqueConvertido.FORMA_PROJETIL:
					c._pedir_hitstop(h_pesado if d.pesado else h_leve)
	return {
		&"dano_total": dano_total,
		&"dps": dano_total * 60.0 / 600.0,
		&"especiais": especiais,
	}
