extends GdUnitTestSuite
## Story conteudo-005: unidades do Godot e F1–F8 (AC-19, AC-28..AC-33, AC-35, AC-36).
## Os números são os exemplos do GDD (boundary/example values: o número É o ponto).

const TOL := 1e-6


func _curva(base: float, slope: float, x_min: float, piso: float, teto: float) -> LinearCurveDef:
	var c := LinearCurveDef.new()
	c.base = base
	c.slope = slope
	c.x_min = x_min
	c.y_floor = piso
	c.y_cap = teto
	return c


func test_f1_ticks_para_segundos_exemplos_do_gdd() -> void:
	assert_float(Unidades.ticks_para_segundos(16)).is_equal_approx(0.266667, 1e-6)
	assert_float(Unidades.ticks_para_segundos(26)).is_equal_approx(0.433333, 1e-6)
	assert_float(Unidades.ticks_para_segundos(0)).is_equal(0.0)
	assert_float(Unidades.ticks_para_segundos(16)).is_equal(16.0 / 60.0)


func test_f2_f3_conversoes_de_velocidade_e_taxa_exemplos_do_gdd() -> void:
	var casos_v := {1.7: 153.0, 4.3: 387.0, 11.0: 990.0, 5.0: 450.0, 4.0: 360.0, 7.0: 630.0}
	for v: float in casos_v:
		assert_float(Unidades.velocidade_para_pxs(v)).is_equal_approx(casos_v[v], TOL)
	var casos_r := {0.06: 3.6, 0.12: 7.2, 0.04: 2.4}
	for r: float in casos_r:
		assert_float(Unidades.taxa_por_segundo(r)).is_equal_approx(casos_r[r], TOL)


func test_f4_distancia_e_escala_nao_uniforme_recusa() -> void:
	assert_float(Unidades.unidade_para_px(95.0)).is_equal_approx(142.5, TOL)
	assert_bool(Unidades.escala_uniforme(1280.0, 720.0)).is_true()
	assert_bool(Unidades.escala_uniforme(1280.0, 800.0)).is_false()


func test_f5_arco_meio_angulo_exemplos_e_limites() -> void:
	assert_float(Unidades.arco_meio_angulo_graus(0.35)).is_equal_approx(69.51, 0.005)
	assert_float(Unidades.arco_meio_angulo_graus(0.5)).is_equal_approx(60.0, 0.005)
	assert_float(Unidades.arco_meio_angulo_graus(0.1)).is_equal_approx(84.26, 0.005)
	assert_float(Unidades.arco_meio_angulo_graus(-1.0)).is_equal_approx(180.0, 0.005)
	assert_float(Unidades.arredondar_casas(Unidades.arco_meio_angulo_graus(0.35), 2)).is_equal_approx(69.51, TOL)
	assert_bool(Unidades.arco_valido(Unidades.arco_meio_angulo_graus(0.999))).is_false()
	assert_bool(Unidades.arco_valido(60.0)).is_true()


func test_f5_alvo_exatamente_em_theta_e_acertado() -> void:
	var theta := Unidades.arredondar_casas(Unidades.arco_meio_angulo_graus(0.35), 2)
	var cos_meio := Unidades.cosseno_do_meio_angulo(theta)
	# Ângulo até a mira em float64 (Vector2 é float32 e erraria o limite exato).
	assert_bool(Unidades.acerta_arco(cos(deg_to_rad(theta)), cos_meio)).is_true()
	assert_bool(Unidades.acerta_arco(cos(deg_to_rad(theta + 0.5)), cos_meio)).is_false()


func test_f6_projetil_vida_e_alcance_no_relatorio() -> void:
	var vida := Unidades.vida_do_projetil_s(50)
	assert_float(vida).is_equal_approx(0.8333, 1e-4)
	assert_float(Unidades.alcance_do_projetil_px(990.0, vida)).is_equal_approx(825.0, TOL)
	assert_str(Unidades.linha_de_alcance("AttackDef pulso", 990.0, vida)).contains("reach_px 825.0")
	assert_str(Unidades.verificar_duracao(0.0, false)).starts_with("erro:")


func test_f7_duracao_para_passos_exemplos_do_gdd() -> void:
	assert_int(Unidades.duracao_para_passos(0.2667)).is_equal(16)
	assert_int(Unidades.duracao_para_passos(0.7)).is_equal(42)
	assert_int(Unidades.duracao_para_passos(16.0 / 60.0)).is_equal(16)
	assert_int(Unidades.duracao_para_passos(0.025)).is_equal(2)
	assert_int(Unidades.duracao_para_passos(0.005)).is_equal(1)
	assert_int(Unidades.duracao_para_passos(0.0)).is_equal(0)


