class_name Telegrafos
extends RefCounted
## Módulo de lógica pura de Telégrafos: pool fixo de até 24 slots, ciclo Aviso -> Disparo -> Cancelado/Quebrado,
## mira e alvo travados, testes geométricos e publicação de vistas imutáveis (GDD telegrafos.md R1–R11; ADR-0014).

var _tuning: TelegraphTuning = null
var _consulta: ConsultaDeAlvoMaldicao = null
var _camara: GeometriaDeMovimento = null
var _eventos: EventosDoPasso = null
var _politica: TelegrafoTipos.PoliticaDeTroca = TelegrafoTipos.PoliticaDeTroca.LIBERAR_JA

var _slots: Array[TelegrafoSlot] = []
var _por_dono: Dictionary[int, int] = {}
var _disparos_do_passo: Dictionary[int, bool] = {}
var _seq_atual: int = 0
var _recusas_por_teto: int = 0


func configurar(tuning: TelegraphTuning, consulta: ConsultaDeAlvoMaldicao,
		camara: GeometriaDeMovimento = null, eventos: EventosDoPasso = null,
		politica: TelegrafoTipos.PoliticaDeTroca = TelegrafoTipos.PoliticaDeTroca.LIBERAR_JA) -> void:
	_tuning = tuning if tuning != null else TelegraphTuning.de_fabrica()
	_consulta = consulta
	_camara = camara
	_eventos = eventos
	_politica = politica
	iniciar_run()


## Aloca o pool fixo de `teto_telegrafos` slots uma única vez por run (ADR-0014 Decisão 2).
func iniciar_run() -> void:
	var teto := _tuning.teto_telegrafos if _tuning != null else 24
	teto = maxi(0, teto)
	_slots.clear()
	_por_dono.clear()
	_disparos_do_passo.clear()
	_seq_atual = 0
	_recusas_por_teto = 0
	for i in teto:
		_slots.append(TelegrafoSlot.new(i))


func definir_camara(camara: GeometriaDeMovimento) -> void:
	_camara = camara


func definir_politica(politica: TelegrafoTipos.PoliticaDeTroca) -> void:
	_politica = politica


## Inicia o telégrafo de um inimigo comum ou elite a partir de seu EnemyDef (R2, R2a).
func iniciar_telegrafo(inimigo_id: int, def: EnemyDef, alvo_id: int = 0,
		alvo_faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR) -> bool:
	if def == null:
		return false
	var r_alvo := _ler_raio_alvo(alvo_faccao, alvo_id)
	var n_avanco := _tuning.avanco_passos if _tuning != null else TelegrafoTipos.AVANCO_PASSOS_PADRAO
	var derivada := FormasDeTelegrafo.derivar(def, r_alvo, n_avanco)
	return _alocar_slot(inimigo_id, derivada, alvo_id, alvo_faccao, r_alvo)


## Inicia o telégrafo de um padrão de chefe a partir de seu BossPatternDef (R5a).
func iniciar_telegrafo_chefe(chefe_id: int, padrao: BossPatternDef, raio_chefe_px: float = 45.0,
		alvo_id: int = 0, alvo_faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR,
		v_avanco_pxs: float = 675.0) -> bool:
	if padrao == null:
		return false
	var r_alvo := _ler_raio_alvo(alvo_faccao, alvo_id)
	var derivada := FormasDeTelegrafo.derivar_padrao_chefe(padrao, raio_chefe_px, r_alvo, v_avanco_pxs)
	return _alocar_slot(chefe_id, derivada, alvo_id, alvo_faccao, r_alvo)


## Inicia um telégrafo diretamente com uma FormaDerivada já calculada.
func iniciar_com_forma(inimigo_id: int, derivada: FormasDeTelegrafo.FormaDerivada,
		alvo_id: int = 0, alvo_faccao: TelegrafoTipos.FaccaoAlvo = TelegrafoTipos.FaccaoAlvo.JOGADOR,
		raio_alvo: float = TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX) -> bool:
	return _alocar_slot(inimigo_id, derivada, alvo_id, alvo_faccao, raio_alvo)


