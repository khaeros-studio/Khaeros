## Story input-008: arquivo de binds corrompido, .bak byte a byte e chaves desconhecidas/ausentes (AC-32).
extends GdUnitTestSuite

const RAIZ := "user://_testes/input_binds_corrompidos/"
const CAMINHO := "user://input_binds.cfg"
const LIXO := "%%lixo\u0000[[[ não é cfg"

var _armazem: ArmazemUserGodot
var _avisos: Array[StringName] = []


func before_test() -> void:
	_avisos.clear()
	_armazem = ArmazemUserGodot.new(RAIZ)
	_armazem.garantir_pasta("user://")


func after_test() -> void:
	for nome in _armazem.listar_arquivos("user://"):
		_armazem.apagar("user://" + nome)


func _repo(armazem: ArmazemDeArquivos) -> RepositorioDeBinds:
	return RepositorioDeBinds.new(armazem, CAMINHO, func(c: StringName) -> void: _avisos.append(c))


func _gravar_texto(texto: String) -> PackedByteArray:
	var w := _armazem.criar_escritor_de_linhas(CAMINHO)
	w.escrever_linha(texto)
	w.fechar()
	return _armazem.ler_texto(CAMINHO).bytes


func test_lixo_usa_padroes_avisa_uma_vez_e_bak_identico() -> void:
	var original := _gravar_texto(LIXO)
	var repo := _repo(_armazem)
	assert_bool(repo.carregar().igual_a(MapaDeBinds.padrao())).is_true()
	repo.carregar()
	assert_array(_avisos).is_equal([RepositorioDeBinds.AVISO_CORROMPIDO])
	assert_array(_armazem.ler_texto(CAMINHO + ".bak").bytes).is_equal(original)
	assert_bool(_armazem.existe(CAMINHO + ".bak2")).is_true() # 2ª carga não apaga o 1º backup


func test_chave_desconhecida_ignorada_e_ausente_recebe_padrao() -> void:
	var memoria := ArmazemEmMemoria.new()
	memoria.colocar_texto(CAMINHO, "[meta]\nschema_version=1\n[teclado]\nvoar=[{\"tipo\": \"tecla_fisica\", \"codigo\": %d}]\nselo=[{\"tipo\": \"tecla_fisica\", \"codigo\": %d}]\n" % [KEY_V, KEY_Q])
	var mapa := _repo(memoria).carregar()
	assert_int(mapa.de(Acoes.DISPOSITIVO_TECLADO, Acoes.SELO).size()).is_equal(1)
	assert_bool(mapa.de(Acoes.DISPOSITIVO_TECLADO, &"voar").is_empty()).is_true()
	assert_int(mapa.de(Acoes.DISPOSITIVO_TECLADO, Acoes.ATAQUE).size()).is_equal(2)
	assert_bool(_avisos.has(RepositorioDeBinds.AVISO_CORROMPIDO)).is_false()


func test_entrada_conhecida_invalida_torna_o_arquivo_invalido() -> void:
	var memoria := ArmazemEmMemoria.new()
	memoria.colocar_texto(CAMINHO, "[meta]\nschema_version=1\n[teclado]\nselo=[{\"tipo\": \"tecla_fisica\", \"codigo\": %d}]\nataque=[{\"tipo\": \"xyz\", \"codigo\": 1}]\n" % KEY_Q)
	assert_bool(_repo(memoria).carregar().igual_a(MapaDeBinds.padrao())).is_true()
	assert_array(_avisos).is_equal([RepositorioDeBinds.AVISO_CORROMPIDO])


func test_falha_ao_preservar_bak_impede_sobrescrita_e_segue_com_padroes() -> void:
	var memoria := ArmazemEmMemoria.new()
	memoria.colocar_texto(CAMINHO, LIXO)
	memoria.programar_falha(&"copiar_bytes", 1)
	var repo := _repo(memoria)
	assert_bool(repo.carregar().igual_a(MapaDeBinds.padrao())).is_true()
	assert_bool(repo.sem_gravacao()).is_true()
	assert_int(repo.salvar(MapaDeBinds.padrao())).is_not_equal(OK)
	assert_str(memoria.texto_de(CAMINHO)).is_equal(LIXO)


func test_versao_futura_usa_padroes_e_preserva_arquivo() -> void:
	var memoria := ArmazemEmMemoria.new()
	var texto := "[meta]\nschema_version=99\n"
	memoria.colocar_texto(CAMINHO, texto)
	var repo := _repo(memoria)
	assert_bool(repo.carregar().igual_a(MapaDeBinds.padrao())).is_true()
	assert_bool(repo.versao_futura()).is_true()
	assert_str(memoria.texto_de(CAMINHO)).is_equal(texto)
	assert_bool(_avisos.is_empty()).is_true()
