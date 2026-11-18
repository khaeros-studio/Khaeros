extends GdUnitTestSuite
## Story conteudo-004: validadores V1–V4, V6–V8, V10, V11.


class ArteFalsa:
	extends VerificadorDeArte
	var existentes: PackedStringArray = []

	func existe(caminho: String) -> bool:
		return existentes.has(caminho)


class LeitorEmMemoria:
	extends CarregadorDeCatalogo.Leitor
	var recursos: Dictionary[String, Resource] = {}

	func existe(caminho: String) -> bool:
		return recursos.has(caminho)

	func carregar(caminho: String) -> Resource:
		return recursos.get(caminho, null)


func _item(d: DefinicaoBase, pos: int = 0, tipo: StringName = &"") -> ItemDoCatalogo:
	var t := tipo if tipo != &"" else d.tipo_do_catalogo()
	return ItemDoCatalogo.new(t, "res://teste/%s/%s.tres" % [t, d.id], pos, d)


func _regras(lista: Array[Diagnostico], regra: StringName) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	for d in lista:
		if d.regra == regra:
			out.append(d)
	return out


func _bencao(id: StringName, efeitos: Array[EffectDef], chave_desc: StringName = &"") -> BoonDef:
	var b := BoonDef.new()
	b.id = id
	b.doutrina = &"lamina"
	b.chave_nome = StringName(String(id).to_upper())
	b.chave_descricao = chave_desc
	for e in efeitos:
		b.efeitos.append(e)
	return b


func _efeito(tipo: StringName, valor: float, params: Dictionary[StringName, float] = {}) -> EffectDef:
	var e := EffectDef.new()
	e.tipo = tipo
	e.valor = valor
	e.params = params
	return e


# --- catálogo de fábrica ---------------------------------------------------

func test_catalogo_mvp_de_fabrica_passa_sem_erros() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(itens), ArteFalsa.new())
	var diags := v.validar(itens)
	var textos: Array = []
	for d in diags:
		textos.append(d.texto())
	assert_array(textos).is_empty()


# --- V1 (AC-09) --------------------------------------------------------------

func test_v1_dano_ausente_e_inimigo_listado_como_arma_geram_dois_erros() -> void:
	# Arrange: eco sem dano gravado (default do script = 0) e um EnemyDef listado como arma
	var eco := FabricasDeCatalogo.inimigo(&"eco_perdido")
	var gravados := PackedStringArray(eco.esquema().nomes())
	gravados.remove_at(gravados.find("dano"))
	gravados.remove_at(gravados.find("obsoleto"))
	var leitor := LeitorEmMemoria.new()
	var m := ManifestoDoCatalogo.new()
	m.acrescentar(&"enemy", "res://t/eco.tres")
	m.acrescentar(&"weapon", "res://t/falsa.tres")
	leitor.recursos["res://t/m.tres"] = m
	leitor.recursos["res://t/eco.tres"] = eco
	leitor.recursos["res://t/falsa.tres"] = FabricasDeCatalogo.inimigo(&"falsa")
	var item := _item(eco)
	item.definir_campos_gravados(gravados)
	# Act
	var v1 := V1Estrutura.new().validar([item] as Array[ItemDoCatalogo])
	var carregador := CarregadorDeCatalogo.new(ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), TabelaDeTextosEmMemoria.new(), ArteFalsa.new()), RelatorAcumulador.new(), leitor)
	carregador.carregar("res://t/m.tres")
	var v1_carga := _regras(carregador.diagnosticos(), &"V1")
	# Assert
	assert_int(v1.size()).is_equal(1)
	assert_str(v1[0].campo).is_equal("dano")
	assert_int(v1_carga.size()).is_equal(1)
	assert_str(v1_carga[0].arquivo).is_equal("res://t/falsa.tres")
	assert_int(carregador.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)


# --- V2 (AC-10) --------------------------------------------------------------