func _alocar_slot(inimigo_id: int, derivada: FormasDeTelegrafo.FormaDerivada,
		alvo_id: int, alvo_faccao: TelegrafoTipos.FaccaoAlvo, raio_alvo: float) -> bool:
	if derivada == null or not derivada.valida or derivada.preparo_passos < 1:
		return false
	if _por_dono.has(inimigo_id):
		var idx_atual: int = _por_dono[inimigo_id]
		if idx_atual >= 0 and idx_atual < _slots.size() and _slots[idx_atual].ocupado():
			return false
	var vaga := _menor_vaga_livre()
	if vaga < 0:
		_recusas_por_teto += 1
		return false
	var slot := _slots[vaga]
	slot.liberar()
	slot.estado = TelegrafoTipos.Estado.CRESCENDO
	slot.dono_id = inimigo_id
	_seq_atual += 1
	slot.seq = _seq_atual
	slot.preparo = derivada.preparo_passos
	slot.restante = derivada.preparo_passos
	slot.passos_no_estado = 0
	slot.alvo_id = alvo_id
	slot.alvo_faccao = alvo_faccao
	slot.raio_alvo = raio_alvo
	slot.derivada = derivada
	var pos_dono := _ler_posicao_dono(inimigo_id)
	var pos_alvo := _ler_posicao_alvo(alvo_faccao, alvo_id)
	var delta := pos_alvo - pos_dono
	# ADR-0014 Decisão 6: distância 0 -> (1, 0) por teste explícito de length_squared() == 0
	if delta.length_squared() == 0.0:
		slot.mira = Vector2.RIGHT
	else:
		slot.mira = delta / delta.length()
	_por_dono[inimigo_id] = vaga
	if _eventos != null:
		_eventos.emitir(EventosDeTelegrafos.EvTelegrafoIniciado.new(
			inimigo_id, alvo_id, int(alvo_faccao), int(derivada.forma)))
	return true


## Roda uma vez no início do item 7 (passo vivo): avança estados terminais, libera quem chegou a 2 passos
## e cancela CRESCENDO cujo dono morreu (ADR-0014 Decisão 3).
func varrer() -> void:
	_disparos_do_passo.clear()
	for slot: TelegrafoSlot in _slots:
		if not slot.ocupado():
			continue
		if slot.terminal():
			slot.passos_no_estado += 1
			if slot.passos_no_estado >= TelegrafoTipos.PASSOS_TERMINAL:
				_liberar_slot(slot)
		elif slot.em_crescimento():
			if not _dono_vivo(slot.dono_id):
				_passar_a_cancelado(slot, TelegrafoTipos.CausaCancelamento.DONO_MORTO, true)


## Roda no laço do item 7 para cada inimigo vivo, depois do Status e antes do impacto e da IA (ADR-0014 Decisão 3).
func avancar(inimigo_id: int) -> void:
	if not _por_dono.has(inimigo_id):
		return
	var idx: int = _por_dono[inimigo_id]
	var slot := _slots[idx]
	if not slot.em_crescimento():
		return
	if not _dono_vivo(inimigo_id):
		_passar_a_cancelado(slot, TelegrafoTipos.CausaCancelamento.DONO_MORTO, true)
		return
	slot.restante = maxi(0, slot.restante - 1)
	if slot.restante == 0:
		slot.estado = TelegrafoTipos.Estado.DISPARO
		slot.passos_no_estado = 0
		_disparos_do_passo[inimigo_id] = true
		if _eventos != null:
			_eventos.emitir(EventosDeTelegrafos.EvTelegrafoDisparou.new(
				inimigo_id, int(slot.derivada.forma)))


func disparou_neste_passo(inimigo_id: int) -> bool:
	return _disparos_do_passo.get(inimigo_id, false)


