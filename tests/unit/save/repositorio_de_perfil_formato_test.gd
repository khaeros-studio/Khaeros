## Story persistencia/003: formato do perfil.cfg, seção [vinculo] opaca, texto
## determinístico e "só grava se mudou". ArmazemEmMemoria, sem I/O.
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const PERFIL := "user://perfil.cfg"
const IDS := ["vulto_mudo"]

var _avisos: Array[StringName] = []


func before_test() -> void:
	_avisos.clear()


func _estado_ac_sp_02() -> Dictionary:
	return {
		"especies": {"vulto_mudo": {"pactuada": true, "vinculo_pontos": 7, "nivel": 1, "encontros_vistos": 2}},
		"ultima_dupla": ["vulto_mudo", ""],
	}


func _repo(a: ArmazemDeArquivos, v: PortaDeSecao) -> RepositorioDePerfil:
	return RepositorioDePerfil.new(a, CaminhosDePersistencia.de(0),
		func(chave: StringName) -> void: _avisos.append(chave), PackedStringArray(IDS), v)


func test_ida_e_volta_ler_recebe_dicionario_igual_e_schema_1() -> void:
	# AC-SP-02
	var a := ArmazemEmMemoria.new()
	var v1 := VinculoFalso.new()
	v1.estado = _estado_ac_sp_02()
	var r1 := _repo(a, v1)
	r1.carregar()
	assert_int(r1.salvar()).is_equal(OK)
	var v2 := VinculoFalso.new()
	_repo(a, v2).carregar()
	assert_int(v2.lidos.size()).is_equal(1)
	assert_dict(v2.lidos[0]).is_equal(_estado_ac_sp_02())
	var cf := ConfigFile.new()
	assert_int(cf.parse(a.texto_de(PERFIL))).is_equal(OK)
	assert_int(cf.get_value("meta", "schema_version")).is_equal(1)


func test_gatilho_sem_mudanca_zero_gravar_atomico() -> void:
	# AC-SP-03
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	v.estado = _estado_ac_sp_02()
	var r := _repo(a, v)
	r.carregar()
	r.salvar()
	var antes := a.contar(&"gravar_atomico")
	assert_int(r.salvar()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(antes)


func test_perfil_carregado_sem_mudanca_nao_regrava() -> void:
	var a := ArmazemEmMemoria.new()
	var v1 := VinculoFalso.new()
	v1.estado = _estado_ac_sp_02()
	var r1 := _repo(a, v1)
	r1.carregar()
	r1.salvar()
	var v2 := VinculoFalso.new()
	v2.estado = _estado_ac_sp_02()
	var r2 := _repo(a, v2)
	r2.carregar()
	assert_int(r2.salvar()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)


func test_gatilho_com_mudanca_grava_uma_vez() -> void:
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	v.estado = _estado_ac_sp_02()
	var r := _repo(a, v)
	r.carregar()
	r.salvar()
	v.estado["especies"]["vulto_mudo"]["vinculo_pontos"] = 8
	assert_int(r.salvar()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(2)


func test_float_em_especies_carrega_como_corrompido() -> void:
	# AC-SP-16
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "[meta]\nschema_version=1\n[vinculo]\nespecies={\"vulto_mudo\": {\"nivel\": 1.5}}\n")
	var v := VinculoFalso.new()
	_repo(a, v).carregar()
	assert_bool(a.tem_arquivo(PERFIL + ".bak")).is_true()
	assert_array(_avisos).is_equal([RepositorioDePerfil.AVISO_CORROMPIDO])
	assert_dict(v.lidos[0]).is_empty()


func test_mesmo_escrever_duas_vezes_textos_identicos_e_sem_dados_pessoais() -> void:
	# AC-SP-23
	var v := VinculoFalso.new()
	v.estado = _estado_ac_sp_02()
	var a1 := ArmazemEmMemoria.new()
	var a2 := ArmazemEmMemoria.new()
	var r1 := _repo(a1, v)
	var r2 := _repo(a2, v)
	r1.carregar()
	r2.carregar()
	r1.salvar()
	r2.salvar()
	var t1 := a1.bytes_de(PERFIL)
	assert_array(Array(t1)).is_equal(Array(a2.bytes_de(PERFIL)))
	var texto := t1.get_string_from_utf8()
	assert_str(texto).not_contains("user://")
	assert_str(texto).not_contains(":\\")
	assert_str(texto).not_contains(":/")
	assert_str(texto).not_contains("Users")


func test_ordem_de_chaves_em_escrever_nao_muda_o_texto() -> void:
	var a1 := ArmazemEmMemoria.new()
	var a2 := ArmazemEmMemoria.new()
	var v1 := VinculoFalso.new()
	v1.estado = {"ultima_dupla": ["", ""], "especies": {"b": {"y": 1, "x": 2}, "a": {}}}
	var v2 := VinculoFalso.new()
	v2.estado = {"especies": {"a": {}, "b": {"x": 2, "y": 1}}, "ultima_dupla": ["", ""]}
	var r1 := RepositorioDePerfil.new(a1, CaminhosDePersistencia.de(0), Callable(), PackedStringArray(["a", "b"]), v1)
	var r2 := RepositorioDePerfil.new(a2, CaminhosDePersistencia.de(0), Callable(), PackedStringArray(["a", "b"]), v2)
	r1.carregar()
	r2.carregar()
	r1.salvar()
	r2.salvar()
	assert_str(a1.texto_de(PERFIL)).is_equal(a2.texto_de(PERFIL))


func test_escrever_com_tipo_proibido_nao_grava_e_devolve_erro() -> void:
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	v.estado = {"especies": {"vulto_mudo": {"nivel": 1.0}}}
	var r := _repo(a, v)
	r.carregar()
	assert_int(r.salvar()).is_equal(ERR_INVALID_DATA)
	v.estado = {"especies": {}, "id": &"sn"}
	assert_int(r.salvar()).is_equal(ERR_INVALID_DATA)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)


func test_salvar_falha_do_armazem_devolve_erro_e_proximo_tenta_de_novo() -> void:
	var a := ArmazemEmMemoria.new()
	a.programar_falha(&"gravar_atomico", 1)
	var v := VinculoFalso.new()
	v.estado = _estado_ac_sp_02()
	var r := _repo(a, v)
	r.carregar()
	assert_int(r.salvar()).is_not_equal(OK)
	assert_bool(a.tem_arquivo(PERFIL)).is_false()
	assert_int(r.salvar()).is_equal(OK)
	assert_bool(a.tem_arquivo(PERFIL)).is_true()


func test_escrever_vazio_grava_so_meta() -> void:
	var a := ArmazemEmMemoria.new()
	var r := _repo(a, VinculoFalso.new())
	r.carregar()
	r.salvar()
	var cf := ConfigFile.new()
	cf.parse(a.texto_de(PERFIL))
	assert_array(Array(cf.get_sections())).is_equal(["meta"])


func test_gravado_por_vai_para_meta() -> void:
	var a := ArmazemEmMemoria.new()
	var r := _repo(a, VinculoFalso.new())
	r.gravado_por = "0.1.0"
	r.carregar()
	r.salvar()
	var cf := ConfigFile.new()
	cf.parse(a.texto_de(PERFIL))
	assert_str(cf.get_value("meta", "gravado_por")).is_equal("0.1.0")
