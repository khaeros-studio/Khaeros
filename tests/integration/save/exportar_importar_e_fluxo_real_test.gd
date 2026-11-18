## Story persistencia/009 [I]: AC-SP-25 — raiz temporária user://_testes/<caso>/, perfil
## ausente; a 1ª sessão faz um pacto (dublê) e sai; a 2ª carrega e vê a espécie pactuada.
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const RAIZ_BASE := "user://_testes/"

var _raiz: String


func before_test() -> void:
	_raiz = RAIZ_BASE + "fluxo_real_perfil/"
	_apagar_recursivo(_raiz)
	DirAccess.make_dir_recursive_absolute(_raiz)


func after_test() -> void:
	_apagar_recursivo(_raiz)
	DirAccess.remove_absolute(RAIZ_BASE)


func _sessao(v: PortaDeSecao) -> Save:
	var s := Save.new()
	s.configurar(RepositorioDePerfil.new(ArmazemUserGodot.new(_raiz), CaminhosDePersistencia.de(0),
		Callable(), PackedStringArray(["vulto_mudo"]), v), Callable())
	s.carregar(true)
	return s


func test_pacto_na_primeira_sessao_aparece_na_segunda() -> void:
	var v1 := VinculoFalso.new()
	var s1 := _sessao(v1)
	assert_array(v1.lidos).is_equal([{}])
	v1.estado = {"especies": {"vulto_mudo": {"pactuada": true}}}
	s1.marcar_pendente()
	assert_int(s1.gravar_se_pendente(EstadoDeJogo.Valor.BENCAO)).is_equal(OK)
	assert_int(s1.pedir_saida()).is_equal(OK)
	var v2 := VinculoFalso.new()
	_sessao(v2)
	assert_bool(v2.lidos[0]["especies"]["vulto_mudo"]["pactuada"]).is_true()


func _apagar_recursivo(pasta: String) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	for sub in d.get_directories():
		_apagar_recursivo(pasta + sub + "/")
	DirAccess.remove_absolute(pasta)
