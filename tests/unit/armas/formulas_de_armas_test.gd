extends GdUnitTestSuite
## Story armas-das-doutrinas-003: Fórmulas de referência das armas (F1–F7)
## (AC-AR-16, AC-AR-17, AC-AR-18, AC-AR-19, AC-AR-20, AC-AR-22, AC-AR-40, AC-AR-47, AC-AR-48).


func test_ac_ar_16_e_40_f1_dps_de_referencia_e_teto_de_m() -> void:
	var lam: WeaponDef = FabricaDeArmas.lamina()
	var res: WeaponDef = FabricaDeArmas.ressonancia()

	var corte: Dictionary = FormulasDeArmas.dps_golpe(lam.ataque, 1.0)
	var inv: Dictionary = FormulasDeArmas.dps_golpe(lam.especial, 1.0)
	var lam_comb: Dictionary = FormulasDeArmas.dps_combinado(lam, 1.0, 1.0)
	assert_float(float(corte[&"dps_vivo"])).is_equal_approx(66.500, 0.001)
	assert_float(float(corte[&"dps_real"])).is_equal_approx(53.200, 0.001)
	assert_float(float(inv[&"dps_vivo"])).is_equal_approx(22.286, 0.001)
	assert_float(float(inv[&"dps_real"])).is_equal_approx(20.526, 0.001)
	assert_float(float(lam_comb[&"k"])).is_equal_approx(4.375, 0.001)
	assert_float(float(lam_comb[&"d_ciclo"])).is_equal_approx(103.583, 0.001)
	assert_float(float(lam_comb[&"h_ciclo"])).is_equal_approx(23.5, 0.001)
	assert_float(float(lam_comb[&"dps_vivo"])).is_equal_approx(88.786, 0.001)
	assert_float(float(lam_comb[&"dps_real"])).is_equal_approx(66.471, 0.001)

	var pulso: Dictionary = FormulasDeArmas.dps_golpe(res.ataque, 1.0)
	var onda: Dictionary = FormulasDeArmas.dps_golpe(res.especial, 1.0)
	var res_comb: Dictionary = FormulasDeArmas.dps_combinado(res, 1.0, 1.0)
	assert_float(float(pulso[&"dps_vivo"])).is_equal_approx(51.429, 0.001)
	assert_float(float(pulso[&"dps_real"])).is_equal_approx(51.429, 0.001)
	assert_float(float(onda[&"dps_vivo"])).is_equal_approx(20.000, 0.001)
	assert_float(float(onda[&"dps_real"])).is_equal_approx(18.750, 0.001)
	assert_float(float(res_comb[&"k"])).is_equal_approx(6.4286, 0.001)
	assert_float(float(res_comb[&"d_ciclo"])).is_equal_approx(107.143, 0.001)
	assert_float(float(res_comb[&"h_ciclo"])).is_equal_approx(6.0, 0.001)
	assert_float(float(res_comb[&"dps_vivo"])).is_equal_approx(71.429, 0.001)
	assert_float(float(res_comb[&"dps_real"])).is_equal_approx(66.964, 0.001)

	# Com M = 1,3 a razão Lâmina/Ressonância não muda
	var lam_13: Dictionary = FormulasDeArmas.dps_combinado(lam, 1.3, 1.3)
	var res_13: Dictionary = FormulasDeArmas.dps_combinado(res, 1.3, 1.3)
	var razao_1: float = float(lam_comb[&"dps_real"]) / float(res_comb[&"dps_real"])
	var razao_13: float = float(lam_13[&"dps_real"]) / float(res_13[&"dps_real"])
	assert_float(razao_13).is_equal_approx(razao_1, 0.0001)

	# AC-AR-40: teto de M = 4,0 -> DPS máximo Lâmina = 66,471 * 4 = 265,882 (±0,01)
	var lam_max: Dictionary = FormulasDeArmas.dps_combinado(lam, 6.0, 6.0, null, 4.0)
	assert_float(float(lam_max[&"dps_real"])).is_equal_approx(265.882, 0.01)
	assert_float(FormulasDeArmas.ttk_chefe_continuo(float(lam_max[&"dps_real"]), 700.0)).is_equal_approx(2.63, 0.01)


