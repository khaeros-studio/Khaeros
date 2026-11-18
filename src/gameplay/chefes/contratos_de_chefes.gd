class_name ContratosDeChefes
extends RefCounted


@abstract class CombateParaChefes extends RefCounted:
	@abstract func pausar_combate(passos: int) -> void
	@abstract func descartar_projeteis_inimigos() -> void
	@abstract func resolver_subjugado(id_chefe: int, escolha: StringName) -> void
	@abstract func jogador_morreu_neste_passo() -> bool


@abstract class CamarasParaChefes extends RefCounted:
	@abstract func limpar_camara_chefe() -> void
	@abstract func configurar_pilares_arena(pilares: Array[Vector2], raio_px: float) -> void


@abstract class VinculoParaChefes extends RefCounted:
	@abstract func creditar(fonte: StringName, quantidade: int) -> void


class CombateParaChefesNulo extends CombateParaChefes:
	func pausar_combate(_passos: int) -> void:
		return

	func descartar_projeteis_inimigos() -> void:
		return

	func resolver_subjugado(_id_chefe: int, _escolha: StringName) -> void:
		return

	func jogador_morreu_neste_passo() -> bool:
		return false


class CamarasParaChefesNula extends CamarasParaChefes:
	func limpar_camara_chefe() -> void:
		return

	func configurar_pilares_arena(_pilares: Array[Vector2], _raio_px: float) -> void:
		return


class VinculoParaChefesNulo extends VinculoParaChefes:
	func creditar(_fonte: StringName, _quantidade: int) -> void:
		return
