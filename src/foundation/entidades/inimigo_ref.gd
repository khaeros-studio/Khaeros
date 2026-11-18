## Estado vivo de um inimigo (ADR-0003). Só campos, sem regra.
##
## A definição é um [Resource] do catálogo, compartilhado e tratado como imutável;
## o estado mutável fica aqui, por instância. Cada campo tem um único dono e só
## muda pela interface desse dono:
## [br]- IA: lista, [member fase], [member passos_na_fase], [member posicao].
## [br]- Combate: [member vida], [member escudo], [member impacto_passos].
## [br]- Modificadores: [member portador] (atributos, fontes, gatilhos).
## [br]- Selo: [member no_selo].
## [br]- Status: os três efeitos ficam no módulo de Status, indexados por [member id].
##
## O chefe é um [InimigoRef] com [member chefe] verdadeiro. A acuada não é
## [InimigoRef] e não entra na lista de inimigos (pertence ao Vínculo).
## Quem guarda o resultado além da chamada guarda [member id] e revalida.
##
## Exemplo:
## [codeblock]
## var i := InimigoRef.new(ids.proximo(), catalogo.inimigo(&"rastejante"))
## inimigos.append(i)  # dono: IA
## [/codeblock]
class_name InimigoRef
extends RefCounted

## Id da run ([GeradorDeIds]); estável, nunca reaproveitado. Somente leitura.
var id: int
## Definição do catálogo (imutável por convenção; nunca escrever nela).
var definicao: Resource
## Marca de chefe (fixa na criação).
var chefe: bool
## Marca de elite (fixa na criação; dona: IA).
var elite: bool

## Dono: IA. Fase do ciclo (valores definidos pela IA).
var fase: StringName = &""
## Dono: IA. Passos decorridos na fase atual.
var passos_na_fase: int = 0
## Dono: IA. Posição em pixels de mundo.
var posicao: Vector2 = Vector2.ZERO

## Dono: Combate. Vida atual.
var vida: float = 0.0
## Dono: Combate. Escudo atual.
var escudo: float = 0.0
## Dono: Combate. Passos restantes de impacto/cambaleio.
var impacto_passos: int = 0

## Dono: Selo. Inimigo dentro do Selo.
var no_selo: bool = false

## Dono: Modificadores. Portador de atributos (ADR-0009); o portador nunca guarda
## referência forte de volta a este objeto.
var portador: RefCounted = null


## [param p_id]: de [method GeradorDeIds.proximo]. [param p_definicao]: recurso do catálogo.
func _init(p_id: int, p_definicao: Resource, p_chefe: bool = false, p_elite: bool = false) -> void:
	id = p_id
	definicao = p_definicao
	chefe = p_chefe
	elite = p_elite
