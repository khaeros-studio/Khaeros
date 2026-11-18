## Story persistencia/006: carga uma vez por sessão, catálogo Falhou → Sem gravação
## (AC-SP-21) e PerfilNulo injetável sem if no Save (TR-save-004, 005, 016).
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const PERFIL := "user://perfil.cfg"
const PACTO := {"especies": {"vulto_mudo": {"pactuada": true}}}
const VERSAO_FUTURA := "[meta]\n\nschema_version=2\n"


class EvFalso extends EventoDoPasso:
	var _tipo: StringName

	func _init(t: StringName) -> void:
		_tipo = t

	func tipo() -> StringName:
		return _tipo


var _avisos: Array[StringName] = []


func before_test() -> void:
	_avisos = []


func _avisar(chave: StringName) -> void:
	_avisos.append(chave)


func _save(a: ArmazemDeArquivos, v: PortaDeSecao) -> Save:
	var s := Save.new()
	s.configurar(RepositorioDePerfil.new(a, CaminhosDePersistencia.de(0), _avisar,
		PackedStringArray(["vulto_mudo"]), v), _avisar)
	return s


func _gatilho(s: Save) -> void:
	var lista: Array[EventoDoPasso] = [EvFalso.new(Save.EV_PACTO_REGISTRADO)]
	s.consumir(lista)


func test_catalogo_falhou_gatilho_zero_leituras_e_zero_gravacoes() -> void:
	# AC-SP-21
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, "[meta]\n\nschema_version=1\n")
	var v := VinculoFalso.new()
	var s := _save(a, v)
	assert_int(s.carregar(false)).is_equal(ModoDoPerfil.Valor.SEM_GRAVACAO)
	v.estado = PACTO
	_gatilho(s)
	s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)
	s.pedir_saida()
	assert_int(s.estado()).is_equal(Save.Estado.SEM_GRAVACAO)
	assert_int(a.contar_tudo_sobre(PERFIL)).is_equal(0)
	assert_int(a.registro().size()).is_equal(0)
	assert_int(v.lidos.size()).is_equal(0)
	assert_array(_avisos).is_empty()
	assert_bool(s.reset_disponivel()).is_false()


func test_carregar_duas_vezes_le_o_perfil_uma_vez() -> void:
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	var s := _save(a, v)
	assert_int(s.carregar(true)).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_int(s.carregar(true)).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_int(s.carregar(false)).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_int(a.contar(&"ler_texto")).is_equal(1)
	assert_int(v.lidos.size()).is_equal(1)


func test_gatilho_antes_da_carga_nao_grava_e_fica_pendente() -> void:
	var a := ArmazemEmMemoria.new()
	var s := _save(a, VinculoFalso.new())
	assert_int(s.estado()).is_equal(Save.Estado.NAO_CARREGADO)
	_gatilho(s)
	assert_int(s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)).is_equal(ERR_BUSY)
	assert_int(a.registro().size()).is_equal(0)
	assert_bool(s.pendente()).is_true()
	s.carregar(true)
	assert_int(s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)).is_equal(OK)
	assert_int(a.contar(&"gravar_atomico")).is_equal(1)


func test_catalogo_pronto_repositorio_real_le_e_grava() -> void:
	# TR-save-016: o build de playtest compõe o repositório real (lê e grava)
	var a := ArmazemEmMemoria.new()
	var v := VinculoFalso.new()
	var s := _save(a, v)
	s.carregar(true)
	v.estado = PACTO
	_gatilho(s)
	assert_int(s.gravar_se_pendente(EstadoDeJogo.Valor.BENCAO)).is_equal(OK)
	assert_str(a.texto_de(PERFIL)).contains("vulto_mudo")


func test_versao_futura_deixa_save_sem_gravacao() -> void:
	var a := ArmazemEmMemoria.new()
	a.colocar_texto(PERFIL, VERSAO_FUTURA)
	var s := _save(a, VinculoFalso.new())
	assert_int(s.carregar(true)).is_equal(ModoDoPerfil.Valor.SEM_GRAVACAO)
	_gatilho(s)
	assert_int(s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)).is_equal(ERR_UNAVAILABLE)
	assert_int(a.contar(&"gravar_atomico")).is_equal(0)
	assert_str(a.texto_de(PERFIL)).is_equal(VERSAO_FUTURA)


func test_perfil_nulo_mesmo_fluxo_sem_ler_nem_gravar() -> void:
	# TR-save-016: o Save roda o mesmo caminho com o PerfilNulo, sem if próprio
	var v := VinculoFalso.new()
	var s := Save.new()
	s.configurar(PerfilNulo.new(v), _avisar)
	assert_int(s.carregar(true)).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_array(v.lidos).is_equal([{}])
	v.estado = PACTO
	_gatilho(s)
	assert_int(s.gravar_se_pendente(EstadoDeJogo.Valor.MENU)).is_equal(OK)
	assert_bool(s.pendente()).is_false()
	assert_int(s.pedir_saida()).is_equal(OK)
	assert_int(s.resetar(Save.CONFIRMACOES_DO_RESET)).is_equal(OK)
	assert_str(s.exportar_texto()).is_empty()
	assert_array(_avisos).is_empty()


func test_perfil_nulo_sem_porta_nao_falha() -> void:
	var s := Save.new()
	s.configurar(PerfilNulo.new(), Callable())
	assert_int(s.carregar(true)).is_equal(ModoDoPerfil.Valor.NORMAL)
	assert_int(s.importar_texto("[meta]\n\nschema_version=1\n")).is_equal(ERR_UNAVAILABLE)
