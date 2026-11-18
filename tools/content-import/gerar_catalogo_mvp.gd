extends SceneTree
## Script de geração do catálogo MVP (`assets/data/**/*.tres`, `assets/data/content_catalog.tres`
## e `assets/data/canon/ids_registrados.csv`) para os épicos `conteudo` (story 010) e
## `assets-e-conteudo` (stories 001..005, 009).
## Roda em modo headless: `godot --headless --script res://tools/content-import/gerar_catalogo_mvp.gd`.


func _init() -> void:
	_garantir_pastas()
	# Remove o combat_tuning.tres antigo da raiz para não ficar órfão fora de assets/data/tuning/
	if FileAccess.file_exists("res://assets/data/combat_tuning.tres"):
		DirAccess.remove_absolute("res://assets/data/combat_tuning.tres")

	var manifesto := ManifestoDoCatalogo.new()
	var pares_ids := PackedStringArray()
	pares_ids.append("tipo,id")

	# 1. Armas (3 WeaponDef)
	for w: WeaponDef in [FabricaDeArmas.lamina(), FabricaDeArmas.ressonancia(), FabricaDeArmas.pactos()]:
		_salvar_item(manifesto, pares_ids, &"weapon", "res://assets/data/armas/%s.tres" % w.id, w)

	# 2. Inimigos e Chefe (5 EnemyDef: 3 comuns + anomalia_maior reservado + soberano_do_limiar ativo)
	var inimigos_dict := FabricaDeArmas.inimigos_limiar()
	for id_inim: StringName in [&"eco_perdido", &"anomalia_menor", &"fenda_errante", &"anomalia_maior"]:
		var e: EnemyDef = inimigos_dict[id_inim]
		_salvar_item(manifesto, pares_ids, &"enemy", "res://assets/data/inimigos/%s.tres" % e.id, e)
	var soberano := FabricasDeCatalogo.chefe_soberano()
	soberano.chave_nome = &"ENEMY_SOBERANO_DO_LIMIAR_NAME"
	_salvar_item(manifesto, pares_ids, &"enemy", "res://assets/data/inimigos/soberano_do_limiar.tres", soberano)

	# 3. As 18 Bênçãos (BoonDef) na ordem canônica de FixtureBn.IDS
	var bencaos := _criar_18_bencaos()
	for b: BoonDef in bencaos:
		_salvar_item(manifesto, pares_ids, &"boon", "res://assets/data/bencaos/%s.tres" % b.id, b)

	# 4. As 4 Espécies de Maldição (CurseDef) na ordem do manifesto
	for i in FabricasDeCatalogo.ESPECIES.size():
		var id_esp := FabricasDeCatalogo.ESPECIES[i]
		var rar := FabricasDeCatalogo.RARIDADES[i]
		var c := FabricasDeCatalogo.maldicao(id_esp, rar)
		_salvar_item(manifesto, pares_ids, &"curse", "res://assets/data/maldicoes/%s.tres" % c.id, c)

	# 5. Região Limiar (RegionDef)
	var reg := RegionDef.new()
	reg.id = &"limiar"
	reg.chave_nome = &"REGION_LIMIAR_NAME"
	reg.camaras = [&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"]
	reg.pool_inimigos = [&"eco_perdido", &"anomalia_menor", &"fenda_errante"]
	reg.chefe = &"soberano_do_limiar"
	reg.fragmentos_chefe = 24
	_salvar_item(manifesto, pares_ids, &"region", "res://assets/data/regioes/limiar.tres", reg)

	# 6. Tabelas de Câmara, Raridade, Recompensa, Elite e Economia
	var rar_tab := FixtureBn.tabela()
	_salvar_item(manifesto, pares_ids, &"rarity_table", "res://assets/data/camaras/rarity_table.tres", rar_tab)

	var rew_tab := FabricasDeCatalogo.reward_table()
	_salvar_item(manifesto, pares_ids, &"reward_table", "res://assets/data/camaras/reward_table.tres", rew_tab)

	var wave_r := FabricasDeCatalogo.wave_rules()
	_salvar_item(manifesto, pares_ids, &"wave_rules", "res://assets/data/camaras/wave_rules.tres", wave_r)

	var elite_r := _criar_elite_rules()
	_salvar_item(manifesto, pares_ids, &"elite_rules", "res://assets/data/camaras/elite_rules.tres", elite_r)

	var econ := FabricasDeCatalogo.economy_rates()
	_salvar_item(manifesto, pares_ids, &"economy_rates", "res://assets/data/economy_rates/economy_rates.tres", econ)

	# 7. Tunings do MVP
	var tunings: Array[DefinicaoBase] = [
		_criar_combat_tuning(),
		FabricasDeCatalogo.armas_tuning(),
		_criar_camera_tuning(),
		_criar_input_tuning(),
		FabricasDeCatalogo.visual_tuning(),
		FabricasDeCatalogo.bencaos_tuning(),
		FabricasDeCatalogo.run_tuning(),
		FabricasDeCatalogo.hud_tuning(),
		FabricasDeCatalogo.tela_bencao_tuning(),
		FabricasDeCatalogo.feedback_tuning(),
		FabricasDeCatalogo.telemetria_tuning(),
		_criar_status_tuning(),
		FabricasDeCatalogo.maldicoes_tuning(),
		FabricasDeCatalogo.vinculo_tuning(),
		FabricasDeCatalogo.chefes_tuning(),
		FabricasDeCatalogo.room_tuning(),
		_criar_modifiers_tuning(),
		_criar_movement_tuning(),
		SealTuning.fabrica(),
		TelegraphTuning.de_fabrica(),
		IATuning.de_fabrica(),
	]
	for t: DefinicaoBase in tunings:
		_salvar_item(manifesto, pares_ids, t.tipo_do_catalogo(), "res://assets/data/tuning/%s.tres" % t.id, t)

	var audio_t := AudioTuning.new()
	audio_t.id = &"audio_tuning"
	_salvar_item(manifesto, pares_ids, audio_t.tipo_do_catalogo(), "res://assets/data/tuning/audio_tuning.tres", audio_t)

	# 8. Sons P0 (SomDef)
	for s: SomDef in _criar_sons_p0():
		_salvar_item(manifesto, pares_ids, &"som", "res://assets/data/audio/%s.tres" % s.id, s)

	# 9. Salva o manifesto e ids_registrados.csv
	var err_m := ResourceSaver.save(manifesto, "res://assets/data/content_catalog.tres")
	if err_m != OK:
		push_error("Falha ao salvar content_catalog.tres: %d" % err_m)
		quit(1)
		return

	var f_ids := FileAccess.open("res://assets/data/canon/ids_registrados.csv", FileAccess.WRITE)
	f_ids.store_string("\n".join(pares_ids) + "\n")
	f_ids.close()

	print("Catálogo MVP gerado com sucesso: %d recursos." % manifesto.tamanho())
	quit(0)


func _garantir_pastas() -> void:
	for p in [
		"res://assets/data/tuning",
		"res://assets/data/armas",
		"res://assets/data/inimigos",
		"res://assets/data/bencaos",
		"res://assets/data/regioes",
		"res://assets/data/camaras",
		"res://assets/data/economy_rates",
		"res://assets/data/maldicoes",
		"res://assets/data/audio",
		"res://assets/data/canon",
	]:
		DirAccess.make_dir_recursive_absolute(p)


func _salvar_item(
	manifesto: ManifestoDoCatalogo,
	pares_ids: PackedStringArray,
	tipo: StringName,
	caminho: String,
	def: DefinicaoBase
) -> void:
	var err := ResourceSaver.save(def, caminho)
	if err != OK:
		push_error("Erro ao salvar %s: %d" % [caminho, err])
		return
	_garantir_campos_obrigatorios_no_texto(caminho, def)
	manifesto.acrescentar(tipo, caminho)
	pares_ids.append("%s,%s" % [tipo, def.id])


## Garante que campos obrigatórios cujo valor coincide com o default do script (ex.: 0.0)
## também fiquem explicitamente gravados na seção [resource] do .tres (AC-09).
func _garantir_campos_obrigatorios_no_texto(caminho: String, def: DefinicaoBase) -> void:
	var texto := FileAccess.get_file_as_string(caminho)
	var gravados := EsquemaDeDefinicao.campos_gravados_no_texto(texto)
	var faltantes := def.esquema().campos_ausentes(gravados)
	if faltantes.is_empty():
		return
	var extras := PackedStringArray()
	for nome_cpo in faltantes:
		var val: Variant = def.get(StringName(nome_cpo))
		extras.append("%s = %s" % [nome_cpo, var_to_str(val)])
	if not texto.ends_with("\n"):
		texto += "\n"
	texto += "\n".join(extras) + "\n"
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f != null:
		f.store_string(texto)
		f.close()


func _criar_18_bencaos() -> Array[BoonDef]:
	var specs: Array = [
		[&"trad_blade_traco_unico", &"lamina", [{&"tipo": &"dano_ataque_pct", &"valor": 0.25, &"escala": true, &"params": {}}], &""],
		[&"trad_blade_lamina_pesada", &"lamina", [{&"tipo": &"dano_especial_pct", &"valor": 0.40, &"escala": true, &"params": {}}], &""],
		[&"trad_blade_corte_fantasma", &"lamina", [{&"tipo": &"corte_da_esquiva", &"valor": 10.0, &"escala": true, &"params": {&"sangramento": 1.0, &"alcance_extra_px": 9.0, &"empurrao": 360.0}}], &""],
		[&"trad_resonance_fundo_poco", &"ressonancia", [{&"tipo": &"dano_vida_baixa_pct", &"valor": 0.40, &"escala": true, &"params": {&"limiar_vida": 0.5}}], &""],
		[&"trad_resonance_linha_contada", &"ressonancia", [{&"tipo": &"dano_enesimo_acerto", &"valor": 0.60, &"escala": true, &"params": {&"a_cada": 4.0}}], &""],
		[&"trad_resonance_preco_nome", &"ressonancia", [
			{&"tipo": &"dano_todo_pct", &"valor": 0.20, &"escala": true, &"params": {}},
			{&"tipo": &"vida_max_plano", &"valor": -10.0, &"escala": false, &"params": {}},
		], &"TRAD_RESONANCE_PRECO_NOME_PRICE"],
		[&"trad_guardian_muro_pedras", &"guardiao", [{&"tipo": &"vida_max_plano", &"valor": 25.0, &"escala": true, &"params": {}}], &""],
		[&"trad_guardian_voo_escudo", &"guardiao", [{&"tipo": &"reducao_dano", &"valor": 0.12, &"escala": true, &"params": {}}], &""],
		[&"trad_guardian_armadura_vazia", &"guardiao", [{&"tipo": &"escudo_sala", &"valor": 15.0, &"escala": true, &"params": {}}], &""],
		[&"trad_veil_penumbra", &"veu", [{&"tipo": &"dano_apos_esquiva", &"valor": 0.50, &"escala": true, &"params": {&"janela_s": 1.5}}], &""],
		[&"trad_veil_sombra_viva", &"veu", [{&"tipo": &"golpe_sangramento", &"valor": 1.0, &"escala": true, &"params": {}}], &""],
		[&"trad_veil_fio_invisivel", &"veu", [
			{&"tipo": &"velocidade_pct", &"valor": 0.12, &"escala": true, &"params": {}},
			{&"tipo": &"cargas_esquiva", &"valor": 1.0, &"escala": false, &"params": {}},
		], &""],
		[&"trad_transmutation_molde_vivo", &"transmutacao", [{&"tipo": &"golpe_queimadura", &"valor": 1.0, &"escala": true, &"params": {}}], &""],
		[&"trad_transmutation_forma_fixa", &"transmutacao", [
			{&"tipo": &"dano_selo_pct", &"valor": 0.60, &"escala": true, &"params": {}},
			{&"tipo": &"selo_abala", &"valor": 1.0, &"escala": false, &"params": {&"duracao_s": 0.5}},
		], &""],
		[&"trad_transmutation_materia_residual", &"transmutacao", [{&"tipo": &"explosao_ao_abater", &"valor": 12.0, &"escala": true, &"params": {&"raio_px": 150.0, &"empurrao": 720.0}}], &""],
		[&"trad_pacts_primeiro_vinculo", &"pactos", [{&"tipo": &"cura_ao_abater", &"valor": 2.0, &"escala": true, &"params": {}}], &""],
		[&"trad_pacts_os_que_ficam", &"pactos", [{&"tipo": &"recusas_morte", &"valor": 1.0, &"escala": false, &"params": {&"vida_ao_voltar": 0.4, &"invuln_s": 2.0}}], &""],
		[&"trad_pacts_fardo_repartido", &"pactos", [{&"tipo": &"refletir_dano", &"valor": 3.0, &"escala": true, &"params": {}}], &""],
	]
	var out: Array[BoonDef] = []
	for item_spec: Array in specs:
		var id_b: StringName = item_spec[0]
		var dout: StringName = item_spec[1]
		var efs_raw: Array = item_spec[2]
		var preco: StringName = item_spec[3]
		var b := BoonDef.new()
		b.id = id_b
		b.doutrina = dout
		var upper := String(id_b).to_upper()
		b.chave_nome = StringName(upper + "_NAME")
		b.chave_descricao = StringName(upper + "_DESC")
		b.glifo = StringName("glifo_%s" % dout)
		b.icone_ganho = "res://assets/art/export/glifo_%s.png" % dout
		b.chave_preco = preco
		for ed: Dictionary in efs_raw:
			var ef := EffectDef.new()
			ef.tipo = ed[&"tipo"]
			ef.valor = float(ed[&"valor"])
			ef.escala_com_raridade = bool(ed[&"escala"])
			var p_map: Dictionary[StringName, float] = {}
			var p_in: Dictionary = ed[&"params"]
			for k: Variant in p_in:
				p_map[StringName(str(k))] = float(p_in[k])
			ef.params = p_map
			b.efeitos.append(ef)
		out.append(b)
	return out


func _criar_elite_rules() -> EliteRules:
	var er := EliteRules.new()
	er.id = &"elite_rules"
	er.mult_vida = 2.4
	er.mult_dano = 1.25
	er.mult_raio = 1.2
	er.resistencia_empurrao = 0.4
	er.profundidade_minima = 3
	er.max_elites_onda = 2
	var c := LinearCurveDef.new()
	c.x_min = 3.0
	c.base = 0.05
	c.slope = 0.02
	c.y_floor = 0.0
	c.y_cap = 0.25
	c.sem_teto = false
	er.curva_chance = c
	return er


func _criar_combat_tuning() -> CombatTuning:
	var ct := CombatTuning.new()
	ct.id = &"combat_tuning"
	ct.hitstop_leve_s = 3.0 / 60.0
	ct.hitstop_pesado_s = 6.0 / 60.0
	ct.hitstop_abate_s = 4.0 / 60.0
	ct.hitstop_atingido_s = 6.0 / 60.0
	ct.hitstop_abate_chefe_s = 36.0 / 60.0
	ct.hitstop_recusa_s = 18.0 / 60.0
	ct.empurrao_pesado = 900.0
	ct.limiar_finalizador = 1.2
	ct.janela_combo_s = 34.0 / 60.0
	ct.recuperacao_max_s = 12.0 / 60.0
	ct.fator_recuperacao_golpe = 0.5
	ct.passo_apoio_px = 10.5
	ct.folga_encostado_px = 6.0
	ct.nascimento_projetil_px = 36.0
	ct.invuln_extra_investida_s = 2.0 / 60.0
	ct.cambaleio_s = 8.0 / 60.0
	ct.fator_cambaleio = 0.4
	ct.quebrou_recuperacao_s = 24.0 / 60.0
	ct.parede_vel_min = 630.0
	ct.parede_dano = 8.0
	ct.queda_empurrao = 0.78
	ct.empurrao_zero = 4.5
	ct.invuln_atingido_s = 40.0 / 60.0
	ct.passes_varredura = 4
	ct.fator_guarda = 0.5
	ct.giro_leque_graus = 12.0
	ct.fator_raio_obstaculo_projetil = 0.5
	ct.flash_acerto_s = 5.0 / 60.0
	ct.extra_inversao_s = 4.0 / 60.0
	ct.impact_chefe_s = 12.0 / 60.0
	return ct


func _criar_camera_tuning() -> CameraTuning:
	var c := CameraTuning.new()
	c.id = &"camera_tuning"
	c.meia_vida = 0.12
	c.lookahead_max = 120.0
	c.raio_mouse = 480.0
	c.teto_deslocamento = 40.0
	c.teto_zoom = 1.15
	c.limiar_descarte = 0.05
	c.max_impulsos = 16
	c.parallax_primeiro_plano = 1.2
	return c


func _criar_input_tuning() -> InputTuning:
	var t := InputTuning.new()
	t.id = &"input_tuning"
	t.buffer_passos = 10
	t.zona_morta_interna = 0.20
	t.zona_morta_externa = 0.05
	t.raio_mira_px = 540.0
	t.limiar_mouse_px = 4.0
	t.gatilho_aperta = 0.50
	t.gatilho_solta = 0.40
	return t


func _criar_status_tuning() -> StatusTuning:
	var s := StatusTuning.new()
	s.id = &"status_tuning"
	s.duracao_sangramento_s = 3.0
	s.dano_sangramento_s = 2.4
	s.max_acumulos_sangramento = 5
	s.duracao_queimadura_s = 2.5
	s.dano_queimadura_s = 4.8
	s.max_acumulos_queimadura = 5
	s.duracao_abalo_s = 3.0
	s.reducao_dano_causado = 0.30
	s.intervalo_numero_s = 0.50
	return s


func _criar_modifiers_tuning() -> ModifiersTuning:
	var m := ModifiersTuning.new()
	m.id = &"modifiers_tuning"
	m.piso_vida_jogador = 20.0
	m.piso_vida_inimigo = 1.0
	m.teto_reducao_dano = 0.60
	m.teto_multiplicador_dano = 4.0
	m.fator_empurrao_chefe = 0.12
	m.piso_vida_maldicao = 20.0
	m.tipos_propagados_maldicao = [&"dano_todo_pct", &"velocidade_pct"]
	m.fator_propagacao_maldicao = 1.0
	return m


func _criar_movement_tuning() -> MovementTuning:
	var m := MovementTuning.new()
	m.id = &"movement_tuning"
	m.cargas_base = 1
	m.duracao_esquiva_s = 9.0 / 60.0
	m.velocidade_esquiva_pxs = 1140.0
	m.invuln_extra_s = 3.0 / 60.0
	m.recarga_s = 38.0 / 60.0
	m.fator_recuperacao = 0.40
	m.raio_jogador_px = 21.0
	m.alvos_max_corte = 0
	return m


func _criar_sons_p0() -> Array[SomDef]:
	var lista: Array = [
		[&"sfx_telegrafo_disparo", "res://assets/audio/sfx/sfx_telegrafo_disparo.wav", &"Efeitos", 0.0, []],
		[&"sfx_telegrafo_tom", "res://assets/audio/sfx/sfx_telegrafo_tom.wav", &"Efeitos", -3.0, []],
		[&"sfx_jogador_atingido", "res://assets/audio/sfx/sfx_jogador_atingido.wav", &"Efeitos", 0.0, []],
		[&"sfx_acerto_leve", "res://assets/audio/sfx/sfx_acerto_leve.wav", &"Efeitos", -1.5, [
			"res://assets/audio/sfx/sfx_acerto_leve_2.wav",
			"res://assets/audio/sfx/sfx_acerto_leve_3.wav",
		]],
		[&"sfx_acerto_pesado", "res://assets/audio/sfx/sfx_acerto_pesado.wav", &"Efeitos", 0.0, []],
		[&"sfx_quebrou", "res://assets/audio/sfx/sfx_quebrou.wav", &"Efeitos", 0.0, []],
		[&"sfx_maldicao_recusa", "res://assets/audio/sfx/sfx_maldicao_recusa.wav", &"Efeitos", -2.0, []],
		[&"sfx_carta_foco", "res://assets/audio/sfx/sfx_carta_foco.wav", &"Interface", -3.0, []],
		[&"sfx_carta_confirmar", "res://assets/audio/sfx/sfx_carta_confirmar.wav", &"Interface", 0.0, []],
		[&"sfx_chefe_surgimento", "res://assets/audio/sfx/sfx_chefe_surgimento.wav", &"Efeitos", 0.0, []],
	]
	var out: Array[SomDef] = []
	for item: Array in lista:
		var s := SomDef.new()
		s.id = item[0]
		s.caminho_stream = item[1]
		s.barramento = item[2]
		s.ganho_db = float(item[3])
		s.pitch_min = 0.95
		s.pitch_max = 1.05
		var vars_arr: Array[String] = []
		for v_str: String in item[4]:
			vars_arr.append(v_str)
		s.variacoes = vars_arr
		out.append(s)
	return out
