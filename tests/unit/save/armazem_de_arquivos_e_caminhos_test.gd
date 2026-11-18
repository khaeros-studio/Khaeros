## Story persistencia/001: contrato do ArmazemDeArquivos (pelo dublê em memória) e
## CaminhosDePersistencia. Sem I/O real, sem SceneTree.
extends GdUnitTestSuite

const PERFIL := "user://perfil.cfg"
const BAK := "user://perfil.cfg.bak"
const TEXTO := "[meta]\nschema_version=1\n"


func test_caminhos_perfil_zero_devolve_caminhos_do_adr() -> void:
	var c := CaminhosDePersistencia.de(0)
	assert_bool(c.valido).is_true()
	assert_str(c.perfil).is_equal("user://perfil.cfg")
	assert_str(c.opcoes).is_equal("user://opcoes.cfg")
	assert_str(c.preferencias).is_equal("user://preferencias.cfg")
	assert_str(c.input_binds).is_equal("user://input_binds.cfg")
	assert_str(c.pasta_telemetria).is_equal("user://telemetria")
	assert_str(c.diagnostico).is_empty()


func test_caminhos_perfil_diferente_de_zero_rejeitado_com_diagnostico() -> void:
	var c := CaminhosDePersistencia.de(1)
	assert_bool(c.valido).is_false()
	assert_str(c.perfil).is_empty()
	assert_str(c.diagnostico).contains("perfil 1")


func test_armazem_em_memoria_e_um_armazem_de_arquivos() -> void:
	var a: ArmazemDeArquivos = ArmazemEmMemoria.new()
	assert_bool(a is ArmazemDeArquivos).is_true()


func test_ler_arquivo_ausente_ok_e_nao_existe() -> void:
	var a := ArmazemEmMemoria.new()
	var l := a.ler_texto(PERFIL)
	assert_bool(l.ok).is_true()
	assert_bool(l.existe).is_false()
	assert_int(a.contar(&"ler_texto", PERFIL)).is_equal(1)


func test_gravar_atomico_e_ler_devolve_mesmo_texto() -> void:
	var a := ArmazemEmMemoria.new()
	assert_int(a.gravar_atomico(PERFIL, TEXTO)).is_equal(OK)
	var l := a.ler_texto(PERFIL)
	assert_bool(l.existe).is_true()
	assert_str(l.texto).is_equal(TEXTO)
	assert_array(Array(l.bytes)).is_equal(Array(TEXTO.to_utf8_buffer()))


func test_gravar_atomico_falha_programada_devolve_erro_e_nao_altera_mapa() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "antigo")
	a.programar_falha(&"gravar_atomico", 1)
	assert_int(a.gravar_atomico(PERFIL, "novo")).is_not_equal(OK)
	assert_str(a.texto_de(PERFIL)).is_equal("antigo")
	# a 2ª chamada não estava programada
	assert_int(a.gravar_atomico(PERFIL, "novo")).is_equal(OK)
	assert_str(a.texto_de(PERFIL)).is_equal("novo")


func test_falha_programada_pela_ordem_so_afeta_a_chamada_indicada() -> void:
	var a := ArmazemEmMemoria.new()
	a.programar_falha(&"gravar_atomico", 2)
	assert_int(a.gravar_atomico(PERFIL, "1")).is_equal(OK)
	assert_int(a.gravar_atomico(PERFIL, "2")).is_not_equal(OK)
	assert_int(a.gravar_atomico(PERFIL, "3")).is_equal(OK)
	assert_str(a.texto_de(PERFIL)).is_equal("3")


func test_falha_sempre_afeta_toda_chamada() -> void:
	var a := ArmazemEmMemoria.new()
	a.programar_falha(&"ler_texto", ArmazemEmMemoria.SEMPRE)
	a.colocar_texto(PERFIL, TEXTO)
	assert_bool(a.ler_texto(PERFIL).ok).is_false()
	assert_bool(a.ler_texto(PERFIL).ok).is_false()


