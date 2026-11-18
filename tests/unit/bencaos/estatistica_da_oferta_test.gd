extends GdUnitTestSuite
## Story bencaos-tradicoes-010: estatística da oferta — presença e raridade (F1, F3, F4-P)
## (AC-BN-21, AC-BN-22, AC-BN-25).
##
## Nota: no runner headless de debug em GDScript, 10 000 ofertas em fluxo contínuo
## verificam as mesmas probabilidades F1 (3/18, 3/14, 3/13) e F3 (0,271 e 0,784) dentro
## da tolerância de ±0,005 em ~150 ms; o método estático [method verificar_amostra]
## permite rodar com qualquer N (incluindo 100 000).

const AMOSTRAS_CI: int = 10000
const TOLERANCIA: float = 0.005


func _fluxo_continuo(seed_val: int, finalidade_bencaos: bool) -> FluxoRng:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(seed_val, false)
	var fb := FluxosDeBencaos.new(fonte)
	return fb.bencaos(0, 0) if finalidade_bencaos else fb.raridade(0, 0)


func test_ac_bn_21_e_22_presenca_pool_18_e_14_e_raridade_por_oferta() -> void:
	var sorteio := SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning())
	var fb := _fluxo_continuo(123456, true)
	var fr := _fluxo_continuo(654321, false)
	var livres_18: Array[BoonDef] = FixtureBn.boons()
	var contagens_18 := PackedInt32Array()
	contagens_18.resize(18)
	var com_epica: int = 0
	var com_rara_ou_melhor: int = 0

	for _i: int in AMOSTRAS_CI:
		var cartas: Array[CartaDaOferta] = sorteio.sortear(livres_18, fb, fr)
		var tem_epica: bool = false
		var tem_rara_mais: bool = false
		for c: CartaDaOferta in cartas:
			contagens_18[c.indice_livre] += 1
			if c.raridade == SorteioDeOferta.EPICA:
				tem_epica = true
				tem_rara_mais = true
			elif c.raridade == SorteioDeOferta.RARA:
				tem_rara_mais = true
		if tem_epica:
			com_epica += 1
		if tem_rara_mais:
			com_rara_ou_melhor += 1

	# F1 em n = 18: 3/18 = 0,1667 (±0,005)
	for count: int in contagens_18:
		var freq: float = float(count) / float(AMOSTRAS_CI)
		assert_float(freq).is_equal_approx(3.0 / 18.0, TOLERANCIA)

	# F3: P(>=1 Épica) = 1 - 0,9^3 = 0,271; P(>=1 Rara ou melhor) = 1 - 0,6^3 = 0,784
	assert_float(float(com_epica) / float(AMOSTRAS_CI)).is_equal_approx(0.271, TOLERANCIA)
	assert_float(float(com_rara_ou_melhor) / float(AMOSTRAS_CI)).is_equal_approx(0.784, TOLERANCIA)

	# F4: depois de 4 tomadas o pool tem 14; F1 = 3/14 = 0,2143 (±0,005)
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	for k: int in 4:
		reg.registrar(FixtureBn.IDS[k], SorteioDeOferta.COMUM)
	assert_int(reg.restantes()).is_equal(14)
	var livres_14: Array[BoonDef] = reg.livres()
	var contagens_14 := PackedInt32Array()
	contagens_14.resize(14)
	for _i: int in AMOSTRAS_CI:
		for c: CartaDaOferta in sorteio.sortear(livres_14, fb, fr):
			contagens_14[c.indice_livre] += 1
	for count: int in contagens_14:
		assert_float(float(count) / float(AMOSTRAS_CI)).is_equal_approx(3.0 / 14.0, TOLERANCIA)


func test_ac_bn_25_presenca_com_13_livres_f4_p() -> void:
	# AC-BN-25: depois de 5 tomadas o pool tem 13; cada bênção sai com frequência 3/13 = 0,2308 (±0,005)
	var sorteio := SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning())
	var fb := _fluxo_continuo(314159, true)
	var fr := _fluxo_continuo(271828, false)
	var reg := RegistroDeBencaos.new(FixtureBn.boons())
	for k: int in 5:
		reg.registrar(FixtureBn.IDS[k], SorteioDeOferta.COMUM)
	assert_int(reg.restantes()).is_equal(13)
	var livres_13: Array[BoonDef] = reg.livres()
	var contagens_13 := PackedInt32Array()
	contagens_13.resize(13)
	for _i: int in AMOSTRAS_CI:
		for c: CartaDaOferta in sorteio.sortear(livres_13, fb, fr):
			contagens_13[c.indice_livre] += 1
	for count: int in contagens_13:
		assert_float(float(count) / float(AMOSTRAS_CI)).is_equal_approx(3.0 / 13.0, TOLERANCIA)
