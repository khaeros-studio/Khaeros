extends GdUnitTestSuite
## Stories selo-e-fluxo-004 e 005:
## - Story 004: Dano do Selo, abates e imunidade da Maldição (AC-SF-14 a AC-SF-21, AC-SF-28, AC-SF-31)
## - Story 005: Lentidão, consulta `no_selo` e Selos apagados na câmara nova (AC-SF-22, AC-SF-23)

const CAMARA := Rect2(0.0, 0.0, 1920.0, 1080.0)


func _tuning_mod() -> ModifiersTuning:
	var t := ModifiersTuning.new()
	t.piso_vida_jogador = 20
	t.teto_multiplicador_dano = 4.0
	t.teto_reducao_dano = 0.6
	t.fator_empurrao_chefe = 0.12
	return t


func test_ac_sf_14_e_15_dano_de_um_selo_selo_fim_dentro_fora_e_surgindo() -> void:
	var eventos := EventosDoPasso.new()
	var s := Selo.new(SealTuning.fabrica(), eventos)
	var saco: Dictionary = {&"id": 1, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 1000.0}
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)

	# Passos 0..199 (200 passos vivos): fere 0,12 por passo = 24 de dano -> Vida 976; selo_fim no passo 199
	for p: int in 200:
		if p > 0:
			buf.avancar_passo()
		s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, p == 0, false, [saco])
		if p < 199:
			assert_bool(eventos.ha(EvSeloFim.TIPO)).is_false()
	assert_float(float(saco[&"vida"])).is_equal_approx(976.0, 1e-6)
	assert_int(eventos.do_tipo(EvSeloFim.TIPO).size()).is_equal(1)
	assert_int(s.quantidade_ativos()).is_equal(0)

	# Passo 200: nenhum dano adicional
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false, false, [saco])
	assert_float(float(saco[&"vida"])).is_equal_approx(976.0, 1e-6)

	# AC-SF-15: a 166,5 px (142,5 + 24) leva dano; a 166,6 px não; surgindo não leva nem fica no_selo
	var s2 := Selo.new()
	var b2 := BufferDeComandos.new(10)
	b2.apertar(Acoes.SELO)
	var dentro: Dictionary = {&"id": 1, &"pos": Vector2(1140.0 + 166.5, 540.0), &"raio": 24.0, &"vida": 100.0}
	var fora: Dictionary = {&"id": 2, &"pos": Vector2(1140.0 + 166.6, 540.0), &"raio": 24.0, &"vida": 100.0}
	var surgindo: Dictionary = {&"id": 3, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 100.0, &"surgindo": true}
	s2.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b2, true, false, [dentro, fora, surgindo])
	assert_float(float(dentro[&"vida"])).is_equal_approx(99.88, 1e-6)
	assert_float(float(fora[&"vida"])).is_equal_approx(100.0, 1e-6)
	assert_float(float(surgindo[&"vida"])).is_equal_approx(100.0, 1e-6)
	assert_bool(s2.no_selo(1)).is_true()
	assert_bool(s2.no_selo(2)).is_false()
	assert_bool(s2.no_selo(3)).is_false()
	# Terminou surgimento: passa a levar dano
	surgindo[&"surgindo"] = false
	s2.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b2, false, false, [surgindo])
	assert_float(float(surgindo[&"vida"])).is_equal_approx(99.88, 1e-6)
	assert_bool(s2.no_selo(3)).is_true()


func test_ac_sf_16_e_19_e_20_dois_selos_abate_e_pulo_de_morto() -> void:
	# AC-SF-16: Selos nos passos 0 e 30 sobre o mesmo Saco -> passo 100 fere 0,24; após passo 229 Vida = 952
	var s := Selo.new()
	var buf := BufferDeComandos.new(10)
	var saco: Dictionary = {&"id": 1, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 1000.0}
	for p: int in 230:
		if p > 0:
			buf.avancar_passo()
		if p == 0 or p == 30:
			buf.apertar(Acoes.SELO)
		var v_antes: float = float(saco[&"vida"])
		s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, p == 0 or p == 30, false, [saco])
		if p == 100:
			assert_float(v_antes - float(saco[&"vida"])).is_equal_approx(0.24, 1e-6)
			assert_bool(s.no_selo(1)).is_true()
	assert_float(float(saco[&"vida"])).is_equal_approx(952.0, 1e-6)

	# AC-SF-20: Fenda (Vida 46) dentro dos Selos 0 e 30 morre no passo 213 (M = 1)
	var s_fenda := Selo.new()
	var b_fenda := BufferDeComandos.new(10)
	var fenda: Dictionary = {&"id": 2, &"pos": Vector2(1140.0, 540.0), &"raio": 30.0, &"vida": 46.0}
	var passo_morte: int = -1
	for p: int in 230:
		if p > 0:
			b_fenda.avancar_passo()
		if p == 0 or p == 30:
			b_fenda.apertar(Acoes.SELO)
		s_fenda.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_fenda, p == 0 or p == 30, false, [fenda])
		if float(fenda[&"vida"]) <= 0.0 and passo_morte < 0:
			passo_morte = p
	assert_int(passo_morte).is_equal(213)

	# AC-SF-19: Eco com Vida 0,12 e dois Selos no mesmo passo -> 1º Selo leva a Vida a 0, 2º o pula
	var s_eco := Selo.new()
	var b_eco := BufferDeComandos.new(10)
	b_eco.apertar(Acoes.SELO)
	s_eco.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_eco, true)
	s_eco.definir_recarga_para_teste(0)
	b_eco.apertar(Acoes.SELO)
	var eco: Dictionary = {&"id": 3, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 0.12}
	var ferimentos: Array[int] = [0]
	s_eco.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_eco, true, false, [eco],
		func(_id: int, d: float) -> void:
			ferimentos[0] += 1
			eco[&"vida"] = float(eco[&"vida"]) - d
	)
	assert_int(ferimentos[0]).is_equal(1)
	assert_float(float(eco[&"vida"])).is_equal_approx(0.0, 1e-6)


