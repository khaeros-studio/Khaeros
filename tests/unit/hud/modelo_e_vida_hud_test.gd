class_name ModeloEVidaHudTest
extends GdUnitTestSuite
## Testes unitários de `LeituraDoHud`, `RelogioDeInterface`, `FormatoNumerico` e `ModeloDaVida` (`story-001` e `story-002`).

class LeituraDuble extends LeituraDoHud:
	var v_vida: Vector2i = Vector2i(100, 100)
	var v_escudo: int = 0
	var v_recusas: Vector2i = Vector2i(2, 2)
	var v_fluxo: Dictionary = {"atual": 50.0, "max": 100.0, "custo": 40.0, "recarga_s": 0.0}
	var v_esquiva: Dictionary = {"cargas": 2, "max": 2, "progresso": 0.0}
	var v_saldo: int = 1234
	var v_limiar_poco: int = 30
	var v_inimigos: Array[Dictionary] = []
	var v_porta: Dictionary = {}
	var v_estado: int = EstadoDeJogo.Valor.JOGO
	var v_hitstop: bool = false
	var v_chefe: Dictionary = {}
	var v_pacto: Dictionary = {}

	func vida() -> Vector2i:
		return v_vida

	func escudo() -> int:
		return v_escudo

	func recusas() -> Vector2i:
		return v_recusas

	func fluxo() -> Dictionary:
		return v_fluxo

	func esquiva() -> Dictionary:
		return v_esquiva

	func saldo() -> int:
		return v_saldo

	func limiar_fundo_do_poco() -> int:
		return v_limiar_poco

	func inimigos_feridos() -> Array[Dictionary]:
		return v_inimigos

	func porta_interagivel() -> Dictionary:
		return v_porta

	func estado_de_jogo() -> int:
		return v_estado

	func hitstop_ativo() -> bool:
		return v_hitstop

	func chefe() -> Dictionary:
		return v_chefe

	func estado_pacto() -> Dictionary:
		return v_pacto


func test_relogio_de_interface_pausa_t_ui_mas_mantem_t_real_e_formato_numerico() -> void:
	var rel: RelogioDeInterface = RelogioDeInterface.new()
	rel.avancar(0.05, false)
	assert_that(rel.t_ui()).is_equal_approx(0.05, 0.0001)
	assert_that(rel.t_real()).is_equal_approx(0.05, 0.0001)

	rel.avancar(0.05, true)
	assert_that(rel.t_ui()).is_equal_approx(0.05, 0.0001)
	assert_that(rel.t_real()).is_equal_approx(0.10, 0.0001)
	assert_that(FormatoNumerico.formatar_inteiro(1234567)).is_equal("1 234 567")


func test_segmentos_largura_racha_pos_hitstop_e_histerese_de_vida_baixa() -> void:
	var duble: LeituraDuble = LeituraDuble.new()
	var hud: ModeloDoHud = ModeloDoHud.new(duble, HudTuning.new())
	var vida: ModeloDaVida = hud.vida_modelo()

	assert_that(vida.quantidade_segmentos()).is_equal(10)
	assert_that(vida.largura_barra_100_px()).is_equal_approx(260.0, 0.01)

	# Dano para 25/100 ativa vida baixa e mantém racha em 1.0 durante hitstop
	duble.v_vida = Vector2i(25, 100)
	duble.v_hitstop = true
	hud.sincronizar_da_leitura()
	assert_that(vida.vida_baixa_ativa()).is_true()
	assert_that(vida.fracao_vida()).is_equal_approx(0.25, 0.001)
	assert_that(vida.fracao_racha()).is_equal_approx(1.0, 0.001)

	hud.avancar_quadro(0.50)
	# Ainda 1.0 porque hitstop_ativo == true
	assert_that(vida.fracao_racha()).is_equal_approx(1.0, 0.001)

	# Fim do hitstop -> racha escorre até alcançar a vida atual
	duble.v_hitstop = false
	for i: int in range(15):
		hud.avancar_quadro(0.10)
	assert_that(vida.fracao_racha()).is_equal_approx(0.25, 0.001)

	# Cura para 28/100 mantém vida baixa por histerese (< 30%); cura para 30/100 desativa
	duble.v_vida = Vector2i(28, 100)
	hud.sincronizar_da_leitura()
	assert_that(vida.vida_baixa_ativa()).is_true()

	duble.v_vida = Vector2i(30, 100)
	hud.sincronizar_da_leitura()
	assert_that(vida.vida_baixa_ativa()).is_false()
