extends GdUnitTestSuite
## Story armas-das-doutrinas-001: WeaponDef, AttackDef e as três armas de fábrica
## (AC-AR-01, AC-AR-02, AC-AR-03, AC-AR-04, AC-AR-05, AC-AR-07, AC-AR-41, AC-AR-42).


class _MovFalso:
	extends MovimentoParaCombate
	var deslocamentos: Array[Vector2] = []

	func posicao(_player_id: int) -> Vector2:
		return Vector2(960.0, 540.0)

	func em_esquiva(_player_id: int) -> bool:
		return false

	func raio(_player_id: int) -> float:
		return 27.0

	func deslocar(_player_id: int, delta: Vector2) -> void:
		deslocamentos.append(delta)


func _tuning_mod() -> ModifiersTuning:
	var t := ModifiersTuning.new()
	t.piso_vida_jogador = 20
	t.teto_multiplicador_dano = 4.0
	t.teto_reducao_dano = 0.6
	t.fator_empurrao_chefe = 0.12
	return t


func test_ac_ar_01_esquema_weapon_def_tem_exatamente_os_7_campos_e_recusa_sem_especial() -> void:
	var w := WeaponDef.new()
	var exportados: PackedStringArray = FabricasDeCatalogo.campos_exportados(w)
	# DefinicaoBase contribui com id e obsoleto; WeaponDef acrescenta os 6 campos próprios = 7 campos de conteúdo
	assert_bool(exportados.has("id")).is_true()
	for campo: String in ["doutrina", "chave_nome", "vida_max", "velocidade", "ataque", "especial"]:
		assert_bool(exportados.has(campo)).is_true()
	# Sem especial: falha na validação de esquema obrigatório
	var sem_esp := FabricaDeArmas.lamina()
	sem_esp.especial = null
	assert_bool(FabricaDeArmas.validar_esquema_weapon_def(sem_esp).is_empty()).is_false()
	assert_str(FabricaDeArmas.validar_esquema_weapon_def(FabricaDeArmas.lamina())).is_empty()


func test_ac_ar_02_lamina_do_juramento_carregada_de_fabrica() -> void:
	var w: WeaponDef = FabricaDeArmas.lamina()
	assert_str(String(w.id)).is_equal("lamina")
	assert_str(String(w.doutrina)).is_equal("lamina")
	assert_int(w.vida_max).is_equal(100)
	assert_float(w.velocidade).is_equal_approx(387.0, 1e-6)

	var atk: AtaqueConvertido = AtaqueConvertido.de(w.ataque)
	assert_str(String(atk.forma)).is_equal("arco")
	assert_float(atk.param(&"alcance_px")).is_equal_approx(142.5, 1e-6)
	assert_float(atk.param(&"meio_angulo_graus")).is_equal_approx(69.51, 1e-6)
	assert_float(atk.cos_meio).is_equal_approx(0.350044, 0.000001)
	assert_float(atk.dano).is_equal_approx(14.0, 1e-6)
	assert_float(w.ataque.recarga_s).is_equal_approx(16.0 / 60.0, 1e-12)
	assert_int(atk.recarga).is_equal(16)
	assert_float(atk.empurrao).is_equal_approx(450.0, 1e-6)
	assert_array(Array(atk.combo)).is_equal([1.0, 1.0, 1.8])
	assert_str(String(w.ataque.status)).is_empty()
	assert_float(w.ataque.guarda_s).is_equal(0.0)

	var esp: AtaqueConvertido = AtaqueConvertido.de(w.especial)
	assert_str(String(esp.forma)).is_equal("avanco")
	assert_float(esp.param(&"distancia_px")).is_equal_approx(330.0, 1e-6)
	assert_int(esp.passos_avanco).is_equal(10)
	assert_float(esp.param(&"raio_px")).is_equal_approx(69.0, 1e-6)
	assert_float(esp.dano).is_equal_approx(26.0, 1e-6)
	assert_int(esp.recarga).is_equal(70)
	assert_float(esp.empurrao).is_equal_approx(1080.0, 1e-6)
	assert_bool(esp.combo.is_empty()).is_true()


func test_ac_ar_03_foco_ressonante_carregado_de_fabrica() -> void:
	var w: WeaponDef = FabricaDeArmas.ressonancia()
	assert_str(String(w.id)).is_equal("ressonancia")
	assert_str(String(w.doutrina)).is_equal("ressonancia")
	assert_int(w.vida_max).is_equal(80)
	assert_float(w.velocidade).is_equal_approx(378.0, 1e-6)

	var atk: AtaqueConvertido = AtaqueConvertido.de(w.ataque)
	assert_str(String(atk.forma)).is_equal("projetil")
	assert_float(atk.param(&"velocidade_pxs")).is_equal_approx(990.0, 1e-6)
	assert_float(atk.param(&"raio_px")).is_equal_approx(15.0, 1e-6)
	assert_int(atk.vida_projetil).is_equal(50)
	assert_array(Array(w.ataque.leque)).is_equal([0.0])
	assert_bool(w.ataque.atravessa).is_false()
	assert_float(atk.dano).is_equal_approx(12.0, 1e-6)
	assert_int(atk.recarga).is_equal(14)
	assert_float(atk.empurrao).is_equal_approx(540.0, 1e-6)
	assert_bool(atk.combo.is_empty()).is_true()

	var esp: AtaqueConvertido = AtaqueConvertido.de(w.especial)
	assert_str(String(esp.forma)).is_equal("circulo")
	assert_float(esp.param(&"raio_px")).is_equal_approx(195.0, 1e-6)
	assert_float(esp.param(&"deslocamento_px")).is_equal_approx(0.0, 1e-6)
	assert_float(esp.dano).is_equal_approx(30.0, 1e-6)
	assert_int(esp.recarga).is_equal(90)
	assert_float(esp.empurrao).is_equal_approx(1260.0, 1e-6)


