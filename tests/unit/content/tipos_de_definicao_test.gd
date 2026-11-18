extends GdUnitTestSuite
## Story conteudo-002: tipos de definição do MVP (AC-53 e AC-55 estruturais).


func test_cada_tipo_tem_os_campos_da_tabela_esperada() -> void:
	# Arrange
	var base := FabricasDeCatalogo.campos_exportados(DefinicaoBase.new())
	var instancias := FabricasDeCatalogo.instancias_por_classe()
	# Act / Assert
	for nome: String in FabricasDeCatalogo.CAMPOS_ESPERADOS:
		var proprios: Array = []
		for c in FabricasDeCatalogo.campos_exportados(instancias[nome]):
			if not base.has(c):
				proprios.append(c)
		var esperado: Array = FabricasDeCatalogo.CAMPOS_ESPERADOS[nome]
		assert_array(proprios).override_failure_message("%s: %s" % [nome, proprios]).contains_exactly_in_any_order(esperado)


func test_weapon_def_tem_exatamente_sete_campos_de_conteudo() -> void:
	var campos: Array = Array(FabricasDeCatalogo.campos_exportados(WeaponDef.new()))
	campos.erase("obsoleto")
	assert_array(campos).contains_exactly_in_any_order(["id", "doutrina", "chave_nome", "vida_max", "velocidade", "ataque", "especial"])


func test_hud_tuning_tem_dezessete_campos() -> void:
	var proprios := FabricasDeCatalogo.campos_exportados(HudTuning.new())
	assert_int(proprios.size() - FabricasDeCatalogo.campos_exportados(DefinicaoBase.new()).size()).is_equal(17)


func test_catalogo_mvp_instancia_tipos_de_pactos() -> void:
	# Arrange
	var cat := Catalogo.new(RelatorAcumulador.new())
	for item in FabricasDeCatalogo.itens_mvp():
		cat.adicionar(item.tipo, item.definicao)
	# Assert
	var ids: Array = []
	for d in cat.listar(&"curse"):
		ids.append(d.id)
	assert_array(ids).is_equal([&"vulto_mudo", &"espreitador_da_fenda", &"baluarte_de_cinza", &"soberano_do_limiar"])
	assert_bool(cat.existe(&"tuning", &"maldicoes_tuning")).is_true()
	assert_bool(cat.existe(&"tuning", &"vinculo_tuning")).is_true()
	assert_bool(cat.existe(&"tuning", &"chefes_tuning")).is_true()
	assert_bool(cat.existe(&"weapon", &"pactos")).is_true()
	var chefe := cat.obter(&"enemy", &"soberano_do_limiar", "teste") as EnemyDef
	assert_int(chefe.padroes.size()).is_equal(4)
	assert_bool(cat.existe(&"enemy", &"anomalia_maior")).is_true()


func test_mesmo_id_em_curse_e_enemy_coexiste() -> void:
	var cat := Catalogo.new(RelatorAcumulador.new())
	for item in FabricasDeCatalogo.itens_mvp():
		cat.adicionar(item.tipo, item.definicao)
	assert_object(cat.obter(&"curse", &"soberano_do_limiar", "teste")).is_instanceof(CurseDef)
	assert_object(cat.obter(&"enemy", &"soberano_do_limiar", "teste")).is_instanceof(EnemyDef)


func test_run_tuning_arma_padrao_aceita_pactos() -> void:
	var rt := RunTuning.new()
	rt.arma_padrao = &"pactos"
	assert_str(String(rt.arma_padrao)).is_equal("pactos")
	assert_str(String(rt.esquema().regra(&"arma_padrao").ref_tipo)).is_equal("weapon")


func test_padroes_e_tipado_como_boss_pattern_def() -> void:
	var e := EnemyDef.new()
	assert_bool(e.padroes.is_typed()).is_true()
	assert_str(String(e.padroes.get_typed_class_name())).is_equal("Resource")
	assert_object(e.padroes.get_typed_script()).is_equal(BossPatternDef)


func test_copia_profunda_nao_altera_a_definicao() -> void:
	var chefe := FabricasDeCatalogo.chefe_soberano()
	var copia := chefe.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as EnemyDef
	(copia.padroes[0] as BossPatternDef).dano = 999.0
	assert_float((chefe.padroes[0] as BossPatternDef).dano).is_not_equal(999.0)
