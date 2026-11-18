## Testes unitários do CampusHub (design/gdd/campus-hub.md e mestres-ofertantes.md).
extends GdUnitTestSuite


func test_spawn_inicial_e_sem_zona_focada() -> void:
	var hub := CampusHub.new()
	assert_vector(hub.pos).is_equal(Vector2(960.0, 760.0))
	assert_that(hub.zona_focada()).is_equal(&"")
	assert_that(hub.interagir()).is_equal(&"")


func test_movimento_respeita_limites_do_patio() -> void:
	var hub := CampusHub.new()
	hub.atualizar_movimento(Vector2(-1.0, -1.0), 10.0)
	assert_float(hub.pos.x).is_equal_approx(120.0, 0.01)
	assert_float(hub.pos.y).is_equal_approx(140.0, 0.01)

	hub.atualizar_movimento(Vector2(1.0, 1.0), 20.0)
	assert_float(hub.pos.x).is_equal_approx(1800.0, 0.01)
	assert_float(hub.pos.y).is_equal_approx(960.0, 0.01)


func test_selecao_da_zona_mais_proxima_dentro_do_raio() -> void:
	var hub := CampusHub.new()
	hub.pos = Vector2(420.0, 420.0) + Vector2(50.0, 0.0)
	assert_that(hub.zona_focada()).is_equal(&"oficina")
	assert_that(hub.interagir()).is_equal(&"oficina")

	hub.pos = Vector2(960.0, 320.0) + Vector2(0.0, 80.0)
	assert_that(hub.zona_focada()).is_equal(&"mestres")

	hub.pos = Vector2(1500.0, 420.0) + Vector2(-90.0, 0.0)
	assert_that(hub.zona_focada()).is_equal(&"doutrinas")

	hub.pos = Vector2(960.0, 190.0) + Vector2(0.0, -40.0)
	assert_that(hub.zona_focada()).is_equal(&"portal")

	# Fora do raio de 110 px entre mestres (320) e portal (190): ponto 255 está a 65 px de ambos,
	# deve escolher mestres se mais perto ou respeitar menor distância.
	hub.pos = Vector2(960.0, 260.0) # 60 px de mestres, 70 px de portal
	assert_that(hub.zona_focada()).is_equal(&"mestres")

	# Fora de qualquer raio
	hub.pos = Vector2(960.0, 760.0)
	assert_that(hub.zona_focada()).is_equal(&"")


func test_dialogo_dos_tres_mestres_e_rotacao() -> void:
	var hub := CampusHub.new()
	var f1 := hub.fala_mestre_atual()
	assert_that(f1["id"]).is_equal(&"halvar")
	assert_str(String(f1["nome"])).is_not_empty()
	assert_str(String(f1["titulo"])).is_not_empty()
	assert_str(String(f1["fala"])).is_not_empty()

	hub.avancar_mestre()
	var f2 := hub.fala_mestre_atual()
	assert_that(f2["id"]).is_equal(&"maren")
	assert_str(String(f2["fala"])).is_not_empty()

	hub.avancar_mestre()
	var f3 := hub.fala_mestre_atual()
	assert_that(f3["id"]).is_equal(&"oreth")
	assert_str(String(f3["fala"])).is_not_empty()

	hub.avancar_mestre()
	var f4 := hub.fala_mestre_atual()
	assert_that(f4["id"]).is_equal(&"halvar")
	assert_str(String(f4["fala"])).is_not_equal(String(f1["fala"]))
