class_name MaldicaoAcuada
extends RefCounted
## Entidade da Maldição acuada em campo durante um encontro de pacto
## (GDD vinculo-e-pactos.md V7, V8, V9, V12, F2; ADR-0010, ADR-0017 §11, ADR-0018 §4).
##
## Regras:
## - Posição: primeiro ponto de [code]PONTOS_ACUADA[/code] que respeita
##   [code]|p − pedra.centro| > pedra.raio + raio_especie + spawn_folga_pedra_px[/code] (12 px);
##   se nenhum servir, usa o último ponto (960, 720). Não consome RNG.
## - Vida inicial (F2): [code]round(vida_max_base * frac_vida_acuada)[/code] (ex.: Espreitador 95 * 1,2 = 114).
## - Sem fogo amigo: ataques do jogador, Selo, explosões e Maldição em campo nunca a ferem (AC-VP-08).
## - Só golpes de inimigos com alvo travado na acuada chamam [method ferir_acuada]:
##   [code]dano_in = max(1, round(dano_base * m_atacante))[/code], sem redução de dano e sem hitstop.
## - Se [code]vida <= 0[/code] na fase Combate: entra em [code]FUGIU[/code], dissolve-se em 12 passos,
##   [method acuada_atingivel] passa a [code]false[/code] imediatamente (para os inimigos seguintes do mesmo
##   item 7 já mirarem o jogador — V8, V12) e marca a espécie em [code]encontro_pendente[/code].

enum Estado { INATIVA, ACUADA, AGUARDANDO, FUGIU, RESOLVIDA }

const PONTOS_ACUADA: Array[Vector2] = [
	Vector2(960.0, 540.0),
	Vector2(660.0, 540.0),
	Vector2(1260.0, 540.0),
	Vector2(960.0, 360.0),
	Vector2(960.0, 720.0),
]
const PASSOS_FUGA: int = 12
const RAIO_JOGADOR_PADRAO: float = 27.0
const FOLGA_INTERAGIR_PADRAO: float = 15.0

var especie_id: StringName = &""
var raridade: StringName = &"comum"
var posicao: Vector2 = Vector2.ZERO
var raio_px: float = 24.0
var vida_max: int = 100
var vida: int = 100
var estado: Estado = Estado.INATIVA
var passos_fuga_restantes: int = 0


## Calcula a Vida máxima da acuada pela F2: [code]round(vida_max_base * frac_vida_acuada)[/code].
static func calcular_vida_acuada(def: CurseDef, frac_vida_acuada: float = 1.2) -> int:
	var base: float = def.vida_max if def != null else 110.0
	return maxi(1, Unidades.arredondar_meio_longe_do_zero(base * frac_vida_acuada))


## Escolhe o 1º ponto livre de [constant PONTOS_ACUADA] fora das [param pedras] (V7, AC-VP-07).
static func escolher_ponto_acuada(raio_especie: float, pedras: Array[ObstaculoCircular],
		folga_pedra_px: float = 12.0) -> Vector2:
	for pto: Vector2 in PONTOS_ACUADA:
		var livre: bool = true
		for pedra: ObstaculoCircular in pedras:
			if pto.distance_to(pedra.centro) <= pedra.raio + raio_especie + folga_pedra_px + 1e-9:
				livre = false
				break
		if livre:
			return pto
	return PONTOS_ACUADA[PONTOS_ACUADA.size() - 1]


## Inicializa a acuada em campo na montagem da câmara do encontro (V7).
func nascer(def: CurseDef, pedras: Array[ObstaculoCircular], frac_vida: float = 1.2,
		folga_pedra_px: float = 12.0) -> Vector2:
	especie_id = def.id if def != null else &"espreitador_da_fenda"
	raridade = def.raridade if def != null else &"refinado"
	raio_px = def.raio_px if (def != null and def.raio_px > 0.0) else 22.5
	vida_max = calcular_vida_acuada(def, frac_vida)
	vida = vida_max
	posicao = escolher_ponto_acuada(raio_px, pedras, folga_pedra_px)
	estado = Estado.ACUADA
	passos_fuga_restantes = 0
	return posicao


## Verdadeiro enquanto a acuada está em [code]ACUADA[/code] com [code]vida > 0[/code] (V8, V44, ADR-0018 §4).
func acuada_atingivel() -> bool:
	return estado == Estado.ACUADA and vida > 0


## Posição e raio empacotados como [code]Vector3(x, y, raio)[/code] (contrato `ConsultaDaAcuada` do ADR-0018).
func posicao_e_raio_acuada() -> Vector3:
	return Vector3(posicao.x, posicao.y, raio_px)


## Alvo padrão de um inimigo que nasce na onda com índice [param ordem] (V8, AC-VP-09):
## Ordem par (0, 2, 4...) mira [code]&"acuada"[/code] se a acuada estiver atingível; ímpar mira [code]&"jogador"[/code].
func alvo_padrao_por_ordem(ordem: int) -> StringName:
	if acuada_atingivel() and ordem >= 0 and (ordem % 2) == 0:
		return &"acuada"
	return &"jogador"


## Resolve o alvo efetivo de um inimigo considerando atração da Maldição em campo e estado da acuada (V8, AC-VP-10, AC-VP-11).
func alvo_efetivo_inimigo(ordem: int, atraido_pela_maldicao: bool = false) -> StringName:
	if atraido_pela_maldicao:
		return &"maldicao"
	if acuada_atingivel() and ordem >= 0 and (ordem % 2) == 0:
		return &"acuada"
	return &"jogador"


## Aplica dano de inimigo à acuada (V7, V12, V44, F2):
## - Ignora fogo amigo ([param faccao_atacante] != [code]&"inimigo"[/code]);
## - Calcula [code]dano_in = max(1, round(dano_base * m_atacante))[/code], sem hitstop;
## - Se [code]vida <= 0[/code], transiciona para [code]FUGIU[/code] com 12 passos de dissolução e devolve [code]true[/code] (fuga).
func ferir_acuada(dano_base: float, m_atacante: float = 1.0,
		faccao_atacante: StringName = &"inimigo") -> bool:
	if faccao_atacante != &"inimigo":
		return false
	if not acuada_atingivel() or dano_base <= 0.0:
		return false
	var d_int: int = maxi(1, Unidades.arredondar_meio_longe_do_zero(dano_base * m_atacante))
	vida = maxi(0, vida - d_int)
	if vida <= 0:
		estado = Estado.FUGIU
		passos_fuga_restantes = PASSOS_FUGA
		return true
	return false


## Avança a dissolução de fuga (12 passos vivos) se estiver em [code]FUGIU[/code] (V12.1).
func passo_vivo() -> void:
	if estado == Estado.FUGIU and passos_fuga_restantes > 0:
		passos_fuga_restantes -= 1


## Passa para [code]AGUARDANDO[/code] quando a câmara limpa com [code]vida > 0[/code] (V9).
func ao_limpar_camara() -> bool:
	if estado == Estado.ACUADA and vida > 0:
		estado = Estado.AGUARDANDO
		return true
	return false


## Verdadeiro se o jogador em [param pos_jogador] está ao alcance de Interagir com a acuada (V9: raio + 27 + 15 px).
func pode_interagir(pos_jogador: Vector2, raio_jogador: float = RAIO_JOGADOR_PADRAO,
		folga_px: float = FOLGA_INTERAGIR_PADRAO) -> bool:
	if estado != Estado.AGUARDANDO:
		return false
	return pos_jogador.distance_to(posicao) <= raio_px + raio_jogador + folga_px + 1e-9
