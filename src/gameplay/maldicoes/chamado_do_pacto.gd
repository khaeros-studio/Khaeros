class_name ChamadoDoPacto
extends RefCounted
## Execução do Especial da Besta do Vínculo (*Chamado do Pacto*, sub-passos 4 e 6 do item 6.1;
## GDD maldicoes.md R13, R17, F4, F4b; ADR-0017 §4, §7).


static func iniciar_salto(m: MaldicaoRef, ctx: ContextoDaTecnica,
		ponto_mirado: Vector2, dano_golpe: float, m_chamado: float,
		geometria: GeometriaDeMovimento = null) -> void:
	if m == null or ctx == null or ctx.tuning == null:
		return
	IADeAliado.limpar_passivas_condicionais(m)
	var u := ponto_mirado - ctx.pos_jogador
	var dist_mira := u.length()
	var dir_mira := Vector2.RIGHT
	if dist_mira > 0.0:
		dir_mira = u / dist_mira
	elif ctx.mira_jogador.length_squared() > 0.0:
		dir_mira = ctx.mira_jogador.normalized()
	var alcance_max := minf(dist_mira if dist_mira > 0.0 else ctx.tuning.alcance_chamado_px, ctx.tuning.alcance_chamado_px)
	var p_alvo := ctx.pos_jogador + dir_mira * alcance_max

	# Se o caminho do salto encontrar obstáculo ou parede antes de P_alvo, corta no último ponto válido (R13.1, F4, Edge Case)
	var delta_salto := p_alvo - m.pos
	var comp_salto := delta_salto.length()
	if comp_salto > 0.0 and geometria != null:
		var dir_s := delta_salto / comp_salto
		var alc_livre := GeometriaDeAcerto.alcance_do_raio(
			m.pos, dir_s, comp_salto, geometria.jogavel.grow(-m.raio_px()), geometria.obstaculos())
		if alc_livre < comp_salto:
			p_alvo = ctx.ia.conter(m.pos + dir_s * maxf(0.0, alc_livre - m.raio_px()), m.raio_px())
		else:
			p_alvo = ctx.ia.conter(p_alvo, m.raio_px())

	var n_salto := maxi(1, Unidades.duracao_para_passos(ctx.tuning.duracao_salto_s))
	m.estado = MaldicaoRef.Estado.SALTANDO
	m.salto_origem = m.pos
	m.salto_destino = p_alvo
	m.salto_total = n_salto
	m.salto_restante = n_salto
	m.salto_passo_px = (p_alvo - m.pos) / float(n_salto)
	m.salto_dano_golpe = dano_golpe
	m.salto_m_chamado = m_chamado
	if (p_alvo - m.pos).length_squared() > 0.0:
		m.dir = (p_alvo - m.pos).normalized()
	if ctx.eventos != null:
		ctx.eventos.emitir(EventosMaldicoes.EvChamadoSalto.new(m.id, m.salto_origem, m.salto_destino))


static func avancar_salto(m: MaldicaoRef, ctx: ContextoDaTecnica) -> void:
	if m == null or m.estado != MaldicaoRef.Estado.SALTANDO:
		return
	m.salto_restante -= 1
	if m.salto_restante > 0:
		m.pos += m.salto_passo_px
		return
	# Passo de pouso (passo s + N_salto): aplica impacto, imobilização do comum mais próximo, atração e efeito próprio (R13.2–13.5, F4)
	m.pos = m.salto_destino
	if ctx.eventos != null:
		ctx.eventos.emitir(EventosMaldicoes.EvChamadoPouso.new(m.id, m.salto_origem, m.salto_destino))

	var r_chamado := ctx.tuning.raio_chamado_px if ctx.tuning != null else 135.0
	var r_atracao := ctx.tuning.raio_atracao_px if ctx.tuning != null else 210.0
	var passos_imob := Unidades.duracao_para_passos(ctx.tuning.duracao_imobilizar_s if ctx.tuning != null else 1.50)
	var passos_atr := Unidades.duracao_para_passos(ctx.tuning.duracao_atracao_s if ctx.tuning != null else 1.50)

	var atingiveis := ctx.ia.atingiveis() if ctx.ia != null else ([] as Array[VistaDeInimigo])
	var ids_dano: Array[int] = []
	var comum_mais_perto_id := -1
	var comum_melhor_d2 := INF

	for v: VistaDeInimigo in atingiveis:
		if GeometriaDeAcerto.circulo_toca(m.pos, r_chamado, v.pos, v.raio):
			ids_dano.append(v.id)
			if not v.elite and not v.chefe and not v.armadura_ativa:
				var d2 := (v.pos - m.pos).length_squared()
				if d2 < comum_melhor_d2 - 1e-6:
					comum_melhor_d2 = d2
					comum_mais_perto_id = v.id

	# R13.2 / Emenda Pactos: golpe de área com M_chamado (grupo Especial do jogador) e sem empurrão
	if not ids_dano.is_empty() and ctx.combate != null:
		ctx.combate.aplicar_golpe_maldicao(
			m.player_id, m.id, ids_dano, m.salto_dano_golpe, m.salto_m_chamado,
			m.dir, 0.0, [], false, &"chamado_do_pacto")

	# R13.3: imobiliza apenas o inimigo comum atingido mais próximo do centro (elites e chefes imunes)
	if comum_mais_perto_id != -1 and ctx.ia != null and ctx.ia.atingivel(comum_mais_perto_id):
		if ctx.ia.imobilizar(comum_mais_perto_id, passos_imob):
			if ctx.pacto != null and not ctx.pacto.ids_imobilizados.has(comum_mais_perto_id):
				ctx.pacto.ids_imobilizados.append(comum_mais_perto_id)
			if ctx.eventos != null:
				ctx.eventos.emitir(EventosMaldicoes.EvImobilizado.new(comum_mais_perto_id, passos_imob))

	# R13.4: atrai todo inimigo atingível em raio_atracao_px + r_inimigo (incluindo elites e chefes, se livres)
	if ctx.ia != null:
		for v: VistaDeInimigo in ctx.ia.atingiveis():
			if GeometriaDeAcerto.circulo_toca(m.pos, r_atracao, v.pos, v.raio):
				if ctx.ia.atrair(v.id, passos_atr, ctx.respiro_atracao_passos, m.player_id):
					if ctx.pacto != null and not ctx.pacto.ids_atraidos.has(v.id):
						ctx.pacto.ids_atraidos.append(v.id)
					if ctx.eventos != null:
						ctx.eventos.emitir(EventosMaldicoes.EvAtraido.new(v.id, passos_atr))

	# R13.5: efeito próprio da espécie no Chamado (Raro+: Eco de Muralha do Baluarte, Convergência do Soberano)
	var tec_ch := CatalogoMaldicoes.tecnica_chamado(m.especie_id)
	if tec_ch != null:
		ExecutorDeTecnica.executar(tec_ch, m, ctx)

	m.estado = MaldicaoRef.Estado.PERSEGUINDO if m.alvo_id != -1 else MaldicaoRef.Estado.SEGUINDO