func test_ac_sf_17_e_18_e_21_e_28_e_31_m_por_passo_abalo_e_imunidade_da_maldicao() -> void:
	# AC-SF-17 e AC-SF-28: M avaliado a cada passo para todos os Selos ativos
	var port := Portador.new(1, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 100.0}, _tuning_mod())
	port.aplicar_fonte(FonteDeModificador.new(&"b:forma_fixa", [
		Modificador.new(Atributos.DANO_SELO, Modificador.Operacao.PERCENTUAL, 0.60)
	], [
		GatilhoAtivo.new(&"selo_abala", 1.0, {&"duracao_s": 0.5})
	]))
	var s := Selo.new(SealTuning.fabrica(), EventosDoPasso.new(), port)
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	var saco: Dictionary = {&"id": 1, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 1000.0}
	var abalos_aplicados: Array[float] = []
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true, false, [saco], Callable(),
		func(_id: int, _tipo: StringName, dur: float) -> void:
			abalos_aplicados.append(dur)
	)
	# M = 1,6 -> dano = 0,12 * 1,6 = 0,192; selo_abala disparou com 0,5 s
	assert_float(1000.0 - float(saco[&"vida"])).is_equal_approx(0.192, 1e-6)
	assert_int(abalos_aplicados.size()).is_equal(1)
	assert_float(abalos_aplicados[0]).is_equal_approx(0.5, 1e-6)

	# Remove o bônus: no passo seguinte o mesmo Selo já usa M = 1,0 (0,12)
	port.remover_fonte(&"b:forma_fixa")
	var antes: float = float(saco[&"vida"])
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false, false, [saco])
	assert_float(antes - float(saco[&"vida"])).is_equal_approx(0.12, 1e-6)

	# AC-SF-31: Maldição (`faccao: &"aliado"`) dentro do Selo por 200 passos vivos não leva dano nem lentidão
	var s_mald := Selo.new(SealTuning.fabrica(), EventosDoPasso.new(), port)
	var b_mald := BufferDeComandos.new(10)
	b_mald.apertar(Acoes.SELO)
	var maldicao: Dictionary = {&"id": 99, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 110.0, &"faccao": &"aliado"}
	var saco_m: Dictionary = {&"id": 1, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 1000.0}
	for p: int in 200:
		if p > 0:
			b_mald.avancar_passo()
		s_mald.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, b_mald, p == 0, false, [maldicao, saco_m])
		assert_bool(s_mald.no_selo(99)).is_false()
	assert_float(float(maldicao[&"vida"])).is_equal_approx(110.0, 1e-6)
	assert_float(float(saco_m[&"vida"])).is_equal_approx(976.0, 1e-6)


func test_ac_sf_22_e_23_lentidao_no_selo_e_apagar_na_camara_nova() -> void:
	var eventos := EventosDoPasso.new()
	var s := Selo.new(SealTuning.fabrica(), eventos)
	var buf := BufferDeComandos.new(10)
	buf.apertar(Acoes.SELO)
	var saco: Dictionary = {&"id": 1, &"pos": Vector2(1140.0, 540.0), &"raio": 24.0, &"vida": 1000.0}
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true, false, [saco])
	s.definir_recarga_para_teste(0)
	buf.apertar(Acoes.SELO)
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, true, false, [saco])

	# AC-SF-22: mesmo dentro de 2 Selos, o fator é 0,5 (0,2 com cambaleio)
	assert_int(s.quantidade_ativos()).is_equal(2)
	assert_bool(s.no_selo(1)).is_true()
	assert_float(s.velocidade_andar_efetiva(100.0, 1, false)).is_equal_approx(50.0, 1e-6)
	assert_float(s.velocidade_andar_efetiva(100.0, 1, true, 0.4)).is_equal_approx(20.0, 1e-6)

	# AC-SF-23: ao_camara_nova apaga os 2 Selos sem emitir selo_fim, e nenhum fere no passo seguinte
	s.ao_camara_nova()
	assert_int(s.quantidade_ativos()).is_equal(0)
	assert_bool(s.no_selo(1)).is_false()
	assert_bool(eventos.ha(EvSeloFim.TIPO)).is_false()
	var vida_antes: float = float(saco[&"vida"])
	s.passo_item_6(Vector2(960.0, 540.0), Vector2.RIGHT, CAMARA, buf, false, false, [saco])
	assert_float(float(saco[&"vida"])).is_equal_approx(vida_antes, 1e-6)