## Testa se `ponto` está dentro da forma do telégrafo de `inimigo_id` (mesma montagem da vista, R6).
func dentro(inimigo_id: int, ponto: Vector2) -> bool:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return false
	return FormaDeTelegrafo.dentro(slot, _posicao_ancora(slot), ponto, _camara)


## Testa se `ponto` está dentro da envoltória retangular de desenho (F5, AC-TG-27).
func dentro_envoltoria(inimigo_id: int, ponto: Vector2) -> bool:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return false
	return FormaDeTelegrafo.dentro_envoltoria_retangulo(slot, _posicao_ancora(slot), ponto, _camara)


## Testa se o próprio alvo travado no início do preparo está dentro da forma neste passo (R6a).
## Se o alvo travado saiu de campo ou não é mais atingível, devolve falso (falha no vazio, AC-TG-31).
func acerta_alvo_travado(inimigo_id: int) -> bool:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return false
	if _consulta != null and not _consulta.alvo_atingivel(slot.alvo_faccao, slot.alvo_id):
		return false
	var pos_alvo := _ler_posicao_alvo(slot.alvo_faccao, slot.alvo_id)
	return FormaDeTelegrafo.dentro(slot, _posicao_ancora(slot), pos_alvo, _camara)


## Devolve `(alvo_faccao, alvo_id)` travados na criação do telégrafo (ADR-0014 Decisão 9).
func alvo_de(inimigo_id: int) -> Vector2i:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return Vector2i(int(TelegrafoTipos.FaccaoAlvo.JOGADOR), 0)
	return Vector2i(int(slot.alvo_faccao), slot.alvo_id)


func raio_alvo_de(inimigo_id: int) -> float:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX
	return slot.raio_alvo


func mira_de(inimigo_id: int) -> Vector2:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return Vector2.RIGHT
	return slot.mira


func progresso_de(inimigo_id: int) -> float:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return 0.0
	return slot.progresso()


func restante_de(inimigo_id: int) -> int:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return 0
	return slot.restante


func estado_de(inimigo_id: int) -> TelegrafoTipos.Estado:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return TelegrafoTipos.Estado.LIVRE
	return slot.estado


func forma_derivada_de(inimigo_id: int) -> FormasDeTelegrafo.FormaDerivada:
	var slot := _slot_de(inimigo_id)
	if slot == null:
		return null
	return slot.derivada


## Pedido "Quebrou!" do Combate no item 5: só age em CRESCENDO (R7, AC-TG-15).
func quebrar(inimigo_id: int) -> bool:
	var slot := _slot_de(inimigo_id)
	if slot == null or not slot.em_crescimento():
		return false
	slot.estado = TelegrafoTipos.Estado.QUEBRADO
	slot.passos_no_estado = 0
	_disparos_do_passo.erase(inimigo_id)
	return true


## Cancela o telégrafo de `inimigo_id` (dono morto, TransicaoFase ou queda do chefe; R7, R7a, AC-TG-16, AC-TG-38).
func cancelar(inimigo_id: int,
		causa: TelegrafoTipos.CausaCancelamento = TelegrafoTipos.CausaCancelamento.DONO_MORTO,
		em_passo_vivo: bool = true) -> bool:
	var slot := _slot_de(inimigo_id)
	if slot == null or not slot.em_crescimento():
		return false
	_passar_a_cancelado(slot, causa, em_passo_vivo)
	return true


## Ação 3 da troca de câmara (fora de passo vivo): aplica a política injetada sem emitir evento (ADR-0014 Decisão 7).
func cancelar_todos() -> void:
	_disparos_do_passo.clear()
	if _politica == TelegrafoTipos.PoliticaDeTroca.LIBERAR_JA:
		for slot: TelegrafoSlot in _slots:
			if slot.ocupado():
				_liberar_slot(slot)
		_por_dono.clear()
		return
	for slot: TelegrafoSlot in _slots:
		if not slot.ocupado():
			continue
		slot.ancora_copiada = _ler_posicao_dono(slot.dono_id)
		slot.usar_ancora_copiada = true
		if slot.em_crescimento():
			slot.estado = TelegrafoTipos.Estado.CANCELADO
			slot.passos_no_estado = 0


