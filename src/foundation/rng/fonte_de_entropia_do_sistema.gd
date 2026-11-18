## Entropia real do sistema: o ÚNICO uso permitido do gerador da engine em
## código de jogo (GDD rng-com-seed.md R1/R2; ADR-0005). Chamado só pela criação
## da seed da run. O lint de CI (story RNG-006) lista este arquivo como exceção.
class_name FonteDeEntropiaDoSistema
extends FonteDeEntropia


## Sorteia 32 bits a partir da entropia do sistema operacional.
func sortear_u32() -> int:
	var gerador := RandomNumberGenerator.new()
	gerador.randomize()
	return gerador.randi()
