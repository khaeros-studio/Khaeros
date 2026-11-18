## Interface limitada de ia à fonte de fluxos (ADR-0005, matriz dono × finalidade):
## só abre elites (2) e ia (7); IA de aliado e chefe não ganham fluxo.
class_name FluxosDeIa
extends AcessoAFluxos


## Recebe a fonte da run; a matriz deste dono é fixa.
func _init(fonte: FonteDeFluxos) -> void:
	super(fonte, [FonteDeFluxos.ELITES, FonteDeFluxos.IA] as Array[int], &"ia")


## Fluxo `elites` de (região, profundidade).
func elites(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.ELITES, regiao, profundidade)

## Fluxo `ia` de (região, profundidade).
func ia(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.IA, regiao, profundidade)