## Avança telégrafos cancelados durante a Transição quando a política é FADE_DOIS_PASSOS.
func passo_de_transicao() -> void:
	if _politica != TelegrafoTipos.PoliticaDeTroca.FADE_DOIS_PASSOS:
		return
	for slot: TelegrafoSlot in _slots:
		if slot.ocupado() and slot.terminal():
			slot.passos_no_estado += 1
			if slot.passos_no_estado >= TelegrafoTipos.PASSOS_TERMINAL:
				_liberar_slot(slot)


func ativos() -> int:
	var n := 0
	for slot: TelegrafoSlot in _slots:
		if slot.ocupado():
			n += 1
	return n


func capacidade() -> int:
	return _slots.size()


func recusas_por_teto() -> int:
	return _recusas_por_teto


## Preenche `saida` pré-alocado com as vistas dos slots ocupados sem alocar (ADR-0014 Decisão 8, AC-TG-13).
func publicar(saida: Array[VistaDeTelegrafo]) -> int:
	var n := 0
	var limite := saida.size()
	for slot: TelegrafoSlot in _slots:
		if not slot.ocupado():
			continue
		if n >= limite:
			break
		var vista := saida[n]
		if vista == null:
			continue
		FormaDeTelegrafo.preencher_vista(slot, _posicao_ancora(slot), _camara, vista)
		n += 1
	return n


func _menor_vaga_livre() -> int:
	for i in _slots.size():
		if not _slots[i].ocupado():
			return i
	return -1


func _slot_de(inimigo_id: int) -> TelegrafoSlot:
	if not _por_dono.has(inimigo_id):
		return null
	var idx: int = _por_dono[inimigo_id]
	if idx < 0 or idx >= _slots.size():
		return null
	var s := _slots[idx]
	return s if s.ocupado() and s.dono_id == inimigo_id else null


func _passar_a_cancelado(slot: TelegrafoSlot, causa: TelegrafoTipos.CausaCancelamento,
		em_passo_vivo: bool) -> void:
	slot.ancora_copiada = _ler_posicao_dono(slot.dono_id)
	slot.usar_ancora_copiada = true
	slot.estado = TelegrafoTipos.Estado.CANCELADO
	slot.passos_no_estado = 0
	_disparos_do_passo.erase(slot.dono_id)
	if em_passo_vivo and _eventos != null:
		_eventos.emitir(EventosDeTelegrafos.EvTelegrafoCancelado.new(slot.dono_id, int(causa)))


func _liberar_slot(slot: TelegrafoSlot) -> void:
	var dono := slot.dono_id
	slot.liberar()
	if _por_dono.get(dono, -1) == slot.indice:
		_por_dono.erase(dono)


func _posicao_ancora(slot: TelegrafoSlot) -> Vector2:
	if slot.usar_ancora_copiada:
		return slot.ancora_copiada
	return _ler_posicao_dono(slot.dono_id)


func _dono_vivo(inimigo_id: int) -> bool:
	if _consulta == null:
		return true
	return _consulta.dono_vivo(inimigo_id)


func _ler_posicao_dono(inimigo_id: int) -> Vector2:
	if _consulta == null:
		return Vector2.ZERO
	return _consulta.posicao_dono(inimigo_id)


func _ler_posicao_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> Vector2:
	if _consulta == null:
		return Vector2.ZERO
	return _consulta.posicao_alvo(faccao, alvo_id)


func _ler_raio_alvo(faccao: TelegrafoTipos.FaccaoAlvo, alvo_id: int) -> float:
	if _consulta == null:
		return TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX
	var r := _consulta.raio_alvo(faccao, alvo_id)
	return r if r > 0.0 else TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX
