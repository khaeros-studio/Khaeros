@abstract
class_name DeslocamentosDoChefe
extends RefCounted
## Porta para deslocamentos forçados sem dano causados pelo chefe (puxão da Convergência e pulso da TransicaoFase;
## GDD chefes.md R5.4, R7, F3, F4; ADR-0018 §8).


@abstract func imune(faccao: TelegrafoTipos.FaccaoAlvo, id: int) -> bool
@abstract func deslocar(faccao: TelegrafoTipos.FaccaoAlvo, id: int, delta: Vector2) -> void


class Nulo extends DeslocamentosDoChefe:
	func imune(_faccao: TelegrafoTipos.FaccaoAlvo, _id: int) -> bool:
		return false

	func deslocar(_faccao: TelegrafoTipos.FaccaoAlvo, _id: int, _delta: Vector2) -> void:
		pass
