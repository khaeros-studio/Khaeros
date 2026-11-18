extends GdUnitTestSuite
## Story conteudo-009 [I]: recarga de arquivos .tres editados em disco com
## ResourceLoader.CACHE_MODE_IGNORE_DEEP e revogação em falha (AC-47, AC-51).

const PASTA_TEMP := "user://teste_recarga_disco"


class ArteSempre:
	extends VerificadorDeArte
	func existe(_c: String) -> bool:
		return true


class ConsumidorInputFalso:
	extends ConsumidorDeAjustes
	var tuning: InputTuning = null
	var revogacoes: int = 0
	var recepcoes: int = 0

	func receber_ajustes(catalogo: Catalogo) -> void:
		recepcoes += 1
		tuning = catalogo.obter(&"tuning", &"input_tuning", "input_falso") as InputTuning

	func revogar_ajustes() -> void:
		revogacoes += 1
		tuning = null


var _itens: Array[ItemDoCatalogo] = []


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_TEMP)
	_itens = FabricasDeCatalogo.itens_mvp()
	var it := InputTuning.new()
	it.id = &"input_tuning"
	it.buffer_passos = 10
	it.zona_morta_interna = 0.20
	it.zona_morta_externa = 0.05
	it.raio_mira_px = 540.0
	it.limiar_mouse_px = 4.0
	it.gatilho_aperta = 0.50
	it.gatilho_solta = 0.40
	_itens.append(ItemDoCatalogo.new(&"tuning", PASTA_TEMP + "/tuning_input_tuning.tres", _itens.size(), it))


func after_test() -> void:
	var d := DirAccess.open(PASTA_TEMP)
	if d != null:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(PASTA_TEMP)


func _gravar_em_disco() -> String:
	var m := ManifestoDoCatalogo.new()
	for item in _itens:
		var caminho := "%s/%s_%s.tres" % [PASTA_TEMP, item.tipo, item.definicao.id]
		assert_int(ResourceSaver.save(item.definicao, caminho)).is_equal(OK)
		m.acrescentar(item.tipo, caminho)
	var caminho_m := PASTA_TEMP + "/content_catalog.tres"
	assert_int(ResourceSaver.save(m, caminho_m)).is_equal(OK)
	return caminho_m


func test_ac47_e_ac51_recarga_em_disco_ignora_cache_atualiza_impressao_e_revoga_em_falha() -> void:
	var caminho_m := _gravar_em_disco()
	var v := ValidadorDeCatalogo.new(
		FabricasDeCatalogo.registros(),
		FabricasDeCatalogo.textos_para(_itens),
		ArteSempre.new()
	)
	var carregador := CarregadorDeCatalogo.new(v, RelatorAcumulador.new(), null, 60)
	carregador.definir_debug_build(true)
	carregador.definir_consulta_em_run(func() -> bool: return false)

	var consumidor := ConsumidorInputFalso.new()
	carregador.registrar_consumidor(consumidor)

	# 1. Carga inicial em Pronto
	assert_bool(carregador.carregar(caminho_m)).is_true()
	assert_int(carregador.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	assert_object(consumidor.tuning).is_not_null()
	assert_int(consumidor.tuning.buffer_passos).is_equal(10)
	var impressao_1 := carregador.catalogo().impressao_completa()
	assert_int(impressao_1.length()).is_equal(64)

	# 2. Edita input_tuning.tres diretamente no disco (buffer_passos: 10 -> 14)
	var caminho_it := PASTA_TEMP + "/tuning_input_tuning.tres"
	var it_novo := InputTuning.new()
	it_novo.id = &"input_tuning"
	it_novo.buffer_passos = 14
	it_novo.zona_morta_interna = 0.25
	it_novo.zona_morta_externa = 0.05
	it_novo.raio_mira_px = 540.0
	it_novo.limiar_mouse_px = 4.0
	it_novo.gatilho_aperta = 0.50
	it_novo.gatilho_solta = 0.40
	assert_int(ResourceSaver.save(it_novo, caminho_it)).is_equal(OK)

	# 3. Recarrega fora de run -> lê o valor novo sem cache e recalcula impressão
	assert_bool(carregador.recarregar(caminho_m)).is_true()
	assert_int(carregador.estado()).is_equal(CarregadorDeCatalogo.Estado.PRONTO)
	assert_object(consumidor.tuning).is_not_null()
	assert_int(consumidor.tuning.buffer_passos).is_equal(14)
	var impressao_2 := carregador.catalogo().impressao_completa()
	assert_str(impressao_2).is_not_equal(impressao_1)

	# 4. Edita input_tuning.tres com zm + ze >= 1.0 e recarrega -> Falhou e consumidor sem tuning (AC-51)
	it_novo.zona_morta_interna = 0.85
	it_novo.zona_morta_externa = 0.20
	assert_int(ResourceSaver.save(it_novo, caminho_it)).is_equal(OK)

	assert_bool(carregador.recarregar(caminho_m)).is_false()
	assert_int(carregador.estado()).is_equal(CarregadorDeCatalogo.Estado.FALHOU)
	assert_object(carregador.catalogo()).is_null()
	assert_object(consumidor.tuning).is_null()
