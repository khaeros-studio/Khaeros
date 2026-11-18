## Story input-007: rotulo_acao (AC-39, AC-47).
extends GdUnitTestSuite

var _avisos: Array[String] = []


func _rotulos() -> RotulosDeAcao:
	_avisos.clear()
	return RotulosDeAcao.new(func(c: int) -> String: return OS.get_keycode_string(c as Key),
			func(m: String) -> void: _avisos.append(m))


func test_troca_padrao_teclado_r_gamepad_lt() -> void:
	var r := _rotulos()
	assert_str(r.rotulo(MapaDeBinds.padrao(), Acoes.TROCA, Acoes.DISPOSITIVO_TECLADO)["texto"]).is_equal("R")
	assert_str(r.rotulo(MapaDeBinds.padrao(), Acoes.TROCA, Acoes.DISPOSITIVO_GAMEPAD)["glifo"]).is_equal("pad_lt")


func test_troca_remapeada_para_g_devolve_g() -> void:
	var mapa := MapaDeBinds.padrao()
	mapa.definir(Acoes.DISPOSITIVO_TECLADO, Acoes.TROCA, [{"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": KEY_G}])
	assert_str(_rotulos().rotulo(mapa, Acoes.TROCA, Acoes.DISPOSITIVO_TECLADO)["texto"]).is_equal("G")


func test_layout_azerty_injetado_mostra_tecla_logica() -> void:
	var azerty := RotulosDeAcao.new(
			func(c: int) -> String: return "Z" if c == KEY_W else OS.get_keycode_string(c as Key))
	assert_str(azerty.rotulo(MapaDeBinds.padrao(), Acoes.MOVER, Acoes.DISPOSITIVO_TECLADO)["texto"]).is_equal("Z")


func test_invalido_rotulo_vazio_e_um_aviso() -> void:
	var r := _rotulos()
	assert_str(r.rotulo(MapaDeBinds.padrao(), &"voar", Acoes.DISPOSITIVO_TECLADO)["texto"]).is_empty()
	assert_str(r.rotulo(MapaDeBinds.padrao(), Acoes.SELO, &"volante")["glifo"]).is_empty()
	assert_int(_avisos.size()).is_equal(2)


func test_provedor_reflete_dispositivo_do_passo_anterior() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.configurar_rotulos(_rotulos())
	adaptador.registrar_botao(DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_X, 0, 0), true)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	assert_str(provedor.rotulo_acao(Acoes.SELO, provedor.dispositivo_ativo())["glifo"]).is_equal("pad_b")
