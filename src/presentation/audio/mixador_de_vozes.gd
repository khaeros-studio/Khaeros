class_name MixadorDeVozes
extends RefCounted
## Mixador puro de vozes de efeitos sonoros (`F4` / `R9`, ADR-0016 §2).
## Gerencia até `vozes_max_total` (16) slots e teto de `vozes_max_gancho` (4) por gancho.
## Prioridades: `P0 (0) > P1 (1) > P2 (2) > P3 (3) > P4 (4)`. Vozes `P0` nunca são roubadas.

var _vozes_max_gancho: int = 4
var _vozes_max_total: int = 16

var _ocupado: PackedByteArray = PackedByteArray()
var _gancho_slot: Array[StringName] = []
var _prioridade_slot: PackedInt32Array = PackedInt32Array()
var _ordem_slot: PackedInt64Array = PackedInt64Array()
var _contador_ordem: int = 0
var _vozes_p0_descartadas: int = 0


func _init(vozes_max_gancho: int = 4, vozes_max_total: int = 16) -> void:
	configurar(vozes_max_gancho, vozes_max_total)


func configurar(vozes_max_gancho: int = 4, vozes_max_total: int = 16) -> void:
	_vozes_max_gancho = maxi(1, vozes_max_gancho)
	_vozes_max_total = maxi(1, vozes_max_total)
	_ocupado.resize(_vozes_max_total)
	_gancho_slot.resize(_vozes_max_total)
	_prioridade_slot.resize(_vozes_max_total)
	_ordem_slot.resize(_vozes_max_total)
	zerar()


func zerar() -> void:
	for i: int in range(_vozes_max_total):
		_ocupado[i] = 0
		_gancho_slot[i] = &""
		_prioridade_slot[i] = 4
		_ordem_slot[i] = 0
	_contador_ordem = 0


func liberar(slot: int) -> void:
	if slot < 0 or slot >= _vozes_max_total:
		return
	_ocupado[slot] = 0
	_gancho_slot[slot] = &""
	_prioridade_slot[slot] = 4
	_ordem_slot[slot] = 0


func slot_ocupado(slot: int) -> bool:
	if slot < 0 or slot >= _vozes_max_total:
		return false
	return _ocupado[slot] != 0


func gancho_no_slot(slot: int) -> StringName:
	if slot < 0 or slot >= _vozes_max_total:
		return &""
	return _gancho_slot[slot]


func prioridade_no_slot(slot: int) -> int:
	if slot < 0 or slot >= _vozes_max_total:
		return 4
	return _prioridade_slot[slot]


func vozes_ativas() -> int:
	var cont: int = 0
	for i: int in range(_vozes_max_total):
		if _ocupado[i] != 0:
			cont += 1
	return cont


func vozes_ativas_do_gancho(gancho: StringName) -> int:
	var cont: int = 0
	for i: int in range(_vozes_max_total):
		if _ocupado[i] != 0 and _gancho_slot[i] == gancho:
			cont += 1
	return cont


func vozes_p0_descartadas() -> int:
	return _vozes_p0_descartadas


func resolver(pedidos: Array[PedidoDeSom], saida: Array[ComandoDeVoz]) -> int:
	saida.clear()
	if pedidos.is_empty():
		return 0

	# Deduplica ganchos idênticos no mesmo passo preservando a maior prioridade (menor número)
	var unicos: Array[PedidoDeSom] = []
	for p: PedidoDeSom in pedidos:
		if p == null or p.gancho == &"":
			continue
		var achou: bool = false
		for u: PedidoDeSom in unicos:
			if u.gancho == p.gancho:
				if p.prioridade < u.prioridade:
					u.prioridade = p.prioridade
				achou = true
				break
		if not achou:
			unicos.append(PedidoDeSom.new(p.gancho, p.prioridade, p.player_id))

	# Ordena os pedidos do passo por prioridade (P0 -> P4) mantendo ordem de chegada nos empates
	var n: int = unicos.size()
	for i: int in range(1, n):
		var chave: PedidoDeSom = unicos[i]
		var j: int = i - 1
		while j >= 0 and unicos[j].prioridade > chave.prioridade:
			unicos[j + 1] = unicos[j]
			j -= 1
		unicos[j + 1] = chave

	for pedido: PedidoDeSom in unicos:
		var cmd: ComandoDeVoz = _alocar_para_pedido(pedido)
		if cmd != null:
			saida.append(cmd)

	return saida.size()


func _alocar_para_pedido(pedido: PedidoDeSom) -> ComandoDeVoz:
	var prio: int = clampi(pedido.prioridade, 0, 4)

	# 1. Verifica teto por gancho (vozes_max_gancho = 4)
	var cont_gancho: int = 0
	var slot_mais_antigo_gancho: int = -1
	var menor_ordem_gancho: int = 9223372036854775807
	for i: int in range(_vozes_max_total):
		if _ocupado[i] != 0 and _gancho_slot[i] == pedido.gancho:
			cont_gancho += 1
			if _ordem_slot[i] < menor_ordem_gancho:
				menor_ordem_gancho = _ordem_slot[i]
				slot_mais_antigo_gancho = i

	if cont_gancho >= _vozes_max_gancho and slot_mais_antigo_gancho >= 0:
		# Mesmo gancho atingiu o teto: rouba a mais antiga desse gancho (exceto se for P0 e o novo > P0)
		if _prioridade_slot[slot_mais_antigo_gancho] == 0 and prio > 0:
			return null
		_ocupar_slot(slot_mais_antigo_gancho, pedido.gancho, prio)
		return ComandoDeVoz.new(slot_mais_antigo_gancho, pedido.gancho, true, prio)

	# 2. Procura slot livre no pool total
	for i: int in range(_vozes_max_total):
		if _ocupado[i] == 0:
			_ocupar_slot(i, pedido.gancho, prio)
			return ComandoDeVoz.new(i, pedido.gancho, false, prio)

	# 3. Pool cheio: rouba a voz mais antiga da menor prioridade (maior número > 0 e >= prio)
	var melhor_slot: int = -1
	var pior_prio: int = -1
	var menor_ordem: int = 9223372036854775807

	for i: int in range(_vozes_max_total):
		var prio_slot: int = _prioridade_slot[i]
		# P0 nunca é roubada
		if prio_slot == 0:
			continue
		# Um pedido só pode roubar voz de prioridade igual ou inferior (número >= prio)
		if prio_slot < prio:
			continue
		if prio_slot > pior_prio or (prio_slot == pior_prio and _ordem_slot[i] < menor_ordem):
			pior_prio = prio_slot
			menor_ordem = _ordem_slot[i]
			melhor_slot = i

	if melhor_slot < 0:
		if prio == 0:
			_vozes_p0_descartadas += 1
		return null

	_ocupar_slot(melhor_slot, pedido.gancho, prio)
	return ComandoDeVoz.new(melhor_slot, pedido.gancho, true, prio)


func _ocupar_slot(slot: int, gancho: StringName, prio: int) -> void:
	_contador_ordem += 1
	_ocupado[slot] = 1
	_gancho_slot[slot] = gancho
	_prioridade_slot[slot] = prio
	_ordem_slot[slot] = _contador_ordem
