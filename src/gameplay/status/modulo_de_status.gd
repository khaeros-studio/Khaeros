class_name ModuloDeStatus
extends RefCounted
## Sistema de Efeitos de Status (`design/gdd/efeitos-de-status.md` R1–R10, F1–F5;
## ADR-0001 item 7, ADR-0002, ADR-0009, ADR-0010, ADR-0017).
##
## Gere os três status do MVP (`sangramento`, `queimadura`, `abalo`) apenas em inimigos
## (comuns, elites e o chefe). Nunca aplica status no jogador nem na Maldição aliada (R10).
## Dano periódico no item 7 é silencioso: reduz a vida sem hitstop, empurrão, invulnerabilidade,
## ganho de Fluxo nem gatilhos de acerto (R4).

const ID_SANGRAMENTO: StringName = &"sangramento"
const ID_QUEIMADURA: StringName = &"queimadura"
const ID_ABALO: StringName = &"abalo"

const FONTE_ABALO: StringName = &"status:abalo"

## Duração especial de *Eco de Muralha* (`baluarte_3`): `1,5 s` (`90` passos, R3).
const DURACAO_ECO_DE_MURALHA_S: float = 1.5
## Duração especial de `selo_abala` (*Selo de Cinza*): `0,5 s` (`30` passos, Selo R5 / Status R3).
const DURACAO_SELO_ABALA_S: float = 0.5

var _tuning: StatusTuning
var _relator: RelatorDeErros
var _estados: Dictionary[int, EstadoDeStatus] = {}
var _portadores: Dictionary[int, Portador] = {}
var _alvejaveis: Dictionary[int, bool] = {}
var _faccoes: Dictionary[int, StringName] = {}

## Callback `func(inimigo_id: int, dano_passo: float) -> bool`: aplica dano silencioso e
## devolve `true` se o inimigo morreu neste sub-passo (ou já estava morto).
var _aplicar_dano_silencioso: Callable
## Callback `func(inimigo_id: int) -> bool`: consulta se o inimigo está vivo e alvejável.
var _eh_vivo_e_alvejavel: Callable

var _eventos_do_passo: Array[EventoDoPasso] = []


func _init(p_tuning: StatusTuning = null, p_relator: RelatorDeErros = null) -> void:
	_tuning = p_tuning if p_tuning != null else ValidadorStatus.fabrica()
	_relator = p_relator


func tuning() -> StatusTuning:
	return _tuning


func configurar_callbacks(p_aplicar_dano_silencioso: Callable, p_eh_vivo_e_alvejavel: Callable = Callable()) -> void:
	_aplicar_dano_silencioso = p_aplicar_dano_silencioso
	_eh_vivo_e_alvejavel = p_eh_vivo_e_alvejavel


## Regista um combatente (inimigo, jogador ou maldição) para validação de facção, alvejabilidade
## e ligação opcional ao seu `Portador` (para `status:abalo` em `ADR-0009`).
func registrar_combatente(id_combatente: int, faccao: StringName = &"inimigo",
		portador: Portador = null, alvejavel: bool = true) -> void:
	_faccoes[id_combatente] = faccao
	_alvejaveis[id_combatente] = alvejavel
	if portador != null:
		_portadores[id_combatente] = portador


func definir_alvejavel(id_combatente: int, alvejavel: bool) -> void:
	_alvejaveis[id_combatente] = alvejavel


func definir_portador(id_combatente: int, portador: Portador) -> void:
	if portador == null:
		_portadores.erase(id_combatente)
	else:
		_portadores[id_combatente] = portador


func drenar_eventos() -> Array[EventoDoPasso]:
	var out: Array[EventoDoPasso] = _eventos_do_passo.duplicate()
	_eventos_do_passo.clear()
	return out


