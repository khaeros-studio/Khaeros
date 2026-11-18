@abstract
class_name ConsultaDaMaldicao
extends RefCounted
## Porta implementada por `ModuloDeMaldicoes` e consumida por `ModuloDeIA` (ADR-0017, ADR-0018).


@abstract func maldicao_em_campo(player_id: int) -> int
@abstract func posicao_e_raio(maldicao_id: int) -> Vector3
@abstract func maldicao_atingivel(maldicao_id: int) -> bool
@abstract func fator_andar_atraido(player_id: int) -> float


class Nula extends ConsultaDaMaldicao:
	func maldicao_em_campo(_player_id: int) -> int:
		return -1

	func posicao_e_raio(_maldicao_id: int) -> Vector3:
		return Vector3.ZERO

	func maldicao_atingivel(_maldicao_id: int) -> bool:
		return false

	func fator_andar_atraido(_player_id: int) -> float:
		return 1.0
