## Story input-001: ações, mapa padrão e adaptador (AC-01, AC-41, AC-35 varredura, AC-21, AC-28, eco,
## múltiplos binds, Shift esquerdo/direito). Lógica do adaptador testada por descritores, sem dispositivo.
extends GdUnitTestSuite

const KEY_LOCATION_ESQ := 1
const KEY_LOCATION_DIR := 2


func _binds(familia: StringName, chave: StringName) -> Array[StringName]:
	var saida: Array[StringName] = []
	for bind: Dictionary in (BindsPadrao.mapa()[familia] as Dictionary).get(chave, []):
		saida.append(DescritorDeEntrada.de_bind(bind).chave_logica())
	return saida


func _tecla(codigo: int) -> StringName:
	return DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, codigo).chave_logica()


func test_mapa_padrao_acoes_iguais_a_r1_sem_debug() -> void:
	var acoes := BindsPadrao.acoes_do_mapa(BindsPadrao.mapa())
	# mirar não tem bind (cursor/analógico fixos); toda outra ação R1 tem bind.
	var esperado := Acoes.TODAS.duplicate()
	esperado.erase(Acoes.MIRAR)
	assert_int(acoes.size()).is_equal(esperado.size())
	for acao: StringName in esperado:
		assert_bool(acoes.has(acao)).override_failure_message("falta %s" % acao).is_true()
	for acao: StringName in Acoes.TODAS:
		assert_bool(String(acao).begins_with("debug_")).is_false()
	assert_bool(acoes.has(Acoes.TROCA)).is_true()


func test_mapa_padrao_nenhuma_chave_passa_de_tres_binds() -> void:
	var mapa := BindsPadrao.mapa()
	for familia: StringName in mapa:
		for chave: StringName in (mapa[familia] as Dictionary):
			assert_int((mapa[familia][chave] as Array).size()).is_less_equal(BindsPadrao.MAX_BINDS)


func test_mapa_padrao_esquiva_e_ui_aceitar_usam_tres_binds() -> void:
	assert_array(_binds(Acoes.DISPOSITIVO_TECLADO, Acoes.ESQUIVA)).is_equal(
			[_tecla(KEY_SPACE), _tecla(KEY_SHIFT), _tecla(KEY_L)])
	assert_array(_binds(Acoes.DISPOSITIVO_TECLADO, Acoes.UI_ACEITAR)).is_equal(
			[_tecla(KEY_ENTER), _tecla(KEY_SPACE), _tecla(KEY_E)])


func test_troca_binds_padrao_r_tab_e_lt() -> void:
	assert_array(_binds(Acoes.DISPOSITIVO_TECLADO, Acoes.TROCA)).is_equal([_tecla(KEY_R), _tecla(KEY_TAB)])
	var lt := DescritorDeEntrada.new(DescritorDeEntrada.GATILHO, JOY_AXIS_TRIGGER_LEFT).chave_logica()
	assert_array(_binds(Acoes.DISPOSITIVO_GAMEPAD, Acoes.TROCA)).is_equal([lt])
	assert_array(_binds(Acoes.DISPOSITIVO_TECLADO, Acoes.UI_TROCAR_OFERTAS)).is_equal([_tecla(KEY_R)])


func test_troca_r_tab_lt_nao_aparecem_em_outra_acao_de_jogo() -> void:
	var mapa := BindsPadrao.mapa()
	var lt := DescritorDeEntrada.new(DescritorDeEntrada.GATILHO, JOY_AXIS_TRIGGER_LEFT).chave_logica()
	var proibidos: Array[StringName] = [_tecla(KEY_R), _tecla(KEY_TAB), lt]
	for familia: StringName in mapa:
		for chave: StringName in (mapa[familia] as Dictionary):
			var acao := Acoes.acao_da_chave(chave)
			if acao == Acoes.TROCA or not Acoes.existe_no_contexto(acao, Acoes.CONTEXTO_JOGO):
				continue
			for bind: Dictionary in mapa[familia][chave]:
				assert_bool(proibidos.has(DescritorDeEntrada.de_bind(bind).chave_logica())).is_false()


func test_varredura_mapa_padrao_sem_conflito_em_nenhum_contexto() -> void:
	assert_array(BindsPadrao.varrer_conflitos(BindsPadrao.mapa())).is_empty()


func test_varredura_conflito_injetado_e_detectado() -> void:
	var mapa := BindsPadrao.mapa()
	(mapa[Acoes.DISPOSITIVO_TECLADO][Acoes.SELO] as Array).append({"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": KEY_R})
	assert_array(BindsPadrao.varrer_conflitos(mapa)).has_size(1)


func test_mapa_padrao_copias_sao_independentes() -> void:
	var a := BindsPadrao.mapa()
	(a[Acoes.DISPOSITIVO_TECLADO] as Dictionary).erase(Acoes.ATAQUE)
	assert_bool((BindsPadrao.mapa()[Acoes.DISPOSITIVO_TECLADO] as Dictionary).has(Acoes.ATAQUE)).is_true()


func test_adaptador_aperto_e_soltura_no_intervalo_uma_borda_sem_segurado() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var j := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J)
	adaptador.registrar_botao(j, true)
	adaptador.registrar_botao(j, false)
	var lote := adaptador.drenar()
	assert_int(lote.bordas.size()).is_equal(1)
	assert_int(lote.segurados.size()).is_equal(0)
	assert_int(adaptador.drenar().bordas.size()).is_equal(0)


func test_adaptador_aperto_soltura_aperto_uma_borda_e_segurado() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var j := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_J)
	adaptador.registrar_botao(j, true)
	adaptador.registrar_botao(j, false)
	adaptador.registrar_botao(j, true)
	var lote := adaptador.drenar()
	assert_int(lote.bordas.size()).is_equal(1)
	assert_int(lote.segurados.size()).is_equal(1)


func test_adaptador_shift_esquerdo_e_direito_estado_fisico_separado_mesmo_bind() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var esq := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_SHIFT, KEY_LOCATION_ESQ)
	var dir := DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_SHIFT, KEY_LOCATION_DIR)
	assert_str(String(esq.chave_logica())).is_equal(String(dir.chave_logica()))
	assert_str(String(esq.chave_fisica())).is_not_equal(String(dir.chave_fisica()))
	adaptador.registrar_botao(esq, true)
	adaptador.registrar_botao(dir, true)
	adaptador.registrar_botao(esq, false)
	var lote := adaptador.drenar()
	assert_int(lote.segurados.size()).is_equal(1)
	assert_str(String(lote.segurados[0].chave_fisica())).is_equal(String(dir.chave_fisica()))


func test_adaptador_clique_preserva_posicao_do_aperto() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var clique := DescritorDeEntrada.new(DescritorDeEntrada.MOUSE, MOUSE_BUTTON_LEFT)
	adaptador.registrar_botao(clique, true, Vector2(100, 50), true)
	adaptador.registrar_cursor(Vector2(300, 200))
	var borda: AdaptadorDeEntradaGodot.Borda = adaptador.drenar().bordas[0]
	assert_vector(borda.posicao_janela).is_equal(Vector2(100, 50))
	assert_str(String(borda.descritor.origem())).is_equal(String(DescritorDeEntrada.ORIGEM_MOUSE))
