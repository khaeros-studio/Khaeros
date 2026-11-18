class_name ValidadorTelegrafos
extends ValidadorDoDono
## Validação de TelegraphTuning, EnemyDef e BossPatternDef (TV1–TV6 e TL1–TL12; GDD telegrafos.md e ADR-0014).

const CAPACIDADE_MAX_POOL: int = 24
const REACAO_REF_PADRAO_S: float = 0.25
const PREPARO_MIN_PADRAO_S: float = 0.40
const FOLGA_MIN_PADRAO: int = 8


func prefixo() -> StringName:
	return &"TV"


func validar(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	return validar_completo(itens)


static func validar_completo(itens: Array[ItemDoCatalogo], tuning_injetado: TelegraphTuning = null,
		max_simultaneos_cenario: int = 9) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_tt: ItemDoCatalogo = null
	for i in itens:
		if i != null and i.definicao != null and i.definicao.get_script() == TelegraphTuning:
			item_tt = i
			break
	var tt: TelegraphTuning = tuning_injetado
	if tt == null:
		tt = item_tt.definicao as TelegraphTuning if item_tt != null else TelegraphTuning.de_fabrica()

	# TV1 / TL1: teto_telegrafos < 1 ou > 24, ou preparo_min_s <= 0 ou reacao_ref_s <= 0
	if tt.teto_telegrafos < 1 or tt.preparo_min_s <= 0.0:
		out.append(_diag(item_tt, &"TV1", "teto_telegrafos", tt.teto_telegrafos,
			"TelegraphTuning: teto_telegrafos < 1 ou preparo_min_s <= 0", Diagnostico.Nivel.ERRO))
		out.append(_diag(item_tt, &"TL1", "teto_telegrafos", tt.teto_telegrafos,
			"TelegraphTuning: teto_telegrafos < 1 ou preparo_min_s <= 0", Diagnostico.Nivel.ERRO))
	if tt.teto_telegrafos > CAPACIDADE_MAX_POOL:
		out.append(_diag(item_tt, &"TL2", "teto_telegrafos", tt.teto_telegrafos,
			"TelegraphTuning: teto_telegrafos > 24 estoura orçamento do Pipeline", Diagnostico.Nivel.ERRO))
	if tt.reacao_ref_s <= 0.0 or tt.avanco_passos < 1:
		out.append(_diag(item_tt, &"TL3", "reacao_ref_s", tt.reacao_ref_s,
			"TelegraphTuning: reacao_ref_s <= 0 ou avanco_passos < 1", Diagnostico.Nivel.ERRO))

	# TV5 / TL5: teto_telegrafos < número máximo simultâneo
	var max_sim := max_simultaneos_cenario
	for i in itens:
		if i != null and i.definicao is WaveRules:
			var w := i.definicao as WaveRules
			if w.max_inimigos_onda > 0:
				max_sim = maxi(max_sim, w.max_inimigos_onda)
		elif i != null and i.definicao is ChefesTuning:
			var ct := i.definicao as ChefesTuning
			max_sim = maxi(max_sim, 1 + ct.max_lacaios_vivos)
	if tt.teto_telegrafos >= 1 and tt.teto_telegrafos < max_sim:
		out.append(_diag(item_tt, &"TV5", "teto_telegrafos", tt.teto_telegrafos,
			"TelegraphTuning: teto_telegrafos (%d) < simultâneos máximos (%d)" % [tt.teto_telegrafos, max_sim],
			Diagnostico.Nivel.AVISO))
		out.append(_diag(item_tt, &"TL5", "teto_telegrafos", tt.teto_telegrafos,
			"TelegraphTuning: teto_telegrafos reduzido causará espera na IA", Diagnostico.Nivel.AVISO))

	# TV6 / TL6: faixas de design do TelegraphTuning
	var p_min_passos := Unidades.duracao_para_passos(tt.preparo_min_s)
	if p_min_passos < 18 or p_min_passos > 26 or tt.teto_telegrafos < 12 or tt.teto_telegrafos > 24 \
			or tt.reacao_ref_s < 0.15 - 1e-9 or tt.reacao_ref_s > 0.40 + 1e-9 \
			or tt.folga_min < 4 or tt.folga_min > 15:
		out.append(_diag(item_tt, &"TV6", "telegraph_tuning", tt.preparo_min_s,
			"TelegraphTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))
		out.append(_diag(item_tt, &"TL6", "telegraph_tuning", tt.preparo_min_s,
			"TelegraphTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))

	# Inimigos comuns e chefes
	for item in itens:
		if item == null or not (item.definicao is EnemyDef):
			continue
		var e := item.definicao as EnemyDef
		if e.comportamento == &"chefe":
			for idx in e.padroes.size():
				var p := e.padroes[idx]
				if p == null:
					continue
				var p_passos := Unidades.duracao_para_passos(p.preparo_s)
				if p_passos < 1:
					out.append(_diag(item, &"TV1", "padroes[%d].preparo_s" % idx, p.preparo_s,
						"Chefe %s: padrão %d com preparo < 1 passo" % [e.id, idx], Diagnostico.Nivel.ERRO))
					out.append(_diag(item, &"TL7", "padroes[%d].preparo_s" % idx, p.preparo_s,
						"Chefe %s: padrão %d com preparo < 1 passo" % [e.id, idx], Diagnostico.Nivel.ERRO))
					continue
				var fd := FormasDeTelegrafo.derivar_padrao_chefe(p, e.raio_px)
				if not fd.valida:
					out.append(_diag(item, &"TV2", "padroes[%d]" % idx, p.forma_telegrafo,
						"Chefe %s: padrão %d sem forma válida ou dimensão <= 0" % [e.id, idx], Diagnostico.Nivel.ERRO))
					out.append(_diag(item, &"TL8", "padroes[%d]" % idx, p.forma_telegrafo,
						"Chefe %s: padrão %d sem forma válida ou dimensão <= 0" % [e.id, idx], Diagnostico.Nivel.ERRO))
					continue
				var folga_ch := FormasDeTelegrafo.folga_de_leitura(p_passos, tt.reacao_ref_s)
				if folga_ch < tt.folga_min:
					out.append(_diag(item, &"TV4", "padroes[%d].preparo_s" % idx, folga_ch,
						"Chefe %s: padrão %d com folga %d < %d" % [e.id, idx, folga_ch, tt.folga_min],
						Diagnostico.Nivel.AVISO))
					out.append(_diag(item, &"TL9", "padroes[%d].preparo_s" % idx, folga_ch,
						"Chefe %s: padrão %d com folga < folga_min" % [e.id, idx], Diagnostico.Nivel.AVISO))
				if p.raio_secundario_px < 0.0 or (p.raio_secundario_px > 0.0 and p.raio_secundario_px <= fd.raio):
					out.append(_diag(item, &"TL10", "padroes[%d].raio_secundario_px" % idx, p.raio_secundario_px,
						"Chefe %s: contorno secundário inválido no padrão %d" % [e.id, idx], Diagnostico.Nivel.AVISO))
			continue

		var prep := Unidades.duracao_para_passos(e.preparo_s)
		if prep < 1:
			out.append(_diag(item, &"TV1", "preparo_s", e.preparo_s,
				"EnemyDef %s: preparo_s < 1 passo" % e.id, Diagnostico.Nivel.ERRO))
			out.append(_diag(item, &"TL1", "preparo_s", e.preparo_s,
				"EnemyDef %s: preparo_s < 1 passo" % e.id, Diagnostico.Nivel.ERRO))
			continue
		var derivada := FormasDeTelegrafo.derivar(e, TelegrafoTipos.RAIO_JOGADOR_PADRAO_PX, tt.avanco_passos)
		if not derivada.valida:
			out.append(_diag(item, &"TV2", "comportamento", e.comportamento,
				"EnemyDef %s: forma não mapeada ou dimensão derivada <= 0" % e.id, Diagnostico.Nivel.ERRO))
			out.append(_diag(item, &"TL4", "comportamento", e.comportamento,
				"EnemyDef %s: forma não mapeada ou dimensão derivada <= 0" % e.id, Diagnostico.Nivel.ERRO))
			continue
		if prep < p_min_passos:
			out.append(_diag(item, &"TV3", "preparo_s", e.preparo_s,
				"EnemyDef %s: preparo %d < mínimo %d" % [e.id, prep, p_min_passos], Diagnostico.Nivel.AVISO))
			out.append(_diag(item, &"TL11", "preparo_s", e.preparo_s,
				"EnemyDef %s: preparo abaixo do mínimo" % e.id, Diagnostico.Nivel.AVISO))
		var folga := FormasDeTelegrafo.folga_de_leitura(prep, tt.reacao_ref_s)
		if folga < tt.folga_min:
			out.append(_diag(item, &"TV4", "preparo_s", folga,
				"EnemyDef %s: folga %d < folga_min %d" % [e.id, folga, tt.folga_min], Diagnostico.Nivel.AVISO))
			out.append(_diag(item, &"TL12", "preparo_s", folga,
				"EnemyDef %s: folga de leitura abaixo do mínimo" % e.id, Diagnostico.Nivel.AVISO))
	return out


static func _diag(item: ItemDoCatalogo, codigo: StringName, campo: String, valor: Variant,
		msg: String, nivel: Diagnostico.Nivel) -> Diagnostico:
	if item != null:
		return Diagnostico.de_item(item, codigo, campo, valor, msg, nivel)
	return Diagnostico.novo(codigo, campo, valor, msg, nivel)
