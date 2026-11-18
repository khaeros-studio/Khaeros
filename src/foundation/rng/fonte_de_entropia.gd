## Contrato da fonte de entropia injetada na criação da seed (GDD rng-com-seed.md
## R2, R9). Os testes injetam uma entropia falsa; o ponto de composição injeta
## [FonteDeEntropiaDoSistema].
@abstract
class_name FonteDeEntropia
extends RefCounted


## Devolve um inteiro de entropia; quem chama aplica a máscara u32.
@abstract func sortear_u32() -> int
