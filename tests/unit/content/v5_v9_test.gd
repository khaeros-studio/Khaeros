extends GdUnitTestSuite
## Story conteudo-010 [L]: validadores de CI V5 (nomes canônicos e NFC), V9 (ids registrados),
## varredura de órfãos e importador do cânone (AC-04, AC-09, AC-13, AC-17, AC-20, AC-30,
## AC-39, AC-40, AC-44, AC-60).


func _item(d: DefinicaoBase, pos: int = 0) -> ItemDoCatalogo:
	return ItemDoCatalogo.new(d.tipo_do_catalogo(), "res://teste/%s/%s.tres" % [d.tipo_do_catalogo(), d.id], pos, d)


func test_ac13_e_ac40_v5_nfc_nfd_doutrina_e_nomes_canonicos() -> void:
	var b := BoonDef.new()
	b.id = &"trad_blade_traco_unico"
	b.doutrina = &"lamina"
	b.chave_nome = &"TRAD_BLADE_TRACO_UNICO_NAME"
	b.chave_descricao = &"TRAD_BLADE_TRACO_UNICO_DESC"

	var t := TabelaDeTextosEmMemoria.new()
	# 1. Grafia canônica em NFD passa após normalização NFC
	t.definir("TRAD_BLADE_TRACO_UNICO_NAME", "O Trac\u0327o U\u0301nico")
	var diags_ok := V5NomesCanonicos.new(t).validar([_item(b)] as Array[ItemDoCatalogo])
	assert_array(diags_ok).is_empty()

	# 2. Nome sem artigo "Traço Único" gera erro V5 (AC-13)
	t.definir("TRAD_BLADE_TRACO_UNICO_NAME", "Traço Único")
	var diags_nome := V5NomesCanonicos.new(t).validar([_item(b)] as Array[ItemDoCatalogo])
	assert_int(diags_nome.size()).is_equal(1)
	assert_str(String(diags_nome[0].regra)).is_equal("V5")
	assert_str(diags_nome[0].mensagem).contains("Traço Único").contains("O Traço Único")

	# 3. Doutrina divergente ("ressonancia" em trad_blade_*) gera erro V5 (AC-40)
	t.definir("TRAD_BLADE_TRACO_UNICO_NAME", "O Traço Único")
	b.doutrina = &"ressonancia"
	var diags_dout := V5NomesCanonicos.new(t).validar([_item(b)] as Array[ItemDoCatalogo])
	assert_int(diags_dout.size()).is_equal(1)
	assert_str(diags_dout[0].campo).is_equal("doutrina")


