## Story persistencia/004: carga com arquivo ausente, corrompido (.bak/.bakN), cópia que
## falha, versão futura, schema ausente + migração, e forma fina deixada ao Vínculo.
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const PERFIL := "user://perfil.cfg"
const LIXO := "%%lixo"
const VALIDO := "[meta]\nschema_version=1\n[vinculo]\nespecies={\"vulto_mudo\": {\"nivel\": 1}}\n"

var _avisos: Array[StringName] = []


func before_test() -> void:
	_avisos.clear()


func _repo(a: ArmazemDeArquivos, v: PortaDeSecao, m: MigracaoDePerfil = null) -> RepositorioDePerfil:
	return RepositorioDePerfil.new(a, CaminhosDePersistencia.de(0),
		func(chave: StringName) -> void: _avisos.append(chave), PackedStringArray(["vulto_mudo"]), v, m)


func test_armazem_vazio_ler_vazio_uma_vez_sem_gravacao_nem_aviso() -> void:
	# AC-SP-01
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	var modo := _repo(a, v).carregar()
	assert_int(v.lidos.size()).is_equal(1)
	assert_dict(v.lidos[0]).is_empty()
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
	assert_int(a.contar(&"copiar_bytes")).is_equal(0)
	assert_array(_avisos).is_empty()
	assert_int(modo).is_equal(ModoDoPerfil.Valor.NORMAL)


func test_lixo_copia_bak_identico_avisa_uma_vez_e_proximo_gatilho_substitui() -> void:
	# AC-SP-08
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, LIXO)
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	var modo := r.carregar()
	assert_array(Array(a.bytes_de(PERFIL + ".bak"))).is_equal(Array(LIXO.to_utf8_buffer()))
	assert_dict(v.lidos[0]).is_empty()
	assert_array(_avisos).is_equal([RepositorioDePerfil.AVISO_CORROMPIDO])
	assert_int(modo).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
	v.estado = {"especies": {}}
	assert_int(r.salvar()).is_equal(OK)
	assert_str(a.texto_de(PERFIL)).contains("schema_version=1")


func test_bak_ja_existe_copia_vai_para_bak2_e_bak_intacto() -> void:
	# AC-SP-09
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, LIXO)
	a.colocar_texto(PERFIL + ".bak", "backup antigo")
	_repo(a, VinculoFalso.new()).carregar()
	assert_str(a.texto_de(PERFIL + ".bak")).is_equal("backup antigo")
	assert_str(a.texto_de(PERFIL + ".bak2")).is_equal(LIXO)


func test_bak_e_bak2_existem_copia_vai_para_bak3() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, LIXO)
	a.colocar_texto(PERFIL + ".bak", "1")
	a.colocar_texto(PERFIL + ".bak2", "2")
	_repo(a, VinculoFalso.new()).carregar()
	assert_str(a.texto_de(PERFIL + ".bak3")).is_equal(LIXO)


func test_copia_falha_sem_gravacao_zero_gravar_e_arquivo_original() -> void:
	# AC-SP-10
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, LIXO)
	a.programar_falha(&"copiar_bytes", 1)
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	var modo := r.carregar()
	v.estado = {"especies": {"vulto_mudo": {"pactuada": true}}}
	assert_int(r.salvar()).is_equal(ERR_UNAVAILABLE)
	assert_int(modo).is_equal(ModoDoPerfil.Valor.SEM_GRAVACAO)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
	assert_str(a.texto_de(PERFIL)).is_equal(LIXO)


func test_versao_futura_ler_vazio_aviso_sem_gravacao_arquivo_igual() -> void:
	# AC-SP-11
	var futuro := "[meta]\nschema_version=2\n[vinculo]\nespecies={}\ncampo_novo=1\n"
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, futuro)
	var v := VinculoFalso.new()
	var r := _repo(a, v)
	var modo := r.carregar()
	v.estado = {"especies": {"vulto_mudo": {"pactuada": true}}}
	assert_int(r.salvar()).is_equal(ERR_UNAVAILABLE)
	assert_dict(v.lidos[0]).is_empty()
	assert_array(_avisos).is_equal([RepositorioDePerfil.AVISO_VERSAO_FUTURA])
	assert_int(modo).is_equal(ModoDoPerfil.Valor.SEM_GRAVACAO)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
	assert_int(a.contar(&"copiar_bytes")).is_equal(0)
	assert_array(Array(a.bytes_de(PERFIL))).is_equal(Array(futuro.to_utf8_buffer()))


