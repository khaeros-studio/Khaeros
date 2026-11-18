extends GdUnitTestSuite
## AC-09 (GDD Cena R4): 11 camadas com o z e o parallax da tabela; todo item numa
## camada só; nenhuma atribuição a `z_index` em `src/` fora do módulo de camadas.

const MODULO_DE_CAMADAS := "res://src/presentation/cena/camadas_do_mundo.gd"
const Z_ESPERADO: Array[int] = [-30, -25, -20, -10, -6, -5, 0, 5, 10]


func _camadas() -> CamadasDoMundo:
	var c: CamadasDoMundo = auto_free(CamadasDoMundo.new())
	add_child(c)
	return c


func test_montar_nove_camadas_de_mundo_com_z_absoluto_da_tabela() -> void:
	var c := _camadas()
	for i in CamadasDoMundo.CAMADAS_DE_MUNDO:
		var r := c.raiz(i) as Node2D
		assert_object(r).is_not_null()
		assert_int(r.z_index).is_equal(Z_ESPERADO[i])
		assert_bool(r.z_as_relative).is_false()
		assert_bool(r.y_sort_enabled).is_false()
		assert_float(c.parallax_de(i)).is_equal(1.0)


func test_montar_pos_e_ui_sao_canvas_50_e_100_sem_seguir_viewport() -> void:
	var c := _camadas()
	var pos := c.raiz(CamadasDoMundo.Camada.POS) as CanvasLayer
	var ui := c.raiz(CamadasDoMundo.Camada.UI) as CanvasLayer
	assert_int(pos.layer).is_equal(50)
	assert_int(ui.layer).is_equal(100)
	assert_bool(pos.follow_viewport_enabled).is_false()
	assert_bool(ui.follow_viewport_enabled).is_false()


func test_registrar_um_item_por_camada_cada_um_cai_em_exatamente_uma() -> void:
	var c := _camadas()
	var itens: Array[CanvasItem] = []
	for i in CamadasDoMundo.Camada.size():
		var it := Polygon2D.new()
		assert_bool(c.registrar(it, i)).is_true()
		itens.append(it)
	for i in itens.size():
		assert_int(c.camada_de(itens[i])).is_equal(i)
		var contagem := 0
		for j in CamadasDoMundo.Camada.size():
			if c.raiz(j).is_ancestor_of(itens[i]):
				contagem += 1
		assert_int(contagem).is_equal(1)


func test_registrar_item_que_ja_tem_pai_e_recusado() -> void:
	var c := _camadas()
	var it := Polygon2D.new()
	c.registrar(it, CamadasDoMundo.Camada.CHAO)
	assert_bool(c.registrar(it, CamadasDoMundo.Camada.PAREDE)).is_false()
	assert_int(c.camada_de(it)).is_equal(CamadasDoMundo.Camada.CHAO)


func test_trocar_camada_move_para_uma_so() -> void:
	var c := _camadas()
	var it := Polygon2D.new()
	c.registrar(it, CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO)
	assert_bool(c.trocar_camada(it, CamadasDoMundo.Camada.TELEGRAFO_CONTORNO)).is_true()
	assert_int(c.camada_de(it)).is_equal(CamadasDoMundo.Camada.TELEGRAFO_CONTORNO)
	assert_int(c.raiz(CamadasDoMundo.Camada.TELEGRAFO_PREENCHIMENTO).get_child_count()).is_equal(0)


func test_parallax_em_pos_e_ui_e_recusado() -> void:
	var c := _camadas()
	assert_bool(c.definir_parallax(CamadasDoMundo.Camada.UI, 1.2)).is_false()
	assert_bool(c.definir_parallax(CamadasDoMundo.Camada.PRIMEIRO_PLANO, 1.2)).is_true()
	assert_float(c.parallax_de(CamadasDoMundo.Camada.PRIMEIRO_PLANO)).is_equal_approx(1.2, 1e-6)


func test_atualizar_ordem_ancoras_seguem_pe_e_ordinal() -> void:
	var reg := RegistroDeCriacaoVisual.new()
	var c: CamadasDoMundo = auto_free(CamadasDoMundo.new(reg))
	add_child(c)
	reg.registrar_criacao(&"coluna")
	reg.registrar_criacao(&"jogador")
	var coluna := c.registrar_ancora(&"coluna")
	var jogador := c.registrar_ancora(&"jogador")
	c.definir_pe(coluna, Vector2(500, 600))
	c.definir_pe(jogador, Vector2(500, 640))
	c.atualizar_ordem()
	assert_array(c.ancoras_em_ordem()).is_equal([coluna, jogador])
	c.definir_pe(jogador, Vector2(500, 560))
	assert_bool(c.atualizar_ordem()).is_true()
	assert_array(c.ancoras_em_ordem()).is_equal([jogador, coluna])
	assert_bool(c.atualizar_ordem()).is_false()


func test_grep_z_index_em_src_fora_do_modulo_de_camadas_encontra_zero() -> void:
	var arquivos: Array[String] = []
	_listar_gd("res://src", arquivos)
	var regex := RegEx.create_from_string("\\bz_index\\s*(=|\\+=|-=)|set_z_index\\s*\\(|\"z_index\"")
	var ocorrencias: Array[String] = []
	for caminho in arquivos:
		if caminho == MODULO_DE_CAMADAS:
			continue
		var linhas := FileAccess.get_file_as_string(caminho).split("\n")
		for n in linhas.size():
			var l := linhas[n].strip_edges()
			if l.begins_with("#"):
				continue
			if regex.search(l) != null:
				ocorrencias.append("%s:%d" % [caminho, n + 1])
	print("AC-09 grep z_index: %d arquivos .gd varridos em src/, %d ocorrências fora do módulo" % [arquivos.size(), ocorrencias.size()])
	assert_int(arquivos.size()).is_greater(1)
	assert_array(ocorrencias).is_empty()


func _listar_gd(dir: String, saida: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			saida.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_listar_gd(dir.path_join(d), saida)
