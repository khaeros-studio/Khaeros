## Interface limitada de vinculo à fonte de fluxos (ADR-0005, matriz dono × finalidade):
## só abre pactos (9), chave (pactos, região, 0), e só em runs de Pactos (ADR-0015).
class_name FluxosDeVinculo
extends AcessoAFluxos


## Recebe a fonte da run; a matriz deste dono é fixa.
func _init(fonte: FonteDeFluxos) -> void:
	super(fonte, [FonteDeFluxos.PACTOS] as Array[int], &"vinculo")


## Fluxo `pactos` da região (profundidade sempre 0, R3-P).
func pactos(regiao: int) -> FluxoRng:
	return fluxo(FonteDeFluxos.PACTOS, regiao, 0)
