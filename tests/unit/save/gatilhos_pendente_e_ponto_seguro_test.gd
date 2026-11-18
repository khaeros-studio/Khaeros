## Story persistencia/007: gatilhos só marcam pendente; gravação no fim do passo fora de
## JOGO, coalescida; falha avisa uma vez, sem laço (AC-SP-04..07; TR-save-006, 007, 010).
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const PERFIL := "user://perfil.cfg"


class EvFalso extends EventoDoPasso:
	var _tipo: StringName

	func _init(t: StringName) -> void:
		_tipo = t

	func tipo() -> StringName:
		return _tipo


var _avisos: Array[StringName] = []
var _a: ArmazemEmMemoria
var _v: PortaDeSecao
var _s: Save


func before_test() -> void:
	_avisos = []
	_a = ArmazemEmMemoria.new()
	_v = VinculoFalso.new()
	_s = Save.new()
	_s.configurar(RepositorioDePerfil.new(_a, CaminhosDePersistencia.de(0), _avisar,
		PackedStringArray(["vulto_mudo", "eco_cinza"]), _v), _avisar)
	_s.carregar(true)


func _avisar(chave: StringName) -> void:
	_avisos.append(chave)


func _estado_pactos(n: int) -> Dictionary:
	return {"especies": {"vulto_mudo": {"pactuada": true, "vinculo_pontos": n}}}


# Um passo simulado: eventos entregues, depois o ponto seguro do Main.
func _passo(tipos: Array[StringName], estado: EstadoDeJogo.Valor) -> Error:
	var lista: Array[EventoDoPasso] = []
	for t in tipos:
		lista.append(EvFalso.new(t))
	_s.consumir(lista)
	return _s.gravar_se_pendente(estado)


func _gravacoes() -> int:
	return _a.contar(&"gravar_atomico")


func test_pacto_em_jogo_grava_so_no_fim_do_passo_em_transicao() -> void:
	# AC-SP-04
	_v.estado = _estado_pactos(1)
	assert_int(_passo([Save.EV_PACTO_REGISTRADO], EstadoDeJogo.Valor.JOGO)).is_equal(ERR_BUSY)
	for i in 5:
		assert_int(_passo([], EstadoDeJogo.Valor.JOGO)).is_equal(ERR_BUSY)
		assert_int(_gravacoes()).is_equal(0)
	# consumir (meio da entrega) nunca grava; só o ponto seguro
	var lista: Array[EventoDoPasso] = [EvFalso.new(&"inimigo_morreu")]
	_s.consumir(lista)
	assert_int(_gravacoes()).is_equal(0)
	assert_int(_s.gravar_se_pendente(EstadoDeJogo.Valor.TRANSICAO)).is_equal(OK)
	assert_int(_gravacoes()).is_equal(1)
	assert_int(_passo([], EstadoDeJogo.Valor.TRANSICAO)).is_equal(OK)
	assert_int(_gravacoes()).is_equal(1)


func test_tres_gatilhos_antes_do_ponto_seguro_uma_gravacao_com_ultimo_estado() -> void:
	# AC-SP-05
	_v.estado = _estado_pactos(1)
	_passo([Save.EV_PACTO_REGISTRADO], EstadoDeJogo.Valor.JOGO)
	_v.estado = _estado_pactos(2)
	_passo([Save.EV_DUPLA_CONFIRMADA], EstadoDeJogo.Valor.JOGO)
	_v.estado = _estado_pactos(3)
	_passo([Save.EV_PACTO_REGISTRADO], EstadoDeJogo.Valor.JOGO)
	assert_int(_s.gravar_se_pendente(EstadoDeJogo.Valor.BENCAO)).is_equal(OK)
	assert_int(_gravacoes()).is_equal(1)
	var cf := ConfigFile.new()
	cf.parse(_a.texto_de(PERFIL))
	var especies: Dictionary = cf.get_value("vinculo", "especies")
	assert_int(especies["vulto_mudo"]["vinculo_pontos"]).is_equal(3)


func test_duas_runs_encerradas_uma_gravacao_cada() -> void:
	# AC-SP-06
	_v.estado = _estado_pactos(4)
	_passo([Save.EV_RUN_ENCERRADA], EstadoDeJogo.Valor.MORTE)
	assert_int(_gravacoes()).is_equal(1)
	_v.estado = _estado_pactos(9)
	_passo([Save.EV_RUN_ENCERRADA], EstadoDeJogo.Valor.MENU)
	assert_int(_gravacoes()).is_equal(2)


