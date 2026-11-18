## Interface limitada de bencaos à fonte de fluxos (ADR-0005, matriz dono × finalidade):
## só abre bencaos (5) e raridade (6).
class_name FluxosDeBencaos
extends AcessoAFluxos


## Recebe a fonte da run; a matriz deste dono é fixa.
func _init(fonte: FonteDeFluxos) -> void:
	super(fonte, [FonteDeFluxos.BENCAOS, FonteDeFluxos.RARIDADE] as Array[int], &"bencaos")


## Fluxo `bencaos` de (região, profundidade).
func bencaos(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.BENCAOS, regiao, profundidade)

## Fluxo `raridade` de (região, profundidade).
func raridade(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.RARIDADE, regiao, profundidade)