func test_f7_validacao_aviso_abaixo_de_meio_passo_e_zero_conforme_campo() -> void:
	assert_str(Unidades.verificar_duracao(0.005, false)).starts_with("aviso:")
	assert_str(Unidades.verificar_duracao(0.0, true)).is_equal("")
	assert_str(Unidades.verificar_duracao(0.0, false)).starts_with("erro:")
	assert_str(Unidades.verificar_duracao(0.2667, false)).is_equal("")


func test_f7_v2_campo_s_abaixo_de_meio_passo_da_aviso_nao_bloqueante() -> void:
	var ataque := AttackDef.new()
	ataque.recarga_s = 0.005
	var arma := WeaponDef.new()
	arma.id = &"teste"
	arma.ataque = ataque
	var item := ItemDoCatalogo.new(&"weapon", "res://x.tres", 0, arma)
	var diags := V2Faixas.new().validar([item] as Array[ItemDoCatalogo])
	var avisos := diags.filter(func(d: Diagnostico) -> bool: return d.campo == "ataque.recarga_s")
	assert_int(avisos.size()).is_equal(1)
	assert_bool((avisos[0] as Diagnostico).eh_erro()).is_false()


func test_arredondamento_meio_longe_do_zero() -> void:
	assert_int(Unidades.arredondar_meio_longe_do_zero(1.5)).is_equal(2)
	assert_int(Unidades.arredondar_meio_longe_do_zero(-1.5)).is_equal(-2)
	assert_int(Unidades.arredondar_meio_longe_do_zero(2.4999)).is_equal(2)


func test_f8_curva_de_elite_exemplos_do_gdd() -> void:
	var c := _curva(0.05, 0.02, 3.0, 0.0, 0.25)
	assert_float(CurvaLinear.avaliar(c, 2.0)).is_equal(0.0)
	assert_float(CurvaLinear.avaliar(c, 3.0)).is_equal_approx(0.11, TOL)
	assert_float(CurvaLinear.avaliar(c, 5.0)).is_equal_approx(0.15, TOL)
	assert_float(CurvaLinear.avaliar(c, 12.0)).is_equal_approx(0.25, TOL)


func test_f8_piso_antes_da_ativacao_e_zero_e_sem_teto_nao_limita() -> void:
	var c := _curva(0.05, 0.02, 3.0, 0.1, 0.25)
	assert_float(CurvaLinear.avaliar(c, 1.0)).is_equal(0.0)
	c.sem_teto = true
	assert_float(CurvaLinear.avaliar(c, 100.0)).is_equal_approx(2.05, TOL)


func test_f8_piso_maior_que_teto_e_erro_v2_citando_campos() -> void:
	var regras := ElitesComCurva.nova(_curva(0.0, 0.0, 0.0, 0.5, 0.25))
	var diags := V2Faixas.new().validar([regras] as Array[ItemDoCatalogo])
	var erros := diags.filter(func(d: Diagnostico) -> bool: return d.eh_erro() and d.mensagem.contains("y_floor") and d.mensagem.contains("y_cap"))
	assert_int(erros.size()).is_equal(1)
	var com_sem_teto := _curva(0.0, 0.0, 0.0, 0.5, 0.25)
	com_sem_teto.sem_teto = true
	var diags2 := V2Faixas.new().validar([ElitesComCurva.nova(com_sem_teto)] as Array[ItemDoCatalogo])
	assert_int(diags2.filter(func(d: Diagnostico) -> bool: return d.mensagem.contains("y_cap")).size()).is_equal(0)


func test_tick_rate_30_e_erro_bloqueante_na_carga() -> void:
	assert_object(Unidades.verificar_tick_rate(60)).is_null()
	var d := Unidades.verificar_tick_rate(30)
	assert_object(d).is_not_null()
	assert_bool(d.eh_erro()).is_true()
	var carregador := CarregadorDeCatalogo.new(null, RelatorAcumulador.new(), _LeitorVazio.new(), 30)
	assert_bool(carregador.carregar("res://nao_existe.tres")).is_false()
	var regras := carregador.diagnosticos().map(func(x: Diagnostico) -> StringName: return x.regra)
	assert_bool(regras.has(Unidades.REGRA_TICK_RATE)).is_true()


class _LeitorVazio:
	extends CarregadorDeCatalogo.Leitor

	func existe(_caminho: String) -> bool:
		return false


## Item de catálogo com um ElitesRules cuja curva é [param curva] (achado do campo de curva por esquema).
class ElitesComCurva:
	static func nova(curva: LinearCurveDef) -> ItemDoCatalogo:
		var r := EliteRules.new()
		for p: Dictionary in r.get_property_list():
			if String(p["hint_string"]) == "LinearCurveDef":
				r.set(p["name"], curva)
				break
		return ItemDoCatalogo.new(&"elite_rules", "res://elite.tres", 0, r)
