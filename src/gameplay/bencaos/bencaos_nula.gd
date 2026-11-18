class_name BencaosNula
extends Bencaos
## Variante Nula das Bênçãos (ADR-0015 §9): comportamento "ausente".
## [method pedir_oferta] responde sempre [constant Bencaos.SEM_BENCAO]; nada sorteia,
## nada emite. Overrides com [code]return[/code] explícito (regra 4.7).


## Sem dependências.
func _init() -> void:
	var sem_regioes: Dictionary[StringName, int] = {}
	super(null, null, null, null, null, sem_regioes, null)


## Sempre [constant Bencaos.SEM_BENCAO].
func pedir_oferta(_regiao: StringName, _indice: int) -> StringName:
	return SEM_BENCAO


## Nunca troca.
func trocar() -> bool:
	return false


## Zero.
func trocas_restantes() -> int:
	return 0


## Sempre [constant Bencaos.Estado.SEM_OFERTA].
func estado() -> Bencaos.Estado:
	return Bencaos.Estado.SEM_OFERTA


## Sempre false.
func oferta_aberta() -> bool:
	return false


## Vazia.
func cartas() -> Array[CartaDaOferta]:
	return [] as Array[CartaDaOferta]


## Zero (pool vazio).
func restantes() -> int:
	return 0


## Vazia.
func tomadas() -> Array[Dictionary]:
	return [] as Array[Dictionary]


## Nunca escolhe.
func escolher(_indice_carta: int, _fechar_imediato: bool = true) -> bool:
	return false


## Nada a fechar.
func notificar_tela_fechada() -> bool:
	return false


## Vazia.
func cartas_view(_textos: TabelaDeTextos = null) -> Array[Dictionary]:
	return [] as Array[Dictionary]

