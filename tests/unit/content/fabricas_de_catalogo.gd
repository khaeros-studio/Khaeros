class_name FabricasDeCatalogo
extends RefCounted
## Fábricas de dados de teste do épico Conteúdo (fixtures). Os números daqui são
## valores de fábrica dos GDDs donos (placeholders do cânone e valores da emenda
## Pactos), usados só em testes.

## Tabela esperada de campos @export próprios de cada classe (sem os da base
## DefinicaoBase: id, obsoleto). Fonte: GDD de Conteúdo R1/R1-P e GDDs donos.
const CAMPOS_ESPERADOS: Dictionary = {
	"WeaponDef": ["doutrina", "chave_nome", "vida_max", "velocidade", "ataque", "especial"],
	"AttackDef": ["chave_nome", "forma", "params", "leque", "atravessa", "dano", "recarga_s", "preparo_s", "empurrao", "status", "multiplicadores_combo", "guarda_s"],
	"EnemyDef": ["chave_nome", "comportamento", "vida", "velocidade", "raio_px", "dano", "alcance_px", "preparo_s", "recarga_s", "velocidade_projetil", "custo_onda", "padroes"],
	"BossPatternDef": ["chave_nome", "forma_telegrafo", "dimensoes", "preparo_s", "execucao_s", "recarga_s", "dano", "efeitos", "raio_secundario_px"],
	"LinearCurveDef": ["x_min", "base", "slope", "y_floor", "y_cap", "sem_teto"],
	"EliteRules": ["mult_vida", "mult_dano", "mult_raio", "resistencia_empurrao", "profundidade_minima", "max_elites_onda", "curva_chance"],
	"EffectDef": ["tipo", "valor", "escala_com_raridade", "params"],
	"BoonDef": ["doutrina", "chave_nome", "chave_descricao", "efeitos", "glifo", "icone_ganho", "chave_preco"],
	"RarityTable": ["escalas", "pesos"],
	"RegionDef": ["chave_nome", "camaras", "pool_inimigos", "chefe", "fragmentos_chefe"],
	"RewardTable": ["pesos_portas", "chance_tres_portas", "primeira_recompensa", "profundidade_min_provacao", "cura_porta", "fragmentos_porta_base", "fragmentos_porta_passo"],
	"EconomyRates": ["fragmentos_provacao", "saldo_max"],
	"UpgradeDef": ["chave_nome", "custos", "efeitos"],
	"CurseDef": ["chave_nome", "raridade", "vida_max", "velocidade", "raio_px", "forma_basica", "alcance_basico_px", "dano_basico", "empurrao_basico", "preparo_s", "execucao_s", "recuperacao_s", "efeito_saida", "efeito_entrada", "bonus_sinergia_pct", "passivas", "efeito_chamado", "habilidade_unica", "chefe_origem_id", "memorias"],
	"HudTuning": ["vida_por_segmento", "segmento_px", "barra_max_frac", "vida_baixa_pct", "vida_baixa_histerese", "vinheta_max_borda", "vinheta_opacidade_max", "janela_ganho_s", "fio_visivel_s", "largura_fio", "fio_elite_escala", "esquiva_tremor_ms", "fade_estado_s", "margem_segura_px", "pacto_tremor_px", "pacto_tremor_s", "pacto_intervalo_px"],
	"TelaBencaoTuning": ["trava_confirmar_ms", "trava_troca_ms", "entrada_s", "anim_troca_s", "anim_confirmar_s", "foco_escala", "foco_sobe_px", "valor_nao_focada", "intervalo_cartas_px", "tremor_botao_ms"],
	"FeedbackTuning": ["janela_soma_s", "teto_numeros", "limiar_degradacao", "limiar_retorno", "limiar_nivel2", "retorno_nivel2", "vozes_max_gancho", "vozes_max_total", "assenta_camara_s"],
	"TelemetriaTuning": ["max_bytes_sessao", "max_sessoes", "orcamento_linha_ms", "orcamento_passo_ms", "casas_decimais_duracao"],
	"RunTuning": ["camaras_jogaveis", "fragmentos_vitoria", "arma_padrao"],
	"BencaosTuning": ["tamanho_oferta", "trocas_iniciais", "raridade_bonus"],
	"ArmasTuning": ["meta_paridade", "margem_fragil", "g_max_fragil", "periodos_trava", "f_esp_min", "f_esp_max", "vel_media_min", "vel_media_max", "p_max"],
	"StatusTuning": ["duracao_sangramento_s", "dano_sangramento_s", "max_acumulos_sangramento", "duracao_queimadura_s", "dano_queimadura_s", "max_acumulos_queimadura", "duracao_abalo_s", "reducao_dano_causado", "intervalo_numero_s"],
	"MaldicoesTuning": ["alcance_fio_px", "distancia_seguir_px", "alcance_chamado_px", "duracao_salto_s", "raio_chamado_px", "raio_atracao_px", "duracao_imobilizar_s", "duracao_atracao_s", "recarga_troca_s", "recuperacao_exausta_s", "vida_retorno_frac", "regen_reserva_frac_s"],
	"ChefesTuning": ["espera_inicial_chefe_s", "espera_entre_padroes_chefe_s", "limiar_furia_frac", "fator_recarga_furia", "mult_velocidade_furia", "transicao_fase_s", "raio_pulso_furia_px", "empurrao_pulso_furia_px", "raio_puxao_px", "puxao_convergencia_px", "max_lacaios_vivos", "lacaios_por_convergencia", "dist_spawn_lacaio_px"],
	"VinculoTuning": ["especie_primeiro_pacto", "chance_encontro", "pity_runs", "indices_encontro", "chance_nao_pactuada", "peso_raridade", "pontos_acuada", "frac_vida_acuada", "encontros_para_consentir", "pts_camara", "pts_abate", "pts_tecnica", "pts_vitoria", "teto_abates_run", "teto_tecnicas_run", "pts_reafirmar", "pts_reafirmar_chefe", "limiares_nivel", "nivel_max", "pontos_teto", "bonus_vida", "mult_recuperacao", "bonus_dano_basico", "memorias_por_raridade"],
	"VisualTuning": ["forca_grading_personagem", "saturacao_bencao", "valor_bencao", "passo_profundidade", "piso_profundidade", "opacidade_max_feixes", "ciclo_veio_s", "amplitude_veio", "duracao_flash_telegrafo_s", "contorno_telegrafo_px", "contorno_telegrafo_alto_px", "traco_secundario_px", "intervalo_secundario_px", "largura_fio_px", "opacidade_fio", "ciclo_fio_estourado_s", "raio_marca_virote_px", "largura_anel_px", "opacidade_base_telegrafo", "largura_tracejado_px", "traco_tracejado_px", "intervalo_tracejado_px", "contorno_silhueta_px", "opacidade_oclusao", "duracao_transicao_oclusao_s", "margem_histerese_oclusao_px", "duracao_wipe_s", "duracao_fade_s", "dt_max_apres", "teto_drawcalls_passes"],
	"WaveRules": ["orcamento_base", "orcamento_por_prof", "orcamento_por_regiao", "ondas_limites", "max_inimigos_onda", "intervalo_onda_s"],
	"RoomTuning": ["camara_largura_px", "camara_altura_px", "obstaculos_min", "obstaculos_var", "obstaculo_raio_min_px", "obstaculo_passos", "folga_obstaculo_px", "obstaculo_tentativas", "spawn_candidatos", "spawn_dist_jogador_px", "spawn_margem_px", "spawn_folga_pedra_px", "portas_espaco_px", "portas_y_px", "porta_raio_px", "entrada_px", "interagir_folga_px", "santuario_cura", "spawn_dist_acuada_px"],
}

