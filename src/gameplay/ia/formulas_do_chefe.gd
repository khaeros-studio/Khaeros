class_name FormulasDoChefe
extends RefCounted
## Fórmulas puras da luta contra o Chefe e deslocamentos de puxão/pulso (GDD chefes.md F1–F5, IA R18b; ADR-0018 §5, §8).


## Passo de puxão determinístico rumo a `centro`, parando a `parar_a_px` e aplicando colisão (F3 de Chefes, R18b da IA).
static func calcular_posicao_puxada(pos_atual: Vector2, raio_corpo: float, centro: Vector2,
		distancia_px: float, parar_a_px: float, geometria: GeometriaDeMovimento = null) -> Vector2:
	if distancia_px <= 0.0:
		return pos_atual
	var para_centro := centro - pos_atual
	var d := para_centro.length()
	if d <= parar_a_px or d == 0.0:
		return pos_atual
	var passo := minf(distancia_px, maxf(0.0, d - parar_a_px))
	var nova_pos := pos_atual + (para_centro / d) * passo
	if geometria != null:
		return Colisao.resolver_colisao(nova_pos, raio_corpo, geometria)
	return nova_pos


## Passo do pulso repulsor da TransicaoFase (F4 de Chefes: afasta `empurrao_pulso_px` quem está a d < `raio_pulso_px`).
static func calcular_posicao_repelida_furia(pos_atual: Vector2, raio_corpo: float, centro_chefe: Vector2,
		raio_pulso_px: float, empurrao_pulso_px: float, geometria: GeometriaDeMovimento = null) -> Vector2:
	if empurrao_pulso_px <= 0.0 or raio_pulso_px <= 0.0:
		return pos_atual
	var delta := pos_atual - centro_chefe
	var d := delta.length()
	if d >= raio_pulso_px:
		return pos_atual
	var dir := Vector2.DOWN if d == 0.0 else delta / d
	var nova_pos := pos_atual + dir * empurrao_pulso_px
	if geometria != null:
		return Colisao.resolver_colisao(nova_pos, raio_corpo, geometria)
	return nova_pos


## F3 de Chefes: calcula a quantidade de lacaios a invocar respeitando vagas de `max_lacaios_vivos` e `max_inimigos_onda`.
static func quantidade_lacaios_para_invocar(lacaios_vivos: int, vivos_na_lista: int,
		max_lacaios_vivos: int = 3, lacaios_por_convergencia: int = 2,
		max_inimigos_onda: int = 9) -> int:
	var vagas_lacaios := maxi(0, max_lacaios_vivos - lacaios_vivos)
	var vagas_onda := maxi(0, max_inimigos_onda - vivos_na_lista)
	return mini(lacaios_por_convergencia, mini(vagas_lacaios, vagas_onda))


## F3 de Chefes: posições laterais determinísticas de nascimento dos lacaios (`k = 0` à esquerda `-dist`, `k = 1` à direita `+dist`),
## empurradas para fora de pilares (`r_pilar + r_lacaio + folga`) e presas à margem da câmara.
static func posicoes_spawn_lacaios(pos_chefe: Vector2, n_invocar: int, dist_spawn_lacaio_px: float = 135.0,
		raio_lacaio_px: float = 24.0, folga_pilar_px: float = 12.0,
		geometria: GeometriaDeMovimento = null) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k in n_invocar:
		var sinal := -1.0 if k == 0 else 1.0
		var p := pos_chefe + Vector2(sinal * dist_spawn_lacaio_px, 0.0)
		if geometria != null:
			for obs: ObstaculoCircular in geometria.obstaculos():
				var delta := p - obs.centro
				var r_min := obs.raio + raio_lacaio_px + folga_pilar_px
				if delta.length_squared() < r_min * r_min:
					var normal := Vector2.UP if delta == Vector2.ZERO else delta.normalized()
					p = obs.centro + normal * r_min
			p = Colisao.resolver_colisao(p, raio_lacaio_px, geometria)
		out.append(p)
	return out


## F1 de Chefes: passos de recarga do padrão `padrao` na Fase 1 (`em_furia = false`) ou Fase 2 (`× fator_recarga_furia`).
static func passos_recarga_padrao(recarga_s: float, em_furia: bool, fator_recarga_furia: float = 0.60) -> int:
	var mult := fator_recarga_furia if em_furia else 1.0
	return Unidades.duracao_para_passos(recarga_s * mult)


## F4 de Chefes: limiar inteiro de Vida para ativar a Fase 2 (`round(vida_max * limiar_furia_frac)` = 350 para 700 HP).
static func limiar_vida_furia(vida_max: float, limiar_furia_frac: float = 0.50) -> int:
	return Unidades.arredondar_meio_longe_do_zero(vida_max * limiar_furia_frac)
