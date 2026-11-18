class_name DegradacaoDeVfx
extends RefCounted
## Máquina de degradação graciosa de VFX sob carga medida (`F3`, `R4`, `R8`).
## Aplica histerese (`0.90/0.75` para nível 1, `0.95/0.85` para nível 2), corta
## `P4 -> P3 -> P2` (mais antigo primeiro) quando `uso >= 1.0`, nunca corta `P0` ou `P1`,
## e limita estrelas de acerto por passo (`teto_estrelas_passo = 6`).

var _entrar_nivel_1: float = 0.90
var _sair_nivel_1: float = 0.75
var _entrar_nivel_2: float = 0.95
var _sair_nivel_2: float = 0.85
var _teto_estrelas_passo: int = 6

var _nivel_atual: int = 0
var _estrelas_no_passo: int = 0
var _uso_atual: float = 0.0


func _init(tuning: FeedbackTuning = null) -> void:
	configurar(tuning if tuning != null else FeedbackTuning.new())


func configurar(tuning: FeedbackTuning) -> void:
	if tuning == null:
		return
	_entrar_nivel_1 = tuning.entrar_nivel_1
	_sair_nivel_1 = tuning.sair_nivel_1
	_entrar_nivel_2 = tuning.entrar_nivel_2
	_sair_nivel_2 = tuning.sair_nivel_2
	_teto_estrelas_passo = tuning.teto_estrelas_passo


func iniciar_passo(uso_orcamento: float) -> void:
	_uso_atual = maxf(0.0, uso_orcamento)
	_estrelas_no_passo = 0
	_atualizar_nivel(_uso_atual)


func nivel_atual() -> int:
	return _nivel_atual


func fator_particulas() -> float:
	if _nivel_atual >= 2:
		return 0.25
	if _nivel_atual == 1:
		return 0.50
	return 1.0


func aceita_vfx(prioridade: int, eh_estrela_acerto: bool = false) -> bool:
	# P0 e P1 nunca são cortados pela degradação de VFX (exceto teto de estrelas por passo)
	if eh_estrela_acerto:
		if _estrelas_no_passo >= _teto_estrelas_passo:
			return false
	if prioridade >= 4 and _nivel_atual >= 1:
		return false
	if prioridade >= 3 and _nivel_atual >= 2:
		return false
	if prioridade >= 2 and _uso_atual >= 1.0:
		return false
	if eh_estrela_acerto:
		_estrelas_no_passo += 1
	return true


## Quando `uso >= 1.0`, desaloja VFX ativos na ordem `P4 -> P3 -> P2` (mais antigo primeiro).
## Nunca remove `P0` (`0`) ou `P1` (`1`). Retorna quantidade removida.
func cortar_ativos_no_teto(ativos: Array[PedidosDeFeedback.PedidoVfx], quantidade_para_cortar: int = 1) -> int:
	if _uso_atual < 1.0 or ativos.is_empty() or quantidade_para_cortar <= 0:
		return 0
	var removidos: int = 0
	while removidos < quantidade_para_cortar:
		var idx_candidato: int = -1
		var pior_prio: int = 1 # só considera prioridade >= 2 (P2, P3, P4)
		for i: int in range(ativos.size()):
			var vfx: PedidosDeFeedback.PedidoVfx = ativos[i]
			if vfx == null or vfx.prioridade <= 1:
				continue
			if vfx.prioridade > pior_prio:
				pior_prio = vfx.prioridade
				idx_candidato = i
		if idx_candidato < 0:
			break
		ativos.remove_at(idx_candidato)
		removidos += 1
	return removidos


func _atualizar_nivel(uso: float) -> void:
	if _nivel_atual == 0:
		if uso >= _entrar_nivel_2:
			_nivel_atual = 2
		elif uso >= _entrar_nivel_1:
			_nivel_atual = 1
	elif _nivel_atual == 1:
		if uso >= _entrar_nivel_2:
			_nivel_atual = 2
		elif uso < _sair_nivel_1:
			_nivel_atual = 0
	elif _nivel_atual == 2:
		if uso < _sair_nivel_1:
			_nivel_atual = 0
		elif uso < _sair_nivel_2:
			_nivel_atual = 1
