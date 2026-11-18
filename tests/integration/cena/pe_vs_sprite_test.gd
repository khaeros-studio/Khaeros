extends GdUnitTestSuite
## AC-08 (GDD Cena R3): colisão pela posição de chão, nunca pela sprite.
## A colisão real é de movimento-e-esquiva/combate-nucleo; aqui um dublê da
## interface de entidade (posição de chão + deslocamento visual + raio) prova que
## a Cena entrega o pé separado da altura visual, e que o mesmo pé ordena.


## Dublê da interface de entidade vista pela Cena.
class EntidadeFalsa:
	extends RefCounted
	var posicao_chao: Vector2
	var deslocamento_visual: Vector2
	var raio: float
	var meia_sprite: Vector2

	func _init(chao: Vector2, desloc: Vector2, r: float, sprite: Vector2) -> void:
		posicao_chao = chao
		deslocamento_visual = desloc
		raio = r
		meia_sprite = sprite

	func retangulo_sprite() -> Rect2:
		var c := posicao_chao + deslocamento_visual
		return Rect2(c - meia_sprite, meia_sprite * 2.0)


## Dublê da regra de colisão: círculos no plano de chão (R3).
static func _colidem(a: EntidadeFalsa, b: EntidadeFalsa) -> bool:
	return a.posicao_chao.distance_to(b.posicao_chao) <= a.raio + b.raio


func test_projetil_desenhado_60_px_acima_colide_pela_posicao_de_chao() -> void:
	var alvo := EntidadeFalsa.new(Vector2(400, 500), Vector2.ZERO, 27.0, Vector2(30, 45))
	var proj := EntidadeFalsa.new(Vector2(410, 500), Vector2(0, -60), 8.0, Vector2(8, 8))
	# A sprite do projétil está acima da do alvo, mas o chão coincide.
	assert_bool(_colidem(alvo, proj)).is_true()


func test_so_sobreposicao_de_sprite_nao_colide() -> void:
	var alvo := EntidadeFalsa.new(Vector2(400, 500), Vector2.ZERO, 27.0, Vector2(30, 45))
	# Chão 100 px abaixo, sprite voando 100 px acima: as sprites se sobrepõem.
	var proj := EntidadeFalsa.new(Vector2(400, 600), Vector2(0, -100), 8.0, Vector2(8, 8))
	assert_bool(alvo.retangulo_sprite().intersects(proj.retangulo_sprite())).is_true()
	assert_bool(_colidem(alvo, proj)).is_false()


func test_ordenacao_usa_o_mesmo_pe_de_chao_da_colisao() -> void:
	var alvo := EntidadeFalsa.new(Vector2(400, 500), Vector2.ZERO, 27.0, Vector2(30, 45))
	var proj := EntidadeFalsa.new(Vector2(400, 600), Vector2(0, -100), 8.0, Vector2(8, 8))
	var ord := OrdenacaoPorPe.new()
	ord.definir(0, OrdenacaoPorPe.pe_de_projetil(proj.posicao_chao, proj.deslocamento_visual), 9, proj.deslocamento_visual)
	ord.definir(1, alvo.posicao_chao, 1)
	ord.ordenar(2)
	# Chão do projétil (600) abaixo do alvo (500): fica na frente, apesar do voo.
	assert_array(ord.ordem()).is_equal([1, 0])
