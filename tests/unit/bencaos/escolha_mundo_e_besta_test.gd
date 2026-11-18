extends GdUnitTestSuite
## Stories bencaos-tradicoes-006, 007 e 009:
## - Story 006: escolha — aplicar no Modificadores, registrar e emitir (AC-BN-08, 09, 10)
## - Story 007: mundo parado com a oferta aberta (AC-BN-19, Edge Case pausa em Bênção)
## - Story 009: cinco bênçãos por run e bênçãos com a Besta do Vínculo (AC-BN-24, AC-BN-26)

const REGIAO := &"limiar"
const SEED := 2026


class _ModuloCombateDuble:
	extends Passo
	var passos_executados: int = 0
	var contador_recarga: int = 60

	func passo(_amostra: AmostraDeEntrada) -> void:
		passos_executados += 1
		if contador_recarga > 0:
			contador_recarga -= 1


class _HitstopFalso:
	extends ControleDeHitstop

	func hitstop_ativo() -> bool:
		return false

	func passo_congelado_do_combate() -> void:
		pass


class _FonteAmostraVazia:
	extends FonteDeAmostra

	func amostrar() -> AmostraDeEntrada:
		return AmostraDeEntrada.new()


func _tuning_mod() -> ModifiersTuning:
	var t := ModifiersTuning.new()
	t.piso_vida_jogador = 20
	t.piso_vida_maldicao = 20
	t.teto_multiplicador_dano = 4.0
	t.teto_reducao_dano = 0.6
	t.fator_empurrao_chefe = 0.12
	t.fator_propagacao_maldicao = 1.0
	t.tipos_propagados_maldicao = [&"dano_todo_pct", &"velocidade_pct"]
	return t


func _portador_jogador(vida_base: float = 100.0) -> Portador:
	return Portador.new(1, 0, Atributos.Especie.JOGADOR, {
		Atributos.VIDA_MAX: vida_base,
		Atributos.VELOCIDADE: 382.5,
		Atributos.TROCAS_OFERTA: 0.0,
	}, _tuning_mod())


func _fonte_rng(seed_val: int = SEED) -> FonteDeFluxos:
	var f := FonteDeFluxos.new(RelatorGravadorRng.new())
	f.iniciar_run(seed_val, false)
	return f


func _boon_por_id(id: StringName) -> BoonDef:
	for b: BoonDef in FixtureBn.boons():
		if b.id == id:
			return b
	return null


# --- Story 006: Escolha, aplicar e eventos (AC-BN-08, 09, 10) ----------------

func test_ac_bn_08_pegar_muro_de_pedras_epico_e_raro_aplica_escala_no_portador() -> void:
	var muro: BoonDef = _boon_por_id(&"trad_guardian_muro_pedras")
	# 1. Épico (u = 0,95 -> Épica, escala 2,0 -> +50 -> Vida 150)
	var port_epico := _portador_jogador(100.0)
	var tuning_epico := FixtureBn.tuning(2.0) # bônus 2 força Épica
	var b_epico := Bencaos.new(
		RegistroDeBencaos.new([muro] as Array[BoonDef]),
		SorteioDeOferta.new(FixtureBn.tabela(), tuning_epico),
		FluxosDeBencaos.new(_fonte_rng()),
		port_epico,
		tuning_epico,
		{REGIAO: 0},
		EventosDoPasso.new()
	)
	b_epico.pedir_oferta(REGIAO, 0)
	assert_bool(b_epico.escolher(0)).is_true()
	assert_int(port_epico.inteiro(Atributos.VIDA_MAX)).is_equal(150)

	# 2. Rara (bônus 1 sobre u < 0,6 -> Rara, escala 1,5 -> +37,5 arredondado meio longe de zero = +38 -> 138)
	var port_rara := _portador_jogador(100.0)
	var b_rara := Bencaos.new(
		RegistroDeBencaos.new([muro] as Array[BoonDef]),
		SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(_fonte_rng(101)),
		port_rara,
		FixtureBn.tuning(),
		{REGIAO: 0},
		EventosDoPasso.new()
	)
	b_rara.pedir_oferta(REGIAO, 0)
	# Força a carta 0 a Rara para verificar exatamente a escala Rara
	b_rara._cartas[0].raridade = SorteioDeOferta.RARA
	assert_bool(b_rara.escolher(0)).is_true()
	assert_int(port_rara.inteiro(Atributos.VIDA_MAX)).is_equal(138)