func test_schema_ausente_tratado_como_1_e_migrado_sem_gravar() -> void:
	# AC-SP-12
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "[meta]\ngravado_por=\"0.0.1\"\n[vinculo]\nespecies={}\npontos_velhos=4\n")
	var m := MigracaoDePerfil.new(2)
	m.registrar(1, func(doc: Dictionary) -> Dictionary:
		var vinc: Dictionary = doc["vinculo"]
		vinc["pontos_novos"] = vinc["pontos_velhos"]
		vinc.erase("pontos_velhos")
		return doc)
	var v := VinculoFalso.new()
	var modo := _repo(a, v, m).carregar()
	assert_int(modo).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_dict(v.lidos[0]).is_equal({"especies": {}, "pontos_novos": 4})
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)


func test_migracao_de_conteudo_do_dono_recebe_versao_do_arquivo() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, VALIDO)
	var v := VinculoFalso.new()
	var versoes: Array[int] = []
	v.migrador = func(v_de: int, dados: Dictionary) -> Dictionary:
		versoes.append(v_de)
		dados["migrado"] = true
		return dados
	_repo(a, v).carregar()
	assert_array(versoes).is_equal([1])
	assert_bool(v.lidos[0]["migrado"]).is_true()


func test_cadeia_de_migracao_incompleta_tratada_como_corrompida() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, VALIDO)
	var v := VinculoFalso.new()
	_repo(a, v, MigracaoDePerfil.new(2)).carregar()
	assert_array(_avisos).is_equal([RepositorioDePerfil.AVISO_CORROMPIDO])
	assert_bool(a.tem_arquivo(PERFIL + ".bak")).is_true()


func test_nivel_texto_nao_e_corrompido_e_vai_para_o_vinculo() -> void:
	# AC-SP-17
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "[meta]\nschema_version=1\n[vinculo]\nespecies={\"vulto_mudo\": {\"nivel\": \"dois\", \"pactuada\": true}}\n")
	var v := VinculoFalso.new()
	_repo(a, v).carregar()
	assert_int(a.contar(&"copiar_bytes")).is_equal(0)
	assert_array(_avisos).is_empty()
	assert_str(v.lidos[0]["especies"]["vulto_mudo"]["nivel"]).is_equal("dois")


func test_casos_de_forma_corrompida() -> void:
	# Edge Cases: vazio, só espaços, schema texto, schema 0, especies não-Dictionary,
	# [vinculo] sem especies, StringName, gravado_por não-texto, chave fora de seção.
	var casos: Array[String] = [
		"",
		"   \n  ",
		"[meta]\nschema_version=\"1\"\n",
		"[meta]\nschema_version=0\n",
		"[meta]\nschema_version=-1\n",
		"[meta]\nschema_version=1\n[vinculo]\nespecies=[]\n",
		"[meta]\nschema_version=1\n[vinculo]\nultima_dupla=[\"\", \"\"]\n",
		"[meta]\nschema_version=1\n[vinculo]\nespecies={}\nx=&\"sn\"\n",
		"[meta]\nschema_version=1\ngravado_por=3\n",
		"solta=1\n[meta]\nschema_version=1\n",
	]
	for texto in casos:
		_avisos.clear()
		var a := ArmazemEmMemoria.new()
		a.colocar_texto(PERFIL, texto)
		var v := VinculoFalso.new()
		_repo(a, v).carregar()
		assert_array(_avisos).override_failure_message("caso: " + JSON.stringify(texto)).is_equal([RepositorioDePerfil.AVISO_CORROMPIDO])
		assert_dict(v.lidos[0]).is_empty()


func test_meta_presente_sem_vinculo_valido_ler_vazio() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "[meta]\nschema_version=1\n")
	var v := VinculoFalso.new()
	_repo(a, v).carregar()
	assert_array(_avisos).is_empty()
	assert_dict(v.lidos[0]).is_empty()


func test_leitura_que_falha_tratada_como_corrompida() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, VALIDO)
	a.programar_falha(&"ler_texto", 1)
	var v := VinculoFalso.new()
	_repo(a, v).carregar()
	assert_array(_avisos).is_equal([RepositorioDePerfil.AVISO_CORROMPIDO])
	assert_bool(a.tem_arquivo(PERFIL + ".bak")).is_true()


func test_aviso_corrompido_uma_vez_por_sessao_mesmo_carregando_de_novo() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, LIXO)
	var r := _repo(a, VinculoFalso.new())
	r.carregar()
	r.carregar()
	assert_array(_avisos).is_equal([RepositorioDePerfil.AVISO_CORROMPIDO])
