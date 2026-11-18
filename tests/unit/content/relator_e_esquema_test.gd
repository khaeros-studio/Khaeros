extends GdUnitTestSuite
## Story conteudo-001: esquema, diagnóstico e relatores (AC-21, AC-43, base de AC-09).


func test_obter_id_inexistente_devolve_null_e_relator_recebe_entrada() -> void:
	# Arrange
	var relator := RelatorAcumulador.new()
	var cat := Catalogo.new(relator)
	cat.adicionar(&"enemy", FabricasDeCatalogo.inimigo(&"eco_perdido"))
	# Act
	var achado := cat.obter(&"enemy", &"nao_existe", "ia")
	# Assert
	assert_object(achado).is_null()
	assert_int(relator.entradas.size()).is_equal(1)
	assert_str(String(relator.entradas[0].tipo)).is_equal("enemy")
	assert_str(String(relator.entradas[0].id)).is_equal("nao_existe")
	assert_str(relator.entradas[0].solicitante).is_equal("ia")


func test_existe_id_inexistente_responde_false_sem_registrar() -> void:
	var relator := RelatorAcumulador.new()
	var cat := Catalogo.new(relator)
	assert_bool(cat.existe(&"enemy", &"nao_existe")).is_false()
	assert_int(relator.entradas.size()).is_equal(0)


func test_obter_id_obsoleto_resolve_e_listar_exclui() -> void:
	var cat := Catalogo.new(RelatorAcumulador.new())
	var e := FabricasDeCatalogo.inimigo(&"velho")
	e.obsoleto = true
	cat.adicionar(&"enemy", e)
	assert_object(cat.obter(&"enemy", &"velho", "teste")).is_same(e)
	assert_int(cat.listar(&"enemy").size()).is_equal(0)
	assert_int(cat.listar(&"enemy", true).size()).is_equal(1)


func test_relator_padrao_sem_parada_escreve_linha_no_log_falso() -> void:
	# Arrange
	var linhas: PackedStringArray = []
	var relator := RelatorPadrao.new(func(l: String) -> void: linhas.append(l), false)
	# Act
	relator.relatar(RelatorDeErros.Entrada.new(&"weapon", &"veu", "run"))
	# Assert
	assert_int(linhas.size()).is_equal(1)
	assert_str(linhas[0]).contains("weapon").contains("veu").contains("run")


func test_diagnostico_guarda_contexto_e_nivel() -> void:
	var item := ItemDoCatalogo.new(&"enemy", "res://x/eco.tres", 2, FabricasDeCatalogo.inimigo(&"eco"))
	var d := Diagnostico.de_item(item, &"V2", "dano", -1.0, "dano -1", Diagnostico.Nivel.AVISO)
	assert_str(d.arquivo).is_equal("res://x/eco.tres")
	assert_str(d.campo).is_equal("dano")
	assert_str(String(d.regra)).is_equal("V2")
	assert_float(float(d.valor)).is_equal(-1.0)
	assert_bool(d.eh_erro()).is_false()
	assert_int(d.posicao).is_equal(2)


func test_ordenar_diagnosticos_por_tipo_posicao_regra_e_campo() -> void:
	# Arrange
	var ordem: Array[StringName] = [&"weapon", &"enemy"]
	var a := _diag(&"enemy", 1, &"V2", "b")
	var b := _diag(&"weapon", 5, &"V10", "a")
	var c := _diag(&"weapon", 5, &"V2", "z")
	var d := _diag(&"enemy", 1, &"V2", "a")
	var e := _diag(&"enemy", 0, &"V3", "a")
	var lista: Array[Diagnostico] = [a, b, c, d, e]
	# Act
	var out := Diagnostico.ordenar(lista, ordem)
	# Assert
	assert_array(out).is_equal([c, b, e, d, a])


func test_esquema_declara_obrigatoriedade_limites_e_zero() -> void:
	var e := AttackDef.new().esquema()
	assert_bool(e.regra(&"recarga_s").aceita_zero).is_false()
	assert_bool(e.regra(&"preparo_s").aceita_zero).is_true()
	assert_bool(e.regra(&"preparo_s").tem_minimo).is_true()
	assert_bool(e.regra(&"status").obrigatorio).is_false()
	assert_bool(e.regra(&"dano").obrigatorio).is_true()
	assert_object(e.regra(&"inexistente")).is_null()


func test_esquema_campo_ausente_no_arquivo_mesmo_com_default_do_script() -> void:
	# Arrange: o script tem default (dano = 0.0), mas o arquivo não grava dano
	var texto := "[gd_resource type=\"Resource\" format=3]\n\n[ext_resource type=\"Script\" path=\"res://src/content/enemy_def.gd\" id=\"1\"]\n\n[resource]\nscript = ExtResource(\"1\")\nid = &\"eco\"\nchave_nome = &\"ENEMY_ECO\"\ncomportamento = &\"corpo_a_corpo\"\nvida = 48.0\nvelocidade = 120.0\nraio_px = 21.0\nalcance_px = 45.0\npreparo_s = 0.5\nrecarga_s = 1.0\ncusto_onda = 1\n"
	# Act
	var gravados := EsquemaDeDefinicao.campos_gravados_no_texto(texto)
	var ausentes := EnemyDef.new().esquema().campos_ausentes(gravados)
	# Assert
	assert_bool(gravados.has("script")).is_false()
	assert_array(Array(ausentes)).is_equal(["dano"])


func test_esquema_regra_entre_campos_da_curva() -> void:
	var regras := LinearCurveDef.new().esquema().regras_entre_campos()
	assert_int(regras.size()).is_equal(1)
	assert_bool(regras[0].vale(0.3, 0.25)).is_false()
	assert_bool(regras[0].vale(0.1, 0.25)).is_true()


func _diag(tipo: StringName, posicao: int, regra: StringName, campo: String) -> Diagnostico:
	var d := Diagnostico.novo(regra, campo, null, "")
	d.tipo = tipo
	d.posicao = posicao
	return d
