## Interface limitada de camaras à fonte de fluxos (ADR-0005, matriz dono × finalidade):
## só abre ondas (1), spawn (3) e layout (8).
class_name FluxosDeCamaras
extends AcessoAFluxos


## Recebe a fonte da run; a matriz deste dono é fixa.
func _init(fonte: FonteDeFluxos) -> void:
	super(fonte, [FonteDeFluxos.ONDAS, FonteDeFluxos.SPAWN, FonteDeFluxos.LAYOUT] as Array[int], &"camaras")


## Fluxo `ondas` de (região, profundidade).
func ondas(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.ONDAS, regiao, profundidade)

## Fluxo `spawn` de (região, profundidade).
func spawn(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.SPAWN, regiao, profundidade)

## Fluxo `layout` de (região, profundidade).
func layout(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.LAYOUT, regiao, profundidade)
