extends GdUnitTestSuite
## Story conteudo-008: impressão canônica SHA-256 (AC-46; ADR-0004 §Impressão canônica).


func _catalogo_mvp() -> Catalogo:
	var cat := Catalogo.new(RelatorAcumulador.new())
	for item in FabricasDeCatalogo.itens_mvp():
		cat.adicionar(item.tipo, item.definicao)
	return cat


func _impressao(cat: Catalogo) -> String:
	var r := ImpressaoCanonica.calcular(cat)
	assert_array(r.erros).is_empty()
	return r.completa


func _upgrade(id: StringName, efeito_valor: float) -> UpgradeDef:
	var e := EffectDef.new()
	e.tipo = &"vida_max_plano"
	e.valor = efeito_valor
	var u := UpgradeDef.new()
	u.id = id
	u.chave_nome = &"UPGRADE_X_NAME"
	u.efeitos = [e]
	return u


func test_vetor_congelado_bytes_e_hash_coincidem() -> void:
	var r := ImpressaoCanonica.calcular(VetorCanonico.catalogo_minimo())
	assert_array(r.erros).is_empty()
	assert_str(r.bytes.hex_encode()).is_equal(VetorCanonico.BYTES_HEX)
	assert_str(r.completa).is_equal(VetorCanonico.SHA256)
	assert_str(r.curta).is_equal(VetorCanonico.SHA256.substr(0, 4).to_upper())


func test_cabecalho_tem_marca_e_versao_do_formato() -> void:
	var r := ImpressaoCanonica.calcular(VetorCanonico.catalogo_minimo())
	var marca := ImpressaoCanonica.CABECALHO.to_ascii_buffer()
	assert_str(r.bytes.slice(0, marca.size()).get_string_from_ascii()).is_equal(ImpressaoCanonica.CABECALHO)
	assert_int(r.bytes.decode_u32(marca.size())).is_equal(ImpressaoCanonica.VERSAO_DO_FORMATO)


func test_catalogos_iguais_tem_impressoes_iguais_e_curta_e_prefixo() -> void:
	var a := ImpressaoCanonica.calcular(_catalogo_mvp())
	var b := ImpressaoCanonica.calcular(_catalogo_mvp())
	assert_str(a.completa).is_equal(b.completa)
	assert_int(a.completa.length()).is_equal(64)
	assert_int(a.curta.length()).is_equal(4)
	assert_str(a.curta).is_equal(a.curta.to_upper())
	assert_bool(a.completa.to_upper().begins_with(a.curta)).is_true()


func test_mudar_um_campo_muda_a_completa() -> void:
	var cat_a := Catalogo.new(RelatorAcumulador.new())
	cat_a.adicionar(&"upgrade", _upgrade(&"u", 0.25))
	var cat_b := Catalogo.new(RelatorAcumulador.new())
	cat_b.adicionar(&"upgrade", _upgrade(&"u", 0.26))
	assert_str(_impressao(cat_a)).is_not_equal(_impressao(cat_b))


func test_trocar_ordem_no_manifesto_muda_a_completa() -> void:
	var cat_a := Catalogo.new(RelatorAcumulador.new())
	cat_a.adicionar(&"upgrade", _upgrade(&"u1", 1.0))
	cat_a.adicionar(&"upgrade", _upgrade(&"u2", 1.0))
	var cat_b := Catalogo.new(RelatorAcumulador.new())
	cat_b.adicionar(&"upgrade", _upgrade(&"u2", 1.0))
	cat_b.adicionar(&"upgrade", _upgrade(&"u1", 1.0))
	assert_str(_impressao(cat_a)).is_not_equal(_impressao(cat_b))


func test_texto_traduzido_nao_entra_e_zero_negativo_normaliza() -> void:
	# Tradução não é entrada (a impressão nem recebe TabelaDeTextos): só a chave conta.
	var antes := _impressao(_catalogo_mvp())
	var textos := FabricasDeCatalogo.textos_para(FabricasDeCatalogo.itens_mvp())
	textos.definir("WEAPON_LAMINA_NAME", "Outro nome")
	assert_str(_impressao(_catalogo_mvp())).is_equal(antes)
	var neg := Catalogo.new(RelatorAcumulador.new())
	neg.adicionar(&"upgrade", _upgrade(&"u", -0.0))
	var pos := Catalogo.new(RelatorAcumulador.new())
	pos.adicionar(&"upgrade", _upgrade(&"u", 0.0))
	assert_str(_impressao(neg)).is_equal(_impressao(pos))


