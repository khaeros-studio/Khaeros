extends GdUnitTestSuite
## Story conteudo-003 [I]: carregador síncrono com ResourceLoader real sobre .tres
## gravados numa pasta temporária de user:// (limpa ao fim). AC-02, AC-03, AC-24 e
## a forma de AC-01 (o manifesto real de assets/data/ é do épico assets-e-conteudo).

const RAIZ := "user://teste_conteudo_carga"


class ArteSempre:
	extends VerificadorDeArte

	func existe(_caminho: String) -> bool:
		return true


var _itens: Array[ItemDoCatalogo] = []


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(RAIZ)
	_itens = FabricasDeCatalogo.itens_mvp()


func after_test() -> void:
	var d := DirAccess.open(RAIZ)
	if d != null:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(RAIZ)


func _gravar_manifesto(defs: Array[ItemDoCatalogo], extras: PackedStringArray = []) -> String:
	var m := ManifestoDoCatalogo.new()
	for item in defs:
		var caminho := "%s/%s_%s.tres" % [RAIZ, item.tipo, item.definicao.id]
		assert_int(ResourceSaver.save(item.definicao, caminho)).is_equal(OK)
		m.acrescentar(item.tipo, caminho)
	for e in extras:
		m.acrescentar(&"enemy", e)
	var caminho_m := RAIZ + "/content_catalog.tres"
	assert_int(ResourceSaver.save(m, caminho_m)).is_equal(OK)
	return caminho_m


func _carregador() -> CarregadorDeCatalogo:
	var v := ValidadorDeCatalogo.new(FabricasDeCatalogo.registros(), FabricasDeCatalogo.textos_para(_itens), ArteSempre.new())
	return CarregadorDeCatalogo.new(v, RelatorAcumulador.new())


func test_manifesto_valido_termina_pronto_com_os_ids_listados() -> void:
	var caminho := _gravar_manifesto(_itens)
	var c := _carregador()
	var ok := c.carregar(caminho)
	assert_bool(ok).override_failure_message(str(c.diagnosticos().map(func(d: Diagnostico) -> String: return d.texto()))).is_true()
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	var cat := c.catalogo()
	for item in _itens:
		assert_bool(cat.existe(item.tipo, item.definicao.id)).is_true()
	var especies: Array = cat.listar(&"curse").map(func(d: DefinicaoBase) -> StringName: return d.id)
	assert_array(especies).is_equal(FabricasDeCatalogo.ESPECIES)
	var chefe := cat.obter(&"enemy", &"soberano_do_limiar", "teste") as EnemyDef
	assert_int(chefe.padroes.size()).is_equal(4)


func test_manifesto_inexistente_falha_com_um_erro_e_sem_definicoes() -> void:
	var c := _carregador()
	var ok := c.carregar(RAIZ + "/nao_existe.tres")
	assert_bool(ok).is_false()
	assert_int(c.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)
	assert_int(c.diagnosticos().size()).is_equal(1)
	assert_str(c.diagnosticos()[0].mensagem).starts_with("manifesto não encontrado: ")
	assert_object(c.catalogo()).is_null()


func test_dois_arquivos_inexistentes_e_uma_definicao_invalida_dao_tres_erros() -> void:
	var defs: Array[ItemDoCatalogo] = []
	var ruim := FabricasDeCatalogo.inimigo(&"eco_ruim")
	ruim.vida = 0.0
	ruim.chave_nome = &"ENEMY_ECO_PERDIDO_NAME"
	defs.append(ItemDoCatalogo.new(&"enemy", "", 0, ruim))
	var caminho := _gravar_manifesto(defs, PackedStringArray([RAIZ + "/falta_a.tres", RAIZ + "/falta_b.tres"]))
	var c := _carregador()
	var ok := c.carregar(caminho)
	assert_bool(ok).is_false()
	var regras: Array = c.diagnosticos().map(func(d: Diagnostico) -> String: return String(d.regra))
	assert_array(regras).contains_exactly_in_any_order(["V2", "LEITURA", "LEITURA"])


func test_src_fora_do_carregador_nao_abre_assets_data() -> void:
	var re := RegEx.create_from_string("(load\\(|preload\\(|ResourceLoader)[^\\n]*assets/data")
	var achados: PackedStringArray = []
	_varrer("res://src", re, achados)
	assert_array(Array(achados)).is_empty()


func _varrer(pasta: String, re: RegEx, achados: PackedStringArray) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	for sub in d.get_directories():
		_varrer(pasta + "/" + sub, re, achados)
	for f in d.get_files():
		if not f.ends_with(".gd") or f == "carregador_de_catalogo.gd":
			continue
		var texto := FileAccess.get_file_as_string(pasta + "/" + f)
		if re.search(texto) != null:
			achados.append(pasta + "/" + f)
