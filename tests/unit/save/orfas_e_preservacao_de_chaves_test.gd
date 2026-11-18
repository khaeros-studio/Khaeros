## Story persistencia/005: ids desconhecidos (órfãs, campos_de_ids) e preservação de
## chaves/seções desconhecidas na regravação (save-e-perfil R9).
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const PERFIL := "user://perfil.cfg"
const X := {"pactuada": true, "vinculo_pontos": 3, "nivel": 1}


func _repo(a: ArmazemDeArquivos, v: PortaDeSecao) -> RepositorioDePerfil:
	return RepositorioDePerfil.new(a, CaminhosDePersistencia.de(0), Callable(),
		PackedStringArray(["vulto_mudo"]), v)


func _arquivo(vinculo: Dictionary, extra: String = "") -> String:
	var cf := ConfigFile.new()
	cf.set_value("meta", "schema_version", 1)
	for k in vinculo.keys():
		cf.set_value("vinculo", k, vinculo[k])
	return cf.encode_to_text() + extra


func _ler_secao(texto: String, secao: String) -> Dictionary:
	var cf := ConfigFile.new()
	cf.parse(texto)
	var d: Dictionary = {}
	if cf.has_section(secao):
		for k in cf.get_section_keys(secao):
			d[k] = cf.get_value(secao, k)
	return d


func test_especie_fora_do_catalogo_fica_orfa_e_volta_ao_arquivo() -> void:
	# AC-SP-13
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {"vulto_mudo": {"nivel": 1}, "especie_teste_x": X}}))
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	r.carregar()
	assert_bool((v.lidos[0]["especies"] as Dictionary).has("especie_teste_x")).is_false()
	assert_bool((v.lidos[0]["especies"] as Dictionary).has("vulto_mudo")).is_true()
	# o Vínculo devolve só o que conhece, com mudança para forçar gravação
	v.estado = {"especies": {"vulto_mudo": {"nivel": 2}}}
	assert_int(r.salvar()).is_equal(OK)
	var especies: Dictionary = _ler_secao(a.texto_de(PERFIL), "vinculo")["especies"]
	assert_dict(especies["especie_teste_x"]).is_equal(X)
	assert_dict(especies["vulto_mudo"]).is_equal({"nivel": 2})


func test_orfa_reaparece_quando_build_com_a_especie_le() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {"especie_teste_x": X}}))
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	r.carregar()
	v.estado = {"especies": {"vulto_mudo": {"nivel": 1}}}
	r.salvar()
	var v2 := VinculoFalso.new()
	RepositorioDePerfil.new(a, CaminhosDePersistencia.de(0), Callable(),
		PackedStringArray(["vulto_mudo", "especie_teste_x"]), v2).carregar()
	assert_dict(v2.lidos[0]["especies"]["especie_teste_x"]).is_equal(X)


func test_ultima_dupla_id_desconhecido_vira_vazio() -> void:
	# AC-SP-14
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {}, "ultima_dupla": ["especie_teste_x", "vulto_mudo"]}))
	var v := VinculoFalso.new()
	_repo(a, v).carregar()
	assert_array(v.lidos[0]["ultima_dupla"]).is_equal(["", "vulto_mudo"])


func test_encontro_pendente_id_desconhecido_vira_vazio() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {}, "encontro_pendente": ["especie_teste_x"]}))
	var v := VinculoFalso.new()
	_repo(a, v).carregar()
	assert_array(v.lidos[0]["encontro_pendente"]).is_equal([""])


func test_secao_desconhecida_preservada_ao_regravar() -> void:
	# AC-SP-15
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {}}, "\n[oficina]\n\nnivel=3\n"))
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	r.carregar()
	v.estado = {"especies": {"vulto_mudo": {"nivel": 1}}}
	assert_int(r.salvar()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)
	assert_dict(_ler_secao(a.texto_de(PERFIL), "oficina")).is_equal({"nivel": 3})


func test_chave_desconhecida_em_vinculo_preservada_se_escrever_nao_a_traz() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {}, "campo_do_futuro": [1, 2]}))
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	r.carregar()
	v.estado = {"especies": {"vulto_mudo": {"nivel": 1}}, "versao": 1}
	r.salvar()
	var vinc := _ler_secao(a.texto_de(PERFIL), "vinculo")
	assert_array(vinc["campo_do_futuro"]).is_equal([1, 2])
	assert_int(vinc["versao"]).is_equal(1)


func test_preservacao_mantem_texto_identico_entre_gravacoes_iguais() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _arquivo({"especies": {"especie_teste_x": X}}, "\n[oficina]\n\nnivel=3\n"))
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	r.carregar()
	v.estado = {"especies": {"vulto_mudo": {"nivel": 1}}}
	r.salvar()
	var primeiro := a.texto_de(PERFIL)
	# nova sessão, mesmo estado: o texto montado é o mesmo, nada é gravado
	var v2 := VinculoFalso.new()
	v2.estado = {"especies": {"vulto_mudo": {"nivel": 1}}}
	var r2 := _repo(a, v2)
	r2.carregar()
	assert_str(r2.texto_atual()).is_equal(primeiro)
	r2.salvar()
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)
