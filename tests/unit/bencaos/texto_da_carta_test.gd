extends GdUnitTestSuite
## Story bencaos-tradicoes-008: texto da carta com o número da raridade
## (AC-BN-18, TR-bencaos-009).

const REGIAO := &"limiar"


func _muro_de_pedras() -> BoonDef:
	for b: BoonDef in FixtureBn.boons():
		if b.id == &"trad_guardian_muro_pedras":
			return b
	return null


func _tuning_mod() -> ModifiersTuning:
	var t := ModifiersTuning.new()
	t.piso_vida_jogador = 20
	t.teto_multiplicador_dano = 4.0
	t.teto_reducao_dano = 0.6
	t.fator_empurrao_chefe = 0.12
	t.fator_propagacao_maldicao = 1.0
	t.tipos_propagados_maldicao = [&"dano_todo_pct", &"velocidade_pct"]
	return t


func test_muro_de_pedras_epico_e_raro_mostram_50_e_38() -> void:
	# AC-BN-18: O Muro de Pedras Épico mostra "+50 de Vida máxima"; a Rara, "+38 de Vida máxima".
	var muro: BoonDef = _muro_de_pedras()
	var tabela: RarityTable = FixtureBn.tabela()
	var epico: String = TextoDaCarta.formatar_descricao(muro, SorteioDeOferta.EPICA, tabela)
	var raro: String = TextoDaCarta.formatar_descricao(muro, SorteioDeOferta.RARA, tabela)
	var comum: String = TextoDaCarta.formatar_descricao(muro, SorteioDeOferta.COMUM, tabela)
	assert_str(epico).is_equal("+50 de Vida máxima")
	assert_str(raro).is_equal("+38 de Vida máxima")
	assert_str(comum).is_equal("+25 de Vida máxima")


func test_numero_mostrado_igual_ao_valor_aplicado_no_portador() -> void:
	# TR-bencaos-009: o número mostrado na carta usa a mesma regra de arredondamento
	# do valor aplicado no Portador (137,5 -> 138, ganho +38).
	var muro: BoonDef = _muro_de_pedras()
	var tabela: RarityTable = FixtureBn.tabela()
	var textos := TabelaDeTextosEmMemoria.new()
	textos.definir(String(muro.chave_descricao), "+{valor} de Vida máxima")

	for raridade: int in [SorteioDeOferta.COMUM, SorteioDeOferta.RARA, SorteioDeOferta.EPICA]:
		var vista: Dictionary = TextoDaCarta.montar_carta_view(muro, raridade, tabela, textos)
		var portador := Portador.new(1, 0, Atributos.Especie.JOGADOR, {Atributos.VIDA_MAX: 100.0}, _tuning_mod())
		var escala: float = TextoDaCarta.escala_da_raridade(raridade, tabela)
		portador.aplicar_fonte(AplicadorDeEfeitos.fonte_de(&"bencao:muro", muro.efeitos, escala))
		var ganho_aplicado: int = portador.inteiro(Atributos.VIDA_MAX) - 100
		assert_int(int(vista[&"numero_aplicado"])).is_equal(ganho_aplicado)
		assert_str(String(vista[&"texto"])).is_equal("+%d de Vida máxima" % ganho_aplicado)


func test_cartas_view_entrega_dados_prontos_para_a_tela() -> void:
	var fonte := FonteDeFluxos.new(RelatorGravadorRng.new())
	fonte.iniciar_run(4242, false)
	var b := Bencaos.new(
		RegistroDeBencaos.new(FixtureBn.boons()),
		SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(fonte),
		ConsultaFalsaBn.new(0),
		FixtureBn.tuning(),
		{REGIAO: 0},
		EventosDoPasso.new()
	)
	b.pedir_oferta(REGIAO, 0)
	var vistas: Array[Dictionary] = b.cartas_view()
	assert_int(vistas.size()).is_equal(3)
	for i: int in vistas.size():
		assert_str(String(vistas[i][&"id"])).is_equal(String(b.cartas()[i].id))
		assert_int(int(vistas[i][&"raridade"])).is_equal(b.cartas()[i].raridade)
		assert_bool(String(vistas[i][&"texto"]).is_empty()).is_false()
