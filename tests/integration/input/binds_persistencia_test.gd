## Story input-008: salvar e recarregar binds com armazém real em raiz temporária (AC-31).
extends GdUnitTestSuite

const RAIZ := "user://_testes/input_binds_persistencia/"
const CAMINHO := "user://input_binds.cfg"

var _armazem: ArmazemUserGodot


func before_test() -> void:
	_armazem = ArmazemUserGodot.new(RAIZ)
	_armazem.garantir_pasta("user://")


func after_test() -> void:
	for nome in _armazem.listar_arquivos("user://"):
		_armazem.apagar("user://" + nome)


func test_salvar_e_recarregar_devolve_binds_iguais_e_trocar_analogicos() -> void:
	var r := TransacaoDeRemapeamento.atribuir(MapaDeBinds.padrao(), Acoes.DISPOSITIVO_TECLADO, Acoes.TROCA, 0,
			{"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": KEY_G})
	var mapa := r.mapa
	mapa.trocar_analogicos = true
	var repo := RepositorioDeBinds.new(_armazem, CAMINHO)
	assert_int(repo.salvar(mapa)).is_equal(OK)
	var lido := RepositorioDeBinds.new(_armazem, CAMINHO).carregar()
	assert_bool(lido.igual_a(mapa)).is_true()
	assert_bool(lido.trocar_analogicos).is_true()


func test_restaurar_padrao_do_gamepad_nao_mexe_no_teclado() -> void:
	var mapa := TransacaoDeRemapeamento.atribuir(MapaDeBinds.padrao(), Acoes.DISPOSITIVO_TECLADO, Acoes.TROCA, 0,
			{"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": KEY_G}).mapa
	mapa = TransacaoDeRemapeamento.remover(mapa, Acoes.DISPOSITIVO_GAMEPAD, Acoes.SELO, 1).mapa
	mapa.restaurar_padrao(Acoes.DISPOSITIVO_GAMEPAD)
	var repo := RepositorioDeBinds.new(_armazem, CAMINHO)
	repo.salvar(mapa)
	var lido := repo.carregar()
	assert_int(lido.de(Acoes.DISPOSITIVO_TECLADO, Acoes.TROCA)[0]["codigo"]).is_equal(KEY_G)
	assert_int(lido.de(Acoes.DISPOSITIVO_GAMEPAD, Acoes.SELO).size()).is_equal(2)


func test_falha_de_gravacao_devolve_erro_sem_fingir() -> void:
	var memoria := ArmazemEmMemoria.new()
	memoria.programar_falha(&"gravar_atomico", 1)
	var repo := RepositorioDeBinds.new(memoria, CAMINHO)
	assert_int(repo.salvar(MapaDeBinds.padrao())).is_not_equal(OK)
	assert_bool(memoria.tem_arquivo(CAMINHO)).is_false()
