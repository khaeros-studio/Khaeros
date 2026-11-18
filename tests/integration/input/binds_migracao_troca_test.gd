## Story input-008: arquivo antigo sem `troca`, com R no `especial` (AC-46).
extends GdUnitTestSuite

const CAMINHO := "user://input_binds.cfg"

var _avisos: Array[StringName] = []


func _arquivo_antigo() -> ArmazemEmMemoria:
	var mapa := MapaDeBinds.padrao()
	mapa.binds[Acoes.DISPOSITIVO_TECLADO].erase(Acoes.TROCA)
	mapa.binds[Acoes.DISPOSITIVO_GAMEPAD].erase(Acoes.TROCA)
	mapa.definir(Acoes.DISPOSITIVO_TECLADO, Acoes.ESPECIAL,
			[{"tipo": DescritorDeEntrada.MOUSE, "codigo": MOUSE_BUTTON_RIGHT},
			{"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": KEY_R}])
	var memoria := ArmazemEmMemoria.new()
	memoria.colocar_texto(CAMINHO, RepositorioDeBinds.texto_de(mapa))
	return memoria


func test_troca_recebe_tab_especial_mantem_r_e_aviso_uma_vez() -> void:
	_avisos.clear()
	var memoria := _arquivo_antigo()
	var texto_antes := memoria.texto_de(CAMINHO)
	var repo := RepositorioDeBinds.new(memoria, CAMINHO, func(c: StringName) -> void: _avisos.append(c))
	var mapa := repo.carregar()
	repo.carregar()
	assert_array(mapa.de(Acoes.DISPOSITIVO_TECLADO, Acoes.TROCA)).is_equal(
			[{"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": KEY_TAB}])
	assert_int(mapa.de(Acoes.DISPOSITIVO_TECLADO, Acoes.ESPECIAL)[1]["codigo"]).is_equal(KEY_R)
	assert_int(mapa.de(Acoes.DISPOSITIVO_GAMEPAD, Acoes.TROCA)[0]["codigo"]).is_equal(JOY_AXIS_TRIGGER_LEFT)
	assert_array(_avisos).is_equal([RepositorioDeBinds.AVISO_ACAO_NOVA])
	assert_str(memoria.texto_de(CAMINHO)).is_equal(texto_antes) # só regrava quando o jogador salvar
	var rotulos := RotulosDeAcao.new(func(c: int) -> String: return OS.get_keycode_string(c as Key))
	assert_str(rotulos.rotulo(mapa, Acoes.TROCA, Acoes.DISPOSITIVO_TECLADO)["texto"]).is_equal("Tab")