func test_ac_ar_17_f2_ttk_chefe_paridade_e_folga() -> void:
	var lam: WeaponDef = FabricaDeArmas.lamina()
	var res: WeaponDef = FabricaDeArmas.ressonancia()

	var ttk_lam_comb: float = FormulasDeArmas.ttk_chefe_continuo(float(FormulasDeArmas.dps_combinado(lam)[&"dps_real"]))
	var ttk_res_comb: float = FormulasDeArmas.ttk_chefe_continuo(float(FormulasDeArmas.dps_combinado(res)[&"dps_real"]))
	assert_float(ttk_lam_comb).is_equal_approx(10.5310, 0.001)
	assert_float(ttk_res_comb).is_equal_approx(10.4533, 0.001)
	assert_float(FormulasDeArmas.paridade_ttk(ttk_lam_comb, ttk_res_comb)).is_equal_approx(0.0074, 0.0001)

	var ttk_lam_atk: float = FormulasDeArmas.ttk_chefe_continuo(float(FormulasDeArmas.dps_golpe(lam.ataque)[&"dps_real"]))
	var ttk_res_atk: float = FormulasDeArmas.ttk_chefe_continuo(float(FormulasDeArmas.dps_golpe(res.ataque)[&"dps_real"]))
	assert_float(ttk_lam_atk).is_equal_approx(13.1579, 0.001)
	assert_float(ttk_res_atk).is_equal_approx(13.6111, 0.001)
	assert_float(FormulasDeArmas.paridade_ttk(ttk_lam_atk, ttk_res_atk)).is_equal_approx(0.0344, 0.0001)

	var disc_lam: Dictionary = FormulasDeArmas.ttk_ataque_discreto(lam, 700.0)
	var disc_res: Dictionary = FormulasDeArmas.ttk_ataque_discreto(res, 700.0)
	assert_int(int(disc_lam[&"g"])).is_equal(40)
	assert_int(int(disc_lam[&"passos"])).is_equal(780)
	assert_int(int(disc_res[&"g"])).is_equal(59)
	assert_int(int(disc_res[&"passos"])).is_equal(812)

	var folga: Dictionary = FormulasDeArmas.folga_dano_pulso(lam, res, 0.15)
	assert_float(float(folga[&"min_so_ataque"])).is_equal_approx(10.80, 0.01)
	assert_float(float(folga[&"max_so_ataque"])).is_equal_approx(14.27, 0.01)
	assert_float(float(folga[&"min_combinado"])).is_equal_approx(9.72, 0.01)
	assert_float(float(folga[&"max_combinado"])).is_equal_approx(14.35, 0.01)


func test_ac_ar_18_f3_vida_por_profundidade_e_golpes_ate_matar() -> void:
	var vidas_eco: Array[int] = []
	var vidas_anom: Array[int] = []
	var vidas_fenda: Array[int] = []
	for p: int in range(0, 8):
		vidas_eco.append(FormulasDeArmas.vida_por_profundidade(30.0, p, false))
		vidas_anom.append(FormulasDeArmas.vida_por_profundidade(24.0, p, false))
		vidas_fenda.append(FormulasDeArmas.vida_por_profundidade(46.0, p, false))
	assert_array(vidas_eco).is_equal([30, 32, 33, 35, 36, 38, 39, 41])
	assert_array(vidas_anom).is_equal([24, 25, 26, 28, 29, 30, 31, 32])
	assert_array(vidas_fenda).is_equal([46, 48, 51, 53, 55, 58, 60, 62])

	var elites_eco: Array[int] = []
	var elites_fenda: Array[int] = []
	for p: int in range(3, 8):
		elites_eco.append(FormulasDeArmas.vida_por_profundidade(30.0, p, true))
		elites_fenda.append(FormulasDeArmas.vida_por_profundidade(46.0, p, true))
	assert_array(elites_eco).is_equal([83, 86, 90, 94, 97])
	assert_array(elites_fenda).is_equal([127, 132, 138, 144, 149])

	var lam: WeaponDef = FabricaDeArmas.lamina()
	var res: WeaponDef = FabricaDeArmas.ressonancia()
	# Onda x Eco em p = 0 (30 = 30 -> g = 1, margem = 0) e p = 1 (32 -> g = 2, falta = 2)
	var onda_eco_0: Dictionary = FormulasDeArmas.golpes_ate_matar(res.especial, 30)
	var onda_eco_1: Dictionary = FormulasDeArmas.golpes_ate_matar(res.especial, 32)
	assert_int(int(onda_eco_0[&"g"])).is_equal(1)
	assert_float(float(onda_eco_0[&"margem"])).is_equal_approx(0.0, 0.001)
	assert_int(int(onda_eco_1[&"g"])).is_equal(2)
	assert_float(float(onda_eco_1[&"falta"])).is_equal_approx(2.0, 0.001)

	# Corte x Fenda em p = 3 (53 -> g = 3, margem = 0,2) e p = 4 (55 -> g = 4, falta = 1,8)
	var corte_fenda_3: Dictionary = FormulasDeArmas.golpes_ate_matar(lam.ataque, 53)
	var corte_fenda_4: Dictionary = FormulasDeArmas.golpes_ate_matar(lam.ataque, 55)
	assert_int(int(corte_fenda_3[&"g"])).is_equal(3)
	assert_float(float(corte_fenda_3[&"margem"])).is_equal_approx(0.2, 0.001)
	assert_int(int(corte_fenda_4[&"g"])).is_equal(4)
	assert_float(float(corte_fenda_4[&"falta"])).is_equal_approx(1.8, 0.001)


