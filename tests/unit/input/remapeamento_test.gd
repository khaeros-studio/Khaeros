## Story input-007: remapeamento transacional e captura (AC-25 a AC-30).
extends GdUnitTestSuite

const T := Acoes.DISPOSITIVO_TECLADO
const G := Acoes.DISPOSITIVO_GAMEPAD



func _tecla(codigo: int) -> Dictionary:
	return {"tipo": DescritorDeEntrada.TECLA_FISICA, "codigo": codigo}


func _mouse(codigo: int) -> Dictionary:
	return {"tipo": DescritorDeEntrada.MOUSE, "codigo": codigo}


func _botao(codigo: int) -> Dictionary:
	return {"tipo": DescritorDeEntrada.BOTAO_GAMEPAD, "codigo": codigo}


func _logicas(mapa: MapaDeBinds, familia: StringName, chave: StringName) -> Array[String]:
	var saida: Array[String] = []
	for bind: Dictionary in mapa.de(familia, chave):
		saida.append(String(MapaDeBinds.logica(bind)))
	return saida


func _recusado(r: TransacaoDeRemapeamento.Resultado, aviso: StringName) -> void:
	assert_bool(r.aceito).is_false()
	assert_str(String(r.aviso)).is_equal(String(aviso))
	assert_bool(r.mapa.igual_a(MapaDeBinds.padrao())).is_true()


func test_mapa_padrao_e_valido() -> void:
	assert_str(String(TransacaoDeRemapeamento.validar(MapaDeBinds.padrao()))).is_empty()


# --- AC-25 ---

func test_secundario_do_ataque_no_especial_troca_os_dois_e_avisa() -> void:
	var r := TransacaoDeRemapeamento.atribuir(MapaDeBinds.padrao(), T, Acoes.ESPECIAL, 1, _tecla(KEY_J))
	assert_bool(r.aceito).is_true()
	assert_str(String(r.aviso)).is_equal(String(TransacaoDeRemapeamento.AVISO_CONFLITO_TROCA))
	assert_array(_logicas(r.mapa, T, Acoes.ESPECIAL)).is_equal(
			[String(MapaDeBinds.logica(_mouse(MOUSE_BUTTON_RIGHT))), String(MapaDeBinds.logica(_tecla(KEY_J)))])
	assert_array(_logicas(r.mapa, T, Acoes.ATAQUE)).is_equal(
			[String(MapaDeBinds.logica(_mouse(MOUSE_BUTTON_LEFT))), String(MapaDeBinds.logica(_tecla(KEY_K)))])


func test_troca_que_deixa_acao_sem_primario_recusada() -> void:
	_recusado(TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.ESPECIAL, _mouse(MOUSE_BUTTON_LEFT)), TransacaoDeRemapeamento.AVISO_RECUSA_TECLA)


func test_mesma_entrada_em_contextos_diferentes_nao_troca() -> void:
	var r := TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.SELO, _tecla(KEY_1))
	assert_bool(r.aceito).is_true()
	assert_str(String(r.aviso)).is_empty()
	assert_array(_logicas(r.mapa, T, Acoes.UI_CARTA_1)).is_equal([String(MapaDeBinds.logica(_tecla(KEY_1)))])


func test_conflito_com_pausar_nunca_troca() -> void:
	var com_f10 := TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.PAUSAR, _tecla(KEY_F10)).mapa
	var r := TransacaoDeRemapeamento.acrescentar(com_f10, T, Acoes.ATAQUE, _tecla(KEY_F10))
	assert_bool(r.aceito).is_false()
	assert_str(String(r.aviso)).is_equal(String(TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA))


# --- AC-26 ---

func test_remover_esc_de_pausar_recusado() -> void:
	_recusado(TransacaoDeRemapeamento.remover(MapaDeBinds.padrao(), T, Acoes.PAUSAR, 0), TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA)
	_recusado(TransacaoDeRemapeamento.atribuir(MapaDeBinds.padrao(), T, Acoes.PAUSAR, 0, _tecla(KEY_F10)), TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA)


func test_esc_ou_start_em_outra_acao_de_jogo_pausa_ou_bencao_recusado() -> void:
	_recusado(TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.ATAQUE, _tecla(KEY_ESCAPE)), TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA)
	_recusado(TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), G, Acoes.UI_ACEITAR, _botao(JOY_BUTTON_START)), TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA)
	_recusado(TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.UI_CARTA_2, _tecla(KEY_ESCAPE)), TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA)


func test_acrescentar_f10_em_pausar_aceito() -> void:
	var r := TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.PAUSAR, _tecla(KEY_F10))
	assert_bool(r.aceito).is_true()
	assert_int(r.mapa.de(T, Acoes.PAUSAR).size()).is_equal(2)


# --- AC-27 ---

func test_remover_so_tira_secundario() -> void:
	var r := TransacaoDeRemapeamento.remover(MapaDeBinds.padrao(), T, Acoes.SELO, 1)
	assert_bool(r.aceito).is_true()
	assert_array(_logicas(r.mapa, T, Acoes.SELO)).is_equal([String(MapaDeBinds.logica(_tecla(KEY_Q)))])
	_recusado(TransacaoDeRemapeamento.remover(MapaDeBinds.padrao(), T, Acoes.SELO, 0), TransacaoDeRemapeamento.AVISO_RECUSA_TECLA)


