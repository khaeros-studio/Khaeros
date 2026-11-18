class_name Colisao
extends RefCounted
## Colisão própria, função pura (GDD movimento-e-esquiva R10, F7; ADR-0008 §6 e ajuste de 2026-11-15).
## Uma passada pelos obstáculos na ordem do dado, borda estrita (contato exato não empurra), normal (0, −1)
## em centros coincidentes, depois clamp ao retângulo encolhido do raio. Sem margem, epsilon, solver ou
## subpasso. Reutilizável por Maldições (emenda Pactos) com a mesma semântica.
##
## Exemplo:
## [codeblock]
## var pos := Colisao.resolver_colisao(Vector2(1000, 540), 27.0, geometria)
## [/codeblock]

## Resultado de [method resolver_colisao_informando].
class ResolucaoDeColisao extends RefCounted:
	## Posição resolvida.
	var pos: Vector2
	## Verdadeiro se algum obstáculo ou parede corrigiu a posição.
	var corrigida: bool

	func _init(p_pos: Vector2, p_corrigida: bool) -> void:
		pos = p_pos
		corrigida = p_corrigida


## Posição resolvida de [param pos] (círculo de [param raio]) contra [param geometria].
static func resolver_colisao(pos: Vector2, raio: float, geometria: GeometriaDeMovimento) -> Vector2:
	return resolver_colisao_informando(pos, raio, geometria).pos


## Mesmo algoritmo de [method resolver_colisao], informando se houve correção (parede do empurrão, ADR-0010 §6).
static func resolver_colisao_informando(pos: Vector2, raio: float,
		geometria: GeometriaDeMovimento) -> ResolucaoDeColisao:
	var corrigida := false
	for o: ObstaculoCircular in geometria.obstaculos():
		var delta := pos - o.centro
		var combinado := raio + o.raio
		if delta.length_squared() < combinado * combinado:
			var normal := Vector2.UP if delta == Vector2.ZERO else delta.normalized()
			pos = o.centro + normal * combinado
			corrigida = true
	var minimo := geometria.jogavel.position + Vector2(raio, raio)
	var maximo := geometria.jogavel.end - Vector2(raio, raio)
	var presa := pos.clamp(minimo, maximo)
	if presa != pos:
		corrigida = true
	return ResolucaoDeColisao.new(presa, corrigida)