func test_ac_ar_19_e_20_e_22_f4_f5_f6() -> void:
	# AC-AR-19: F4 golpes recebidos até morrer contra o Chefe (dano 16)
	var lam_chefe: Dictionary = FormulasDeArmas.golpes_ate_morrer(100, 16.0, false)
	var res_chefe: Dictionary = FormulasDeArmas.golpes_ate_morrer(80, 16.0, false)
	var res_81: Dictionary = FormulasDeArmas.golpes_ate_morrer(81, 16.0, false)
	assert_int(int(lam_chefe[&"g_morte"])).is_equal(7)
	assert_int(int(lam_chefe[&"tempo_min_passos"])).is_equal(240)
	assert_int(int(res_chefe[&"g_morte"])).is_equal(5)
	assert_int(int(res_chefe[&"tempo_min_passos"])).is_equal(160)
	assert_int(int(res_81[&"g_morte"])).is_equal(6)

	# AC-AR-20: F5 empurrão do Pulso (540 px/s, R = 14)
	var emp_comum: Dictionary = FormulasDeArmas.empurrao_efetivo(540.0, 1.0, 14)
	var emp_elite: Dictionary = FormulasDeArmas.empurrao_efetivo(540.0, 0.4, 14)
	var emp_chefe: Dictionary = FormulasDeArmas.empurrao_efetivo(540.0, 0.12, 14)
	assert_int(int(emp_comum[&"passos"])).is_equal(20)
	assert_float(float(emp_comum[&"distancia_px"])).is_equal_approx(40.62, 0.01)
	assert_float(float(emp_comum[&"v_sust"])).is_equal_approx(557.20, 0.01)
	assert_float(float(emp_comum[&"teto_av5"])).is_equal_approx(610.56, 0.01)
	assert_int(int(emp_elite[&"passos"])).is_equal(16)
	assert_float(float(emp_elite[&"distancia_px"])).is_equal_approx(16.06, 0.01)
	assert_int(int(emp_chefe[&"passos"])).is_equal(11)
	assert_float(float(emp_chefe[&"distancia_px"])).is_equal_approx(4.59, 0.01)

	# AC-AR-22: F6 fração do Especial
	var f_lam: Dictionary = FormulasDeArmas.fracao_especial(FabricaDeArmas.lamina(), 0.25)
	var f_res: Dictionary = FormulasDeArmas.fracao_especial(FabricaDeArmas.ressonancia(), 0.25)
	assert_float(float(f_lam[&"f_esp"])).is_equal_approx(0.2510, 0.0001)
	assert_float(float(f_res[&"f_esp"])).is_equal_approx(0.2800, 0.0001)
	assert_float(float(f_lam[&"ganho_especial_pct"])).is_equal_approx(0.0628, 0.0001)
	assert_float(float(f_lam[&"ganho_ataque_pct"])).is_equal_approx(0.1872, 0.0001)