## Aplica `n` acúmulos do status `id` no alvo `alvo_id` (`R2`, `F1`).
## Se `duracao_custom_s > 0`, usa `passos(duracao_custom_s)` em vez da duração padrão do `StatusTuning`.
func aplicar_status(alvo_id: int, id: StringName, n: float, duracao_custom_s: float = -1.0) -> bool:
	if id != ID_SANGRAMENTO and id != ID_QUEIMADURA and id != ID_ABALO:
		if _relator != null:
			_relator.relatar(RelatorDeErros.Entrada.new(&"status", id,
					"status desconhecido ignorado: %s" % String(id)))
		return false

	if n <= 0.0:
		return false

	if not _pode_receber_status(alvo_id):
		return false

	var est: EstadoDeStatus = _obter_ou_criar(alvo_id)

	match id:
		ID_SANGRAMENTO:
			var d_s: float = duracao_custom_s if duracao_custom_s > 0.0 else _tuning.duracao_sangramento_s
			var d_passos: int = Unidades.duracao_para_passos(d_s)
			if d_passos < 1:
				return false
			var base_ac: float = est.sangramento_acumulos if est.sangramento_restante > 0 else 0.0
			var novo_ac: float = base_ac + n
			if _tuning.max_acumulos_sangramento > 0:
				novo_ac = minf(novo_ac, float(_tuning.max_acumulos_sangramento))
			est.sangramento_acumulos = novo_ac
			est.sangramento_restante = d_passos
			return true

		ID_QUEIMADURA:
			var d_q: float = duracao_custom_s if duracao_custom_s > 0.0 else _tuning.duracao_queimadura_s
			var d_passos_q: int = Unidades.duracao_para_passos(d_q)
			if d_passos_q < 1:
				return false
			var base_q: float = est.queimadura_acumulos if est.queimadura_restante > 0 else 0.0
			var novo_q: float = base_q + n
			if _tuning.max_acumulos_queimadura > 0:
				novo_q = minf(novo_q, float(_tuning.max_acumulos_queimadura))
			est.queimadura_acumulos = novo_q
			est.queimadura_restante = d_passos_q
			return true

		ID_ABALO:
			var d_a: float = duracao_custom_s if duracao_custom_s > 0.0 else _tuning.duracao_abalo_s
			var d_passos_a: int = Unidades.duracao_para_passos(d_a)
			if d_passos_a < 1:
				return false
			var estava_abalado: bool = est.abalo_restante > 0
			est.abalo_restante = maxi(est.abalo_restante, d_passos_a)
			if not estava_abalado and est.abalo_restante > 0:
				_sincronizar_fonte_abalo(alvo_id, true)
			return true

	return false


## Atalho para aplicar o Abalo curto de *Eco de Muralha* (`baluarte_3`: `1,5 s` = `90` passos, R3).
func aplicar_eco_de_muralha(inimigo_atacante_id: int) -> bool:
	return aplicar_status(inimigo_atacante_id, ID_ABALO, 1.0, DURACAO_ECO_DE_MURALHA_S)


## Atalho para aplicar o Abalo de pulso de *Selo de Cinza* (`selo_abala`: `0,5 s` = `30` passos, R3).
func aplicar_abalo_do_selo(inimigo_id: int) -> bool:
	return aplicar_status(inimigo_id, ID_ABALO, 1.0, DURACAO_SELO_ABALA_S)


## Aplica os gatilhos de status de um golpe (`R3`, `R3a`, `AC-ST-27..30`):
## - Se `origem == &"arma"`, lê `portador_jogador.gatilhos(...)` (`acerto_ataque`, `acerto_especial`,
##   `acerto_qualquer`) e aplica o total somado (`F1`).
## - Se `origem == &"maldicao"`, NÃO lê os gatilhos do jogador (`R3a` — golpe da Maldição não é
##   golpe da arma); aplica apenas o status nativo da Maldição (`status_maldicao_id`, `acumulos_maldicao`).
func aplicar_fontes_no_acerto(alvo_id: int, origem: StringName, slot_golpe: StringName = &"ataque",
		portador_jogador: Portador = null, status_maldicao_id: StringName = &"",
		acumulos_maldicao: int = 0) -> void:
	if origem == &"maldicao":
		if status_maldicao_id != &"" and acumulos_maldicao > 0:
			aplicar_status(alvo_id, status_maldicao_id, float(acumulos_maldicao))
		return

	if origem != &"arma" or portador_jogador == null:
		return

	var tipos_gatilho: Array[StringName] = [&"acerto_qualquer"]
	if slot_golpe == &"ataque":
		tipos_gatilho.insert(0, &"acerto_ataque")
	elif slot_golpe == &"especial":
		tipos_gatilho.insert(0, &"acerto_especial")

	var totais_por_status: Dictionary[StringName, float] = {}
	for tg: StringName in tipos_gatilho:
		var resumo: ResumoDeGatilho = portador_jogador.gatilhos(tg)
		if resumo == null or not resumo.ativo():
			continue
		for entrada: ResumoDeGatilho.Entrada in resumo.entradas:
			var st_id: StringName = StringName(entrada.params.get("status", entrada.params.get(&"status", &"")))
			if st_id == &"":
				continue
			totais_por_status[st_id] = totais_por_status.get(st_id, 0.0) + entrada.valor

	for st_id: StringName in [ID_SANGRAMENTO, ID_QUEIMADURA, ID_ABALO]:
		if totais_por_status.has(st_id):
			aplicar_status(alvo_id, st_id, totais_por_status[st_id])


