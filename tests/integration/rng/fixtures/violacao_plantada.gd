## Fixture da story RNG-006 (AC-32): UMA violação real plantada na linha marcada
## e iscas em comentários e literais que o lint NÃO pode contar.
## Não é carregada pelo jogo; só lida como texto por lint_rng_test.gd.
extends RefCounted

# Isca em comentário: randi() randf() RandomNumberGenerator.new() lista.shuffle()
const ISCA_TEXTO := "randi() randf_range(0, 1) seed(7) hex_to_int"
const ISCA_TRIPLA := """
lista.pick_random()
randomize()
"""


## Valor sorteado da engine — esta é a violação plantada.
func sorteio_proibido() -> int:
	return randi() # VIOLACAO_PLANTADA
