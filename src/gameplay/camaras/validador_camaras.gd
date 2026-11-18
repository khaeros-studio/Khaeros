class_name ValidadorCamaras
extends RefCounted
## Validação WV1–WV12 das Câmaras e ondas (GDD camaras-e-ondas.md §Validação; ADR-0004).
## Envolve [RegrasWv] e acrescenta as verificações geométricas e de pool (WV3, WV4, WV5, WV7, WV12)
## sobre [WaveRules], [RoomTuning], [EliteRules] e [RegionDef] sem editar arquivos fora de
## [code]src/gameplay/camaras/[/code].
##
## Exemplo:
## [codeblock]
## var diags := ValidadorCamaras.validar_tudo(itens, catalogo)
## [/codeblock]

const PEDRAS_SANTUARIO: Array[Vector3] = [Vector3(960.0, 495.0, 63.0)]
const PEDRAS_CHEFE: Array[Vector3] = [
	Vector3(390.0, 300.0, 51.0),
	Vector3(1530.0, 300.0, 51.0),
	Vector3(390.0, 750.0, 51.0),
	Vector3(1530.0, 750.0, 51.0),
]
const RAIO_JOGADOR_PADRAO: float = 27.0
const COBERTURA_MAX_PEDRAS: float = 0.15


## Valida 1ª e 2ª passadas das regras WV1–WV12 sobre [param itens].
static func validar_tudo(itens: Array[ItemDoCatalogo], catalogo: Catalogo = null) -> Array[Diagnostico]:
	var regras_wv := RegrasWv.new()
	var out: Array[Diagnostico] = regras_wv.validar(itens)
	if catalogo != null:
		for d in regras_wv.validar_segunda_passada(itens, catalogo):
			if not _ja_tem(out, d.regra):
				out.append(d)
	out.append_array(_validar_extras(itens))
	return out


static func _validar_extras(itens: Array[ItemDoCatalogo]) -> Array[Diagnostico]:
	var out: Array[Diagnostico] = []
	var item_rt: ItemDoCatalogo = null
	var item_wr: ItemDoCatalogo = null
	var item_er: ItemDoCatalogo = null
	var inimigos: Dictionary[StringName, EnemyDef] = {}
	var regioes: Array[ItemDoCatalogo] = []
	for it in itens:
		if it.definicao is RoomTuning and item_rt == null:
			item_rt = it
		elif it.definicao is WaveRules and item_wr == null:
			item_wr = it
		elif it.definicao is EliteRules and item_er == null:
			item_er = it
		elif it.definicao is EnemyDef:
			var e := it.definicao as EnemyDef
			inimigos[e.id] = e
		elif it.definicao is RegionDef:
			regioes.append(it)

	if item_rt != null:
		var rt := item_rt.definicao as RoomTuning
		# WV3: entrada fora da câmara ou dentro de pedra fixa (santuário / chefe) com folga do raio do jogador
		var ex: float = rt.entrada_px[0] if rt.entrada_px.size() >= 2 else -1.0
		var ey: float = rt.entrada_px[1] if rt.entrada_px.size() >= 2 else -1.0
		var fora_camara: bool = ex < RAIO_JOGADOR_PADRAO or ex > rt.camara_largura_px - RAIO_JOGADOR_PADRAO \
				or ey < RAIO_JOGADOR_PADRAO or ey > rt.camara_altura_px - RAIO_JOGADOR_PADRAO
		var em_pedra_fixa: bool = false
		var entrada := Vector2(ex, ey)
		for p: Vector3 in PEDRAS_SANTUARIO + PEDRAS_CHEFE:
			if entrada.distance_to(Vector2(p.x, p.y)) <= p.z + RAIO_JOGADOR_PADRAO:
				em_pedra_fixa = true
				break
		if fora_camara or em_pedra_fixa:
			out.append(Diagnostico.de_item(item_rt, &"WV3", "entrada_px", rt.entrada_px,
				"RoomTuning: entrada_px fora da câmara ou sobre pedra de layout fixo"))

		# WV7: cobertura máxima de pedras (4 * pi * r_max^2) > 15% da câmara
		var r_max: float = rt.obstaculo_raio_min_px + 1.5 * float(maxi(0, rt.obstaculo_passos - 1))
		var area_camara: float = rt.camara_largura_px * rt.camara_altura_px
		if area_camara > 0.0:
			var n_max_pedras: int = rt.obstaculos_min + maxi(0, rt.obstaculos_var - 1)
			var cobertura: float = float(n_max_pedras) * PI * r_max * r_max / area_camara
			if cobertura > COBERTURA_MAX_PEDRAS:
				out.append(Diagnostico.de_item(item_rt, &"WV7", "obstaculo_raio_min_px", cobertura,
					"RoomTuning: cobertura máxima de pedras %.3f > 0,15" % cobertura,
					Diagnostico.Nivel.AVISO))

		# WV9 (RoomTuning faixas extras)
		if rt.santuario_cura < 0.2 - 1e-9 or rt.santuario_cura > 0.6 + 1e-9 or rt.folga_obstaculo_px < 60.0 or rt.folga_obstaculo_px > 200.0:
			out.append(Diagnostico.de_item(item_rt, &"WV9", "room_tuning", null,
				"RoomTuning: campo fora da faixa de design", Diagnostico.Nivel.AVISO))

	if item_wr != null:
		var wr := item_wr.definicao as WaveRules
		for item_reg in regioes:
			var reg := item_reg.definicao as RegionDef
			var custo_min: float = INF
			for eid: StringName in reg.pool_inimigos:
				if inimigos.has(eid):
					var c := float(inimigos[eid].custo_onda)
					if c > 0.0 and c < custo_min:
						custo_min = c
			# WV4: nenhum inimigo do pool tem custo <= orcamento_base
			if custo_min > wr.orcamento_base + 1e-9:
				out.append(Diagnostico.de_item(item_reg, &"WV4", "pool_inimigos", wr.orcamento_base,
					"RegionDef: nenhum inimigo do pool cabe em orcamento_base"))
			elif is_finite(custo_min) and custo_min > 0.0:
				# WV5: floor(orcamento_pmax / custo_min) > max_inimigos_onda
				var p_max: int = ProfundidadeCamara.calcular_p_max(reg.camaras)
				var orc_pmax: float = wr.orcamento_base + wr.orcamento_por_prof * float(p_max)
				if int(floor(orc_pmax / custo_min)) > wr.max_inimigos_onda:
					out.append(Diagnostico.de_item(item_wr, &"WV5", "max_inimigos_onda", wr.max_inimigos_onda,
						"WaveRules: floor(orcamento_pmax / custo_min) > max_inimigos_onda",
						Diagnostico.Nivel.AVISO))

	# WV12: validação de EliteRules (mult_raio, max_elites_onda, profundidade_minima)
	if item_er != null:
		var er := item_er.definicao as EliteRules
		if er.mult_vida <= 1.0 or er.mult_dano <= 1.0 or er.mult_raio <= 1.0 or er.max_elites_onda < 1:
			out.append(Diagnostico.de_item(item_er, &"WV12", "elite_rules", er.mult_raio,
				"EliteRules: multiplicadores de elite devem ser > 1,0 e max_elites_onda >= 1"))
	return out


static func _ja_tem(lista: Array[Diagnostico], codigo: StringName) -> bool:
	for d in lista:
		if d.regra == codigo:
			return true
	return false