const ESPECIES: Array[StringName] = [&"vulto_mudo", &"espreitador_da_fenda", &"baluarte_de_cinza", &"soberano_do_limiar"]
const RARIDADES: Array[StringName] = [&"comum", &"refinado", &"raro", &"primordial"]


## Instância nova de cada classe da tabela, por nome.
static func instancias_por_classe() -> Dictionary:
	return {
		"WeaponDef": WeaponDef.new(), "AttackDef": AttackDef.new(), "EnemyDef": EnemyDef.new(),
		"BossPatternDef": BossPatternDef.new(), "LinearCurveDef": LinearCurveDef.new(),
		"EliteRules": EliteRules.new(), "EffectDef": EffectDef.new(), "BoonDef": BoonDef.new(),
		"RarityTable": RarityTable.new(), "RegionDef": RegionDef.new(), "RewardTable": RewardTable.new(),
		"EconomyRates": EconomyRates.new(), "UpgradeDef": UpgradeDef.new(), "CurseDef": CurseDef.new(),
		"HudTuning": HudTuning.new(), "TelaBencaoTuning": TelaBencaoTuning.new(),
		"FeedbackTuning": FeedbackTuning.new(), "TelemetriaTuning": TelemetriaTuning.new(),
		"RunTuning": RunTuning.new(), "BencaosTuning": BencaosTuning.new(), "ArmasTuning": ArmasTuning.new(),
		"StatusTuning": StatusTuning.new(), "MaldicoesTuning": MaldicoesTuning.new(),
		"ChefesTuning": ChefesTuning.new(), "VinculoTuning": VinculoTuning.new(),
		"VisualTuning": VisualTuning.new(), "WaveRules": WaveRules.new(), "RoomTuning": RoomTuning.new(),
	}


