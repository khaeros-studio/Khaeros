class_name ModeloDeFocoEFileiraTest
extends GdUnitTestSuite
## Testes unitários de `ModeloDeFoco`, `DadosDaCarta` e geometria F1/F2 da fileira (`story-001`).


func test_foco_inicial_sem_wrap_around_atalhos_123_e_clique_em_dois_passos() -> void:
	var rects: Array[Rect2] = [
		Rect2(Vector2(100, 200), Vector2(320, 500)),
		Rect2(Vector2(460, 200), Vector2(320, 500)),
		Rect2(Vector2(820, 200), Vector2(320, 500)),
	]
	var foco: ModeloDeFoco = ModeloDeFoco.new()
	foco.configurar(3, -1, true, rects)
	# F2: para 3 cartas, foco inicial é a carta central (1)
	assert_that(foco.foco_atual()).is_equal(1)

	# Sem wrap-around nos extremos
	var cmd: ComandosDeTela = ComandosDeTela.new()
	cmd.navegar = Vector2i(-1, 0)
	foco.processar(cmd, true)
	assert_that(foco.foco_atual()).is_equal(0)
	foco.processar(cmd, true)
	assert_that(foco.foco_atual()).is_equal(0)

	# Atalho 1/2/3 (carta_direta = 2) apenas move o foco sem confirmar
	cmd.limpar()
	cmd.carta_direta = 2
	var res_atalho: ModeloDeFoco.ResultadoFoco = foco.processar(cmd, true)
	assert_that(res_atalho.foco_atual).is_equal(2)
	assert_that(res_atalho.confirmar_carta).is_equal(-1)

	# Clique fora do foco apenas move o foco; 2º clique no mesmo alvo confirma
	cmd.limpar()
	cmd.clicou = true
	cmd.clique_pos = Vector2(200, 300) # carta 0
	var res_c1: ModeloDeFoco.ResultadoFoco = foco.processar(cmd, true)
	assert_that(res_c1.foco_atual).is_equal(0)
	assert_that(res_c1.confirmar_carta).is_equal(-1)

	var res_c2: ModeloDeFoco.ResultadoFoco = foco.processar(cmd, true)
	assert_that(res_c2.confirmar_carta).is_equal(0)


func test_largura_fileira_f1_escala_efetiva_e_dados_da_carta_6_zonas() -> void:
	assert_that(GrupoDeCartas.largura_fileira_100_px(3)).is_equal_approx(1040.0, 0.01)
	assert_that(GrupoDeCartas.largura_fileira_100_px(2)).is_equal_approx(680.0, 0.01)
	assert_that(GrupoDeCartas.largura_fileira_100_px(1)).is_equal_approx(320.0, 0.01)
	assert_that(GrupoDeCartas.escala_efetiva_fileira(3, 1.50)).is_equal_approx(1.50, 0.001)

	var carta: DadosDaCarta = DadosDaCarta.criar_de_bencao(&"furia_carmim", &"sangue", 2, 15)
	assert_that(carta.caminho_moldura).is_equal("res://assets/art/ui/cartas/moldura_sangue.png")
	assert_that(carta.caminho_glifo).is_equal("res://assets/art/ui/glifos/glifo_sangue.png")
	assert_that(carta.preco_vida).is_equal(15)
