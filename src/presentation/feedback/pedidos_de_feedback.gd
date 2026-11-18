class_name PedidosDeFeedback
extends RefCounted
## Estruturas tipadas de saída do `ArbitroDeFeedback` por passo (`ADR-0011`, `R11`).

const Z_DECALQUE_CHAO: int = -8
const Z_FIO_E_MARCA: int = -5
const Z_CORPO: int = 0
const Z_ESTRELA_ACERTO: int = 3
const Z_TELEGRAFO_BORDA: int = 5
const Z_NUMERO_DANO: int = 15

class PedidoVfx extends RefCounted:
	var tipo: StringName = &""
	var alvo_id: int = -1
	var pos: Vector2 = Vector2.ZERO
	var cor: Color = Color.WHITE
	var prioridade: int = 2
	var relogio: StringName = &"vivo"
	var camada_z: int = Z_ESTRELA_ACERTO
	var duracao_s: float = 0.15
	var eh_estrela_acerto: bool = false

	func _init(
		p_tipo: StringName = &"",
		p_alvo_id: int = -1,
		p_pos: Vector2 = Vector2.ZERO,
		p_cor: Color = Color.WHITE,
		p_prio: int = 2,
		p_relogio: StringName = &"vivo",
		p_z: int = Z_ESTRELA_ACERTO,
		p_dur: float = 0.15,
		p_estrela: bool = false
	) -> void:
		tipo = p_tipo
		alvo_id = p_alvo_id
		pos = p_pos
		cor = p_cor
		prioridade = p_prio
		relogio = p_relogio
		camada_z = p_z
		duracao_s = p_dur
		eh_estrela_acerto = p_estrela


class PedidoImpacto extends RefCounted:
	var modo: int = 0
	var duracao_passos: int = 0
	var eh_chefe: bool = false
	var eh_recusa: bool = false

	func _init(p_modo: int = 0, p_dur: int = 0, p_chefe: bool = false, p_recusa: bool = false) -> void:
		modo = p_modo
		duracao_passos = p_dur
		eh_chefe = p_chefe
		eh_recusa = p_recusa


class PedidoPasse extends RefCounted:
	var tipo: StringName = &""
	var forca: float = 1.0
	var duracao_s: float = 0.35
	var obrigatorio: bool = false

	func _init(p_tipo: StringName = &"", p_forca: float = 1.0, p_dur: float = 0.35, p_obrig: bool = false) -> void:
		tipo = p_tipo
		forca = p_forca
		duracao_s = p_dur
		obrigatorio = p_obrig


class PedidoFlashTelegrafo extends RefCounted:
	var slot: int = 0
	var area_norm: float = 0.10
	var flash_permitido: bool = true

	func _init(p_slot: int = 0, p_area: float = 0.10, p_permitido: bool = true) -> void:
		slot = p_slot
		area_norm = p_area
		flash_permitido = p_permitido


class SaidaDoArbitro extends RefCounted:
	var pedidos_vfx: Array[PedidoVfx] = []
	var pedidos_som: Array[PedidoDeSom] = []
	var pedido_impulso: PedidoImpulso = null
	var pedido_impacto: PedidoImpacto = null
	var pedidos_passe: Array[PedidoPasse] = []
	var flashes_telegrafo: Array[PedidoFlashTelegrafo] = []

	func limpar() -> void:
		pedidos_vfx.clear()
		pedidos_som.clear()
		pedido_impulso = null
		pedido_impacto = null
		pedidos_passe.clear()
		flashes_telegrafo.clear()