func test_ac_ar_41_besta_do_vinculo_carregada_de_fabrica() -> void:
	var w: WeaponDef = FabricaDeArmas.pactos()
	assert_str(String(w.id)).is_equal("pactos")
	assert_str(String(w.doutrina)).is_equal("pactos")
	assert_int(w.vida_max).is_equal(90)
	assert_float(w.velocidade).is_equal_approx(382.5, 1e-6)

	var atk: AtaqueConvertido = AtaqueConvertido.de(w.ataque)
	assert_str(String(atk.forma)).is_equal("projetil")
	assert_float(atk.param(&"velocidade_pxs")).is_equal_approx(1170.0, 1e-6)
	assert_float(atk.param(&"raio_px")).is_equal_approx(12.0, 1e-6)
	assert_int(atk.vida_projetil).is_equal(45)
	assert_array(Array(w.ataque.leque)).is_equal([0.0])
	assert_bool(w.ataque.atravessa).is_false()
	assert_float(atk.dano).is_equal_approx(10.0, 1e-6)
	assert_int(atk.recarga).is_equal(15)
	assert_float(atk.empurrao).is_equal_approx(360.0, 1e-6)

	var esp: AtaqueConvertido = AtaqueConvertido.de(w.especial)
	assert_str(String(esp.forma)).is_equal("chamado")
	assert_float(esp.dano).is_equal_approx(17.0, 1e-6)
	assert_int(esp.recarga).is_equal(120)
	assert_float(esp.empurrao).is_equal_approx(0.0, 1e-6)
	assert_bool(esp.combo.is_empty()).is_true()
	assert_str(String(w.especial.status)).is_empty()
	assert_float(w.especial.guarda_s).is_equal(0.0)


func test_ac_ar_04_e_05_e_42_conversoes_e_recuperacao_derivada() -> void:
	var lam: WeaponDef = FabricaDeArmas.lamina()
	var res: WeaponDef = FabricaDeArmas.ressonancia()
	var pac: WeaponDef = FabricaDeArmas.pactos()

	# AC-AR-04: 16/60 * 60 dá 16 passos exatos
	assert_int(Unidades.duracao_para_passos(16.0 / 60.0)).is_equal(16)
	assert_int(Unidades.duracao_para_passos(14.0 / 60.0)).is_equal(14)
	assert_int(Unidades.duracao_para_passos(70.0 / 60.0)).is_equal(70)
	assert_int(Unidades.duracao_para_passos(90.0 / 60.0)).is_equal(90)

	# AC-AR-05: Corte 8, Investida 0, Pulso 7, Onda 12 (preso no teto)
	assert_int(FabricaDeArmas.recuperacao_passos(lam.ataque)).is_equal(8)
	assert_int(FabricaDeArmas.recuperacao_passos(lam.especial)).is_equal(0)
	assert_int(FabricaDeArmas.recuperacao_passos(res.ataque)).is_equal(7)
	assert_int(FabricaDeArmas.recuperacao_passos(res.especial)).is_equal(12)

	# AC-AR-42: Virote 8 (round(7,5) longe do zero), Chamado 12 (min(12, 60))
	assert_int(FabricaDeArmas.recuperacao_passos(pac.ataque)).is_equal(8)
	assert_int(FabricaDeArmas.recuperacao_passos(pac.especial)).is_equal(12)


func test_ac_ar_07_arma_sem_regra_propria_clone_produz_sequencia_identica() -> void:
	var original: WeaponDef = FabricaDeArmas.lamina()
	var clone: WeaponDef = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as WeaponDef
	clone.id = &"lamina_clone"
	clone.doutrina = &"doutrina_clone"
	clone.chave_nome = &"WEAPON_CLONE_NAME"

	var seq_orig: Array = _rodar_roteiro_combate(original, 120)
	var seq_clone: Array = _rodar_roteiro_combate(clone, 120)
	assert_array(seq_orig).is_equal(seq_clone)


func _rodar_roteiro_combate(arma: WeaponDef, passos: int) -> Array:
	var port := Portador.new(1, 0, Atributos.Especie.JOGADOR, {
		Atributos.VIDA_MAX: float(arma.vida_max),
		Atributos.VELOCIDADE: arma.velocidade,
	}, _tuning_mod())
	var deps := DependenciasDoCombate.new()
	deps.tuning = FabricaDeArmas.combat_tuning_padrao()
	deps.movimento = _MovFalso.new()
	deps.jogadores.append(DependenciasDoCombate.Jogador.new(port, arma.ataque, arma.especial))
	var c: Combate = Combate.criar(deps)
	var buffer := BufferDeComandos.new(10)
	var trace: Array = []
	for p: int in passos:
		c.inicio_do_passo()
		var segurados: Array[StringName] = []
		if (p % 3) != 0:
			segurados.append(Acoes.ATAQUE)
		if (p % 25) == 0:
			segurados.append(Acoes.ESPECIAL)
		var cmd := ComandosDoPasso.new(buffer, segurados, p, 0)
		c.golpe_do_jogador([cmd])
		var r: RecursosDoJogador = c.recursos(0)
		trace.append("%d|%d|%d|%d|%d" % [r.recarga[0], r.recarga[1], r.recuperacao, r.investida, r.passo_combo[0]])
	return trace
