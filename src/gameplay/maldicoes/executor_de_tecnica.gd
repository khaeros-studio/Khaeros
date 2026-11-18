class_name ExecutorDeTecnica
extends RefCounted
## Intérprete genérico de `TecnicaDef`: executa qualquer Efeito de Saída, Efeito de Entrada,
## Efeito no Chamado ou Habilidade Única Primordial sem código específico por par de espécies
## (GDD maldicoes.md R12, R13.5, R16, R18, F5; ADR-0017 §5).


static func executar(t: TecnicaDef, autor: MaldicaoRef, ctx: ContextoDaTecnica) -> int:
	if t == null or autor == null or ctx == null or ctx.ia == null:
		return 0
	# 1. Determina a posição de ancoragem/origem da técnica
	if t.ancoragem == &"jogador":
		autor.pos = ctx.ia.conter(ctx.pos_jogador, autor.raio_px())
	elif t.ancoragem == &"avanco_alvo":
		var id_alvo := IADeAliado.escolher_alvo_id(autor, ctx)
		var dir_av := ctx.mira_jogador if ctx.mira_jogador.length_squared() > 0.0 else Vector2.RIGHT
		var dist_av := t.alcance_avanco_px if t.alcance_avanco_px > 0.0 else 240.0
		if id_alvo != -1:
			var e_alvo := ctx.ia.estado_de(id_alvo)
			if e_alvo != null:
				var delta := e_alvo.posicao - autor.pos
				var d := delta.length()
				if d > 0.0:
					dir_av = delta / d
					dist_av = minf(dist_av, d)
		autor.dir = dir_av.normalized()
		autor.pos = ctx.ia.conter(autor.pos + autor.dir * dist_av, autor.raio_px())

	# 2. Encontra os inimigos atingíveis dentro da forma, em ordem crescente de id (ADR-0017 Guideline 1)
	var atingiveis := ctx.ia.atingiveis()
	var atingidos: Array[VistaDeInimigo] = []
	for v: VistaDeInimigo in atingiveis:
		if _atinge(t, autor, v):
			atingidos.append(v)

	if atingidos.is_empty():
		return 0

	var m_autor := autor.multiplicador_dano()
	var status_arr: Array = []
	if t.status_id != &"" and t.duracao_status_s > 0.0:
		status_arr.append({"id": t.status_id, "duracao_s": t.duracao_status_s})

	# 3. Aplica dano (com sinergia F5 por alvo se bonus_sinergia_pct > 0) e controle/status
	for v: VistaDeInimigo in atingidos:
		if t.dano > 0.0 and ctx.combate != null:
			var mult_sin := 1.0
			if t.bonus_sinergia_pct > 0.0 and sinergia_ativa(v.id, ctx):
				mult_sin += t.bonus_sinergia_pct
			var d_golpe := t.dano * mult_sin
			var delta := v.pos - autor.pos
			var dir_imp := autor.dir if delta.length_squared() == 0.0 else delta.normalized()
			ctx.combate.aplicar_golpe_maldicao(
				autor.player_id, autor.id, [v.id] as Array[int],
				d_golpe, m_autor, dir_imp, t.empurrao, status_arr, t.pesado, t.id)

		if t.status_id != &"" and t.duracao_status_s > 0.0 and ctx.status != null:
			if ctx.ia.atingivel(v.id):
				ctx.status.aplicar_status(v.id, t.status_id, t.duracao_status_s, autor.player_id)

		if t.controle != &"" and ctx.ia.atingivel(v.id):
			_aplicar_controle(t, autor, v, ctx)

	return atingidos.size()


## F5: `sinergia_ativa(alvo) = (alvo está preso/imobilizado OU marcado pela Saída OU atraído OU Abalado no instante da Entrada)`.
static func sinergia_ativa(inimigo_id: int, ctx: ContextoDaTecnica) -> bool:
	if ctx == null or ctx.ia == null:
		return false
	if ctx.ia.esta_imobilizado(inimigo_id) or ctx.ia.esta_atraido(inimigo_id):
		return true
	if ctx.pacto != null and ctx.pacto.ids_marcados_saida.get(inimigo_id, false):
		return true
	if ctx.status != null and ctx.status.tem_abalo(inimigo_id):
		return true
	return false


static func _atinge(t: TecnicaDef, autor: MaldicaoRef, v: VistaDeInimigo) -> bool:
	if t.forma == &"arco":
		var cos_meio := Unidades.cosseno_do_meio_angulo(60.0)
		return GeometriaDeAcerto.arco_do_golpe(autor.pos, autor.dir, cos_meio, t.raio_px, autor.raio_px(), v.pos, v.raio)
	return GeometriaDeAcerto.circulo_toca(autor.pos, t.raio_px, v.pos, v.raio)


static func _aplicar_controle(t: TecnicaDef, autor: MaldicaoRef, v: VistaDeInimigo, ctx: ContextoDaTecnica) -> void:
	match t.controle:
		&"imobilizar":
			var passos_imob := Unidades.duracao_para_passos(t.duracao_controle_s)
			if ctx.ia.imobilizar(v.id, passos_imob):
				if ctx.pacto != null and not ctx.pacto.ids_imobilizados.has(v.id):
					ctx.pacto.ids_imobilizados.append(v.id)
				if ctx.eventos != null:
					ctx.eventos.emitir(EventosMaldicoes.EvImobilizado.new(v.id, passos_imob))
			elif t.marca_elites_chefes_na_saida and (v.elite or v.chefe) and ctx.pacto != null:
				# R18 da IA / Catálogo Vulto e Soberano: Paredes de Sombra e Fenda Retida marcam elites e chefes para a sinergia F5
				ctx.pacto.ids_marcados_saida[v.id] = true
		&"atrair":
			var passos_atr := Unidades.duracao_para_passos(t.duracao_controle_s)
			var teto_atr := Unidades.duracao_para_passos(ctx.tuning.duracao_atracao_s) if ctx.tuning != null else 90
			passos_atr = mini(passos_atr, teto_atr)
			if ctx.ia.atrair(v.id, passos_atr, ctx.respiro_atracao_passos, autor.player_id):
				if ctx.pacto != null and not ctx.pacto.ids_atraidos.has(v.id):
					ctx.pacto.ids_atraidos.append(v.id)
				if ctx.eventos != null:
					ctx.eventos.emitir(EventosMaldicoes.EvAtraido.new(v.id, passos_atr))
		&"puxar":
			ctx.ia.puxar(v.id, autor.pos, t.puxao_distancia_px, t.puxao_parar_a_px)
