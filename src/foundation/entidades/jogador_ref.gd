## Estado vivo de um jogador (ADR-0003). Só campos, sem regra; um por [member player_id].
##
## Donos dos campos (mudança só pela interface do dono):
## [br]- Movimento: [member posicao], [member cargas], [member esquiva_passos].
## [br]- Combate: [member vida].
## [br]- Selo: [member fluxo].
## [br]- Modificadores: [member portador].
##
## Exemplo:
## [codeblock]
## var p0 := JogadorRef.new(0, catalogo.jogador())
## [/codeblock]
class_name JogadorRef
extends RefCounted

## Índice do jogador (0 no solo; co-op preparado). Somente leitura.
var player_id: int
## Definição do catálogo (imutável por convenção).
var definicao: Resource

## Dono: Movimento. Posição em pixels de mundo.
var posicao: Vector2 = Vector2.ZERO
## Dono: Movimento. Cargas de esquiva disponíveis.
var cargas: int = 0
## Dono: Movimento. Passos restantes da esquiva em curso.
var esquiva_passos: int = 0

## Dono: Combate. Vida atual.
var vida: float = 0.0

## Dono: Selo. Fluxo atual.
var fluxo: float = 0.0

## Dono: Modificadores. Portador (ADR-0009); sem referência forte de volta.
var portador: RefCounted = null


## [param p_player_id]: 0 no solo. [param p_definicao]: recurso do catálogo.
func _init(p_player_id: int, p_definicao: Resource) -> void:
	player_id = p_player_id
	definicao = p_definicao