func test_ac_ar_47_e_48_f7_dps_composto_e_contas_da_besta() -> void:
	var besta: WeaponDef = FabricaDeArmas.pactos()
	var mt: MaldicoesTuning = FabricasDeCatalogo.maldicoes_tuning()
	var vulto: CurseDef = FabricasDeCatalogo.maldicao(&"vulto_mudo", &"comum")
	var esp: CurseDef = FabricasDeCatalogo.maldicao(&"espreitador_da_fenda", &"refinado")

	# F7 com os valores da emenda Pactos (2026-11-15): piso Vulto 64,70 DPS, Espreitador 65,024 DPS, teto 69,35 DPS
	var piso_vulto: Dictionary = FormulasDeArmas.dps_composto_pactos(besta, vulto, mt, 700.0, false)
	var piso_esp: Dictionary = FormulasDeArmas.dps_composto_pactos(besta, esp, mt, 700.0, false)
	# Nível 5 de vínculo: DPS autônomo do Espreitador = 19,28 (Vínculo F4)
	var teto_esp: Dictionary = FormulasDeArmas.dps_composto_pactos(besta, esp, mt, 700.0, true, 0.05, 19.28)
	var sem_mald: Dictionary = FormulasDeArmas.dps_composto_pactos(besta, null, mt, 700.0, false)

	assert_float(float(piso_vulto[&"dps_arma"])).is_equal_approx(48.500, 0.001)
	assert_float(float(piso_vulto[&"dps_pactos"])).is_equal_approx(64.700, 0.001)
	assert_float(float(piso_vulto[&"ttk"])).is_equal_approx(10.8192, 0.001)
	assert_float(float(piso_vulto[&"f_besta"])).is_equal_approx(0.6182, 0.0001)

	assert_float(float(piso_esp[&"dps_pactos"])).is_equal_approx(65.024, 0.001)
	assert_float(float(piso_esp[&"ttk"])).is_equal_approx(10.7653, 0.001)
	assert_float(float(piso_esp[&"f_besta"])).is_equal_approx(0.6152, 0.0001)

	assert_float(float(teto_esp[&"dps_pactos"])).is_equal_approx(69.352, 0.01)
	assert_float(float(teto_esp[&"ttk"])).is_equal_approx(10.0937, 0.001)
	assert_float(float(teto_esp[&"f_besta"])).is_equal_approx(0.5768, 0.0001)

	assert_float(float(sem_mald[&"dps_pactos"])).is_equal_approx(40.000, 0.001)
	assert_float(float(sem_mald[&"ttk"])).is_equal_approx(17.5000, 0.001)

	# AC-AR-48: F4 com Vida 90 -> 10, 9, 12, 9, 7, 6, 6; F5b Virote (360 px/s, R = 15) e alcance 894 px
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 9.0, false)[&"g_morte"])).is_equal(10)
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 9.0, true)[&"g_morte"])).is_equal(9)
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 8.0, false)[&"g_morte"])).is_equal(12)
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 8.0, true)[&"g_morte"])).is_equal(9)
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 13.0, false)[&"g_morte"])).is_equal(7)
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 13.0, true)[&"g_morte"])).is_equal(6)
	assert_int(int(FormulasDeArmas.golpes_ate_morrer(90, 16.0, false)[&"g_morte"])).is_equal(6)

	var emp_virote: Dictionary = FormulasDeArmas.empurrao_efetivo(360.0, 1.0, 15)
	assert_int(int(emp_virote[&"passos"])).is_equal(18)
	assert_float(float(emp_virote[&"distancia_px"])).is_equal_approx(26.96, 0.01)
	assert_float(float(emp_virote[&"v_sust"])).is_equal_approx(368.88, 0.01)
	assert_float(float(emp_virote[&"teto_av5"])).is_equal_approx(614.84, 0.01)
	assert_float(FormulasDeArmas.alcance_testado_projetil_px(besta.ataque)).is_equal_approx(894.0, 0.01)
