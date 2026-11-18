class_name ComportamentoCharger
extends Comportamento
## Comportamento `arremetida` (*Fenda Errante*, *Estilhaço Vivo*; GDD ia-de-inimigos-e-elites.md R4, R6, R7, R9; ADR-0018).


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
			if i.restante_imob <= 0 and d > tuning.charger_reaproxima_px + 1e-5:
				var v_passo: float = ia.velocidade_andar_passo(i)
				i.posicao += dir * v_passo
				delta = alvo.pos - i.posicao
				d = delta.length()
			if i.restante_imob <= 0 and i.timer <= 0 and d <= tuning.charger_engaja_px + 1e-5:
				if ia.tentar_iniciar_preparo(i, alvo):
					i.fase = EstadoDeInimigoIA.Fase.PREPARO
					i.timer = telegrafos.restante_de(i.id)

		EstadoDeInimigoIA.Fase.PREPARO:
			i.timer = telegrafos.restante_de(i.id) if telegrafos != null else maxi(0, i.timer - 1)
			var disparou := telegrafos.disparou_neste_passo(i.id) if telegrafos != null else (i.timer == 0)
			if disparou:
				i.direcao_avanco = telegrafos.mira_de(i.id) if telegrafos != null else i.ultima_direcao
				i.ja_feriu_no_avanco = false
				i.fase = EstadoDeInimigoIA.Fase.EXECUCAO
				i.timer = tuning.avanco_passos
				_passo_de_avanco(i, ia, tuning)

		EstadoDeInimigoIA.Fase.EXECUCAO:
			_passo_de_avanco(i, ia, tuning)

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


func _passo_de_avanco(i: EstadoDeInimigoIA, ia: Object, tuning: IATuning) -> void:
	# R6 / R9: avanço ignora Selo, cambaleio, atração e imobilização em curso
	var v_avanco_passo := (i.velocidade_base / float(Unidades.TICK_RATE)) * tuning.avanco_mult_velocidade
	i.posicao = ia.conter(i.posicao + i.direcao_avanco * v_avanco_passo, i.raio)
	if not i.ja_feriu_no_avanco:
		if ia.testar_e_ferir_contato_avanco(i, i.dano_base, &"charger_avanco"):
			i.ja_feriu_no_avanco = true
	i.timer -= 1
	if i.timer <= 0:
		i.fase = EstadoDeInimigoIA.Fase.RECUPERACAO
		i.timer = Unidades.duracao_para_passos(i.def.recarga_s)
