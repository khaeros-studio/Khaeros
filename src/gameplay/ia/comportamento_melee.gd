class_name ComportamentoMelee
extends Comportamento
## Comportamento `corpo_a_corpo` (*Eco Perdido*, *Eco do Veio*; GDD ia-de-inimigos-e-elites.md R3–R7, F2, F6; ADR-0018).


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
			if d > 0.0:
				i.ultima_direcao = delta / d
			if i.restante_imob <= 0:
				var passo_andar: float = ia.velocidade_andar_passo(i)
				if d > 0.0 and passo_andar > 0.0:
					i.posicao += i.ultima_direcao * minf(passo_andar, d)
					delta = alvo.pos - i.posicao
					d = delta.length()
			var alcance_total := i.def.alcance_px + alvo.raio
			if i.restante_imob <= 0 and i.timer <= 0 and d <= alcance_total + 1e-5:
				if ia.tentar_iniciar_preparo(i, alvo):
					i.fase = EstadoDeInimigoIA.Fase.PREPARO
					i.timer = telegrafos.restante_de(i.id)

		EstadoDeInimigoIA.Fase.PREPARO:
			i.timer = telegrafos.restante_de(i.id) if telegrafos != null else maxi(0, i.timer - 1)
			var disparou := telegrafos.disparou_neste_passo(i.id) if telegrafos != null else (i.timer == 0)
			if disparou:
				ia.resolver_golpe_setor_travado(i, i.dano_base, &"melee_setor")
				i.fase = EstadoDeInimigoIA.Fase.EXECUCAO
				i.timer = tuning.execucao_melee_passos

		EstadoDeInimigoIA.Fase.EXECUCAO:
			i.timer -= 1
			if i.timer <= 0:
				i.fase = EstadoDeInimigoIA.Fase.RECUPERACAO
				i.timer = Unidades.duracao_para_passos(i.def.recarga_s)

		EstadoDeInimigoIA.Fase.RECUPERACAO:
			var delta := alvo.pos - i.posicao
			var d := delta.length()
			if d > 0.0:
				i.ultima_direcao = delta / d
			if i.restante_imob <= 0 and d > tuning.recuperacao_dist_min_px + 1e-5:
				var passo_rec: float = ia.velocidade_andar_passo(i) * tuning.fator_recuperacao_andar
				i.posicao += i.ultima_direcao * passo_rec
			i.timer -= 1
			if i.timer <= 0:
				i.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
				i.timer = ia.sortear_espera_pos_recuperacao()
