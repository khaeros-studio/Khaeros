class_name ComportamentoChefe
extends Comportamento
## Comportamento `chefe` (*Soberano do Limiar*; GDD chefes.md R1–R8, F1–F4, IA R21; ADR-0018 §8).
## 100% determinístico: nunca consome RNG (`ia`, `elites` ou `spawn`).


func ao_surgir(i: EstadoDeInimigoIA, ia: Object) -> void:
	var ct: ChefesTuning = ia.chefes_tuning()
	i.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
	i.timer = Unidades.duracao_para_passos(ct.espera_inicial_chefe_s if ct != null else 0.50)
	if i.estado_chefe != null:
		i.estado_chefe.padrao = 0


func decidir(i: EstadoDeInimigoIA, alvo: AlvoDeInimigo, ia: Object) -> void:
	var ct: ChefesTuning = ia.chefes_tuning()
	var telegrafos: Telegrafos = ia.telegrafos()
	var ec := i.estado_chefe
	if ec == null:
		return

	match i.fase:
		EstadoDeInimigoIA.Fase.TRANSICAO_FASE:
			if ec.pulso_pendente:
				ec.pulso_pendente = false
				ia.aplicar_pulso_transicao_furia(i)
			i.timer -= 1
			if i.timer <= 0:
				ec.em_furia = true
				if ec.avancar_padrao_ao_sair:
					ec.padrao = (ec.padrao + 1) % 4
					ec.avancar_padrao_ao_sair = false
				i.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
				i.timer = Unidades.duracao_para_passos(ct.espera_entre_padroes_chefe_s if ct != null else 0.25)

		EstadoDeInimigoIA.Fase.APROXIMACAO:
			i.timer -= 1
			var delta := alvo.pos - i.posicao
			var d := delta.length()
			if d > 0.0:
				i.ultima_direcao = delta / d
			var alcance_caminhar := PadroesDoChefe.alcance_caminhada_aproximacao(ec.padrao)
			if d > alcance_caminhar + 1e-5:
				var v_passo: float = ia.velocidade_andar_passo(i)
				i.posicao += i.ultima_direcao * minf(v_passo, d - alcance_caminhar)
				delta = alvo.pos - i.posicao
				d = delta.length()
			if PadroesDoChefe.pode_iniciar_preparo(ec.padrao, i.timer, d):
				var padrao_def := _obter_padrao(i, ec.padrao)
				if ia.tentar_iniciar_preparo_chefe(i, padrao_def, alvo):
					i.fase = EstadoDeInimigoIA.Fase.PREPARO
					i.timer = telegrafos.restante_de(i.id)

		EstadoDeInimigoIA.Fase.PREPARO:
			i.timer = telegrafos.restante_de(i.id) if telegrafos != null else maxi(0, i.timer - 1)
			var disparou := telegrafos.disparou_neste_passo(i.id) if telegrafos != null else (i.timer == 0)
			if disparou:
				var padrao_def := _obter_padrao(i, ec.padrao)
				var exec_passos := Unidades.duracao_para_passos(padrao_def.execucao_s if padrao_def != null else 0.20)
				i.fase = EstadoDeInimigoIA.Fase.EXECUCAO
				i.timer = exec_passos
				match ec.padrao:
					0:
						PadroesDoChefe.disparar_padrao_0(i, padrao_def, ia)
					1:
						PadroesDoChefe.iniciar_avanco_padrao_1(i, padrao_def, ia)
						PadroesDoChefe.passo_avanco_padrao_1(i, padrao_def, ia)
						i.timer -= 1
						if i.timer <= 0:
							_encerrar_execucao(i, padrao_def, ct, ia)
					2:
						PadroesDoChefe.disparar_padrao_2(i, padrao_def, ia)
					3:
						PadroesDoChefe.disparar_padrao_3(i, padrao_def, ia)

		EstadoDeInimigoIA.Fase.EXECUCAO:
			var padrao_def := _obter_padrao(i, ec.padrao)
			if ec.padrao == 1:
				PadroesDoChefe.passo_avanco_padrao_1(i, padrao_def, ia)
			i.timer -= 1
			if i.timer <= 0:
				_encerrar_execucao(i, padrao_def, ct, ia)

		EstadoDeInimigoIA.Fase.RECUPERACAO:
			var tuning: IATuning = ia.tuning()
			var delta: Vector2 = alvo.pos - i.posicao
			var d: float = delta.length()
			if d > 0.0:
				i.ultima_direcao = delta / d
			if d > tuning.recuperacao_dist_min_px + 1e-5:
				var passo_rec: float = float(ia.velocidade_andar_passo(i)) * tuning.fator_recuperacao_andar
				i.posicao += i.ultima_direcao * passo_rec
			i.timer -= 1
			if i.timer <= 0:
				i.fase = EstadoDeInimigoIA.Fase.APROXIMACAO
				i.timer = Unidades.duracao_para_passos(ct.espera_entre_padroes_chefe_s if ct != null else 0.25)


func _encerrar_execucao(i: EstadoDeInimigoIA, padrao_def: BossPatternDef,
		ct: ChefesTuning, ia: Object) -> void:
	var ec := i.estado_chefe
	if ec.transicao_pendente:
		ec.transicao_pendente = false
		ia.entrar_em_transicao_fase_chefe(i, true)
		return
	var rec_s := padrao_def.recarga_s if padrao_def != null else 1.0
	var fator_furia := ct.fator_recarga_furia if ct != null else 0.60
	ec.padrao = (ec.padrao + 1) % 4
	i.fase = EstadoDeInimigoIA.Fase.RECUPERACAO
	i.timer = FormulasDoChefe.passos_recarga_padrao(rec_s, ec.em_furia, fator_furia)


func _obter_padrao(i: EstadoDeInimigoIA, idx: int) -> BossPatternDef:
	if i.def == null or i.def.padroes.is_empty():
		return null
	var k := clampi(idx, 0, i.def.padroes.size() - 1)
	return i.def.padroes[k]
