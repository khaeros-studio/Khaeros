@abstract class_name LeituraDoHud
extends RefCounted
## Contrato abstrato de leitura somente-consulta do estado vivo para o HUD (`ADR-0012 §2`).
## Permite que o `ModeloDoHud` consulte os valores reais ao ser construído e ao final
## de cada entrega de eventos do passo, sem jamais mutar sistemas de jogo.


@abstract func vida() -> Vector2i
@abstract func escudo() -> int
@abstract func recusas() -> Vector2i
@abstract func fluxo() -> Dictionary
@abstract func esquiva() -> Dictionary
@abstract func saldo() -> int
@abstract func limiar_fundo_do_poco() -> int
@abstract func inimigos_feridos() -> Array[Dictionary]
@abstract func porta_interagivel() -> Dictionary
@abstract func estado_de_jogo() -> int
@abstract func hitstop_ativo() -> bool
@abstract func chefe() -> Dictionary
@abstract func estado_pacto() -> Dictionary
