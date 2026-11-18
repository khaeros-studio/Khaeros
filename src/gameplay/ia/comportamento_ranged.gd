class_name ComportamentoRanged
extends Comportamento
## Comportamento `distancia` (*Anomalia Menor*, *Anomalia do Veio*; GDD ia-de-inimigos-e-elites.md R4, R6, R7, R11; ADR-0018).


func ao_surgir(i: EstadoDeInimigoIA, ia: Object) -> void:
	i.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	i.timer = ia.sortear_espera_inicial()


func decidir(i: EstadoDeInimigoIA, alvo: AlvoDeInimigo, ia: Object) -> void:
	var tuning: IATuning = ia.tuning()
	var telegrafos: Telegrafos = ia.telegrafos()
	match i.fase:
		EstadoDeInimigoIA.Fase.APROXIMACAO:
			i.timer -= 1
			var delta := alvo.pos - i.posicao
			var d := delta.length()
			var dir := i.ultima_direcao if d == 0.0 else delta / d
			i.ultima_direcao = dir
			var visivel: bool = ia.esta_na_vista(i.posicao)
			if i.restante_imob <= 0:
				var v_passo: float = ia.velocidade_andar_passo(i)
				if not visivel:
					# R11 / AC-IA-19 / AC-IA-28: fora da vista avança sempre rumo ao alvo (nunca recua nem contorna)
					i.posicao += dir * v_passo
				elif d < tuning.ranged_perto_px - 1e-5:
					i.posicao -= dir * v_passo
				elif d > tuning.ranged_longe_px + 1e-5:
					i.posicao += dir * v_passo
				else:
					var perp := Vector2(-dir.y, dir.x)
					i.posicao += perp * (v_passo * tuning.fator_contorno)
				delta = alvo.pos - i.posicao
				d = delta.length()
				visivel = ia.esta_na_vista(i.posicao)

			if i.restante_imob <= 0 and i.timer <= 0 and visivel and d < tuning.ranged_ataque_px - 1e-5:
				if ia.tentar_iniciar_preparo(i, alvo):
					i.fase = EstadoDeInimigoIA.Fase.PREPARO
					i.timer = telegrafos.restante_de(i.id)

		EstadoDeInimigoIA.Fase.PREPARO:
			i.timer = telegrafos.restante_de(i.id) if telegrafos != null else maxi(0, i.timer - 1)
			var disparou := telegrafos.disparou_neste_passo(i.id) if telegrafos != null else (i.timer == 0)
			if disparou:
				ia.disparar_projetil_travado(i)
				i.fase = EstadoDeInimigoIA.Fase.EXECUCAO
				i.timer = tuning.execucao_ranged_passos

		EstadoDeInimigoIA.Fase.EXECUCAO:
			i.timer -= 1
			if i.timer <= 0:
				i.fase = EstadoDeInimigoIA.Fase.RECUPERACAO
				i.timer = Unidades.duracao_para_passos(i.def.recarga_s)

		EstadoDeInimigoIA.Fase.RECUPERACAO:
			# R7: ranged não anda na recuperação
			i.timer -= 1
			if i.timer <= 0:
				i.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
				i.timer = ia.sortear_espera_pos_recuperacao()
