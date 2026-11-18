class_name FormulasDeCombate
extends RefCounted
## Fórmulas puras de Combate núcleo (GDD combate-nucleo F1–F13; ADR-0010 §3, §6, §9).
## Sem estado, sem round()/roundi() da engine: todo arredondamento usa
## [method FormulasDeModificadores.arredondar_meio_longe_do_zero].


## F5: ângulo em graus para o índice [param k] do leque de projéteis (positivo = horário, y para baixo).
## k = 0 -> 0; k > 0 -> (+1 se ímpar senão -1) * giro_leque_graus * ceil(k / 2).
static func angulo_leque_graus(k: int, giro_leque_graus: float) -> float:
	if k <= 0:
		return 0.0
	var sinal := 1.0 if (k % 2) == 1 else -1.0
	var nivel := int(ceil(float(k) / 2.0))
	return sinal * giro_leque_graus * float(nivel)


## F5: alcance testado de um projétil a partir do centro do jogador.
static func alcance_testado_projetil(nascimento_px: float, velocidade_pxs: float, vida_passos: int) -> float:
	if vida_passos <= 1:
		return 0.0
	var s := velocidade_pxs / float(Unidades.TICK_RATE)
	return nascimento_px + float(vida_passos - 1) * s


## F7: número de passos com movimento e distância total de um empurrão de módulo inicial [param v0].
static func percurso_empurrao(v0: float, queda: float, zero_pxs: float) -> Dictionary:
	if v0 <= 0.0:
		return {"passos": 0, "distancia": 0.0}
	var n := maxi(1, int(floor(log(zero_pxs / v0) / log(queda))) + 1)
	var dist := (v0 / float(Unidades.TICK_RATE)) * (1.0 - pow(queda, float(n))) / (1.0 - queda)
	return {"passos": n, "distancia": dist}


## F8: janela de alcance para impacto na parede.
static func alcance_parede(v0: float, parede_vel_min: float, queda: float) -> Dictionary:
	if v0 < parede_vel_min:
		return {"k_p": 0, "alcance": 0.0}
	var kp := int(floor(log(parede_vel_min / v0) / log(queda))) + 1
	var alc := (v0 / float(Unidades.TICK_RATE)) * (1.0 - pow(queda, float(kp))) / (1.0 - queda)
	return {"k_p": kp, "alcance": alc}


## F12: dano inteiro recebido por uma Maldição aliada (F3 de Modificadores com guarda = 1 e escudo = 0).
static func dano_na_maldicao(dano_base: float, m_atacante: float, reducao_m: float, teto_red: float = 0.6) -> int:
	return FormulasDeModificadores.dano_recebido(dano_base * m_atacante, reducao_m, teto_red, 1.0)


## F13: dano inteiro recebido pela Maldição acuada do encontro de pacto (sem redução).
static func dano_na_acuada(dano_base: float, m_atacante: float) -> int:
	return maxi(1, FormulasDeModificadores.arredondar_meio_longe_do_zero(dano_base * m_atacante))


