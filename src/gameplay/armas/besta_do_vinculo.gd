class_name BestaDoVinculo
extends RefCounted
## Regras específicas da Besta do Vínculo (Doutrina de Pactos) como filtros e helpers puros
## sobre o Combate núcleo (GDD `design/gdd/armas-das-doutrinas.md` R2b; Story 006,
## AC-AR-43 a AC-AR-46; ADR-0002, ADR-0010 §11, ADR-0017).
##
## Como manda a R1/R2b ("é um filtro sobre o `acerto_de_arma`, sem regra própria da arma"),
## este módulo:
## - filtra acertos do slot Ataque quando a arma equipada é `pactos` e emite [EvAcertoVirote]
##   (inclusive com dano 0 / M = 0 e quando o golpe mata) e atualiza a marca da Maldição;
## - converte a recusa de `chamado` registrada pelo [Combate] em [EvChamadoIndisponivel]
##   uma vez por toque novo;
## - calcula o ponto mirado limitado a `alcance_chamado_px` (mouse com módulo ou gamepad
##   unitário; R2b, Maldições F4).

const ALCANCE_CHAMADO_PADRAO_PX: float = 420.0


## R2b (AC-AR-45): calcula o ponto alvo do salto do Chamado a partir da posição do jogador,
## da mira unitária e do ponto mirado (cursor do mouse; `Vector2.INF` ou vazio no gamepad).
static func calcular_ponto_chamado(pos_jogador: Vector2, mira: Vector2, ponto_cursor: Vector2,
		usar_cursor_mouse: bool = true, alcance_max_px: float = ALCANCE_CHAMADO_PADRAO_PX) -> Vector2:
	if not usar_cursor_mouse:
		var dir: Vector2 = mira.normalized() if mira != Vector2.ZERO else Vector2.RIGHT
		return pos_jogador + dir * alcance_max_px
	var delta: Vector2 = ponto_cursor - pos_jogador
	var dist: float = delta.length()
	if dist <= alcance_max_px or dist <= 1e-6:
		return ponto_cursor
	return pos_jogador + (delta / dist) * alcance_max_px


## R2b (AC-AR-44): processa um acerto de golpe no passo. Se e somente se [param de_arma]
## for verdadeiro, [param slot] for `RecursosDoJogador.SLOT_ATAQUE` (0) e [param arma_id]
## for `pactos`, emite [EvAcertoVirote] no canal (mesmo com `dano_causado == 0.0` ou se o
## alvo morreu) e retorna `true`. Nunca emite para o Chamado (`de_arma` falso, slot Especial)
## nem para outras armas (`lamina`, `ressonancia`).
static func registrar_impacto_para_marca(arma_id: StringName, slot: int, de_arma: bool,
		alvo_id: int, player_id: int, passo: int, eventos: EventosDoPasso,
		posicao: Vector2 = Vector2.ZERO) -> bool:
	if not de_arma:
		return false
	if arma_id != FabricaDeArmas.ID_PACTOS:
		return false
	if slot != RecursosDoJogador.SLOT_ATAQUE:
		return false
	if eventos != null:
		eventos.emitir(EvAcertoVirote.new(alvo_id, player_id, passo, posicao))
	return true


## Emite [EvChamadoIndisponivel] para cada recusa de Chamado registrada pelo [Combate]
## no último item 5 (uma vez por toque novo consumido do buffer; AC-AR-46).
static func emitir_recusas_do_passo(combate: Combate, eventos: EventosDoPasso) -> int:
	if combate == null or eventos == null:
		return 0
	var emitidos: int = 0
	for d: EstadoDeGolpe in combate.disparos_do_passo():
		if d.recusa_chamado:
			eventos.emitir(EvChamadoIndisponivel.new(d.player_id, d.passo))
			emitidos += 1
	return emitidos
