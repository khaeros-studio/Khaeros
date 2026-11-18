class_name ContextoDaTecnica
extends RefCounted
## Contexto passado ao `ExecutorDeTecnica` e colaboradores de Maldições (ADR-0017 §5, §6).


@abstract
class CombateAliado extends RefCounted:
	@abstract func aplicar_golpe_maldicao(player_id: int, maldicao_id: int, alvos: Array[int],
			dano_golpe: float, m_maldicao: float, dir: Vector2, empurrao: float,
			status: Array, pesado: bool, ataque_id: StringName) -> void


@abstract
class StatusAliado extends RefCounted:
	@abstract func tem_abalo(inimigo_id: int) -> bool
	@abstract func aplicar_status(inimigo_id: int, status_id: StringName, duracao_s: float, autor_player_id: int) -> void


class StatusNulo extends StatusAliado:
	var abalo_por_id: Dictionary[int, int] = {}

	func avancar_um_passo() -> void:
		for k: int in abalo_por_id.keys():
			var r: int = abalo_por_id[k] - 1
			if r <= 0:
				abalo_por_id.erase(k)
			else:
				abalo_por_id[k] = r

	func tem_abalo(inimigo_id: int) -> bool:
		return abalo_por_id.get(inimigo_id, 0) > 0

	func aplicar_status(inimigo_id: int, status_id: StringName, duracao_s: float, _autor_player_id: int) -> void:
		if status_id == &"abalo" and duracao_s > 0.0:
			var p := Unidades.duracao_para_passos(duracao_s)
			abalo_por_id[inimigo_id] = maxi(abalo_por_id.get(inimigo_id, 0), p)


var pacto: EstadoDoPacto = null
var tuning: MaldicoesTuning = null
var ia: ModuloDeIA = null
var combate: CombateAliado = null
var status: StatusAliado = null
var eventos: EventosDoPasso = null
var pos_jogador: Vector2 = Vector2.ZERO
var mira_jogador: Vector2 = Vector2.RIGHT
var respiro_atracao_passos: int = 30
