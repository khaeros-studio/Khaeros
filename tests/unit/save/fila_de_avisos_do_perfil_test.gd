## Story persistencia/010 (modelo): avisos PERFIL_* uma vez por sessão, só fora de JOGO,
## ações navegáveis com padrão e voltar definidos (TR-save-018).
extends GdUnitTestSuite

const MENU := EstadoDeJogo.Valor.MENU


func test_cada_aviso_entra_uma_vez_por_sessao() -> void:
	var f := FilaDeAvisosDoPerfil.new()
	assert_bool(f.receber(&"PERFIL_CORROMPIDO")).is_true()
	assert_bool(f.receber(&"PERFIL_CORROMPIDO")).is_false()
	f.escolher(FilaDeAvisosDoPerfil.ACAO_OK)
	assert_bool(f.receber(&"PERFIL_CORROMPIDO")).is_false()
	assert_int(f.pendentes()).is_equal(0)


func test_em_jogo_nada_aparece_e_fora_de_jogo_aparece() -> void:
	var f := FilaDeAvisosDoPerfil.new()
	f.receber(Save.AVISO_FALHA_GRAVAR)
	assert_dict(f.atual(EstadoDeJogo.Valor.JOGO)).is_empty()
	var a := f.atual(EstadoDeJogo.Valor.TRANSICAO)
	assert_str(String(a["chave"])).is_equal("PERSIST_FALHA_GRAVAR")
	assert_bool(a["discreto"]).is_true()


func test_chave_desconhecida_e_ignorada() -> void:
	var f := FilaDeAvisosDoPerfil.new()
	assert_bool(f.receber(&"OUTRA_COISA")).is_false()
	assert_dict(f.atual(MENU)).is_empty()


func test_sair_sem_salvar_fura_a_fila_e_tentar_de_novo_mantem() -> void:
	var f := FilaDeAvisosDoPerfil.new()
	f.receber(RepositorioDePerfil.AVISO_VERSAO_FUTURA)
	f.receber(Save.AVISO_SAIR_SEM_SALVAR)
	var a := f.atual(MENU)
	assert_str(String(a["chave"])).is_equal("PERFIL_SAIR_SEM_SALVAR")
	assert_str(String(a["acao_padrao"])).is_equal("tentar_de_novo")
	assert_str(String(a["acao_de_voltar"])).is_equal("tentar_de_novo")
	assert_str(String(f.escolher(FilaDeAvisosDoPerfil.ACAO_TENTAR_DE_NOVO))).is_equal("tentar_de_novo")
	assert_str(String(f.atual(MENU)["chave"])).is_equal("PERFIL_SAIR_SEM_SALVAR")
	f.escolher(FilaDeAvisosDoPerfil.ACAO_SAIR_SEM_SALVAR)
	assert_str(String(f.atual(MENU)["chave"])).is_equal("PERFIL_VERSAO_FUTURA")


func test_acao_invalida_nao_fecha_o_aviso() -> void:
	var f := FilaDeAvisosDoPerfil.new()
	f.receber(&"PERFIL_CORROMPIDO")
	assert_str(String(f.escolher(FilaDeAvisosDoPerfil.ACAO_SAIR_SEM_SALVAR))).is_empty()
	assert_int(f.pendentes()).is_equal(1)


func test_toda_acao_tem_chave_de_texto() -> void:
	var f := FilaDeAvisosDoPerfil.new()
	for k: StringName in [&"PERFIL_CORROMPIDO", &"PERFIL_VERSAO_FUTURA", &"PERSIST_FALHA_GRAVAR", &"PERFIL_SAIR_SEM_SALVAR"]:
		f.receber(k)
	while f.pendentes() > 0:
		var a := f.atual(MENU)
		for acao: StringName in a["acoes"]:
			assert_bool(FilaDeAvisosDoPerfil.TEXTO_DA_ACAO.has(acao)).is_true()
		f.escolher(a["acoes"][a["acoes"].size() - 1])