## V14: seleciona o único impulso de câmera de um passo a partir dos eventos emitidos (AC-72).
## Retorna um Dictionary vazio se nenhum evento pede impulso, ou
## {"preset": StringName, "escala": float, "direcao": Vector2, "zoom_principal": bool}.
static func escolher_impulso_camera_do_passo(eventos: Array[EventoDoPasso],
		direcao_empurrao_por_alvo: Dictionary = {}) -> Dictionary:
	var candidatos: Array[Dictionary] = []
	var acertos_investida := 0
	for ev in eventos:
		if ev is EventosDoCombate.EvAcerto:
			var a := ev as EventosDoCombate.EvAcerto
			if a.forma == &"projetil":
				if a.peso_visual == &"pesado":
					candidatos.append(_cand(&"leve", 0.6, a.direcao, false, 1))
			elif a.forma == &"avanco":
				acertos_investida += 1
				if acertos_investida == 1:
					var p_inv := &"pesado" if a.peso_visual == &"pesado" else &"leve"
					candidatos.append(_cand(p_inv, 1.0, a.direcao, false, 1))
				else:
					candidatos.append(_cand(&"leve", 0.5, a.direcao, false, 1))
			elif a.forma == &"arco" or a.forma == &"circulo" or a.forma == &"maldicao":
				var p_ac := &"pesado" if a.peso_visual == &"pesado" else &"leve"
				candidatos.append(_cand(p_ac, 1.0, a.direcao, false, 1))
		elif ev is EventosDoCombate.EvParede:
			var ep := ev as EventosDoCombate.EvParede
			var dir_emp: Vector2 = direcao_empurrao_por_alvo.get(ep.alvo_id, -ep.normal)
			candidatos.append(_cand(&"leve", 1.0, dir_emp, false, 1))
		elif ev is EventosDoCombate.EvJogadorAtingido:
			var ja := ev as EventosDoCombate.EvJogadorAtingido
			candidatos.append(_cand(&"pesado", 1.0, ja.direcao, false, 1))
		elif ev is EventosDoCombate.EvRecusouMorte:
			candidatos.append(_cand(&"pesado", 1.0, Vector2.ZERO, true, 2))
		elif ev is EventosDoCombate.EvInimigoMorreu:
			var im := ev as EventosDoCombate.EvInimigoMorreu
			if not im.limpo_pelo_chefe:
				if im.chefe:
					candidatos.append(_cand(&"chefe", 1.0, Vector2.ZERO, false, 1))
				elif im.elite:
					candidatos.append(_cand(&"pesado", 1.0, Vector2.ZERO, false, 1))
				else:
					candidatos.append(_cand(&"leve", 0.6, Vector2.ZERO, false, 1))
		elif ev is EventosDoCombate.EvChefeVencido:
			candidatos.append(_cand(&"chefe", 1.0, Vector2.ZERO, false, 1))
		elif ev is EventosDoCombate.EvExplosao:
			candidatos.append(_cand(&"leve", 0.5, Vector2.ZERO, false, 1))

	if candidatos.is_empty():
		return {}
	var melhor: Dictionary = candidatos[0]
	for i in range(1, candidatos.size()):
		var c: Dictionary = candidatos[i]
		if _vence_impulso(c, melhor):
			melhor = c
	return {
		"preset": melhor["preset"],
		"escala": melhor["escala"],
		"direcao": melhor["direcao"],
		"zoom_principal": melhor["zoom_principal"],
	}


static func _cand(preset: StringName, escala: float, dir: Vector2, zoom_principal: bool,
		desempate: int) -> Dictionary:
	var peso_preset := 1
	if preset == &"pesado":
		peso_preset = 2
	elif preset == &"chefe":
		peso_preset = 3
	return {
		"preset": preset,
		"peso_preset": peso_preset,
		"escala": escala,
		"direcao": dir,
		"zoom_principal": zoom_principal,
		"desempate": desempate,
	}


static func _vence_impulso(novo: Dictionary, atual: Dictionary) -> bool:
	if int(novo["peso_preset"]) != int(atual["peso_preset"]):
		return int(novo["peso_preset"]) > int(atual["peso_preset"])
	if not is_equal_approx(float(novo["escala"]), float(atual["escala"])):
		return float(novo["escala"]) > float(atual["escala"])
	return int(novo["desempate"]) > int(atual["desempate"])


## A1 / AC-80b: agrupa eventos de combate de um passo em pedidos únicos de som (1 por tipo de som por passo).
static func pedidos_de_som_do_passo(eventos: Array[EventoDoPasso]) -> Array[StringName]:
	var vistos: Dictionary[StringName, bool] = {}
	var ordem: Array[StringName] = []
	for ev in eventos:
		var sons: Array[StringName] = []
		if ev is EventosDoCombate.EvAcerto:
			var a := ev as EventosDoCombate.EvAcerto
			sons.append(&"sfx_acerto_pesado" if a.peso_visual == &"pesado" else &"sfx_acerto_leve")
			if a.enesimo_acerto:
				sons.append(&"sfx_acerto_critico")
		elif ev is EventosDoCombate.EvInimigoMorreu:
			var im := ev as EventosDoCombate.EvInimigoMorreu
			if im.chefe:
				sons.append(&"sfx_morte_chefe")
			elif im.elite:
				sons.append(&"sfx_morte_elite")
			else:
				sons.append(&"sfx_morte_comum")
		elif ev is EventosDoCombate.EvChefeVencido:
			sons.append(&"sfx_morte_chefe")
		else:
			sons.append(StringName("sfx_" + String(ev.tipo())))
		for s in sons:
			if not vistos.has(s):
				vistos[s] = true
				ordem.append(s)
	return ordem
