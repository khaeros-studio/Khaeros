## Story input-001 [I]: eventos sintéticos por `Input.parse_input_event` até `Node._input` do adaptador
## (AC-21 caso [I], AC-28 física, eco, múltiplos binds). Requer `use_accumulated_input` desligado.
extends GdUnitTestSuite

var _acumulacao_anterior: bool
var _adaptador: AdaptadorDeEntradaGodot
var _lotes: Array = []


func before_test() -> void:
	_acumulacao_anterior = Input.use_accumulated_input
	Input.use_accumulated_input = false
	_adaptador = AdaptadorDeEntradaGodot.new()
	add_child(_adaptador)


func after_test() -> void:
	Input.use_accumulated_input = _acumulacao_anterior
	_adaptador.queue_free()
	_adaptador = null


func _tecla(fisica: int, apertada: bool, eco: bool = false, logica: int = 0) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = fisica
	evento.keycode = logica if logica != 0 else fisica
	evento.pressed = apertada
	evento.echo = eco
	Input.parse_input_event(evento)


func _provedor() -> ProvedorDeEntrada:
	return ProvedorDeEntrada.new(_adaptador.drenar)


func test_parse_aperto_e_soltura_entre_passos_apertado_sem_segurado() -> void:
	var provedor := _provedor()
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_J, true)
	_tecla(KEY_J, false)
	var amostra := provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.foi_apertado(Acoes.ATAQUE)).is_true()
	assert_bool(amostra.esta_segurado(Acoes.ATAQUE)).is_false()
	assert_bool(provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false).foi_apertado(Acoes.ATAQUE)).is_false()
	_tecla(KEY_J, false)


func test_parse_aperto_soltura_aperto_um_toque_e_segurado() -> void:
	var provedor := _provedor()
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_J, true)
	_tecla(KEY_J, false)
	_tecla(KEY_J, true)
	var amostra := provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_array(amostra.apertados()).is_equal([Acoes.ATAQUE])
	assert_bool(amostra.esta_segurado(Acoes.ATAQUE)).is_true()
	_tecla(KEY_J, false)


func test_parse_eco_nao_gera_borda() -> void:
	var provedor := _provedor()
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_J, true)
	provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_J, true, true)
	var amostra := provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.foi_apertado(Acoes.ATAQUE)).is_false()
	assert_bool(amostra.esta_segurado(Acoes.ATAQUE)).is_true()
	_tecla(KEY_J, false)


func test_parse_soltar_um_bind_mantem_acao_com_outro_segurado() -> void:
	var provedor := _provedor()
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_SPACE, true)
	provedor.amostrar(2, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_SHIFT, true)
	var amostra := provedor.amostrar(3, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.foi_apertado(Acoes.ESQUIVA)).is_false()  # segundo bind não rearma
	_tecla(KEY_SPACE, false)
	amostra = provedor.amostrar(4, Acoes.CONTEXTO_JOGO, false)
	assert_bool(amostra.esta_segurado(Acoes.ESQUIVA)).is_true()
	_tecla(KEY_SHIFT, false)
	assert_bool(provedor.amostrar(5, Acoes.CONTEXTO_JOGO, false).esta_segurado(Acoes.ESQUIVA)).is_false()


func test_parse_posicao_fisica_w_com_tecla_logica_z_move_para_cima() -> void:
	var provedor := _provedor()
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	_tecla(KEY_W, true, false, KEY_Z)
	var amostra := provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false)
	assert_vector(amostra.mover).is_equal(Vector2(0, -1))
	_tecla(KEY_W, false, false, KEY_Z)