func test_ac40_e_ac60_v5_pactos_inimigos_maldicoes_e_categoria() -> void:
	var w := FabricasDeCatalogo.arma(&"pactos", 90, &"chamado")
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var vulto := FabricasDeCatalogo.maldicao(&"vulto_mudo", &"comum")

	var t := TabelaDeTextosEmMemoria.new()
	t.definir(String(w.chave_nome), "Laço dos Pactos")
	t.definir(String(w.ataque.chave_nome), "Virote")
	t.definir(String(w.especial.chave_nome), "Chamado do Pacto")
	t.definir(String(eco.chave_nome), "Eco perdido")
	t.definir(String(vulto.chave_nome), "Vulto mudo")
	t.definir("CURSE_CATEGORY_NAME", "Criaturas")

	var diags := V5NomesCanonicos.new(t).validar([_item(w, 0), _item(eco, 1), _item(vulto, 2)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(4)
	for d in diags:
		assert_str(String(d.regra)).is_equal("V5")


func test_ac17_ac44_e_ac60_v9_ids_registrados_obsoleto_e_remocao() -> void:
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var vulto := FabricasDeCatalogo.maldicao(&"vulto_mudo", &"comum")
	var registrados := PackedStringArray(["enemy,eco_perdido", "curse,vulto_mudo", "curse,baluarte_de_cinza"])
	var base := PackedStringArray(["enemy,eco_perdido", "curse,vulto_mudo", "curse,baluarte_de_cinza", "enemy,anomalia_menor"])

	# Falta baluarte_de_cinza no catálogo + falta anomalia_menor no registro atual vs base
	var diags := V9IdsRegistrados.new(registrados, base).validar([_item(eco, 0), _item(vulto, 1)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(2)

	# Item obsoleto = true continua satisfazendo V9 (AC-17)
	eco.obsoleto = true
	var reg_simples := PackedStringArray(["enemy,eco_perdido"])
	var diags_obs := V9IdsRegistrados.new(reg_simples, reg_simples).validar([_item(eco, 0)] as Array[ItemDoCatalogo])
	assert_array(diags_obs).is_empty()

	# Item no catálogo sem linha em ids_registrados.csv falha V9 (AC-44)
	var eco_veio := FabricasDeCatalogo.inimigo(&"eco_do_veio")
	var diags_sem_linha := V9IdsRegistrados.new(reg_simples).validar([_item(eco, 0), _item(eco_veio, 1)] as Array[ItemDoCatalogo])
	assert_int(diags_sem_linha.size()).is_equal(1)
	assert_str(String(diags_sem_linha[0].id)).is_equal("eco_do_veio")


func test_ac04_e_ac09_varredura_de_orfaos_e_texto_tres() -> void:
	var m := ManifestoDoCatalogo.new()
	m.acrescentar(&"enemy", "res://assets/data/inimigos/eco_perdido.tres")
	var em_disco := PackedStringArray([
		"res://assets/data/content_catalog.tres",
		"res://assets/data/inimigos/eco_perdido.tres",
		"res://assets/data/inimigos/orfao_secreto.tres",
		"res://assets/data/canon/mapa_ids.csv",
	])
	var orfaos := VarreduraDeOrfaos.verificar_orfaos(m, em_disco)
	assert_int(orfaos.size()).is_equal(1)
	assert_str(orfaos[0].arquivo).is_equal("res://assets/data/inimigos/orfao_secreto.tres")

	# Texto .tres omitindo campo obrigatório ("dano") e com propriedade desconhecida ("campo_fantasma")
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var texto_invalido := """[gd_resource type="Resource" script_class="EnemyDef" format=3]
[resource]
id = &"eco_perdido"
chave_nome = &"ENEMY_ECO_PERDIDO_NAME"
comportamento = &"corpo_a_corpo"
vida = 30.0
velocidade = 153.0
raio_px = 24.0
alcance_px = 45.0
preparo_s = 0.4333
recarga_s = 1.0
velocidade_projetil = 0.0
custo_onda = 1
campo_fantasma = 99
"""
	var diags_txt := VarreduraDeOrfaos.verificar_texto_tres(texto_invalido, eco, "res://assets/data/inimigos/eco_perdido.tres")
	var campos: Array = diags_txt.map(func(d: Diagnostico) -> String: return d.campo)
	assert_array(campos).contains_exactly_in_any_order(["campo_fantasma", "dano"])


func test_ac20_ac30_e_ac39_importador_recusa_token_sem_mapa_e_arena_nao_uniforme() -> void:
	var mapa := ImportadorDeCanone.carregar_mapa_ids()
	var ok_blade := ImportadorDeCanone.traduzir_id(mapa, "doutrina", "BLADE")
	assert_bool(ok_blade["ok"]).is_true()
	assert_str(String(ok_blade["id_godot"])).is_equal("lamina")

	var erro_token := ImportadorDeCanone.traduzir_id(mapa, "doutrina", "DOUTRINA_INEXISTENTE")
	assert_bool(erro_token["ok"]).is_false()
	assert_object(erro_token["erro"]).is_not_null()

	assert_object(ImportadorDeCanone.verificar_arena_canone(1280.0, 720.0)).is_null()
	assert_object(ImportadorDeCanone.verificar_arena_canone(1280.0, 800.0)).is_not_null()
	assert_object(ImportadorDeCanone.verificar_arena_canone(960.0, 600.0)).is_not_null()