func test_falha_na_primeira_gravacao_avisa_uma_vez_e_segunda_grava() -> void:
	# AC-SP-07
	_a.programar_falha(&"gravar_atomico", 1)
	_v.estado = _estado_pactos(1)
	assert_int(_passo([Save.EV_PACTO_REGISTRADO], EstadoDeJogo.Valor.BENCAO)).is_not_equal(OK)
	assert_array(_avisos).is_equal([Save.AVISO_FALHA_GRAVAR])
	assert_bool(_s.pendente()).is_false()
	assert_bool(_a.tem_arquivo(PERFIL)).is_false()
	# estado em memória inalterado: o que seria gravado ainda é o estado novo
	assert_str(_s.exportar_texto()).contains("\"vinculo_pontos\": 1")
	# sem laço: passos seguintes sem gatilho não tentam de novo
	_passo([], EstadoDeJogo.Valor.BENCAO)
	assert_int(_gravacoes()).is_equal(1)
	assert_int(_passo([Save.EV_RUN_ENCERRADA], EstadoDeJogo.Valor.MORTE)).is_equal(OK)
	assert_int(_gravacoes()).is_equal(2)
	assert_str(_a.texto_de(PERFIL)).contains("\"vinculo_pontos\": 1")
	assert_array(_avisos).is_equal([Save.AVISO_FALHA_GRAVAR])


func test_falhas_repetidas_avisam_uma_vez_na_sessao() -> void:
	_a.programar_falha(&"gravar_atomico", ArmazemEmMemoria.SEMPRE)
	_v.estado = _estado_pactos(1)
	_passo([Save.EV_PACTO_REGISTRADO], EstadoDeJogo.Valor.BENCAO)
	_v.estado = _estado_pactos(2)
	_passo([Save.EV_RUN_ENCERRADA], EstadoDeJogo.Valor.MORTE)
	assert_int(_gravacoes()).is_equal(2)
	assert_array(_avisos).is_equal([Save.AVISO_FALHA_GRAVAR])


func test_gatilhos_reconhecidos_marcam_pendente_e_outros_nao() -> void:
	# TR-save-006 (Sair e reset são chamadas diretas: sair_e_reset_test)
	for t: StringName in [Save.EV_PACTO_REGISTRADO, Save.EV_RUN_ENCERRADA, Save.EV_DUPLA_CONFIRMADA]:
		var lista: Array[EventoDoPasso] = [EvFalso.new(t)]
		_s.consumir(lista)
		assert_bool(_s.pendente()).is_true()
		_s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)
		assert_bool(_s.pendente()).is_false()
	var outros: Array[EventoDoPasso] = [EvFalso.new(&"inimigo_morreu"), EvFalso.new(&"pacto")]
	_s.consumir(outros)
	assert_bool(_s.pendente()).is_false()


func test_estados_seguros_gravam_e_jogo_e_iniciando_nao() -> void:
	for e: EstadoDeJogo.Valor in [EstadoDeJogo.Valor.JOGO, EstadoDeJogo.Valor.INICIANDO]:
		_s.marcar_pendente()
		assert_int(_s.gravar_se_pendente(e)).is_equal(ERR_BUSY)
	var n: int = 0
	for e: EstadoDeJogo.Valor in [EstadoDeJogo.Valor.MENU, EstadoDeJogo.Valor.PAUSA,
			EstadoDeJogo.Valor.BENCAO, EstadoDeJogo.Valor.TRANSICAO, EstadoDeJogo.Valor.MORTE]:
		n += 1
		_v.estado = _estado_pactos(n)
		_s.marcar_pendente()
		assert_int(_s.gravar_se_pendente(e)).is_equal(OK)
	assert_int(_gravacoes()).is_equal(5)


func test_gatilho_sem_mudanca_nao_toca_o_disco() -> void:
	_v.estado = _estado_pactos(1)
	_passo([Save.EV_PACTO_REGISTRADO], EstadoDeJogo.Valor.MENU)
	_passo([Save.EV_DUPLA_CONFIRMADA], EstadoDeJogo.Valor.MENU)
	assert_int(_gravacoes()).is_equal(1)
