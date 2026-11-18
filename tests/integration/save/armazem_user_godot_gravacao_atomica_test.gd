## Story persistencia/002 [I]: ArmazemUserGodot em raiz temporária user://_testes/<caso>/.
## AC-SP-24: queda simulada em cada passo da gravação atômica → a leitura dá o arquivo
## antigo ou o novo, nunca um truncado; .tmp sozinho não é promovido. Limpa ao fim.
extends GdUnitTestSuite

const RAIZ_BASE := "user://_testes/"
const PERFIL := "user://perfil.cfg"
const ANTIGO := "[meta]\n\nschema_version=1\ngravado_por=\"antigo\"\n"
const NOVO := "[meta]\n\nschema_version=1\ngravado_por=\"novo, mais longo que o antigo\"\n"

var _raiz: String
var _a: ArmazemUserGodot


func before_test() -> void:
	_raiz = RAIZ_BASE + "armazem_user_godot/"
	_apagar_recursivo(_raiz)
	DirAccess.make_dir_recursive_absolute(_raiz)
	_a = ArmazemUserGodot.new(_raiz)


func after_test() -> void:
	_apagar_recursivo(_raiz)
	DirAccess.remove_absolute(RAIZ_BASE)


func test_resolver_caminho_logico_usa_raiz_injetada() -> void:
	assert_str(_a.resolver(PERFIL)).is_equal(_raiz + "perfil.cfg")
	assert_str(ArmazemUserGodot.new().resolver(PERFIL)).is_equal("user://perfil.cfg")


func test_gravar_atomico_sem_destino_cria_arquivo_e_nao_deixa_tmp() -> void:
	assert_int(_a.gravar_atomico(PERFIL, ANTIGO)).is_equal(OK)
	assert_str(_a.ler_texto(PERFIL).texto).is_equal(ANTIGO)
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.tmp")).is_false()


func test_gravar_atomico_sobre_destino_existente_substitui() -> void:
	_a.gravar_atomico(PERFIL, ANTIGO)
	assert_int(_a.gravar_atomico(PERFIL, NOVO)).is_equal(OK)
	assert_str(_a.ler_texto(PERFIL).texto).is_equal(NOVO)


func test_queda_com_tmp_parcial_leitura_usa_antigo_e_apaga_tmp() -> void:
	_a.gravar_atomico(PERFIL, ANTIGO)
	_a.simular_queda = ArmazemUserGodot.QUEDA_TMP_PARCIAL
	assert_int(_a.gravar_atomico(PERFIL, NOVO)).is_not_equal(OK)
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.tmp")).is_true()
	var l := ArmazemUserGodot.new(_raiz).ler_texto(PERFIL)
	assert_str(l.texto).is_equal(ANTIGO)
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.tmp")).is_false()


func test_queda_antes_de_substituir_leitura_usa_antigo() -> void:
	_a.gravar_atomico(PERFIL, ANTIGO)
	_a.simular_queda = ArmazemUserGodot.QUEDA_ANTES_DE_SUBSTITUIR
	assert_int(_a.gravar_atomico(PERFIL, NOVO)).is_not_equal(OK)
	assert_str(ArmazemUserGodot.new(_raiz).ler_texto(PERFIL).texto).is_equal(ANTIGO)


func test_tmp_sozinho_completo_nunca_e_promovido() -> void:
	_a.simular_queda = ArmazemUserGodot.QUEDA_ANTES_DE_SUBSTITUIR
	_a.gravar_atomico(PERFIL, NOVO)
	var l := ArmazemUserGodot.new(_raiz).ler_texto(PERFIL)
	assert_bool(l.existe).is_false()
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.tmp")).is_false()


func test_destino_ausente_com_old_restaura_old() -> void:
	_escrever_bruto(_raiz + "perfil.cfg.old", ANTIGO)
	_escrever_bruto(_raiz + "perfil.cfg.tmp", NOVO.substr(0, 5))
	assert_str(_a.ler_texto(PERFIL).texto).is_equal(ANTIGO)
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.old")).is_false()
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.tmp")).is_false()


func test_destino_valido_com_old_usa_destino_e_apaga_old() -> void:
	_escrever_bruto(_raiz + "perfil.cfg", NOVO)
	_escrever_bruto(_raiz + "perfil.cfg.old", ANTIGO)
	assert_str(_a.ler_texto(PERFIL).texto).is_equal(NOVO)
	assert_bool(FileAccess.file_exists(_raiz + "perfil.cfg.old")).is_false()


func test_cfg_que_nao_reinterpreta_e_rejeitado_sem_tocar_destino() -> void:
	_a.gravar_atomico(PERFIL, ANTIGO)
	# valor sem fechamento: ConfigFile.parse devolve erro
	assert_int(_a.gravar_atomico(PERFIL, "[meta]\nx={\n")).is_not_equal(OK)
	assert_str(_a.ler_texto(PERFIL).texto).is_equal(ANTIGO)


func test_copiar_bytes_real_identico_e_nao_sobrescreve() -> void:
	_a.gravar_atomico(PERFIL, ANTIGO)
	assert_int(_a.copiar_bytes(PERFIL, "user://perfil.cfg.bak")).is_equal(OK)
	assert_str(_a.ler_texto("user://perfil.cfg.bak").texto).is_equal(ANTIGO)
	assert_int(_a.copiar_bytes(PERFIL, "user://perfil.cfg.bak")).is_equal(ERR_ALREADY_EXISTS)


func test_listar_apagar_e_escritor_reais() -> void:
	assert_int(_a.garantir_pasta("user://telemetria")).is_equal(OK)
	var w := _a.criar_escritor_de_linhas("user://telemetria/s.jsonl")
	assert_object(w).is_not_null()
	assert_bool(w.escrever_linha("{}")).is_true()
	assert_bool(w.descarregar()).is_true()
	w.fechar()
	assert_array(Array(_a.listar_arquivos("user://telemetria"))).is_equal(["s.jsonl"])
	assert_int(_a.apagar("user://telemetria/s.jsonl")).is_equal(OK)
	assert_bool(_a.existe("user://telemetria/s.jsonl")).is_false()


func _escrever_bruto(fisico: String, texto: String) -> void:
	var f := FileAccess.open(fisico, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _apagar_recursivo(pasta: String) -> void:
	if not DirAccess.dir_exists_absolute(pasta):
		return
	for nome in DirAccess.get_files_at(pasta):
		DirAccess.remove_absolute(pasta.path_join(nome))
	for sub in DirAccess.get_directories_at(pasta):
		_apagar_recursivo(pasta.path_join(sub))
	DirAccess.remove_absolute(pasta)
