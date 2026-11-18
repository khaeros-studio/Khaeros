@abstract
class_name ConsultaDaAcuada
extends RefCounted
## Porta injetada na IA para consultar a Maldição acuada do encontro de pacto (GDD R22; Vínculo V7–V12, V44; ADR-0018 §4).


@abstract func acuada_atingivel() -> bool
@abstract func posicao_e_raio_acuada() -> Vector3


class Nula extends ConsultaDaAcuada:
	func acuada_atingivel() -> bool:
		return false

	func posicao_e_raio_acuada() -> Vector3:
		return Vector3.ZERO
