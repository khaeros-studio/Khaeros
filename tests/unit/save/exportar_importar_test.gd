## Story persistencia/009 [L]: exportar_texto/importar_texto com a validação da carga (AC-SP-22).
extends GdUnitTestSuite

const VinculoFalso := preload("res://tests/unit/save/vinculo_falso.gd")
const ESTADO_A := {
	"especies": {"vulto_mudo": {"pactuada": true, "vinculo_pontos": 7, "nivel": 1}},
	"ultima_dupla": ["vulto_mudo", ""],
}


func _save(v: PortaDeSecao) -> Save:
	var s := Save.new()
	s.configurar(RepositorioDePerfil.new(ArmazemEmMemoria.new(), CaminhosDePersistencia.de(0),
		Callable(), PackedStringArray(["vulto_mudo"]), v), Callable())
	s.carregar(true)
	return s


func test_exportar_de_a_e_importar_em_b_ler_recebe_o_mesmo_dicionario() -> void:
	var va := VinculoFalso.new()
	va.estado = ESTADO_A
	var texto := _save(va).exportar_texto()
	var vb := VinculoFalso.new()
	var b := _save(vb)
	assert_int(b.importar_texto(texto)).is_equal(OK)
	assert_dict(vb.lidos[vb.lidos.size() - 1]).is_equal(ESTADO_A)
	assert_bool(b.pendente()).is_true()


func test_importar_texto_corrompido_devolve_erro_e_nao_altera_estado() -> void:
	var vb := VinculoFalso.new()
	vb.estado = ESTADO_A
	var b := _save(vb)
	var antes := b.exportar_texto()
	assert_int(b.importar_texto("%%lixo")).is_not_equal(OK)
	assert_int(b.importar_texto("[meta]\n\nschema_version=\"1\"\n")).is_not_equal(OK)
	assert_int(b.importar_texto("[meta]\n\nschema_version=9\n")).is_not_equal(OK)
	assert_int(vb.lidos.size()).is_equal(1)
	assert_str(b.exportar_texto()).is_equal(antes)
	assert_bool(b.pendente()).is_false()