func test_ac_bn_09_ordem_efeitos_registro_bencao_tomada_bencao_escolhida_e_portas() -> void:
	var port := _portador_jogador(100.0)
	var eventos := EventosDoPasso.new()
	var b := Bencaos.new(
		RegistroDeBencaos.new(FixtureBn.boons()),
		SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(_fonte_rng()),
		port,
		FixtureBn.tuning(),
		{REGIAO: 0},
		eventos
	)
	b.pedir_oferta(REGIAO, 0)
	eventos.esvaziar() # limpa oferta_aberta

	# Escolhe segurando o fechamento da tela (ADR-0012 §5: segura até notificar_tela_fechada)
	assert_bool(b.escolher(0, false)).is_true()
	assert_int(b.estado()).is_equal(Bencaos.Estado.ESCOLHIDA)
	assert_int(b.tomadas().size()).is_equal(1)
	assert_bool(eventos.ha(EvBencaoTomada.TIPO)).is_false()
	assert_bool(eventos.ha(EvBencaoEscolhida.TIPO)).is_false()

	# Quando a tela fecha, saem bencao_tomada e bencao_escolhida nessa ordem
	assert_bool(b.notificar_tela_fechada()).is_true()
	assert_int(b.estado()).is_equal(Bencaos.Estado.SEM_OFERTA)
	assert_array(b.ordem_da_ultima_escolha()).is_equal([
		&"efeitos_aplicados", &"registrado", &"bencao_tomada", &"bencao_escolhida"
	] as Array[StringName])
	var emitidos: Array[EventoDoPasso] = eventos.todos()
	assert_int(emitidos.size()).is_equal(2)
	assert_str(String(emitidos[0].tipo())).is_equal("bencao_tomada")
	assert_str(String(emitidos[1].tipo())).is_equal("bencao_escolhida")


func test_ac_bn_10_sem_pular_indice_invalido_e_troca_vence_escolha_no_mesmo_passo() -> void:
	var port := _portador_jogador(100.0)
	var tuning := FixtureBn.tuning()
	tuning.trocas_iniciais = 1
	var b := Bencaos.new(
		RegistroDeBencaos.new(FixtureBn.boons()),
		SorteioDeOferta.new(FixtureBn.tabela(), tuning),
		FluxosDeBencaos.new(_fonte_rng()),
		port,
		tuning,
		{REGIAO: 0},
		EventosDoPasso.new()
	)
	b.pedir_oferta(REGIAO, 0)
	# Pular é ignorado
	assert_bool(b.pular()).is_false()
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)
	# Índice 3 (fora de 0..2) e negativo são ignorados
	assert_bool(b.escolher(3)).is_false()
	assert_bool(b.escolher(-1)).is_false()
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)
	# Troca e escolha no mesmo passo com 1 troca -> a troca vence
	var res: StringName = b.processar_comandos_do_passo(true, 0)
	assert_str(String(res)).is_equal("trocou")
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)
	assert_int(b.trocas_restantes()).is_equal(0)
	assert_int(b.tomadas().size()).is_equal(0)
	# Agora sem trocas restantes, troca + escolha no mesmo passo -> escolha vale
	var res2: StringName = b.processar_comandos_do_passo(true, 0)
	assert_str(String(res2)).is_equal("escolheu")
	assert_int(b.estado()).is_equal(Bencaos.Estado.SEM_OFERTA)
	assert_int(b.tomadas().size()).is_equal(1)


# --- Story 007: Mundo parado com a oferta aberta (AC-BN-19) ------------------

func test_ac_bn_19_mundo_parado_60_passos_em_bencao_e_pausa_nao_pula_escolha() -> void:
	var eventos := EventosDoPasso.new()
	var orq := OrquestradorDoPasso.new(eventos)
	var combate_duble := _ModuloCombateDuble.new()
	var modulos: Dictionary[StringName, Passo] = {}
	for chave: StringName in OrdemDoPasso.modulos():
		modulos[chave] = combate_duble if chave == OrdemDoPasso.COMBATE_INICIO else _ModuloCombateDuble.new()
	assert_array(orq.configurar_passo(_FonteAmostraVazia.new(), _HitstopFalso.new(), modulos)).is_empty()
	assert_bool(orq.pedir_estado(EstadoDeJogo.Valor.MENU)).is_true()
	assert_bool(orq.pedir_estado(EstadoDeJogo.Valor.TRANSICAO)).is_true()
	assert_bool(orq.pedir_estado(EstadoDeJogo.Valor.JOGO)).is_true()

	# 10 passos em JOGO: contador desce de 60 para 50
	for _i: int in 10:
		orq.passo_fisico()
	assert_int(combate_duble.contador_recarga).is_equal(50)

	# Abre oferta -> estado BENCAO
	var b := Bencaos.new(
		RegistroDeBencaos.new(FixtureBn.boons()),
		SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(_fonte_rng()),
		_portador_jogador(),
		FixtureBn.tuning(),
		{REGIAO: 0},
		eventos
	)
	assert_str(String(b.pedir_oferta(REGIAO, 0))).is_equal("aberta")
	assert_bool(orq.pedir_estado(EstadoDeJogo.Valor.BENCAO)).is_true()

	# 60 passos com a oferta aberta: contadores do Combate permanecem iguais (50)
	for _i: int in 60:
		orq.passo_fisico()
	assert_int(combate_duble.contador_recarga).is_equal(50)
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)

	# Edge Case: pausa abre em BENCAO e retomar volta para BENCAO (nunca pula a escolha)
	assert_bool(orq.pedir_estado(EstadoDeJogo.Valor.PAUSA)).is_true()
	assert_int(orq.estado()).is_equal(EstadoDeJogo.Valor.PAUSA)
	assert_bool(orq.retomar()).is_true()
	assert_int(orq.estado()).is_equal(EstadoDeJogo.Valor.BENCAO)
	assert_int(b.estado()).is_equal(Bencaos.Estado.OFERTA_ABERTA)

	# Depois da escolha, volta a JOGO e os contadores voltam a descontar
	assert_bool(b.escolher(0)).is_true()
	assert_bool(orq.pedir_estado(EstadoDeJogo.Valor.JOGO)).is_true()
	for _i: int in 5:
		orq.passo_fisico()
	assert_int(combate_duble.contador_recarga).is_equal(45)


