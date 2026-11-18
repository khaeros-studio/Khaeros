class_name PoolDeNumeros
extends RefCounted
## Pool fixo de números de dano flutuantes (`F1`, `F2`, `F5`, `R6`, `R16`).
## Avança no relógio `t_apres`, soma golpes comuns por alvo na janela de `0.30 s`,
## agrega ticks de status, nunca gera dourado para a Maldição e nunca gera número
## para `jogador_atingido` ou `maldicao_atingida`.

const FAIXA_GOLPE: StringName = &"golpe"
const FAIXA_DOURADO: StringName = &"dourado"
const FAIXA_STATUS: StringName = &"status"

class SlotNumero extends RefCounted:
	var ativo: bool = false
	var alvo_id: int = -1
	var faixa: StringName = FAIXA_GOLPE
	var valor_acumulado: int = 0
	var pos: Vector2 = Vector2.ZERO
	var idade_s: float = 0.0
	var tempo_desde_ultima_soma_s: float = 0.0
	var duracao_total_s: float = 0.65
	var escala_pop: float = 1.0
	var cor: Color = Color(0.949, 0.929, 0.894, 1.0)
	var ordem_criacao: int = 0


var _slots: Array[SlotNumero] = []
var _janela_soma_s: float = 0.30
var _modo_acessibilidade: StringName = &"ligado" # &"ligado", &"reduzido", &"desligado"
var _contador_ordem: int = 0


func _init(capacidade: int = 6, janela_soma_s: float = 0.30) -> void:
	configurar(capacidade, janela_soma_s)


func configurar(capacidade: int = 6, janela_soma_s: float = 0.30) -> void:
	var cap: int = clampi(capacidade, 4, 8)
	_janela_soma_s = clampf(janela_soma_s, 0.15, 0.45)
	_slots.resize(cap)
	for i: int in range(cap):
		_slots[i] = SlotNumero.new()
	_contador_ordem = 0


func definir_modo_acessibilidade(modo: StringName) -> void:
	if modo == &"ligado" or modo == &"reduzido" or modo == &"desligado":
		_modo_acessibilidade = modo


func modo_acessibilidade() -> StringName:
	return _modo_acessibilidade


func limpar_tudo() -> void:
	for s: SlotNumero in _slots:
		s.ativo = false
		s.valor_acumulado = 0
		s.idade_s = 0.0
		s.tempo_desde_ultima_soma_s = 0.0


func quantidade_ativa() -> int:
	var n: int = 0
	for s: SlotNumero in _slots:
		if s.ativo:
			n += 1
	return n


func slots() -> Array[SlotNumero]:
	return _slots


func avancar_apres(dt_apres: float, pausado: bool = false) -> void:
	if pausado or dt_apres <= 0.0:
		return
	for s: SlotNumero in _slots:
		if not s.ativo:
			continue
		s.idade_s += dt_apres
		s.tempo_desde_ultima_soma_s += dt_apres
		s.escala_pop = move_toward(s.escala_pop, 1.0, dt_apres * 3.0)
		if s.idade_s >= s.duracao_total_s:
			s.ativo = false


## Registra dano sobre um inimigo. Retorna o `SlotNumero` atualizado ou `null` se filtrado.
func registrar_dano(
	evento_id: StringName,
	alvo_id: int,
	valor: int,
	pos: Vector2,
	eh_critico_ou_pesado: bool = false,
	fonte_maldicao: bool = false,
	eh_status: bool = false
) -> SlotNumero:
	if valor <= 0:
		return null
	# R6 / R16: dano recebido pelo jogador ou pela Maldição nunca gera número flutuante
	if evento_id == &"jogador_atingido" or evento_id == &"maldicao_atingida":
		return null
	if _modo_acessibilidade == &"desligado":
		return null
	if _modo_acessibilidade == &"reduzido" and eh_status:
		return null

	var faixa: StringName = FAIXA_GOLPE
	if eh_status:
		faixa = FAIXA_STATUS
	elif eh_critico_ou_pesado and not fonte_maldicao:
		# R16: golpe da Maldição nunca é dourado
		faixa = FAIXA_DOURADO

	# 1. Faixa GOLPE ou STATUS soma no mesmo alvo dentro da janela_soma_s; DOURADO nunca soma
	if faixa == FAIXA_GOLPE or faixa == FAIXA_STATUS:
		var janela_efetiva: float = _janela_soma_s if faixa == FAIXA_GOLPE else minf(0.25, _janela_soma_s)
		for s: SlotNumero in _slots:
			if s.ativo and s.alvo_id == alvo_id and s.faixa == faixa and s.tempo_desde_ultima_soma_s <= janela_efetiva:
				s.valor_acumulado += valor
				s.pos = pos
				s.idade_s = 0.0
				s.tempo_desde_ultima_soma_s = 0.0
				s.escala_pop = 1.25 if faixa == FAIXA_GOLPE else 1.12
				return s

	# 2. Procura slot livre ou desaloja na ordem status -> golpe -> dourado
	var slot_alvo: SlotNumero = _obter_ou_desalojar_slot()
	_contador_ordem += 1
	slot_alvo.ativo = true
	slot_alvo.alvo_id = alvo_id
	slot_alvo.faixa = faixa
	slot_alvo.valor_acumulado = valor
	slot_alvo.pos = pos
	slot_alvo.idade_s = 0.0
	slot_alvo.tempo_desde_ultima_soma_s = 0.0
	slot_alvo.duracao_total_s = 0.75 if faixa == FAIXA_DOURADO else 0.60
	slot_alvo.escala_pop = 1.35 if faixa == FAIXA_DOURADO else 1.15
	slot_alvo.ordem_criacao = _contador_ordem
	if faixa == FAIXA_DOURADO:
		slot_alvo.cor = CatalogoDeRespostas.COR_DOURADO
	elif faixa == FAIXA_STATUS:
		slot_alvo.cor = CatalogoDeRespostas.COR_AMBAR
	else:
		slot_alvo.cor = CatalogoDeRespostas.COR_OSSO
	return slot_alvo


func _obter_ou_desalojar_slot() -> SlotNumero:
	for s: SlotNumero in _slots:
		if not s.ativo:
			return s

	# Desaloja na ordem: status (peso 0) -> golpe (peso 1) -> dourado (peso 2), mais antigo primeiro
	var escolhido: SlotNumero = _slots[0]
	var melhor_peso: int = _peso_faixa(escolhido.faixa)
	var menor_ordem: int = escolhido.ordem_criacao

	for i: int in range(1, _slots.size()):
		var cand: SlotNumero = _slots[i]
		var peso_cand: int = _peso_faixa(cand.faixa)
		if peso_cand < melhor_peso or (peso_cand == melhor_peso and cand.ordem_criacao < menor_ordem):
			escolhido = cand
			melhor_peso = peso_cand
			menor_ordem = cand.ordem_criacao
	return escolhido


static func _peso_faixa(faixa: StringName) -> int:
	if faixa == FAIXA_STATUS:
		return 0
	if faixa == FAIXA_GOLPE:
		return 1
	return 2
