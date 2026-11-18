class_name ParametrosDoMovimento
extends RefCounted
## Derivados do [MovementTuning] calculados uma vez ao configurar (GDD movimento-e-esquiva F2–F4, MV3;
## ADR-0008 §1). D, E e R são quantizados separadamente pela F7 do Conteúdo e somados em inteiros.
##
## Exemplo:
## [codeblock]
## var p := ParametrosDoMovimento.de(tuning)
## assert(p.inv_esquiva == p.d + p.e)
## [/codeblock]

## D: passos de esquiva, contando o do início.
var d: int = 0
## E: passos de invulnerabilidade extra (pode ser 0).
var e: int = 0
## R: passos de recarga de uma carga.
var r: int = 0
## Deslocamento da esquiva por passo, px.
var d_passo: float = 0.0
## Pedido de invulnerabilidade da largada: D + E (soma de inteiros, MV3).
var inv_esquiva: int = 0
## Distância total da esquiva sem obstáculo: D × d_passo.
var dist_total: float = 0.0
## Raio do jogador, px.
var raio: float = 0.0
## Fator de andar em recuperação.
var fator_recuperacao: float = 0.0
## Teto de alvos do Corte por esquiva; 0 = vazio (sem teto, R8 D-W6).
var alvos_max_corte: int = 0


## Calcula os derivados de [param tuning].
static func de(tuning: MovementTuning) -> ParametrosDoMovimento:
	var p := ParametrosDoMovimento.new()
	p.d = Unidades.duracao_para_passos(tuning.duracao_esquiva_s)
	p.e = Unidades.duracao_para_passos(tuning.invuln_extra_s)
	p.r = Unidades.duracao_para_passos(tuning.recarga_s)
	p.d_passo = tuning.velocidade_esquiva_pxs / float(Unidades.TICK_RATE)
	p.inv_esquiva = p.d + p.e
	p.dist_total = float(p.d) * p.d_passo
	p.raio = tuning.raio_jogador_px
	p.fator_recuperacao = tuning.fator_recuperacao
	p.alvos_max_corte = tuning.alvos_max_corte
	return p
