extends GdUnitTestSuite
## Story conteudo-007: consulta (obter, existe, listar, filtrar), ordem do manifesto e
## cópia mutável (AC-22, AC-23, AC-25, AC-26, AC-27, AC-60 parte).


class ArteFalsa:
	extends VerificadorDeArte

	func existe(_caminho: String) -> bool:
		return false


func _maldicao(id: StringName) -> CurseDef:
	var c := CurseDef.new()
	c.id = id
	return c


func _catalogo_cab() -> Catalogo:
	var cat := Catalogo.new(RelatorAcumulador.new())
	for id: StringName in [&"c", &"a", &"b"]:
		cat.adicionar(&"curse", _maldicao(id))
	return cat


func _ids(lista: Array[DefinicaoBase]) -> Array[StringName]:
	var out: Array[StringName] = []
	for d in lista:
		out.append(d.id)
	return out


## Sorteio determinístico de teste (LCG fixo; não é o RNG do jogo): escolhe índices na lista.
func _sorteio(lista: Array[DefinicaoBase], seed_fixa: int, n: int) -> Array[StringName]:
	var estado := seed_fixa
	var out: Array[StringName] = []
	for i in n:
		estado = (estado * 1103515245 + 12345) & 0x7FFFFFFF
		out.append(lista[estado % lista.size()].id)
	return out


func test_listar_e_filtrar_repetidos_e_reconstruido_mantem_ordem_do_manifesto() -> void:
	var esperado: Array[StringName] = [&"c", &"a", &"b"]
	var cat := _catalogo_cab()
	for i in 3:
		assert_array(_ids(cat.listar(&"curse"))).is_equal(esperado)
		assert_array(_ids(cat.filtrar(&"curse", func(_d: DefinicaoBase) -> bool: return true))).is_equal(esperado)
	assert_array(_ids(_catalogo_cab().listar(&"curse"))).is_equal(esperado)


func test_sorteio_com_seed_fixa_sobre_listas_repete_sequencia() -> void:
	var a := _sorteio(_catalogo_cab().listar(&"curse"), 42, 10)
	var b := _sorteio(_catalogo_cab().listar(&"curse"), 42, 10)
	assert_array(a).is_equal(b)


func test_copia_mutavel_alterada_nao_muda_definicao_do_catalogo() -> void:
	var cat := Catalogo.new(RelatorAcumulador.new())
	var chefe := FabricasDeCatalogo.chefe_soberano()
	cat.adicionar(&"enemy", chefe)
	var original := cat.obter(&"enemy", &"soberano_do_limiar", "teste") as EnemyDef
	var snapshot_dano := original.padroes[0].dano
	var snapshot_vida := original.vida
	var copia := Catalogo.copiar_mutavel(original) as EnemyDef
	copia.vida += 1.0
	copia.padroes[0].dano += 1.0
	assert_float(original.vida).is_equal(snapshot_vida)
	assert_float(original.padroes[0].dano).is_equal(snapshot_dano)
	assert_bool(copia.padroes[0] != original.padroes[0]).is_true()
	assert_bool(cat.obter(&"enemy", &"soberano_do_limiar", "teste") == original).is_true()


func test_attack_def_compartilhado_por_duas_armas_nao_da_erro() -> void:
	var itens := FabricasDeCatalogo.itens_mvp()
	var lamina := itens[0].definicao as WeaponDef
	var ress := itens[1].definicao as WeaponDef
	ress.ataque = lamina.ataque
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(itens), ArteFalsa.new())
	assert_int(Diagnostico.contar_erros(v.validar(itens))).is_equal(0)


func test_obsoleto_resolve_por_id_e_so_entra_em_listas_com_parametro() -> void:
	var cat := _catalogo_cab()
	var velho := _maldicao(&"velho")
	velho.obsoleto = true
	cat.adicionar(&"curse", velho)
	assert_object(cat.obter(&"curse", &"velho", "teste")).is_same(velho)
	assert_bool(_ids(cat.listar(&"curse")).has(&"velho")).is_false()
	assert_bool(_ids(cat.filtrar(&"curse", func(_d: DefinicaoBase) -> bool: return true)).has(&"velho")).is_false()
	assert_bool(_ids(cat.listar(&"curse", true)).has(&"velho")).is_true()
	assert_bool(_ids(cat.filtrar(&"curse", func(_d: DefinicaoBase) -> bool: return true, true)).has(&"velho")).is_true()


func test_quatro_maldicoes_de_fabrica_saem_na_ordem_do_manifesto() -> void:
	var cat := Catalogo.new(RelatorAcumulador.new())
	for item in FabricasDeCatalogo.itens_mvp():
		cat.adicionar(item.tipo, item.definicao)
	var esperado: Array[StringName] = []
	for e: StringName in FabricasDeCatalogo.ESPECIES:
		esperado.append(e)
	assert_array(_ids(cat.listar(&"curse"))).is_equal(esperado)


func test_mutar_lista_devolvida_nao_altera_catalogo() -> void:
	var cat := _catalogo_cab()
	var lista := cat.listar(&"curse")
	lista.clear()
	var filtrada := cat.filtrar(&"curse", func(_d: DefinicaoBase) -> bool: return true)
	filtrada.append(_maldicao(&"intrusa"))
	var tipos := cat.tipos()
	tipos.clear()
	assert_int(cat.listar(&"curse").size()).is_equal(3)
	assert_bool(cat.existe(&"curse", &"intrusa")).is_false()
	assert_int(cat.tipos().size()).is_equal(1)
