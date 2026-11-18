class_name IADeAliado
extends RefCounted
## IA de aliado (sub-passo 7 do item 6.1): geometria do fio com histerese (F1), seleção de alvo
## por prioridade (marca do Virote > mais perto do jogador no fio > seguir), passivas condicionais (R22)
## e movimento com contenção na câmara (GDD maldicoes.md R4, R5, R22, F1; ADR-0017 §4).

const FONTE_FARO_DO_VINCULO: StringName = &"especie:espreitador_da_fenda:faro"
const BONUS_VELOCIDADE_FARO: float = 0.15


static func passo(m: MaldicaoRef, ctx: ContextoDaTecnica) -> void:
	if m == null or ctx == null or ctx.tuning == null or ctx.ia == null:
		return
	if m.estado == MaldicaoRef.Estado.SALTANDO or not m.em_campo():
		return

	# Limpa marca_virote se o inimigo marcado deixou de ser atingível (R4, R20)
	if ctx.pacto != null and ctx.pacto.marca_virote != -1:
		if not ctx.ia.atingivel(ctx.pacto.marca_virote):
			ctx.pacto.marca_virote = -1
			if ctx.eventos != null:
				ctx.eventos.emitir(EventosMaldicoes.EvMarcaViroteMudou.new(m.player_id, -1))

	# 1. Fio de vínculo com histerese (F1):
	# estourou_fio = (d_jog > alcance_fio_px) OR (estourou_fio_ant AND d_jog > distancia_seguir_px)
	var delta_jog := ctx.pos_jogador - m.pos
	var d_jog := delta_jog.length()
	var estava_estourado := m.estourou_fio
	m.estourou_fio = (d_jog > ctx.tuning.alcance_fio_px + 1e-5) \
		or (estava_estourado and d_jog > ctx.tuning.distancia_seguir_px + 1e-5)
	if m.estourou_fio and not estava_estourado and ctx.eventos != null:
		ctx.eventos.emitir(EventosMaldicoes.EvFioEstourou.new(m.id))

	if m.estourou_fio:
		m.alvo_id = -1
		if m.estado == MaldicaoRef.Estado.PERSEGUINDO:
			m.estado = MaldicaoRef.Estado.SEGUINDO
	else:
		m.alvo_id = escolher_alvo_id(m, ctx)
		if m.estado == MaldicaoRef.Estado.SEGUINDO and m.alvo_id != -1:
			m.estado = MaldicaoRef.Estado.PERSEGUINDO
		elif m.estado == MaldicaoRef.Estado.PERSEGUINDO and m.alvo_id == -1:
			m.estado = MaldicaoRef.Estado.SEGUINDO

	# 2. Passiva condicional Faro do Vínculo (R22, AC-ML-31):
	# aplica `velocidade +15%` no passo em que o alvo é a `marca_virote` e o estado é Perseguindo
	atualizar_passivas_condicionais(m, ctx)

	# 3. Movimento (só em SEGUINDO ou PERSEGUINDO; durante o ciclo de ataque básico não caminha)
	if m.estado == MaldicaoRef.Estado.SEGUINDO:
		_mover_seguindo_jogador(m, ctx, delta_jog, d_jog)
	elif m.estado == MaldicaoRef.Estado.PERSEGUINDO:
		_mover_perseguindo_alvo(m, ctx)


static func escolher_alvo_id(_m: MaldicaoRef, ctx: ContextoDaTecnica) -> int:
	if ctx == null or ctx.ia == null or ctx.tuning == null:
		return -1
	var alcance_fio := ctx.tuning.alcance_fio_px
	var alcance2 := alcance_fio * alcance_fio + 1e-4
	# 1º Prioridade: marca_virote se ainda atingível e dentro de alcance_fio_px do jogador
	if ctx.pacto != null and ctx.pacto.marca_virote != -1:
		var id_marca := ctx.pacto.marca_virote
		if ctx.ia.atingivel(id_marca):
			var e_m := ctx.ia.estado_de(id_marca)
			if e_m != null and (e_m.posicao - ctx.pos_jogador).length_squared() <= alcance2:
				return id_marca
	# 2º Prioridade: inimigo atingível mais perto do jogador dentro do fio (empate pelo menor id)
	return ctx.ia.mais_perto(ctx.pos_jogador, alcance_fio)


static func atualizar_passivas_condicionais(m: MaldicaoRef, ctx: ContextoDaTecnica) -> void:
	if m == null or m.portador == null or m.def == null:
		return
	if not m.def.passivas.has(&"faro_do_vinculo"):
		return
	var marca := ctx.pacto.marca_virote if ctx != null and ctx.pacto != null else -1
	var ativo := m.em_campo() and m.estado == MaldicaoRef.Estado.PERSEGUINDO \
		and m.alvo_id != -1 and m.alvo_id == marca
	if ativo:
		if not m.portador.tem_fonte(FONTE_FARO_DO_VINCULO):
			m.portador.aplicar_fonte(FonteDeModificador.new(FONTE_FARO_DO_VINCULO, [
				Modificador.new(Atributos.VELOCIDADE, Modificador.Operacao.PERCENTUAL, BONUS_VELOCIDADE_FARO),
			]))
	else:
		if m.portador.tem_fonte(FONTE_FARO_DO_VINCULO):
			m.portador.remover_fonte(FONTE_FARO_DO_VINCULO)


static func limpar_passivas_condicionais(m: MaldicaoRef) -> void:
	if m != null and m.portador != null and m.portador.tem_fonte(FONTE_FARO_DO_VINCULO):
		m.portador.remover_fonte(FONTE_FARO_DO_VINCULO)


static func _mover_seguindo_jogador(m: MaldicaoRef, ctx: ContextoDaTecnica,
		delta_jog: Vector2, d_jog: float) -> void:
	var dist_seguir := ctx.tuning.distancia_seguir_px
	if d_jog <= dist_seguir + 1e-5:
		return
	var dir_ret := Vector2.RIGHT if d_jog == 0.0 else delta_jog / d_jog
	m.dir = dir_ret
	var v_passo := m.velocidade_pxs() / float(Unidades.TICK_RATE)
	var passo_px := minf(maxf(0.0, d_jog - dist_seguir), v_passo)
	m.pos = ctx.ia.conter(m.pos + dir_ret * passo_px, m.raio_px())
	# Ao retornar para dentro de distancia_seguir_px após estourar o fio, libera a histerese no mesmo passo (AC-ML-06)
	if (ctx.pos_jogador - m.pos).length() <= dist_seguir + 1e-5:
		m.estourou_fio = false


static func _mover_perseguindo_alvo(m: MaldicaoRef, ctx: ContextoDaTecnica) -> void:
	var e_alvo := ctx.ia.estado_de(m.alvo_id)
	if e_alvo == null or not ctx.ia.atingivel(m.alvo_id):
		m.alvo_id = -1
		m.estado = MaldicaoRef.Estado.SEGUINDO
		return
	var delta := e_alvo.posicao - m.pos
	var d := delta.length()
	if d > 0.0:
		m.dir = delta / d
	var alcance_atk := (m.def.alcance_basico_px if m.def != null else 105.0) + e_alvo.raio
	if d > alcance_atk:
		var v_passo := m.velocidade_pxs() / float(Unidades.TICK_RATE)
		var passo_px := minf(v_passo, d - alcance_atk)
		m.pos = ctx.ia.conter(m.pos + m.dir * passo_px, m.raio_px())