# --- Story 009: Cinco bênçãos por run e Besta do Vínculo (AC-BN-24, 26) ------

func test_ac_bn_24_cinco_ofertas_chaves_0_1_2_4_5_termina_com_13_livres() -> void:
	var eventos := EventosDoPasso.new()
	var b := Bencaos.new(
		RegistroDeBencaos.new(FixtureBn.boons()),
		SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(_fonte_rng(777)),
		_portador_jogador(),
		FixtureBn.tuning(),
		{REGIAO: 0},
		eventos
	)
	var chaves: Array[int] = [0, 1, 2, 4, 5]
	var escolhidas: Dictionary[StringName, bool] = {}
	for idx_camara: int in chaves:
		var resp: StringName = b.pedir_oferta(REGIAO, idx_camara)
		assert_str(String(resp)).is_equal("aberta")
		var cartas: Array[CartaDaOferta] = b.cartas()
		assert_int(cartas.size()).is_equal(3)
		# 3 cartas distintas e nenhuma já tomada
		assert_bool(cartas[0].id != cartas[1].id and cartas[1].id != cartas[2].id and cartas[0].id != cartas[2].id).is_true()
		for c: CartaDaOferta in cartas:
			assert_bool(escolhidas.has(c.id)).is_false()
		escolhidas[cartas[0].id] = true
		assert_bool(b.escolher(0)).is_true()
	assert_int(b.restantes()).is_equal(13)
	assert_int(b.tomadas().size()).is_equal(5)


func test_ac_bn_26_besta_traco_unico_so_no_virote_e_dano_todo_espelha_na_maldicao() -> void:
	var t_mod: ModifiersTuning = _tuning_mod()
	var port_jog := _portador_jogador(90.0)
	var espelho := EspelhoDeFontes.new(port_jog, t_mod)
	var vulto_def: CurseDef = FabricasDeCatalogo.maldicao(&"vulto_mudo", &"comum")
	var port_mald: Portador = PortadorDaMaldicao.criar(2, 0, vulto_def, t_mod, null, null, espelho)

	var traco_unico: BoonDef = _boon_por_id(&"trad_blade_traco_unico") # dano_ataque_pct +0,25
	var preco_nome: BoonDef = _boon_por_id(&"trad_resonance_preco_nome") # dano_todo_pct +0,20
	var fio_inv: BoonDef = _boon_por_id(&"trad_veil_fio_invisivel") # velocidade_pct +0,12

	var b := Bencaos.new(
		RegistroDeBencaos.new([traco_unico, preco_nome, fio_inv] as Array[BoonDef]),
		SorteioDeOferta.new(FixtureBn.tabela(), FixtureBn.tuning()),
		FluxosDeBencaos.new(_fonte_rng(555)),
		port_jog,
		FixtureBn.tuning(),
		{REGIAO: 0},
		EventosDoPasso.new(),
		espelho
	)

	# 1. Pega Traço Único Comum (dano_ataque_pct +0,25): sobe o M do Virote (ATAQUE) e não muda a Maldição
	b.pedir_oferta(REGIAO, 0)
	var idx_traco: int = -1
	for i: int in b.cartas().size():
		if b.cartas()[i].id == &"trad_blade_traco_unico":
			idx_traco = i
			b._cartas[i].raridade = SorteioDeOferta.COMUM
	assert_bool(b.escolher(idx_traco)).is_true()
	var ctx := ContextoDeDano.new(90.0, false)
	assert_float(port_jog.multiplicador_de_dano(Modificador.Slot.ATAQUE, ctx)).is_equal_approx(1.25, 1e-6)
	assert_float(port_mald.multiplicador_de_dano(Modificador.Slot.NENHUM, ctx)).is_equal_approx(1.0, 1e-6)

	# 2. Pega O Preço com Nome Comum (dano_todo_pct +0,20): espelha no portador da Maldição no mesmo passo
	b.pedir_oferta(REGIAO, 1)
	var idx_preco: int = -1
	for i: int in b.cartas().size():
		if b.cartas()[i].id == &"trad_resonance_preco_nome":
			idx_preco = i
			b._cartas[i].raridade = SorteioDeOferta.COMUM
	assert_bool(b.escolher(idx_preco)).is_true()
	assert_float(port_jog.multiplicador_de_dano(Modificador.Slot.ATAQUE, ctx)).is_equal_approx(1.45, 1e-6)
	assert_float(port_mald.multiplicador_de_dano(Modificador.Slot.NENHUM, ctx)).is_equal_approx(1.20, 1e-6)
	assert_bool(port_mald.tem_fonte(&"espelho:bencao:trad_resonance_preco_nome")).is_true()
