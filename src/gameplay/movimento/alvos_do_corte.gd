@abstract
class_name AlvosDoCorte
extends RefCounted
## Porta da lista de inimigos atingíveis para o Corte (GDD movimento-e-esquiva R8, R12; ADR-0008 §5).
## Ordem estável da IA (spawn/id); já exclui Surgindo, Subjugado e Vida ≤ 0 — o Movimento não refaz o
## filtro. Consultada de novo a cada passo de esquiva (nunca reutilizar a lista de outro passo).
## Implementação de produção: adaptador sobre [code]IA.atingiveis()[/code], ligado pelo Main.


## Alvos atingíveis neste passo, em ordem estável. Somente leitura para o Movimento.
@abstract func alvos_atingiveis() -> Array[AlvoDoCorte]