func test_v2_recarga_zero_erra_e_preparo_zero_passa() -> void:
	var w := FabricasDeCatalogo.arma(&"lamina", 100, &"avanco")
	w.ataque.recarga_s = 0.0
	w.especial.preparo_s = 0.0
	var diags := V2Faixas.new().validar([_item(w)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(1)
	assert_str(diags[0].campo).is_equal("ataque.recarga_s")


func test_v2_regra_entre_campos_y_floor_maior_que_y_cap_erra() -> void:
	var er := EliteRules.new()
	er.id = &"elite_rules"
	er.mult_vida = 2.0
	er.mult_dano = 1.5
	er.mult_raio = 1.2
	er.curva_chance = LinearCurveDef.new()
	er.curva_chance.y_floor = 0.3
	er.curva_chance.y_cap = 0.25
	var diags := V2Faixas.new().validar([_item(er)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(1)
	assert_str(diags[0].mensagem).contains("y_floor").contains("y_cap")


# --- V3 (AC-11) --------------------------------------------------------------

func test_v3_duplicata_cita_dois_caminhos_formato_erra_e_lamina_entre_tipos_passa() -> void:
	var b1 := _bencao(&"trad_veil_penumbra", [] as Array[EffectDef])
	var b2 := _bencao(&"trad_veil_penumbra", [] as Array[EffectDef])
	var ruim := FabricasDeCatalogo.inimigo(&"Lamina-1")
	var arma := FabricasDeCatalogo.arma(&"lamina", 100, &"avanco")
	var bencao_lamina := _bencao(&"lamina", [] as Array[EffectDef])
	var i1 := ItemDoCatalogo.new(&"boon", "res://a/b1.tres", 0, b1)
	var i2 := ItemDoCatalogo.new(&"boon", "res://a/b2.tres", 1, b2)
	var diags := V3Ids.new().validar([i1, i2, _item(ruim, 2), _item(arma, 3), _item(bencao_lamina, 4)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(2)
	assert_str(diags[0].mensagem).contains("res://a/b1.tres").contains("res://a/b2.tres")
	assert_str(String(diags[1].valor)).is_equal("Lamina-1")


# --- V4 (AC-12, AC-49, AC-58, AC-59) -----------------------------------------

func test_v4_referencias_fora_do_registro_ou_do_catalogo_erram() -> void:
	var r := RegionDef.new()
	r.id = &"limiar"
	r.chave_nome = &"R"
	r.camaras = [&"combta"]
	r.pool_inimigos = [&"inimigo_inexistente"]
	r.chefe = &"chefe_inexistente"
	var a := FabricasDeCatalogo.arma(&"lamina", 100, &"avanco")
	a.ataque.status = &"veneno"
	var ef := _bencao(&"trad_x", [_efeito(&"efeito_x", 1.0)] as Array[EffectDef])
	var inimigo := FabricasDeCatalogo.inimigo(&"eco", &"voador")
	var rt := RewardTable.new()
	rt.id = &"reward_table"
	rt.pesos_portas = {&"bencao": 1.0, &"tesouro": 1.0}
	rt.primeira_recompensa = &"bencao"
	var diags := V4Referencias.new(FabricasDeCatalogo.registros()).validar([_item(r), _item(a), _item(ef), _item(inimigo), _item(rt)] as Array[ItemDoCatalogo])
	var valores: Array = []
	for d in diags:
		valores.append(String(d.valor))
	assert_array(valores).contains_exactly_in_any_order(["combta", "inimigo_inexistente", "chefe_inexistente", "veneno", "efeito_x", "voador", "tesouro"])


func test_v4_registro_nao_entregue_gera_registro_ausente() -> void:
	var r := RegistrosDeChaves.new()
	var diags := V4Referencias.new(r).validar([_item(FabricasDeCatalogo.inimigo(&"eco"))] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(1)
	assert_str(diags[0].mensagem).contains("registro de chaves ausente: comportamentos")


func test_v4_chefe_reservado_passa_e_voador_erra() -> void:
	var r := RegistrosDeChaves.new()
	r.registrar(&"comportamentos", [&"corpo_a_corpo"], [&"chefe"])
	var diags := V4Referencias.new(r).validar([_item(FabricasDeCatalogo.inimigo(&"a", &"chefe")), _item(FabricasDeCatalogo.inimigo(&"b", &"voador"))] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(1)
	assert_str(String(diags[0].valor)).is_equal("voador")


func test_v4_chefe_ativo_no_registro_emendado_passa_e_nao_e_reservado() -> void:
	var r := FabricasDeCatalogo.registros()
	var diags := V4Referencias.new(r).validar([_item(FabricasDeCatalogo.chefe_soberano())] as Array[ItemDoCatalogo])
	assert_array(diags).is_empty()
	assert_bool(r.eh_ativa(&"comportamentos", &"chefe")).is_true()
	assert_bool(r.eh_reservada(&"comportamentos", &"chefe")).is_false()


func test_v4_fonte_vinculo_vida_max_passa_e_cargas_esquiva_erra() -> void:
	var r := FabricasDeCatalogo.registros()
	var ok := V4Referencias.validar_fonte_vinculo(&"vinculo:vulto_mudo", [&"vida_max"] as Array[StringName], r)
	var ruim := V4Referencias.validar_fonte_vinculo(&"vinculo:vulto_mudo", [&"cargas_esquiva"] as Array[StringName], r)
	assert_array(ok).is_empty()
	assert_int(ruim.size()).is_equal(1)
	assert_str(ruim[0].mensagem).contains("cargas_esquiva")


# --- V6 (AC-14) --------------------------------------------------------------

func test_v6_chave_sem_texto_e_texto_vazio_geram_dois_erros() -> void:
	var e1 := FabricasDeCatalogo.inimigo(&"a")
	var e2 := FabricasDeCatalogo.inimigo(&"b")
	var t := TabelaDeTextosEmMemoria.new()
	t.definir(String(e2.chave_nome), "  ")
	var diags := V6Textos.new(t).validar([_item(e1), _item(e2)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(2)


func test_v6_confere_chave_derivada_desc_da_arma() -> void:
	var w := FabricasDeCatalogo.arma(&"lamina", 100, &"avanco")
	var itens: Array[ItemDoCatalogo] = [_item(w)]
	var t := FabricasDeCatalogo.textos_para(itens)
	t._textos.erase(String(w.chave_nome) + "_DESC")
	var diags := V6Textos.new(t).validar(itens)
	assert_int(diags.size()).is_equal(1)
	assert_str(String(diags[0].valor)).ends_with("_DESC")


# --- V7 (AC-15) --------------------------------------------------------------

func test_v7_icone_ausente_e_fora_da_pasta_geram_dois_erros() -> void:
	var arte := ArteFalsa.new()
	arte.existentes = ["res://assets/art/export/ok.png"]
	var b1 := _bencao(&"trad_a", [] as Array[EffectDef])
	b1.icone_ganho = "res://assets/art/export/falta.png"
	var b2 := _bencao(&"trad_b", [] as Array[EffectDef])
	b2.icone_ganho = "res://assets/art/source/x.png"
	var b3 := _bencao(&"trad_c", [] as Array[EffectDef])
	b3.icone_ganho = "res://assets/art/export/ok.png"
	var diags := V7Arte.new(arte).validar([_item(b1), _item(b2), _item(b3)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(2)
	assert_str(diags[0].mensagem).contains("não encontrado")
	assert_str(diags[1].mensagem).contains("fora de assets/art/export/")


# --- V8 (AC-16) --------------------------------------------------------------

func test_v8_pesos_zerados_e_negativos_erram_e_um_positivo_passa() -> void:
	assert_str(V8Pesos.verificar_pesos([0.0, 0.0, 0.0])).is_not_empty()
	assert_str(V8Pesos.verificar_pesos([1.0, -1.0])).is_not_empty()
	assert_str(V8Pesos.verificar_pesos([0.0, 1.0, 0.0])).is_empty()


func test_v8_tabelas_do_catalogo_geram_um_erro_por_tabela() -> void:
	var rar := RarityTable.new()
	rar.id = &"rarity_table"
	rar.escalas = PackedFloat64Array([1.0, 1.5, 2.0])
	rar.pesos = PackedFloat64Array([0.0, 0.0, 0.0])
	var vt := FabricasDeCatalogo.vinculo_tuning()
	vt.peso_raridade = PackedFloat64Array([1.0, -1.0])
	var diags := V8Pesos.new().validar([_item(rar), _item(vt)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(2)


# --- V10 (AC-18, AC-42) -------------------------------------------------------

func test_v10_numero_literal_erra_e_marcador_valor_passa() -> void:
	var efs: Array[EffectDef] = [_efeito(&"dano_ataque_pct", 0.6)]
	assert_int(V10Descricoes.verificar("causa 12 de dano", efs, null, null).size()).is_equal(1)
	assert_array(Array(V10Descricoes.verificar("causa {valor} de dano", efs, null, null))).is_empty()
	assert_int(V10Descricoes.verificar("causa {inexistente} de dano", efs, null, null).size()).is_equal(1)


func test_v10_marcadores_com_dois_efeitos_e_formatos() -> void:
	var efs: Array[EffectDef] = [_efeito(&"vida_max_plano", -10.0), _efeito(&"dano_ataque_pct", 0.2)]
	var st := StatusTuning.new()
	st.reducao_dano_causado = 0.3
	var r := FabricasDeCatalogo.registros()
	assert_array(Array(V10Descricoes.verificar("Custa {vida_max_plano.valor:int} de Vida", efs, st, r))).is_empty()
	assert_int(V10Descricoes.verificar("Custa {valor} de Vida", efs, st, r).size()).is_equal(1)
	assert_int(V10Descricoes.verificar("Custa {vida_max_plano.valor:moeda}", efs, st, r).size()).is_equal(1)
	assert_array(Array(V10Descricoes.verificar("Abala {status.abalo.reducao_dano_causado:pct}", efs, st, r))).is_empty()
	assert_str(V10Descricoes.formatar(-10.0, "int")).is_equal("10")
	assert_str(V10Descricoes.formatar(0.6, "pct")).is_equal("60%")
	assert_str(V10Descricoes.formatar(1.5, "num")).is_equal("1,5")
	assert_str(V10Descricoes.formatar(3.0)).is_equal("3")


func test_v10_valida_texto_da_descricao_pela_tabela() -> void:
	var b := _bencao(&"trad_x", [_efeito(&"dano_ataque_pct", 0.6)] as Array[EffectDef], &"TRAD_X_DESC")
	var t := TabelaDeTextosEmMemoria.new()
	t.definir("TRAD_X_DESC", "Cada 4º acerto causa +{valor:pct} de dano.")
	var diags := V10Descricoes.new(t, FabricasDeCatalogo.registros()).validar([_item(b)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(1)
	assert_str(diags[0].mensagem).contains("\"4\"")


# --- V11 (AC-50) --------------------------------------------------------------

func test_v11_params_divergentes_entre_bencao_e_melhoria_geram_um_erro() -> void:
	var b := _bencao(&"trad_pacts_os_que_ficam", [_efeito(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4})] as Array[EffectDef])
	var u := UpgradeDef.new()
	u.id = &"ultimo_folego"
	u.efeitos.append(_efeito(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.5}))
	var diags := V11Efeitos.new().validar([_item(b), _item(u)] as Array[ItemDoCatalogo])
	assert_int(diags.size()).is_equal(1)
	assert_str(diags[0].mensagem).contains("trad_pacts_os_que_ficam").contains("ultimo_folego").contains("0.4").contains("0.5")


func test_v11_params_iguais_ou_tipos_diferentes_passam() -> void:
	var b := _bencao(&"trad_a", [_efeito(&"recusas_morte", 1.0, {&"vida_ao_voltar": 0.4})] as Array[EffectDef])
	var u := UpgradeDef.new()
	u.id = &"m"
	u.efeitos.append(_efeito(&"recusas_morte", 2.0, {&"vida_ao_voltar": 0.4}))
	var c := _bencao(&"trad_c", [_efeito(&"dano_ataque_pct", 1.0, {&"a_cada": 4.0})] as Array[EffectDef])
	var diags := V11Efeitos.new().validar([_item(b), _item(u), _item(c)] as Array[ItemDoCatalogo])
	assert_array(diags).is_empty()