## Item 7 da ordem do passo (`R4`, `F2`, `F5`): avança `sangramento`, `queimadura` e `abalo`
## em um único inimigo. Se morrer no sub-passo de Sangramento, não aplica Queimadura e limpa
## tudo sem emitir número final (`R7`).
func tick(inimigo_id: int) -> void:
	if not _estados.has(inimigo_id):
		return
	var est: EstadoDeStatus = _estados[inimigo_id]
	if not est.tem_qualquer_ativo():
		return

	var tinha_dot_no_inicio: bool = est.tem_dot_ativo()
	var dano_deste_passo: float = 0.0

	# 1. Sangramento primeiro (R4)
	if est.sangramento_restante > 0 and est.sangramento_acumulos > 0.0:
		var dp_s: float = (est.sangramento_acumulos * _tuning.dano_sangramento_s) / float(Unidades.PASSOS_POR_SEGUNDO)
		if dp_s > 0.0:
			var morreu_s: bool = _causar_dano_silencioso(inimigo_id, dp_s)
			if morreu_s:
				limpar_inimigo(inimigo_id)
				return
			dano_deste_passo += dp_s

	# 2. Queimadura em seguida, se continuar vivo (R4)
	if est.queimadura_restante > 0 and est.queimadura_acumulos > 0.0:
		var dp_q: float = (est.queimadura_acumulos * _tuning.dano_queimadura_s) / float(Unidades.PASSOS_POR_SEGUNDO)
		if dp_q > 0.0:
			var morreu_q: bool = _causar_dano_silencioso(inimigo_id, dp_q)
			if morreu_q:
				limpar_inimigo(inimigo_id)
				return
			dano_deste_passo += dp_q

	# 3. Desconta 1 passo de cada status ativo e expira os que chegaram a 0 (R4, R5)
	if est.sangramento_restante > 0:
		est.sangramento_restante -= 1
		if est.sangramento_restante <= 0:
			est.sangramento_restante = 0
			est.sangramento_acumulos = 0.0

	if est.queimadura_restante > 0:
		est.queimadura_restante -= 1
		if est.queimadura_restante <= 0:
			est.queimadura_restante = 0
			est.queimadura_acumulos = 0.0

	if est.abalo_restante > 0:
		est.abalo_restante -= 1
		if est.abalo_restante <= 0:
			est.abalo_restante = 0
			_sincronizar_fonte_abalo(inimigo_id, false)

	# 4. Número agregado por janela de intervalo_numero_s (R6, F5)
	if tinha_dot_no_inicio:
		est.dano_acumulado_janela += dano_deste_passo
		est.passos_janela += 1
		var int_passos: int = maxi(1, Unidades.duracao_para_passos(_tuning.intervalo_numero_s))
		if est.passos_janela >= int_passos:
			var n_exibido: int = FormulasDeModificadores.arredondar_meio_longe_do_zero(est.dano_acumulado_janela)
			if n_exibido >= 1:
				_eventos_do_passo.append(EvNumeroDeStatus.new(inimigo_id, n_exibido))
				est.dano_acumulado_janela -= float(n_exibido)
			est.passos_janela = 0

		# Se ambos os DoTs expiraram neste passo, faz a descarga final do resto (F5)
		if not est.tem_dot_ativo():
			var n_final: int = FormulasDeModificadores.arredondar_meio_longe_do_zero(est.dano_acumulado_janela)
			if n_final >= 1:
				_eventos_do_passo.append(EvNumeroDeStatus.new(inimigo_id, n_final))
			est.dano_acumulado_janela = 0.0
			est.passos_janela = 0


## Avança o item 7 para uma lista de inimigos na ordem de `id` crescente (`ADR-0001`).
func tick_todos(ids_ordenados: Array[int] = []) -> void:
	var lista: Array[int] = ids_ordenados.duplicate()
	if lista.is_empty():
		for k: int in _estados.keys():
			lista.append(k)
		lista.sort()
	for id_inimigo: int in lista:
		tick(id_inimigo)


## Passo congelado (hitstop, pausa ou oferta de bênção, `R7`): não avança durações nem emite dano.
func passo_congelado() -> void:
	pass


## Consulta se o inimigo está abalado (`R5`, `F4`).
func abalado(inimigo_id: int) -> bool:
	if not _estados.has(inimigo_id):
		return false
	return _estados[inimigo_id].abalo_restante > 0