func test_subrecurso_compartilhado_equivale_a_repetir_valores() -> void:
	var compartilhado := Catalogo.new(RelatorAcumulador.new())
	var u1 := _upgrade(&"u1", 3.0)
	var u2 := _upgrade(&"u2", 0.0)
	u2.efeitos = [u1.efeitos[0]]
	compartilhado.adicionar(&"upgrade", u1)
	compartilhado.adicionar(&"upgrade", u2)
	var repetido := Catalogo.new(RelatorAcumulador.new())
	repetido.adicionar(&"upgrade", _upgrade(&"u1", 3.0))
	repetido.adicionar(&"upgrade", _upgrade(&"u2", 3.0))
	assert_str(_impressao(compartilhado)).is_equal(_impressao(repetido))


func test_nan_infinito_e_valor_fora_do_esquema_sao_erros() -> void:
	for ruim: float in [NAN, INF, -INF]:
		var cat := Catalogo.new(RelatorAcumulador.new())
		cat.adicionar(&"upgrade", _upgrade(&"u", ruim))
		var r := ImpressaoCanonica.calcular(cat)
		assert_int(r.erros.size()).is_equal(1)
		assert_str(r.completa).is_empty()
	var fora := Catalogo.new(RelatorAcumulador.new())
	var u := _upgrade(&"u", 1.0)
	u.efeitos[0].params = {&"x": 1.0}
	(u.efeitos[0] as EffectDef).set_meta(&"editor", 1)  # metadado do editor: ignorado
	fora.adicionar(&"upgrade", u)
	assert_array(ImpressaoCanonica.calcular(fora).erros).is_empty()
	var objeto_estranho: Array = [Node2D]
	var r2 := ImpressaoCanonica.calcular_de_listas([&"upgrade"] as Array[StringName], [[_com_lista_estranha(objeto_estranho)]])
	assert_int(r2.erros.size()).is_greater(0)


func test_ciclo_de_subrecursos_e_contagem_acima_de_u32_sao_erros() -> void:
	var ciclo := _CicloDeTeste.new()
	ciclo.proximo = ciclo
	var r := ImpressaoCanonica.calcular_de_listas([&"upgrade"] as Array[StringName], [[_com_lista_estranha([ciclo])]])
	ciclo.proximo = null  # quebra o ciclo de referência (sem vazamento no teste)
	assert_int(r.erros.size()).is_greater(0)
	assert_bool(ImpressaoCanonica.cabe_em_u32(ImpressaoCanonica.MAX_U32)).is_true()
	assert_bool(ImpressaoCanonica.cabe_em_u32(ImpressaoCanonica.MAX_U32 + 1)).is_false()


func test_carregador_publica_impressao_no_catalogo() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var leitor := _LeitorEmMemoria.new()
	var manifesto := ManifestoDoCatalogo.new()
	for item in itens:
		manifesto.tipos.append(item.tipo)
		manifesto.caminhos.append(item.caminho)
		leitor.recursos[item.caminho] = item.definicao
	leitor.recursos["res://m.tres"] = manifesto
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(itens), _ArteFalsa.new())
	var c := CarregadorDeCatalogo.new(v, RelatorAcumulador.new(), leitor, Unidades.TICK_RATE)
	assert_bool(c.carregar("res://m.tres")).is_true()
	var cat := c.catalogo()
	assert_int(cat.impressao_completa().length()).is_equal(64)
	assert_str(cat.impressao_curta()).is_equal(cat.impressao_completa().substr(0, 4).to_upper())
	assert_str(cat.impressao_completa()).is_equal(_impressao(_catalogo_mvp()))


## UpgradeDef cujo campo [code]efeitos[/code] recebe uma lista sem tipo (para injetar valores ruins).
func _com_lista_estranha(lista: Array) -> DefinicaoBase:
	var d := _DefComLivre.new()
	d.id = &"estranha"
	d.livre = lista
	return d


class _DefComLivre:
	extends DefinicaoBase
	@export var livre: Array = []


class _CicloDeTeste:
	extends DadoDeConteudo
	@export var proximo: DadoDeConteudo = null


class _ArteFalsa:
	extends VerificadorDeArte

	func existe(_caminho: String) -> bool:
		return false


class _LeitorEmMemoria:
	extends CarregadorDeCatalogo.Leitor
	var recursos: Dictionary[String, Resource] = {}

	func existe(caminho: String) -> bool:
		return recursos.has(caminho)

	func carregar(caminho: String) -> Resource:
		return recursos.get(caminho, null)
