class_name SpawnCamara
extends RefCounted
## Escolha determinística de pontos de nascimento de inimigos por K (14) candidatos fixos
## (GDD camaras-e-ondas.md R7, R7-P, F3, F3-P; ADR-0005, ADR-0018).
##
## Regras:
## - Para cada inimigo, sorteia **sempre** [code]K = spawn_candidatos[/code] (14) pares [code](x, y)[/code]
##   no fluxo [code]spawn[/code] (28 reais por inimigo), com [code]x ∈ [raio + m, L − raio − m][/code] e
##   [code]y ∈ [raio + m, A − raio − m][/code].
## - O raio de um elite é multiplicado por [code]mult_raio_elite[/code] (1,2) antes de calcular a margem
##   e a folga das pedras.
## - Escolhe o **primeiro** candidato que satisfaz:
##   1. [code]|C − pos_jogador| > spawn_dist_jogador_px[/code] (mais de 390 px);
##   2. para toda pedra: [code]|C − p.centro| > p.raio + raio_efetivo + spawn_folga_pedra_px[/code] (mais de r_pedra + raio + 12 px);
##   3. se [code]acuada_presente[/code] (estado Acuada): [code]|C − pos_acuada| > spawn_dist_acuada_px[/code] (mais de 240 px).
## - Se nenhum dos K candidatos servir, escolhe o último ([code]C_K[/code]).

const MULT_RAIO_ELITE_PADRAO: float = 1.2


## Resultado do nascimento de um inimigo na onda.
class NascimentoDeInimigo:
	extends RefCounted
	var inimigo_id: StringName
	var definicao: EnemyDef
	var posicao: Vector2
	var raio_efetivo: float
	var elite: bool
	var ordem: int
	var candidatos_sorteados: Array[Vector2] = []

	func _init(p_id: StringName, p_def: EnemyDef, p_pos: Vector2, p_raio: float, p_elite: bool, p_ordem: int) -> void:
		inimigo_id = p_id
		definicao = p_def
		posicao = p_pos
		raio_efetivo = p_raio
		elite = p_elite
		ordem = p_ordem


## Sorteia sempre [code]tuning.spawn_candidatos[/code] candidatos no [param fluxo_spawn] e devolve o ponto escolhido (F3, F3-P).
static func escolher_ponto_spawn(raio_efetivo: float, tuning: RoomTuning, fluxo_spawn: FluxoRng,
		pos_jogador: Vector2, obstaculos: Array[ObstaculoCircular],
		acuada_presente: bool = false, pos_acuada: Vector2 = Vector2.ZERO) -> Vector2:
	var candidatos: Array[Vector2] = sortear_candidatos(raio_efetivo, tuning, fluxo_spawn)
	return selecionar_candidato(candidatos, raio_efetivo, tuning, pos_jogador, obstaculos, acuada_presente, pos_acuada)


## Consome exatamente [code]2 * spawn_candidatos[/code] reais do [param fluxo_spawn].
static func sortear_candidatos(raio_efetivo: float, tuning: RoomTuning, fluxo_spawn: FluxoRng) -> Array[Vector2]:
	var lista: Array[Vector2] = []
	if tuning == null or fluxo_spawn == null:
		return lista
	var k: int = maxi(1, tuning.spawn_candidatos)
	var m: float = tuning.spawn_margem_px
	var x_min: float = raio_efetivo + m
	var x_max: float = maxf(x_min, tuning.camara_largura_px - raio_efetivo - m)
	var y_min: float = raio_efetivo + m
	var y_max: float = maxf(y_min, tuning.camara_altura_px - raio_efetivo - m)
	for _i: int in k:
		var x: float = fluxo_spawn.real_entre(x_min, x_max)
		var y: float = fluxo_spawn.real_entre(y_min, y_max)
		lista.append(Vector2(x, y))
	return lista


## Filtra os [param candidatos] já sorteados pela F3/F3-P e devolve o 1º válido, ou o último se nenhum servir.
static func selecionar_candidato(candidatos: Array[Vector2], raio_efetivo: float, tuning: RoomTuning,
		pos_jogador: Vector2, obstaculos: Array[ObstaculoCircular],
		acuada_presente: bool = false, pos_acuada: Vector2 = Vector2.ZERO) -> Vector2:
	if candidatos.is_empty():
		return Vector2.ZERO
	for c: Vector2 in candidatos:
		if candidato_valido(c, raio_efetivo, tuning, pos_jogador, obstaculos, acuada_presente, pos_acuada):
			return c
	return candidatos[candidatos.size() - 1]


## Verdadeiro se o candidato [param c] respeita distância do jogador, folga das pedras e distância da acuada (F3-P).
static func candidato_valido(c: Vector2, raio_efetivo: float, tuning: RoomTuning,
		pos_jogador: Vector2, obstaculos: Array[ObstaculoCircular],
		acuada_presente: bool = false, pos_acuada: Vector2 = Vector2.ZERO) -> bool:
	# Mais de spawn_dist_jogador_px (exatos 390,0 é recusado; 390,1 é aceito — AC-CO-09)
	if c.distance_to(pos_jogador) <= tuning.spawn_dist_jogador_px + 1e-9:
		return false
	for p: ObstaculoCircular in obstaculos:
		var dist_pedra_min: float = p.raio + raio_efetivo + tuning.spawn_folga_pedra_px
		if c.distance_to(p.centro) <= dist_pedra_min + 1e-9:
			return false
	if acuada_presente and tuning.spawn_dist_acuada_px > 0.0:
		if c.distance_to(pos_acuada) <= tuning.spawn_dist_acuada_px + 1e-9:
			return false
	return true


## Nasce uma onda inteira na ordem de composição: sorteia elite primeiro, depois os 14 candidatos de spawn (R7, R7-P).
static func instanciar_onda(onda: Array[ComposicaoDeOndas.EntradaDeOnda], p: int, tuning: RoomTuning,
		fluxo_spawn: FluxoRng, sorteador_elite: Callable, pos_jogador: Vector2,
		obstaculos: Array[ObstaculoCircular], acuada_presente: bool = false,
		pos_acuada: Vector2 = Vector2.ZERO, mult_raio_elite: float = MULT_RAIO_ELITE_PADRAO) -> Array[NascimentoDeInimigo]:
	var nascidos: Array[NascimentoDeInimigo] = []
	var ja_ha_elite: bool = false
	for idx: int in onda.size():
		var entrada: ComposicaoDeOndas.EntradaDeOnda = onda[idx]
		var eh_elite: bool = entrada.elite
		if sorteador_elite.is_valid():
			eh_elite = bool(sorteador_elite.call(p, ja_ha_elite))
			entrada.elite = eh_elite
		if eh_elite:
			ja_ha_elite = true
		var raio_base: float = entrada.definicao.raio_px if entrada.definicao != null else 24.0
		var raio_ef: float = raio_base * mult_raio_elite if eh_elite else raio_base
		var cands: Array[Vector2] = sortear_candidatos(raio_ef, tuning, fluxo_spawn)
		var pos: Vector2 = selecionar_candidato(cands, raio_ef, tuning, pos_jogador, obstaculos, acuada_presente, pos_acuada)
		var nasc := NascimentoDeInimigo.new(entrada.inimigo_id, entrada.definicao, pos, raio_ef, eh_elite, idx)
		nasc.candidatos_sorteados = cands
		nascidos.append(nasc)
	return nascidos