## Fator multiplicador do dano causado pelo inimigo (`1 - reducao_dano_causado` = `0,70` se abalado, `1,0` caso contrário).
func multiplicador_dano_inimigo(inimigo_id: int) -> float:
	if _portadores.has(inimigo_id):
		var p: Portador = _portadores[inimigo_id]
		return p.multiplicador_de_dano(Modificador.Slot.ATAQUE, ContextoDeDano.new())
	if abalado(inimigo_id):
		return 1.0 - _tuning.reducao_dano_causado
	return 1.0


## Dano final causado pelo inimigo (`F4`: `max(1, round(dano_base * (1 - reducao_dano_causado)))` quando `dano_base > 0`).
func calcular_dano_causado_pelo_inimigo(inimigo_id: int, dano_base: int) -> int:
	if dano_base <= 0:
		return 0
	var fator: float = multiplicador_dano_inimigo(inimigo_id)
	if is_equal_approx(fator, 1.0):
		return dano_base
	var d: int = FormulasDeModificadores.arredondar_meio_longe_do_zero(float(dano_base) * fator)
	return maxi(1, d)


## Consulta pura do estado dos três status no inimigo (`R8`, `TR-status-010`).
func estado(inimigo_id: int) -> Dictionary:
	if not _estados.has(inimigo_id):
		return {
			&"sangramento": {&"acumulos": 0.0, &"restante": 0},
			&"queimadura": {&"acumulos": 0.0, &"restante": 0},
			&"abalo": {&"ativo": false, &"restante": 0},
		}
	return _estados[inimigo_id].para_dicionario()


## Quantidade de inimigos atualmente com pelo menos 1 sinal de status ativo (para regra `> 9` da HUD).
func contar_inimigos_marcados() -> int:
	var n: int = 0
	for est: EstadoDeStatus in _estados.values():
		if est.tem_qualquer_ativo():
			n += 1
	return n


## Sinais visuais prontos para a HUD/VFX (`VistaDeStatus.sinais_visuais`).
func sinais_visuais(inimigo_id: int) -> Array[Dictionary]:
	return VistaDeStatus.sinais_visuais(estado(inimigo_id), contar_inimigos_marcados())


## Limpa imediatamente todos os status de um inimigo (morte, fim de encontro, `R7`).
func limpar_inimigo(inimigo_id: int) -> void:
	if _estados.has(inimigo_id):
		var est: EstadoDeStatus = _estados[inimigo_id]
		if est.abalo_restante > 0:
			_sincronizar_fonte_abalo(inimigo_id, false)
		est.limpar()
		_estados.erase(inimigo_id)
	else:
		_sincronizar_fonte_abalo(inimigo_id, false)


## Limpa todos os inimigos (troca de câmara, fim de run, `R7`).
func limpar_todos() -> void:
	for id_inimigo: int in _estados.keys():
		_sincronizar_fonte_abalo(id_inimigo, false)
	_estados.clear()
	_eventos_do_passo.clear()


func _obter_ou_criar(inimigo_id: int) -> EstadoDeStatus:
	if not _estados.has(inimigo_id):
		_estados[inimigo_id] = EstadoDeStatus.new()
	return _estados[inimigo_id]


func _pode_receber_status(alvo_id: int) -> bool:
	if alvo_id <= 0:
		return false
	var faccao: StringName = _faccoes.get(alvo_id, &"inimigo")
	if faccao != &"inimigo":
		return false
	if _alvejaveis.has(alvo_id) and not _alvejaveis[alvo_id]:
		return false
	if _eh_vivo_e_alvejavel.is_valid():
		return bool(_eh_vivo_e_alvejavel.call(alvo_id))
	return true


func _causar_dano_silencioso(inimigo_id: int, dano_passo: float) -> bool:
	if _aplicar_dano_silencioso.is_valid():
		return bool(_aplicar_dano_silencioso.call(inimigo_id, dano_passo))
	return false


func _sincronizar_fonte_abalo(inimigo_id: int, ativo: bool) -> void:
	if not _portadores.has(inimigo_id):
		return
	var p: Portador = _portadores[inimigo_id]
	if p == null:
		return
	if ativo:
		var mult: float = 1.0 - _tuning.reducao_dano_causado
		var mod := Modificador.new(Atributos.DANO_TODO, Modificador.Operacao.MULTIPLICADOR, mult)
		var fonte := FonteDeModificador.new(FONTE_ABALO, [mod], [], FonteDeModificador.PERMANENTE)
		p.aplicar_fonte(fonte)
	else:
		p.remover_fonte(FONTE_ABALO)
