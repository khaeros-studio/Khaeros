## Story persistencia/008: Sair grava antes do fim (AC-SP-20, TR-save-013) e reset com
## duas confirmações e .reset.bak (AC-SP-18, AC-SP-19, TR-save-014).
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const PERFIL := "user://perfil.cfg"
const ORFA := {"pactuada": true, "nivel": 2}

var _avisos: Array[StringName] = []


func before_test() -> void:
	_avisos = []


func _avisar(chave: StringName) -> void:
	_avisos.append(chave)


func _save(a: ArmazemDeArquivos, v: PortaDeSecao) -> Save:
	var s := Save.new()
	s.configurar(RepositorioDePerfil.new(a, CaminhosDePersistencia.de(0), _avisar,
		PackedStringArray(["vulto_mudo"]), v), _avisar)
	s.carregar(true)
	return s


func _perfil_com_pacto_e_orfa() -> String:
	var cf := ConfigFile.new()
	cf.set_value("meta", "schema_version", 1)
	cf.set_value("meta", "gravado_por", "")
	cf.set_value("vinculo", "especies", {"especie_teste_x": ORFA, "vulto_mudo": {"pactuada": true}})
	return cf.encode_to_text()


func test_sair_com_mudanca_grava_uma_vez_antes_do_fim() -> void:
	# AC-SP-20 (sucesso)
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	var s := _save(a, v)
	v.estado = {"especies": {"vulto_mudo": {"vinculo_pontos": 5}}}
	assert_int(s.pedir_saida()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)
	assert_array(_avisos).is_empty()


func test_sair_com_falha_avisa_e_tentar_de_novo_faz_uma_tentativa() -> void:
	# AC-SP-20 (falha)
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	var s := _save(a, v)
	v.estado = {"especies": {"vulto_mudo": {"vinculo_pontos": 5}}}
	a.programar_falha(&"gravar_atomico", 1)
	assert_int(s.pedir_saida()).is_not_equal(OK)
	assert_array(_avisos).is_equal([Save.AVISO_SAIR_SEM_SALVAR])
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)
	assert_int(s.tentar_saida_de_novo()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(2)
	assert_array(_avisos).is_equal([Save.AVISO_SAIR_SEM_SALVAR])


func test_fechar_janela_consolida_abandono_antes_de_gravar() -> void:
	# TR-save-013: o Vínculo consolida a run e o resultado entra na gravação
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	var s := _save(a, v)
	var consolidar := func() -> void:
		v.estado = {"especies": {"vulto_mudo": {"vinculo_pontos": 8}}}
	assert_int(s.pedir_saida(consolidar)).is_equal(OK)
	assert_str(a.texto_de(PERFIL)).contains("\"vinculo_pontos\": 8")


func test_reset_duas_confirmacoes_copia_le_vazio_e_grava_sem_orfa() -> void:
	# AC-SP-18
	var a := ArmazemEmMemoria.new()
	var original := _perfil_com_pacto_e_orfa()
	a.colocar_texto(PERFIL, original)
	var v := VinculoFalso.new()
	var s := _save(a, v)
	var c := CaminhosDePersistencia.de(0)
	v.estado = {}
	assert_int(s.resetar(Save.CONFIRMACOES_DO_RESET)).is_equal(OK)
	assert_int(s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)).is_equal(OK)
	assert_str(a.texto_de(PERFIL + ".reset.bak")).is_equal(original)
	assert_dict(v.lidos[v.lidos.size() - 1]).is_equal({})
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)
	assert_str(a.texto_de(PERFIL)).not_contains("especie_teste_x")
	for outro: String in [c.opcoes, c.preferencias, c.input_binds]:
		assert_int(a.contar_tudo_sobre(outro)).is_equal(0)


func test_reset_com_reset_bak_existente_usa_reset_bak2() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _perfil_com_pacto_e_orfa())
	a.colocar_texto(PERFIL + ".reset.bak", "antigo")
	var s := _save(a, VinculoFalso.new())
	assert_int(s.resetar(Save.CONFIRMACOES_DO_RESET)).is_equal(OK)
	assert_str(a.texto_de(PERFIL + ".reset.bak")).is_equal("antigo")
	assert_bool(a.tem_arquivo(PERFIL + ".reset.bak2")).is_true()


func test_reset_copia_falha_cancela_sem_gravar_nem_ler() -> void:
	# AC-SP-19
	var a := ArmazemEmMemoria.new()
	var original := _perfil_com_pacto_e_orfa()
	a.colocar_texto(PERFIL, original)
	var v := VinculoFalso.new()
	var s := _save(a, v)
	a.programar_falha(&"copiar_bytes", 1)
	assert_int(s.resetar(Save.CONFIRMACOES_DO_RESET)).is_not_equal(OK)
	s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
	assert_int(v.lidos.size()).is_equal(1)
	assert_str(a.texto_de(PERFIL)).is_equal(original)


func test_reset_com_uma_confirmacao_nao_faz_nada() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, _perfil_com_pacto_e_orfa())
	var v := VinculoFalso.new()
	var s := _save(a, v)
	assert_int(s.resetar(Save.CONFIRMACOES_DO_RESET - 1)).is_equal(ERR_UNAUTHORIZED)
	assert_int(a.contar(&"copiar_bytes")).is_equal(0)
	assert_int(v.lidos.size()).is_equal(1)


func test_reset_indisponivel_em_sem_gravacao() -> void:
	# AC-SP-19 (segunda frase)
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "[meta]\n\nschema_version=2\n")
	var s := _save(a, VinculoFalso.new())
	assert_bool(s.reset_disponivel()).is_false()
	assert_int(s.resetar(Save.CONFIRMACOES_DO_RESET)).is_equal(ERR_UNAVAILABLE)
	assert_int(a.contar(&"copiar_bytes")).is_equal(0)
	assert_int(s.pedir_saida()).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
