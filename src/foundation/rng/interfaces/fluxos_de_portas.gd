## Interface limitada de portas à fonte de fluxos (ADR-0005, matriz dono × finalidade):
## só abre portas (4).
class_name FluxosDePortas
extends AcessoAFluxos


## Recebe a fonte da run; a matriz deste dono é fixa.
func _init(fonte: FonteDeFluxos) -> void:
	super(fonte, [FonteDeFluxos.PORTAS] as Array[int], &"portas")


## Fluxo `portas` de (região, profundidade).
func portas(regiao: int, profundidade: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.PORTAS, regiao, profundidade)