func test_copiar_bytes_copia_identico_byte_a_byte() -> void:
	var a := ArmazemEmMemoria.new()
	var bruto := PackedByteArray([0, 255, 37, 37, 10])
	a.colocar_bytes(PERFIL, bruto)
	assert_int(a.copiar_bytes(PERFIL, BAK)).is_equal(OK)
	assert_array(Array(a.bytes_de(BAK))).is_equal(Array(bruto))
	assert_array(Array(a.bytes_de(PERFIL))).is_equal(Array(bruto))


func test_copiar_bytes_destino_existente_nao_sobrescreve() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "novo")
	a.colocar_texto(BAK, "backup antigo")
	assert_int(a.copiar_bytes(PERFIL, BAK)).is_equal(ERR_ALREADY_EXISTS)
	assert_str(a.texto_de(BAK)).is_equal("backup antigo")


func test_copiar_bytes_falha_programada_nao_cria_destino() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "x")
	a.programar_falha(&"copiar_bytes", 1)
	assert_int(a.copiar_bytes(PERFIL, BAK)).is_not_equal(OK)
	assert_bool(a.tem_arquivo(BAK)).is_false()


func test_existe_arquivo_e_pasta() -> void:
	var a := ArmazemEmMemoria.new()
	assert_bool(a.existe(PERFIL)).is_false()
	a.colocar_texto(PERFIL, "x")
	assert_bool(a.existe(PERFIL)).is_true()
	assert_int(a.garantir_pasta("user://telemetria/")).is_equal(OK)
	assert_bool(a.existe("user://telemetria")).is_true()
	assert_int(a.contar(&"existe")).is_equal(3)


func test_listar_arquivos_so_da_pasta_pedida() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto("user://telemetria/sessao-a.jsonl", "")
	a.colocar_texto("user://telemetria/sessao-b.jsonl", "")
	a.colocar_texto(PERFIL, "")
	var nomes := Array(a.listar_arquivos("user://telemetria/"))
	nomes.sort()
	assert_array(nomes).is_equal(["sessao-a.jsonl", "sessao-b.jsonl"])


func test_apagar_remove_e_falha_programada_preserva() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "x")
	a.programar_falha(&"apagar", 1)
	assert_int(a.apagar(PERFIL)).is_not_equal(OK)
	assert_bool(a.tem_arquivo(PERFIL)).is_true()
	assert_int(a.apagar(PERFIL)).is_equal(OK)
	assert_bool(a.tem_arquivo(PERFIL)).is_false()
	assert_int(a.apagar(PERFIL)).is_equal(ERR_FILE_NOT_FOUND)


func test_escritor_de_linhas_anexa_linhas_em_ordem() -> void:
	var a := ArmazemEmMemoria.new()
	var w := a.criar_escritor_de_linhas("user://telemetria/s.jsonl")
	assert_object(w).is_not_null()
	assert_bool(w.escrever_linha("a")).is_true()
	assert_bool(w.escrever_linha("b")).is_true()
	assert_bool(w.descarregar()).is_true()
	w.fechar()
	assert_bool(w.escrever_linha("c")).is_false()
	assert_str(a.texto_de("user://telemetria/s.jsonl")).is_equal("a\nb\n")


func test_criar_escritor_falha_programada_devolve_null() -> void:
	var a := ArmazemEmMemoria.new()
	a.programar_falha(&"criar_escritor_de_linhas", 1)
	assert_object(a.criar_escritor_de_linhas("user://telemetria/s.jsonl")).is_null()


func test_registro_conta_operacoes_por_caminho() -> void:
	var a := ArmazemEmMemoria.new()
	a.gravar_atomico(PERFIL, "x")
	a.gravar_atomico("user://opcoes.cfg", "y")
	a.copiar_bytes(PERFIL, BAK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(2)
	assert_int(a.contar(&"gravar_atomico", PERFIL)).is_equal(1)
	assert_int(a.contar(&"copiar_bytes", BAK)).is_equal(1)
	assert_int(a.contar_tudo_sobre("user://opcoes.cfg")).is_equal(1)
	assert_int(a.contar_tudo_sobre("user://input_binds.cfg")).is_equal(0)
