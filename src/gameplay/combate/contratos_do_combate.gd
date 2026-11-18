class_name ContratosDoCombate
extends RefCounted
## Contratos e registros de colaboradores do [Combate] (GDD combate-nucleo R8–R25; ADR-0010).
## Nenhum Node, Timer ou física da engine.


enum Faccao {
	JOGADOR,
	ALIADO,
	INIMIGO,
	ACUADA,
}


## Estado vivo de combate de um inimigo (ADR-0003, ADR-0010 §1, §11).
class InimigoCombate:
	extends RefCounted
	var id: int
	var posicao: Vector2
	var raio: float
	var vida: float
	var vida_max: float
	var elite: bool = false
	var chefe: bool = false
	var surgindo: bool = false
	var em_preparacao: bool = false
	var em_execucao: bool = false
	var subjugavel: bool = false
	var subjugado: bool = false
	var invocado_pelo_chefe: bool = false
	var invulneravel_por_fase: bool = false
	var limpo_pelo_chefe: bool = false
	var autor_player_id: int = 0
	var vel_empurrao: Vector2 = Vector2.ZERO
	var cambaleio: int = 0
	var portador: Portador = null
	var tipo_id: StringName = &"eco"

	func _init(p_id: int, p_pos: Vector2, p_raio: float, p_vida: float,
			p_portador: Portador = null, p_elite: bool = false, p_chefe: bool = false) -> void:
		id = p_id
		posicao = p_pos
		raio = p_raio
		vida = p_vida
		vida_max = p_vida
		portador = p_portador
		elite = p_elite
		chefe = p_chefe


## Interface da IA vista pelo Combate (ADR-0010 Key Interfaces; GDD R8.7, R9, R14, R24).
class IAParaCombate:
	extends RefCounted

	## Lista de inimigos na ordem estável de spawn/id.
	func inimigos() -> Array[InimigoCombate]:
		return []

	## Busca um inimigo por id (null se não existe).
	func obter_inimigo(id: int) -> InimigoCombate:
		for i in inimigos():
			if i.id == id:
				return i
		return null

	## Pedido de "Quebrou!" (R8.7): passa o inimigo para recuperação por [param passos].
	func pedir_recuperacao(_id: int, _passos: int) -> void:
		pass

	## Remove um morto da lista da IA na varredura (R14), preservando a ordem.
	func remover_morto(_id: int) -> void:
		pass

	## Passa o chefe [code]subjugavel[/code] para o estado Subjugado (R24).
	func subjugar(_id: int) -> void:
		pass

	## Notifica dano sofrido pelo chefe (ADR-0010 §2, ADR-0018).
	func notificar_dano_no_chefe(_id: int) -> void:
		pass


## Interface das Câmaras vista pelo Combate (R11, R13.1).
class CamarasParaCombate:
	extends RefCounted

	func em_combate() -> bool:
		return true

	func geometria() -> GeometriaDeMovimento:
		return GeometriaDeMovimento.new(Rect2(0.0, 0.0, 1920.0, 1080.0))


## Interface do Selo vista pelo Combate (ADR-0010 §2, §8).
class SeloParaCombate:
	extends RefCounted

	func receber_investida(_player_id: int, _ativa: bool) -> void:
		pass

	func creditar_acerto_tardio(_player_id: int, _alvo_id: int, _enesimo: bool, _pesado: bool) -> void:
		pass


## Interface do Status vista pelo Combate (ADR-0010 §2, §5, §8).
class StatusParaCombate:
	extends RefCounted

	func tick(_inimigo_id: int) -> void:
		pass

	func limpar_todos() -> void:
		pass

	func aplicar_status(_alvo_id: int, _status_id: StringName, _acumulos: float) -> void:
		pass


## Interface dos Telégrafos vista pelo Combate (ADR-0010 §6).
class TelegrafosParaCombate:
	extends RefCounted

	func quebrar(_inimigo_id: int) -> void:
		pass


## Interface do Vínculo (acuada do encontro de pacto; GDD R25, F13; ADR-0010 §11).
class VinculoParaCombate:
	extends RefCounted

	func acuada_atingivel() -> bool:
		return false

	func posicao_acuada() -> Vector2:
		return Vector2.ZERO

	func raio_acuada() -> float:
		return 22.5

	func vida_acuada() -> int:
		return 0

	func definir_vida_acuada(_nova_vida: int) -> void:
		pass

	func falhar_encontro() -> void:
		pass
