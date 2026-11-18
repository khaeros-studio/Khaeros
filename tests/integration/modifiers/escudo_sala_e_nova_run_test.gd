extends GdUnitTestSuite
## Story modificadores-007: escudo_sala e trocas (AC-22) e nova run (AC-16), com um dono de
## recurso dublê ligado ao portador pelo NotificadorDeAtributo.

const F := preload("res://tests/unit/modifiers/fabrica_de_portadores.gd")


## Dono de recursos dublê (papel do Combate/Bênçãos): aplica as reações da R9.
class DonoDeRecursos:
	extends OuvinteDeAtributos
	var escudo: int = 0
	var trocas: int = 0

	func atributo_mudou(_id: int, _p: int, atributo: StringName, antigo: int, novo: int) -> void:
		if atributo == Atributos.ESCUDO_SALA:
			escudo = NotificadorDeAtributo.escudo_apos_mudar(escudo, antigo, novo)
		elif atributo == Atributos.TROCAS_OFERTA:
			trocas = NotificadorDeAtributo.restantes_apos_mudar_max(trocas, antigo, novo)


func test_escudo_sala_substitui_na_camara_e_ganha_diferenca_no_meio() -> void:
	var dono := DonoDeRecursos.new()
	var n := NotificadorDeAtributo.new()
	n.registrar(Atributos.ESCUDO_SALA, dono)
	n.registrar(Atributos.TROCAS_OFERTA, dono)
	var p := F.jogador(130.0, {}, null, null, n)
	p.aplicar_fonte(F.fonte(&"bencao:escudo", [F.mod(Atributos.ESCUDO_SALA, F.OP.PLANO, 15.0)]))
	dono.escudo = 4
	dono.escudo = NotificadorDeAtributo.escudo_no_comeco_da_camara(p.inteiro(Atributos.ESCUDO_SALA))
	assert_int(dono.escudo).is_equal(15)
	dono.escudo = 7
	p.aplicar_fonte(F.fonte(&"bencao:escudo2", [F.mod(Atributos.ESCUDO_SALA, F.OP.PLANO, 10.0)]))
	assert_int(dono.escudo).is_equal(17)
	dono.escudo = NotificadorDeAtributo.escudo_no_comeco_da_camara(p.inteiro(Atributos.ESCUDO_SALA))
	assert_int(dono.escudo).is_equal(25)
	p.aplicar_fonte(F.fonte(&"bencao:troca", [F.mod(Atributos.TROCAS_OFERTA, F.OP.PLANO, 1.0)]))
	assert_int(dono.trocas).is_equal(1)


func test_nova_run_recria_portador_com_vida_max_do_comeco() -> void:
	var p := F.jogador(130.0)
	p.aplicar_fonte(F.vigor(20.0))
	p.aplicar_fonte(F.muro_de_pedras())
	p.aplicar_fonte(F.preco_com_nome())
	p.aplicar_fonte(F.impeto())
	# fim da run: descarta e recria com a base da arma + Oficina
	p = F.jogador(130.0)
	p.aplicar_fonte(F.vigor(20.0))
	assert_int(p.inteiro(Atributos.VIDA_MAX)).is_equal(150)