func test_quarto_bind_na_esquiva_recusado_e_os_tres_ficam() -> void:
	var r := TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.ESQUIVA, _tecla(KEY_P))
	_recusado(r, TransacaoDeRemapeamento.AVISO_RECUSA_TECLA)
	assert_int(r.mapa.de(T, Acoes.ESQUIVA).size()).is_equal(3)


# --- AC-28 ---

func test_posicao_fisica_w_com_tecla_logica_z_move_para_cima() -> void:
	var adaptador: AdaptadorDeEntradaGodot = auto_free(AdaptadorDeEntradaGodot.new())
	var provedor := ProvedorDeEntrada.new(adaptador.drenar)
	provedor.amostrar(0, Acoes.CONTEXTO_JOGO, false)
	var evento := InputEventKey.new()
	evento.physical_keycode = KEY_W
	evento.keycode = KEY_Z
	evento.pressed = true
	adaptador.receber_evento(evento)
	assert_float(provedor.amostrar(1, Acoes.CONTEXTO_JOGO, false).mover.y).is_less(0.0)


# --- AC-29 ---

func test_meta_print_screen_e_roda_do_mouse_recusados() -> void:
	for bind: Dictionary in [_tecla(KEY_META), _tecla(KEY_PRINT), _mouse(MOUSE_BUTTON_WHEEL_UP),
			_mouse(MOUSE_BUTTON_WHEEL_DOWN)]:
		_recusado(TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), T, Acoes.INTERAGIR, bind), TransacaoDeRemapeamento.AVISO_RECUSA_TECLA)


func test_vetor_do_gamepad_nao_e_remapeavel() -> void:
	_recusado(TransacaoDeRemapeamento.acrescentar(MapaDeBinds.padrao(), G, &"mover.cima", _botao(JOY_BUTTON_DPAD_UP)), TransacaoDeRemapeamento.AVISO_RECUSA_TECLA)


# --- AC-30 ---

func test_captura_selo_no_gamepad_b_curto_atribuido() -> void:
	var captura := TransacaoDeRemapeamento.Captura.new(G)
	captura.apertar(DescritorDeEntrada.new(DescritorDeEntrada.TECLA_FISICA, KEY_X))
	assert_int(captura.estado).is_equal(TransacaoDeRemapeamento.Captura.Estado.CAPTURANDO)
	captura.apertar(DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_B, 0, 0))
	assert_int(captura.estado).is_equal(TransacaoDeRemapeamento.Captura.Estado.CAPTURADO)
	var r := TransacaoDeRemapeamento.atribuir(MapaDeBinds.padrao(), G, Acoes.SELO, 1, captura.bind)
	assert_bool(r.aceito).is_true()
	assert_int(int(r.mapa.de(G, Acoes.SELO)[1]["codigo"])).is_equal(JOY_BUTTON_B)


func test_captura_start_segurado_um_segundo_cancela() -> void:
	var captura := TransacaoDeRemapeamento.Captura.new(G)
	var start := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_START, 0, 0)
	captura.apertar(start)
	captura.avancar(TransacaoDeRemapeamento.Captura.CANCELAR_S / 2.0)
	assert_int(captura.estado).is_equal(TransacaoDeRemapeamento.Captura.Estado.CAPTURANDO)
	captura.avancar(TransacaoDeRemapeamento.Captura.CANCELAR_S / 2.0)
	assert_int(captura.estado).is_equal(TransacaoDeRemapeamento.Captura.Estado.CANCELADO)
	assert_bool(captura.bind.is_empty()).is_true()


func test_captura_start_curto_vira_candidato_e_cai_na_recusa_da_pausa() -> void:
	var captura := TransacaoDeRemapeamento.Captura.new(G)
	var start := DescritorDeEntrada.new(DescritorDeEntrada.BOTAO_GAMEPAD, JOY_BUTTON_START, 0, 0)
	captura.apertar(start)
	captura.avancar(TransacaoDeRemapeamento.Captura.CANCELAR_S / 4.0)
	captura.soltar(start)
	assert_int(captura.estado).is_equal(TransacaoDeRemapeamento.Captura.Estado.CAPTURADO)
	_recusado(TransacaoDeRemapeamento.atribuir(MapaDeBinds.padrao(), G, Acoes.SELO, 1, captura.bind), TransacaoDeRemapeamento.AVISO_RECUSA_PAUSA)


func test_captura_sem_entrada_pelo_prazo_cancela() -> void:
	var captura := TransacaoDeRemapeamento.Captura.new(G)
	captura.avancar(TransacaoDeRemapeamento.Captura.PRAZO_S)
	assert_int(captura.estado).is_equal(TransacaoDeRemapeamento.Captura.Estado.CANCELADO)
	assert_bool(captura.bind.is_empty()).is_true()
