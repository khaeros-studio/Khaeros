class_name EventosMaldicoes
extends RefCounted
## Eventos tipados emitidos pelo `ModuloDeMaldicoes` no canal `EventosDoPasso` (GDD maldicoes.md R20; ADR-0002, ADR-0017 §10).


class EvMaldicaoTrocada extends EventoDoPasso:
	const TIPO: StringName = &"troca_feita"
	var player_id: int
	var modo: StringName # &"manual" | &"automatica"
	var saiu_id: int
	var entrou_id: int

	func _init(p_player_id: int, p_modo: StringName, p_saiu_id: int, p_entrou_id: int) -> void:
		player_id = p_player_id
		modo = p_modo
		saiu_id = p_saiu_id
		entrou_id = p_entrou_id

	func tipo() -> StringName:
		return TIPO


class EvTrocaIndisponivel extends EventoDoPasso:
	const TIPO: StringName = &"troca_indisponivel"
	var player_id: int
	var motivo: StringName # &"recarga" | &"sem_reserva" | &"reserva_exausta" | &"saltando" | &"sem_campo"

	func _init(p_player_id: int, p_motivo: StringName) -> void:
		player_id = p_player_id
		motivo = p_motivo

	func tipo() -> StringName:
		return TIPO


class EvTecnicaCombinada extends EventoDoPasso:
	const TIPO: StringName = &"tecnica_combinada"
	var player_id: int
	var saida_id: StringName
	var entrada_id: StringName
	var acertos: int

	func _init(p_player_id: int, p_saida_id: StringName, p_entrada_id: StringName, p_acertos: int) -> void:
		player_id = p_player_id
		saida_id = p_saida_id
		entrada_id = p_entrada_id
		acertos = p_acertos

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoEntrou extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_entrou"
	var curse_id: int
	var origem: StringName # &"automatica" | &"retorno" | &"inicio"

	func _init(p_curse_id: int, p_origem: StringName) -> void:
		curse_id = p_curse_id
		origem = p_origem

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoPronta extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_pronta"
	var curse_id: int

	func _init(p_curse_id: int) -> void:
		curse_id = p_curse_id

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoGolpe extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_golpe"
	var curse_id: int
	var forma: StringName

	func _init(p_curse_id: int, p_forma: StringName) -> void:
		curse_id = p_curse_id
		forma = p_forma

	func tipo() -> StringName:
		return TIPO


class EvChamadoSalto extends EventoDoPasso:
	const TIPO: StringName = &"chamado_salto"
	var curse_id: int
	var origem: Vector2
	var destino: Vector2

	func _init(p_curse_id: int, p_origem: Vector2, p_destino: Vector2) -> void:
		curse_id = p_curse_id
		origem = p_origem
		destino = p_destino

	func tipo() -> StringName:
		return TIPO


class EvChamadoPouso extends EventoDoPasso:
	const TIPO: StringName = &"chamado_pouso"
	var curse_id: int
	var origem: Vector2
	var destino: Vector2

	func _init(p_curse_id: int, p_origem: Vector2, p_destino: Vector2) -> void:
		curse_id = p_curse_id
		origem = p_origem
		destino = p_destino

	func tipo() -> StringName:
		return TIPO


class EvMarcaViroteMudou extends EventoDoPasso:
	const TIPO: StringName = &"marca_virote_mudou"
	var player_id: int
	var inimigo_id: int # -1 = vazio

	func _init(p_player_id: int, p_inimigo_id: int) -> void:
		player_id = p_player_id
		inimigo_id = p_inimigo_id

	func tipo() -> StringName:
		return TIPO


class EvAtraido extends EventoDoPasso:
	const TIPO: StringName = &"atraido"
	var inimigo_id: int
	var passos: int

	func _init(p_inimigo_id: int, p_passos: int) -> void:
		inimigo_id = p_inimigo_id
		passos = p_passos

	func tipo() -> StringName:
		return TIPO


class EvAtracaoFim extends EventoDoPasso:
	const TIPO: StringName = &"atracao_fim"
	var inimigo_id: int

	func _init(p_inimigo_id: int) -> void:
		inimigo_id = p_inimigo_id

	func tipo() -> StringName:
		return TIPO


class EvImobilizado extends EventoDoPasso:
	const TIPO: StringName = &"imobilizado"
	var inimigo_id: int
	var passos: int

	func _init(p_inimigo_id: int, p_passos: int) -> void:
		inimigo_id = p_inimigo_id
		passos = p_passos

	func tipo() -> StringName:
		return TIPO


class EvImobilizacaoFim extends EventoDoPasso:
	const TIPO: StringName = &"imobilizacao_fim"
	var inimigo_id: int

	func _init(p_inimigo_id: int) -> void:
		inimigo_id = p_inimigo_id

	func tipo() -> StringName:
		return TIPO


class EvFioEstourou extends EventoDoPasso:
	const TIPO: StringName = &"fio_estourou"
	var curse_id: int

	func _init(p_curse_id: int) -> void:
		curse_id = p_curse_id

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoFerida extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_atingida"
	var curse_id: int
	var dano: int
	var vida_restante: int

	func _init(p_curse_id: int, p_dano: int, p_vida_restante: int) -> void:
		curse_id = p_curse_id
		dano = p_dano
		vida_restante = p_vida_restante

	func tipo() -> StringName:
		return TIPO


class EvMaldicaoExausta extends EventoDoPasso:
	const TIPO: StringName = &"maldicao_exausta"
	var curse_id: int

	func _init(p_curse_id: int) -> void:
		curse_id = p_curse_id

	func tipo() -> StringName:
		return TIPO