## Nomes das propriedades @export (script, armazenadas) de um recurso.
static func campos_exportados(r: Resource) -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in r.get_property_list():
		var uso: int = p["usage"]
		if (uso & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (uso & PROPERTY_USAGE_STORAGE) != 0:
			out.append(String(p["name"]))
	return out


static func ataque(forma: StringName, chave: StringName, dano: float, recarga: float) -> AttackDef:
	var a := AttackDef.new()
	a.chave_nome = chave
	a.forma = forma
	a.dano = dano
	a.recarga_s = recarga
	a.empurrao = 450.0
	return a


static func arma(id: StringName, vida: int, especial_forma: StringName) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = id
	w.doutrina = id
	w.chave_nome = StringName("WEAPON_%s_NAME" % String(id).to_upper())
	w.vida_max = vida
	w.velocidade = 387.0
	var chave_atk := StringName("WEAPON_%s_ATK" % String(id).to_upper())
	var chave_esp := StringName("WEAPON_%s_ESP" % String(id).to_upper())
	if id == &"lamina":
		w.velocidade = 387.0
		w.ataque = ataque(&"arco", chave_atk, 14.0, 16.0 / 60.0)
		w.ataque.multiplicadores_combo = PackedFloat64Array([1.0, 1.0, 1.8])
		w.especial = ataque(especial_forma, chave_esp, 26.0, 70.0 / 60.0)
	elif id == &"ressonancia":
		w.velocidade = 378.0
		w.ataque = ataque(&"projetil", chave_atk, 12.0, 14.0 / 60.0)
		w.especial = ataque(especial_forma, chave_esp, 30.0, 90.0 / 60.0)
	elif id == &"pactos":
		w.velocidade = 382.5
		w.ataque = ataque(&"projetil", chave_atk, 10.0, 15.0 / 60.0)
		w.ataque.empurrao = 360.0
		w.especial = ataque(especial_forma, chave_esp, 17.0, 120.0 / 60.0)
		w.especial.empurrao = 0.0
	else:
		w.ataque = ataque(&"arco", chave_atk, 14.0, 16.0 / 60.0)
		w.especial = ataque(especial_forma, chave_esp, 26.0, 70.0 / 60.0)
	return w


static func inimigo(id: StringName, comportamento: StringName = &"corpo_a_corpo") -> EnemyDef:
	var e := EnemyDef.new()
	e.id = id
	e.chave_nome = StringName("ENEMY_%s_NAME" % String(id).to_upper())
	e.comportamento = comportamento
	e.vida = 30.0
	e.velocidade = 153.0
	e.raio_px = 24.0
	e.dano = 9.0
	e.alcance_px = 45.0
	e.preparo_s = 26.0 / 60.0
	e.recarga_s = 1.0
	e.custo_onda = 1
	return e


static func padrao(forma: StringName, indice: int) -> BossPatternDef:
	var p := BossPatternDef.new()
	p.chave_nome = StringName("BOSS_SOBERANO_P%d" % indice)
	p.forma_telegrafo = forma
	match indice:
		1:
			p.dimensoes = {&"raio_px": 165.0}
			p.preparo_s = 30.0 / 60.0
			p.execucao_s = 10.0 / 60.0
			p.recarga_s = 60.0 / 60.0
			p.dano = 16.0
		2:
			p.dimensoes = {&"raio_px": 207.0}
			p.preparo_s = 36.0 / 60.0
			p.execucao_s = 24.0 / 60.0
			p.recarga_s = 75.0 / 60.0
			p.dano = 18.0
		3:
			p.dimensoes = {&"r_ext": 210.0}
			p.preparo_s = 36.0 / 60.0
			p.execucao_s = 12.0 / 60.0
			p.recarga_s = 90.0 / 60.0
			p.dano = 15.0
		_:
			p.dimensoes = {&"raio_px": 225.0}
			p.preparo_s = 42.0 / 60.0
			p.execucao_s = 12.0 / 60.0
			p.recarga_s = 105.0 / 60.0
			p.dano = 14.0
			p.raio_secundario_px = 420.0
	return p


static func chefe_soberano() -> EnemyDef:
	var e := inimigo(&"soberano_do_limiar", &"chefe")
	e.vida = 700.0
	e.velocidade = 162.0
	e.raio_px = 45.0
	e.dano = 16.0
	var formas: Array[StringName] = [&"setor", &"retangulo", &"anel", &"circulo"]
	for i in formas.size():
		e.padroes.append(padrao(formas[i], i + 1))
	return e


static func maldicao(id: StringName, raridade: StringName) -> CurseDef:
	var c := CurseDef.new()
	c.id = id
	c.chave_nome = StringName("CURSE_%s_NAME" % String(id).to_upper())
	c.raridade = raridade
	c.forma_basica = &"arco"
	c.efeito_saida = &"saida_padrao"
	c.efeito_entrada = &"entrada_padrao"
	match id:
		&"vulto_mudo":
			c.vida_max = 110.0
			c.velocidade = 405.0
			c.raio_px = 24.0
			c.alcance_basico_px = 105.0
			c.dano_basico = 9.0
			c.empurrao_basico = 360.0
			c.preparo_s = 8.0 / 60.0
			c.execucao_s = 6.0 / 60.0
			c.recuperacao_s = 16.0 / 60.0
			c.memorias = PackedStringArray(["CURSE_VULTO_MEM_1"])
		&"espreitador_da_fenda":
			c.vida_max = 95.0
			c.velocidade = 435.0
			c.raio_px = 22.5
			c.alcance_basico_px = 112.5
			c.dano_basico = 7.65
			c.empurrao_basico = 300.0
			c.preparo_s = 6.0 / 60.0
			c.execucao_s = 5.0 / 60.0
			c.recuperacao_s = 14.0 / 60.0
			c.bonus_sinergia_pct = 0.50
			c.passivas = [&"faro_do_vinculo"]
			c.memorias = PackedStringArray(["CURSE_ESP_MEM_1", "CURSE_ESP_MEM_2"])
		&"baluarte_de_cinza":
			c.vida_max = 135.0
			c.velocidade = 360.0
			c.raio_px = 30.0
			c.forma_basica = &"circulo"
			c.alcance_basico_px = 96.0
			c.dano_basico = 12.6
			c.empurrao_basico = 900.0
			c.preparo_s = 12.0 / 60.0
			c.execucao_s = 8.0 / 60.0
			c.recuperacao_s = 22.0 / 60.0
			c.passivas = [&"carapaca_ancorada"]
			c.efeito_chamado = &"eco_de_muralha"
			c.memorias = PackedStringArray(["CURSE_BAL_MEM_1", "CURSE_BAL_MEM_2", "CURSE_BAL_MEM_3"])
		&"soberano_do_limiar":
			c.vida_max = 120.0
			c.velocidade = 390.0
			c.raio_px = 28.5
			c.alcance_basico_px = 120.0
			c.dano_basico = 9.8
			c.empurrao_basico = 540.0
			c.preparo_s = 9.0 / 60.0
			c.execucao_s = 6.0 / 60.0
			c.recuperacao_s = 21.0 / 60.0
			c.bonus_sinergia_pct = 0.50
			c.passivas = [&"presenca_do_limiar", &"vinculo_inquebravel"]
			c.efeito_chamado = &"convergencia"
			c.habilidade_unica = &"pulso_de_soberania"
			c.chefe_origem_id = &"soberano_do_limiar"
			c.memorias = PackedStringArray(["CURSE_SOB_MEM_1", "CURSE_SOB_MEM_2", "CURSE_SOB_MEM_3", "CURSE_SOB_MEM_4"])
		_:
			c.vida_max = 110.0
			c.velocidade = 405.0
			c.raio_px = 24.0
			c.alcance_basico_px = 105.0
			c.dano_basico = 9.0
			c.preparo_s = 8.0 / 60.0
			c.execucao_s = 6.0 / 60.0
			c.recuperacao_s = 16.0 / 60.0
			if raridade == &"primordial":
				c.passivas = [&"p1", &"p2"]
				c.efeito_chamado = &"ec"
				c.habilidade_unica = &"hu"
				c.chefe_origem_id = &"soberano_do_limiar"
	return c


static func maldicoes_tuning() -> MaldicoesTuning:
	var m := MaldicoesTuning.new()
	m.id = &"maldicoes_tuning"
	m.alcance_fio_px = 480.0
	m.distancia_seguir_px = 105.0
	m.alcance_chamado_px = 420.0
	m.duracao_salto_s = 0.20
	m.raio_chamado_px = 135.0
	m.raio_atracao_px = 210.0
	m.duracao_imobilizar_s = 1.50
	m.duracao_atracao_s = 1.50
	m.recarga_troca_s = 4.00
	m.recuperacao_exausta_s = 10.00
	m.vida_retorno_frac = 0.50
	m.regen_reserva_frac_s = 0.05
	return m


static func chefes_tuning() -> ChefesTuning:
	var c := ChefesTuning.new()
	c.id = &"chefes_tuning"
	c.espera_inicial_chefe_s = 0.50
	c.espera_entre_padroes_chefe_s = 0.25
	c.limiar_furia_frac = 0.50
	c.fator_recarga_furia = 0.60
	c.mult_velocidade_furia = 1.15
	c.transicao_fase_s = 0.50
	c.raio_pulso_furia_px = 240.0
	c.empurrao_pulso_furia_px = 120.0
	c.raio_puxao_px = 420.0
	c.puxao_convergencia_px = 75.0
	c.max_lacaios_vivos = 3
	c.lacaios_por_convergencia = 2
	c.dist_spawn_lacaio_px = 135.0
	return c


static func hud_tuning() -> HudTuning:
	var h := HudTuning.new()
	h.id = &"hud_tuning"
	h.vida_por_segmento = 10
	h.segmento_px = 32
	h.barra_max_frac = 0.25
	h.vida_baixa_pct = 0.25
	h.vida_baixa_histerese = 0.05
	h.vinheta_max_borda = 0.08
	h.vinheta_opacidade_max = 0.40
	h.janela_ganho_s = 1.5
	h.fio_visivel_s = 2.0
	h.largura_fio = 48
	h.fio_elite_escala = 1.5
	h.esquiva_tremor_ms = 80
	h.fade_estado_s = 0.25
	h.margem_segura_px = 48
	h.pacto_tremor_px = 4
	h.pacto_tremor_s = 0.15
	h.pacto_intervalo_px = 12
	return h


static func tela_bencao_tuning() -> TelaBencaoTuning:
	var t := TelaBencaoTuning.new()
	t.id = &"tela_bencao_tuning"
	t.trava_confirmar_ms = 500
	t.trava_troca_ms = 300
	t.entrada_s = 0.45
	t.anim_troca_s = 0.30
	t.anim_confirmar_s = 0.60
	t.foco_escala = 1.06
	t.foco_sobe_px = 12
	t.valor_nao_focada = 0.70
	t.intervalo_cartas_px = 48
	t.tremor_botao_ms = 80
	return t


static func feedback_tuning() -> FeedbackTuning:
	var f := FeedbackTuning.new()
	f.id = &"feedback_tuning"
	f.janela_soma_s = 0.30
	f.teto_numeros = 6
	f.limiar_degradacao = 0.90
	f.limiar_retorno = 0.75
	f.limiar_nivel2 = 0.95
	f.retorno_nivel2 = 0.85
	f.vozes_max_gancho = 4
	f.vozes_max_total = 16
	f.assenta_camara_s = 1.0
	return f


static func telemetria_tuning() -> TelemetriaTuning:
	var t := TelemetriaTuning.new()
	t.id = &"telemetria_tuning"
	t.max_bytes_sessao = 2097152
	t.max_sessoes = 20
	t.orcamento_linha_ms = 1.0
	t.orcamento_passo_ms = 3.0
	t.casas_decimais_duracao = 2
	return t


static func run_tuning() -> RunTuning:
	var rt := RunTuning.new()
	rt.id = &"run_tuning"
	rt.arma_padrao = &"pactos"
	rt.fragmentos_vitoria = 15
	rt.camaras_jogaveis = {&"limiar": 7}
	return rt


static func bencaos_tuning() -> BencaosTuning:
	var b := BencaosTuning.new()
	b.id = &"bencaos_tuning"
	b.tamanho_oferta = 3
	b.trocas_iniciais = 0
	b.raridade_bonus = 0.0
	return b


static func armas_tuning() -> ArmasTuning:
	var a := ArmasTuning.new()
	a.id = &"armas_tuning"
	a.meta_paridade = 0.15
	a.margem_fragil = 2
	a.g_max_fragil = 3
	a.periodos_trava = 2
	a.f_esp_min = 0.15
	a.f_esp_max = 0.40
	a.vel_media_min = 360.0
	a.vel_media_max = 400.0
	a.p_max = 4
	return a


static func visual_tuning() -> VisualTuning:
	var v := VisualTuning.new()
	v.id = &"visual_tuning"
	v.forca_grading_personagem = 0.15
	v.saturacao_bencao = 0.20
	v.valor_bencao = 0.60
	v.passo_profundidade = 0.03
	v.piso_profundidade = 0.85
	v.opacidade_max_feixes = 0.20
	v.ciclo_veio_s = 2.0
	v.amplitude_veio = 0.10
	v.duracao_flash_telegrafo_s = 2.0 / 60.0
	v.contorno_telegrafo_px = 4.0
	v.contorno_telegrafo_alto_px = 6.0
	v.traco_secundario_px = 16.0
	v.intervalo_secundario_px = 10.0
	v.largura_fio_px = 2.0
	v.opacidade_fio = 0.60
	v.ciclo_fio_estourado_s = 0.50
	v.raio_marca_virote_px = 9.0
	v.largura_anel_px = 6.0
	v.opacidade_base_telegrafo = 0.25
	v.largura_tracejado_px = 1.75
	v.traco_tracejado_px = 8.0
	v.intervalo_tracejado_px = 6.0
	v.contorno_silhueta_px = 3.0
	v.opacidade_oclusao = 0.40
	v.duracao_transicao_oclusao_s = 0.10
	v.margem_histerese_oclusao_px = 8.0
	v.duracao_wipe_s = 0.40
	v.duracao_fade_s = 0.30
	v.dt_max_apres = 0.10
	v.teto_drawcalls_passes = 6
	return v


static func wave_rules() -> WaveRules:
	var w := WaveRules.new()
	w.id = &"wave_rules"
	w.orcamento_base = 3.0
	w.orcamento_por_prof = 0.9
	w.orcamento_por_regiao = 2.0
	w.ondas_limites = PackedInt64Array([2, 6])
	w.max_inimigos_onda = 9
	w.intervalo_onda_s = 0.0
	return w


static func room_tuning() -> RoomTuning:
	var r := RoomTuning.new()
	r.id = &"room_tuning"
	r.camara_largura_px = 1920.0
	r.camara_altura_px = 1080.0
	r.obstaculos_min = 2
	r.obstaculos_var = 3
	r.obstaculo_raio_min_px = 42.0
	r.obstaculo_passos = 26
	r.folga_obstaculo_px = 105.0
	r.obstaculo_tentativas = 10
	r.spawn_candidatos = 14
	r.spawn_dist_jogador_px = 390.0
	r.spawn_margem_px = 111.0
	r.spawn_folga_pedra_px = 12.0
	r.portas_espaco_px = 450.0
	r.portas_y_px = 177.0
	r.porta_raio_px = 69.0
	r.entrada_px = PackedFloat64Array([960.0, 930.0])
	r.interagir_folga_px = 15.0
	r.santuario_cura = 0.40
	r.spawn_dist_acuada_px = 240.0
	return r


static func reward_table() -> RewardTable:
	var r := RewardTable.new()
	r.id = &"reward_table"
	r.pesos_portas = {&"bencao": 3.0, &"fragmentos": 2.0, &"cura": 1.0, &"provacao": 0.0}
	r.chance_tres_portas = 0.30
	r.primeira_recompensa = &"bencao"
	r.profundidade_min_provacao = 2
	r.cura_porta = 0.30
	r.fragmentos_porta_base = 2
	r.fragmentos_porta_passo = 3
	return r


static func economy_rates() -> EconomyRates:
	var e := EconomyRates.new()
	e.id = &"economy_rates"
	e.fragmentos_provacao = 3
	e.saldo_max = 999999
	return e


static func vinculo_tuning() -> VinculoTuning:
	var v := VinculoTuning.new()
	v.id = &"vinculo_tuning"
	v.especie_primeiro_pacto = &"vulto_mudo"
	v.chance_encontro = 0.6
	v.pity_runs = 2
	v.indices_encontro = PackedInt64Array([1, 2])
	v.chance_nao_pactuada = 0.75
	v.peso_raridade = PackedFloat64Array([3.0, 2.0, 1.0, 1.0])
	v.pontos_acuada = 5
	v.frac_vida_acuada = 1.2
	v.encontros_para_consentir = PackedInt64Array([1, 1, 2, 2, 1])
	v.pts_camara = 2
	v.pts_abate = 1
	v.pts_tecnica = 1
	v.pts_vitoria = 8
	v.teto_abates_run = 12
	v.teto_tecnicas_run = 6
	v.pts_reafirmar = 6
	v.pts_reafirmar_chefe = 10
	v.limiares_nivel = PackedInt64Array([20, 50, 90, 140])
	v.nivel_max = 5
	v.pontos_teto = 9999
	v.bonus_vida = 0.05
	v.mult_recuperacao = 0.90
	v.bonus_dano_basico = 0.05
	v.memorias_por_raridade = PackedInt64Array([1, 2, 3, 4, 4])
	return v


## Catálogo de fábrica do MVP de Pactos (AC-52, AC-53): armas, inimigos, chefe com 4
## padrões, 4 espécies, região limiar e todos os tunings de fábrica.
static func itens_mvp() -> Array[ItemDoCatalogo]:
	var defs: Array[DefinicaoBase] = []
	defs.append(arma(&"lamina", 100, &"avanco"))
	defs.append(arma(&"ressonancia", 80, &"circulo"))
	defs.append(arma(&"pactos", 90, &"chamado"))
	defs.append(inimigo(&"eco_perdido"))
	defs.append(inimigo(&"anomalia_maior", &"chefe"))
	defs.append(chefe_soberano())
	for i in ESPECIES.size():
		defs.append(maldicao(ESPECIES[i], RARIDADES[i]))
	var r := RegionDef.new()
	r.id = &"limiar"
	r.chave_nome = &"REGION_LIMIAR_NAME"
	r.camaras = [&"combate", &"combate", &"combate", &"santuario", &"combate", &"combate", &"chefe"]
	r.pool_inimigos = [&"eco_perdido"]
	r.chefe = &"soberano_do_limiar"
	defs.append(r)
	defs.append(maldicoes_tuning())
	defs.append(vinculo_tuning())
	defs.append(chefes_tuning())
	defs.append(hud_tuning())
	defs.append(tela_bencao_tuning())
	defs.append(feedback_tuning())
	defs.append(telemetria_tuning())
	defs.append(run_tuning())
	defs.append(bencaos_tuning())
	defs.append(armas_tuning())
	defs.append(visual_tuning())
	defs.append(wave_rules())
	defs.append(room_tuning())
	defs.append(reward_table())
	defs.append(economy_rates())
	var st := StatusTuning.new()
	st.id = &"status_tuning"
	st.reducao_dano_causado = 0.3
	defs.append(st)
	var out: Array[ItemDoCatalogo] = []
	for i in defs.size():
		var d := defs[i]
		out.append(ItemDoCatalogo.new(d.tipo_do_catalogo(), "res://teste/%s/%s.tres" % [d.tipo_do_catalogo(), d.id], i, d))
	return out


## Validadores de todos os donos registrados no MVP (story 006).
static func validadores_dos_donos() -> Array[ValidadorDoDono]:
	return [
		RegrasRn.new(), RegrasBn.new(), RegrasAv.new(), RegrasHu.new(),
		RegrasTb.new(), RegrasFb.new(), RegrasTl.new(), RegrasEc.new(),
		RegrasPv.new(), RegrasWv.new(), RegrasVv.new(), RegrasMl.new(),
		RegrasVp.new(), RegrasCh.new(),
	]


## Registros de chaves de fábrica (o que os donos registram no MVP de Pactos).
static func registros() -> RegistrosDeChaves:
	var r := RegistrosDeChaves.new()
	r.registrar(&"comportamentos", [&"corpo_a_corpo", &"distancia", &"arremetida", &"chefe"])
	r.registrar(&"formas_de_ataque", [&"arco", &"circulo", &"projetil", &"avanco", &"chamado"])
	r.registrar(&"formas_de_telegrafo", [&"setor", &"retangulo", &"anel", &"circulo"])
	r.registrar(&"status", [&"sangramento", &"queimadura", &"abalo"])
	r.registrar(&"tipos_de_sala", [&"combate", &"santuario", &"chefe"])
	r.registrar(&"tipos_de_recompensa", [&"bencao", &"fragmentos", &"cura", &"provacao"])
	r.registrar(&"tipos_de_efeito", [&"recusas_morte", &"vida_max_plano", &"dano_ataque_pct", &"corte_da_esquiva"])
	r.registrar(&"raridades_de_especie", [&"comum", &"refinado", &"raro", &"epico", &"primordial"])
	r.registrar(&"atributos_portador_maldicao", [&"vida_max", &"velocidade", &"dano_basico"])
	return r


## Tabela de textos falsa que conhece todas as chaves dos itens (texto não vazio).
static func textos_para(itens: Array[ItemDoCatalogo]) -> TabelaDeTextosEmMemoria:
	var t := TabelaDeTextosEmMemoria.new()
	for item in itens:
		EsquemaDeDefinicao.percorrer(item.definicao, func(regra: EsquemaDeDefinicao.RegraDeCampo, valor: Variant, _c: String, _d: DadoDeConteudo) -> void:
			if not regra.chave_texto:
				return
			var chaves: PackedStringArray = []
			if valor is PackedStringArray:
				chaves = valor
			elif String(valor) != "":
				chaves.append(String(valor))
			for k in chaves:
				t.definir(k, "Texto")
				for s in regra.sufixos_derivados:
					t.definir(k + s, "Texto"))
	return t
