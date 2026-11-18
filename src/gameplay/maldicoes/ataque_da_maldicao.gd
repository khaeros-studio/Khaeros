class_name AtaqueDaMaldicao
extends RefCounted
## Ciclo do ataque básico da Maldição em campo (sub-passo 8 do item 6.1) e gatilho da
## Habilidade Única Primordial (*Pulso de Soberania* a cada 3º ataque concluído;
## GDD maldicoes.md R6, R16, R24, F3, Catálogo; ADR-0017 §3, §5, §6).


static func passo(m: MaldicaoRef, ctx: ContextoDaTecnica) -> void:
	if m == null or m.def == null or ctx == null or ctx.ia == null:
		return
	if not m.em_campo() or m.estado == MaldicaoRef.Estado.SALTANDO or m.estourou_fio:
		return

	var p_passos := Unidades.duracao_para_passos(m.def.preparo_s)
	var e_passos := Unidades.duracao_para_passos(m.def.execucao_s)
	var r_passos := Unidades.duracao_para_passos(m.def.recuperacao_s)

	match m.estado:
		MaldicaoRef.Estado.SEGUINDO, MaldicaoRef.Estado.PERSEGUINDO:
			if m.alvo_id == -1 or not ctx.ia.atingivel(m.alvo_id):
				return
			var alvo_est := ctx.ia.estado_de(m.alvo_id)
			if alvo_est == null:
				return
			var delta := alvo_est.posicao - m.pos
			var d := delta.length()
			if d <= m.def.alcance_basico_px + alvo_est.raio + 1e-5:
				m.dir = Vector2.RIGHT if d == 0.0 else delta / d
				m.estado = MaldicaoRef.Estado.PREPARO
				m.timer_fase = p_passos - 1
				if m.timer_fase <= 0:
					_disparar_execucao_basica(m, ctx, e_passos)

		MaldicaoRef.Estado.PREPARO:
			m.timer_fase -= 1
			if m.timer_fase <= 0:
				_disparar_execucao_basica(m, ctx, e_passos)

		MaldicaoRef.Estado.EXECUCAO:
			m.timer_fase -= 1
			if m.timer_fase <= 0:
				m.estado = MaldicaoRef.Estado.RECUPERACAO
				m.timer_fase = r_passos

		MaldicaoRef.Estado.RECUPERACAO:
			m.timer_fase -= 1
			if m.timer_fase <= 0:
				m.ataques_concluidos += 1
				_verificar_habilidade_unica(m, ctx)
				m.estado = MaldicaoRef.Estado.PERSEGUINDO if m.alvo_id != -1 else MaldicaoRef.Estado.SEGUINDO


static func _disparar_execucao_basica(m: MaldicaoRef, ctx: ContextoDaTecnica, e_passos: int) -> void:
	m.estado = MaldicaoRef.Estado.EXECUCAO
	m.timer_fase = e_passos
	if ctx.eventos != null:
		ctx.eventos.emitir(EventosMaldicoes.EvMaldicaoGolpe.new(m.id, m.def.forma_basica))

	# Quebra-Limiar do Baluarte tem deslocamento curto de 24 px na execução (Catálogo)
	if m.especie_id == &"baluarte_de_cinza":
		m.pos = ctx.ia.conter(m.pos + m.dir * 24.0, m.raio_px())

	var alvos_ids: Array[int] = []
	for v: VistaDeInimigo in ctx.ia.atingiveis():
		if _atinge_basico(m, v):
			alvos_ids.append(v.id)

	if not alvos_ids.is_empty() and ctx.combate != null:
		# F3 / R24: dano_basico * (1 + bonus_dano_basico) com vínculo nível >= 4
		var dano_golpe := m.def.dano_basico * (1.0 + m.bonus_dano_basico_vinculo)
		var m_maldicao := m.multiplicador_dano()
		var eh_pesado := m.def.empurrao_basico >= 600.0 or m.especie_id == &"baluarte_de_cinza"
		ctx.combate.aplicar_golpe_maldicao(
			m.player_id, m.id, alvos_ids, dano_golpe, m_maldicao,
			m.dir, m.def.empurrao_basico, [], eh_pesado,
			StringName("%s_basico" % m.especie_id))


static func _atinge_basico(m: MaldicaoRef, v: VistaDeInimigo) -> bool:
	var alcance := m.def.alcance_basico_px
	if m.def.forma_basica == &"circulo":
		return GeometriaDeAcerto.circulo_toca(m.pos, alcance, v.pos, v.raio)
	var meio_graus := 60.0
	if m.especie_id == &"espreitador_da_fenda":
		meio_graus = 55.0
	elif m.especie_id == &"soberano_do_limiar":
		meio_graus = 65.0
	var cos_meio := Unidades.cosseno_do_meio_angulo(meio_graus)
	return GeometriaDeAcerto.arco_do_golpe(m.pos, m.dir, cos_meio, alcance, m.raio_px(), v.pos, v.raio)


static func _verificar_habilidade_unica(m: MaldicaoRef, ctx: ContextoDaTecnica) -> void:
	if m.def == null or m.def.habilidade_unica == &"":
		return
	var tec := CatalogoMaldicoes.tecnica_habilidade_unica(m.especie_id)
	if tec == null or tec.a_cada_n_ataques <= 0:
		return
	if (m.ataques_concluidos % tec.a_cada_n_ataques) == 0:
		ExecutorDeTecnica.executar(tec, m, ctx)
