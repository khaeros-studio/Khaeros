class_name FabricaDaRun
extends RefCounted
## Fábrica sem estado que monta um [EscopoDaRun] novo a cada início de run (ADR-0015 §1, §2, §3).
## Garante que o reset da Nova run seja satisfeito por construção (sem `reset()` campo a campo).


## Monta um [EscopoDaRun] completo com [Portador] do jogador inicializado pela [param arma_def],
## [RegistroDeBencaos], [Bencaos], [Portas] e [Camaras] interligados.
static func montar(arma_def: WeaponDef, dupla_ids: Array[StringName], seed_da_run: int,
		wave_rules: WaveRules, room_tuning: RoomTuning, reward_table: RewardTable,
		region_def: RegionDef, conta: ContaFragmentos, vinculo: PortaDoVinculoNaRun,
		eventos: EventosDoPasso, orquestrador: Object = null,
		pool_inimigos: Array[EnemyDef] = [], chefe_def: EnemyDef = null,
		boon_defs: Array[BoonDef] = [], rarity_table: RarityTable = null,
		bencaos_tuning: BencaosTuning = null, modifiers_tuning: ModifiersTuning = null) -> EscopoDaRun:
	var escopo := EscopoDaRun.new()
	escopo.arma_def = arma_def
	escopo.dupla_ids = dupla_ids.duplicate()
	escopo.fluxo_max_selo = 100.0
	escopo.fluxo_selo = escopo.fluxo_max_selo

	# 1. Fonte de fluxos da run com a seed nova
	escopo.fonte_fluxos = FonteDeFluxos.new(RelatorDeErrosRng.new())
	var eh_pactos: bool = (arma_def != null and arma_def.doutrina == &"pactos")
	escopo.fonte_fluxos.iniciar_run(seed_da_run, eh_pactos)

	# 2. Portador do jogador com vida_max e velocidade base da arma (TR-armas-003, ADR-0015 §3)
	var mod_tun: ModifiersTuning = modifiers_tuning if modifiers_tuning != null else _modifiers_tuning_padrao()
	var vida_base: float = float(arma_def.vida_max) if (arma_def != null and arma_def.vida_max > 0) else 100.0
	var vel_base: float = arma_def.velocidade if (arma_def != null and arma_def.velocidade > 0.0) else 387.0
	var bases: Dictionary[StringName, float] = {
		Atributos.VIDA_MAX: vida_base,
		Atributos.VELOCIDADE: vel_base,
		Atributos.CARGAS_ESQUIVA: 2.0,
		Atributos.RAIO: 27.0,
	}
	escopo.portador_jogador = Portador.new(escopo.gerador_ids.proximo(), 0, Atributos.Especie.JOGADOR, bases, mod_tun)
	escopo.jogador_ref = JogadorRef.new(0, arma_def)
	escopo.jogador_ref.vida = vida_base
	escopo.jogador_ref.fluxo = escopo.fluxo_max_selo
	escopo.jogador_ref.portador = escopo.portador_jogador

	# 3. Bênçãos da run
	var b_tun: BencaosTuning = bencaos_tuning if bencaos_tuning != null else _bencaos_tuning_padrao()
	var r_tab: RarityTable = rarity_table if rarity_table != null else _rarity_table_padrao()
	var doutrina_id: StringName = arma_def.doutrina if arma_def != null else &"lamina"
	escopo.registro_bencaos = RegistroDeBencaos.new(boon_defs, doutrina_id)
	var sorteio_b := SorteioDeOferta.new(b_tun, r_tab, escopo.portador_jogador)
	escopo.bencaos = Bencaos.new(
		escopo.registro_bencaos, sorteio_b, FluxosDeBencaos.new(escopo.fonte_fluxos),
		escopo.portador_jogador, b_tun, {region_def.id: 0}, eventos
	)

	# 4. Portas e Câmaras da run
	escopo.portas = Portas.new(
		reward_table, FluxosDePortas.new(escopo.fonte_fluxos), conta,
		escopo.bencaos, eventos, room_tuning
	)
	escopo.camaras = Camaras.new(
		wave_rules, room_tuning, region_def,
		FluxosDeCamaras.new(escopo.fonte_fluxos), eventos,
		pool_inimigos, chefe_def, null, FluxosDeIa.new(escopo.fonte_fluxos), escopo.gerador_ids
	)

	# Ligações internas do escopo
	var ref_jog: JogadorRef = escopo.jogador_ref
	escopo.portas.configurar_camaras(escopo.camaras)
	escopo.portas.configurar_vinculo(vinculo)
	escopo.portas.configurar_orquestrador(orquestrador)
	escopo.portas.configurar_jogador(
		escopo.portador_jogador,
		func() -> int: return int(ref_jog.vida),
		func(nv: int) -> void: ref_jog.vida = float(nv)
	)
	escopo.camaras.configurar_orquestrador(orquestrador)
	escopo.camaras.configurar_jogador(
		escopo.portador_jogador,
		func() -> Vector2: return ref_jog.posicao,
		func(np: Vector2) -> void: ref_jog.posicao = np,
		func() -> int: return int(ref_jog.vida),
		func(nv: int) -> void: ref_jog.vida = float(nv)
	)
	if eh_pactos and not dupla_ids.is_empty():
		escopo.estado_maldicoes_run = {"campo": dupla_ids[0], "reserva": dupla_ids[1] if dupla_ids.size() > 1 else &""}

	return escopo


static func _modifiers_tuning_padrao() -> ModifiersTuning:
	var m := ModifiersTuning.new()
	m.piso_vida_jogador = 1.0
	m.piso_vida_inimigo = 1.0
	m.piso_vida_maldicao = 1.0
	m.teto_reducao_dano = 0.80
	m.teto_multiplicador_dano = 10.0
	return m


static func _bencaos_tuning_padrao() -> BencaosTuning:
	var b := BencaosTuning.new()
	b.tamanho_oferta = 3
	b.trocas_iniciais = 1
	b.raridade_bonus = 0.0
	return b


static func _rarity_table_padrao() -> RarityTable:
	var r := RarityTable.new()
	r.pesos = {&"comum": 60.0, &"raro": 30.0, &"epico": 10.0}
	r.escalas = {&"comum": 1.0, &"raro": 1.25, &"epico": 1.5}
	return r
