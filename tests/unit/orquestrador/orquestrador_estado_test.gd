## Testes do estado de jogo, pedidos de estado e final comum do OrquestradorDoPasso
## (ADR-0001; story orquestrador-do-passo/003). Lógica pura com dublês, sem SceneTree.
extends GdUnitTestSuite

const Dubles := preload("res://tests/unit/orquestrador/dubles_do_orquestrador.gd")
const E := EstadoDeJogo.Valor

## dt_max_apres de teste (o valor real vem do VisualTuning).
const DT_MAX_FIXTURE: float = 0.1

# AC-TL-06 (Telemetria F1): 1.044 passos em Jogo, 30 de hitstop, 600 de pausa, 120 de Bênção.
const TL06_JOGO_ANTES_DA_PAUSA: int = 500
const TL06_JOGO_ENTRE: int = 300
const TL06_JOGO_FINAL: int = 244
const TL06_HITSTOP: int = 30
const TL06_PAUSA: int = 600
const TL06_BENCAO: int = 120
const TL06_TOTAL_JOGO: int = 1044
const TL06_DURACAO_S: float = 17.40
# AC-RN-23 (Run F3): 3.600 passos em Jogo com hitstop = 60 s.
const RN23_PASSOS: int = 3600
const RN23_HITSTOP: int = 12
const RN23_DURACAO_S: float = 60.0


func _montar() -> Dubles.Montagem:
	return Dubles.Montagem.new(DT_MAX_FIXTURE)


# --- MORTE vence, aplicada só no final comum -------------------------------------

func test_pedir_estado_bencao_depois_morte_no_mesmo_passo_resulta_em_morte_no_final() -> void:
	# Arrange — Portas pedem BENCAO (item 10) depois de o Combate pedir MORTE (item 9)
	var m := _montar()
	m.levar_a(E.JOGO)
	var durante: Array[int] = []
	var respostas: Array[bool] = []
	m.modulo(OrdemDoPasso.MORTES).acao = func() -> void:
		respostas.append(m.orq.pedir_estado(E.MORTE))
		durante.append(m.orq.estado())
	m.modulo(OrdemDoPasso.CAMARAS).acao = func() -> void:
		respostas.append(m.orq.pedir_estado(E.BENCAO))
		durante.append(m.orq.estado())

	# Act
	m.orq.passo_fisico()

	# Assert
	assert_array(durante).is_equal([E.JOGO, E.JOGO])
	assert_array(respostas).is_equal([true, false])
	assert_int(m.orq.estado()).is_equal(E.MORTE)
	assert_bool(m.orq.ha_pedido_pendente()).is_false()


func test_pedir_estado_morte_depois_bencao_no_mesmo_passo_morte_vence() -> void:
	# Arrange — ordem inversa: BENCAO pedido antes (item 6) e MORTE depois (item 9)
	var m := _montar()
	m.levar_a(E.JOGO)
	var respostas: Array[bool] = []
	m.modulo(OrdemDoPasso.SELO).acao = func() -> void:
		respostas.append(m.orq.pedir_estado(E.BENCAO))
	m.modulo(OrdemDoPasso.MORTES).acao = func() -> void:
		respostas.append(m.orq.pedir_estado(E.MORTE))

	# Act
	m.orq.passo_fisico()

	# Assert
	assert_array(respostas).is_equal([true, true])
	assert_int(m.orq.estado()).is_equal(E.MORTE)


func test_pedir_estado_dois_pedidos_sem_morte_primeiro_fica() -> void:
	# Arrange
	var m := _montar()
	m.levar_a(E.JOGO)
	var respostas: Array[bool] = []
	m.modulo(OrdemDoPasso.SELO).acao = func() -> void:
		respostas.append(m.orq.pedir_estado(E.BENCAO))
	m.modulo(OrdemDoPasso.CAMARAS).acao = func() -> void:
		respostas.append(m.orq.pedir_estado(E.TRANSICAO))

	# Act
	m.orq.passo_fisico()

	# Assert
	assert_array(respostas).is_equal([true, false])
	assert_int(m.orq.estado()).is_equal(E.BENCAO)


# --- Fora do passo ----------------------------------------------------------------

func test_pedir_estado_fora_do_passo_permitido_vale_na_hora() -> void:
	# Arrange
	var m := _montar()
	m.levar_a(E.JOGO)

	# Act
	var ok := m.orq.pedir_estado(E.PAUSA)

	# Assert
	assert_bool(ok).is_true()
	assert_int(m.orq.estado()).is_equal(E.PAUSA)
	assert_bool(m.orq.ha_pedido_pendente()).is_false()


func test_pedir_estado_fora_do_passo_nao_permitido_devolve_false_e_mantem() -> void:
	# Arrange
	var m := _montar()
	m.levar_a(E.MENU)

	# Act
	var ok := m.orq.pedir_estado(E.MORTE)

	# Assert
	assert_bool(ok).is_false()
	assert_int(m.orq.estado()).is_equal(E.MENU)


# --- PAUSA e retomar ----------------------------------------------------------------

func test_retomar_pausa_vinda_de_jogo_volta_a_jogo() -> void:
	var m := _montar()
	m.levar_a(E.PAUSA)

	var ok := m.orq.retomar()

	assert_bool(ok).is_true()
	assert_int(m.orq.estado()).is_equal(E.JOGO)


func test_retomar_pausa_vinda_de_bencao_volta_a_bencao() -> void:
	var m := _montar()
	m.levar_a(E.BENCAO)
	m.orq.pedir_estado(E.PAUSA)

	var ok := m.orq.retomar()

	assert_bool(ok).is_true()
	assert_int(m.orq.estado()).is_equal(E.BENCAO)


func test_retomar_fora_de_pausa_devolve_false() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)

	var ok := m.orq.retomar()

	assert_bool(ok).is_false()
	assert_int(m.orq.estado()).is_equal(E.JOGO)


func test_pedir_pausa_fora_de_jogo_e_bencao_devolve_false() -> void:
	for de: EstadoDeJogo.Valor in [E.INICIANDO, E.MENU, E.TRANSICAO, E.MORTE]:
		var m := _montar()
		if de != E.INICIANDO:
			m.levar_a(de)

		var ok := m.orq.pedir_estado(E.PAUSA)

		assert_bool(ok).override_failure_message("PAUSA a partir de %s" % EstadoDeJogo.nome(de)).is_false()


func test_pedir_jogo_em_pausa_devolve_false_volta_so_por_retomar() -> void:
	var m := _montar()
	m.levar_a(E.PAUSA)

	var ok := m.orq.pedir_estado(E.JOGO)

	assert_bool(ok).is_false()
	assert_int(m.orq.estado()).is_equal(E.PAUSA)


# --- Tabela de pedidos (ADR-0001, decisão 6) ------------------------------------------

## Tabela esperada transcrita do ADR-0001: destino -> origens permitidas.
func _tabela_do_adr() -> Dictionary:
	return {
		E.MORTE: [E.JOGO],                                  # Combate, item 9
		E.BENCAO: [E.JOGO],                                 # Portas, Vínculo, escolha do chefe
		E.TRANSICAO: [E.JOGO, E.MENU],                      # Câmaras (porta); MENU -> TRANSICAO no início da run
		E.MENU: [E.INICIANDO, E.JOGO, E.PAUSA, E.MORTE],    # boot, vitória, abandono, fim da MORTE
		E.JOGO: [E.BENCAO, E.TRANSICAO],                    # tela fechada, fim do wipe
		E.PAUSA: [E.JOGO, E.BENCAO],                        # Input/Main
		E.INICIANDO: [],
	}


func test_pedir_estado_tabela_completa_permitido_e_negado() -> void:
	var tabela := _tabela_do_adr()
	for de: EstadoDeJogo.Valor in EstadoDeJogo.Valor.values():
		for para: EstadoDeJogo.Valor in EstadoDeJogo.Valor.values():
			# Arrange
			var m := _montar()
			if de != E.INICIANDO:
				m.levar_a(de)
			var esperado: bool = (tabela[para] as Array).has(de)

			# Act
			var ok := m.orq.pedir_estado(para)

			# Assert
			var msg := "%s -> %s" % [EstadoDeJogo.nome(de), EstadoDeJogo.nome(para)]
			assert_bool(ok).override_failure_message(msg).is_equal(esperado)
			assert_bool(OrquestradorDoPasso.transicao_permitida(de, para)).override_failure_message(msg).is_equal(esperado)
			assert_int(m.orq.estado()).override_failure_message(msg).is_equal(para if esperado else de)


# --- Final comum -------------------------------------------------------------------

func test_final_comum_evento_de_ui_em_bencao_entregue_no_passo_seguinte() -> void:
	# Arrange — clique na Tela de bênção entre dois passos
	var m := _montar()
	m.levar_a(E.BENCAO)
	m.eventos.emitir(Dubles.EvUiTeste.new())
	assert_int(m.consumidor.entregas.size()).is_equal(0)

	# Act
	m.orq.passo_fisico()

	# Assert
	assert_int(m.consumidor.entregas.size()).is_equal(1)
	assert_array(m.consumidor.entregas[0]).is_equal([Dubles.EvUiTeste.TIPO])


func test_final_comum_passo_fora_de_jogo_sem_eventos_entrega_lista_vazia_uma_vez() -> void:
	var m := _montar()
	m.levar_a(E.BENCAO)

	m.orq.passo_fisico()

	assert_int(m.consumidor.entregas.size()).is_equal(1)
	assert_array(m.consumidor.entregas[0]).is_empty()


func test_final_comum_passo_que_pede_hitstop_entrega_seus_eventos_e_congelado_seguinte_so_passo_vivo() -> void:
	# Arrange — o golpe (item 5) emite e pede hitstop de 1 passo
	var m := _montar()
	m.levar_a(E.JOGO)
	m.modulo(OrdemDoPasso.COMBATE_GOLPE).acao = func() -> void:
		m.eventos.emitir(Dubles.EvGolpeTeste.new())
		m.hitstop.pedir(1)

	# Act
	m.orq.passo_fisico()
	m.modulo(OrdemDoPasso.COMBATE_GOLPE).acao = Callable()
	m.orq.passo_fisico()

	# Assert — passo 1 entrega o golpe; passo 2 (congelado) entrega uma vez, sem o golpe,
	# só o passo_vivo do item 1 (que conta passos em JOGO, inclusive hitstop).
	assert_int(m.consumidor.entregas.size()).is_equal(2)
	assert_array(m.consumidor.entregas[0]).is_equal([EvPassoVivo.TIPO, Dubles.EvGolpeTeste.TIPO])
	assert_array(m.consumidor.entregas[1]).is_equal([EvPassoVivo.TIPO])
	assert_int(m.hitstop.restante).is_equal(0)


func test_final_comum_pedido_vale_depois_da_entrega_do_passo() -> void:
	# Arrange — a entrega do passo do pedido acontece ainda em JOGO (contadores somados)
	var m := _montar()
	m.levar_a(E.JOGO)
	m.modulo(OrdemDoPasso.CAMARAS).acao = func() -> void:
		m.orq.pedir_estado(E.BENCAO)

	# Act
	m.orq.passo_fisico()

	# Assert
	assert_int(m.orq.passos_em_jogo()).is_equal(1)
	assert_int(m.orq.n_vivos()).is_equal(1)
	assert_int(m.consumidor.entregas.size()).is_equal(1)
	assert_int(m.orq.estado()).is_equal(E.BENCAO)


# --- passos_em_jogo e t_vivo --------------------------------------------------------

func test_passos_em_jogo_caso_ac_tl_06_diferenca_1044_duracao_17_40() -> void:
	# Arrange
	var m := _montar()
	m.levar_a(E.JOGO)
	var inicio := m.orq.passos_em_jogo()
	var pediu := [false]
	m.modulo(OrdemDoPasso.COMBATE_GOLPE).acao = func() -> void:
		if not pediu[0]:
			pediu[0] = true
			m.hitstop.pedir(TL06_HITSTOP)

	# Act — 500 em Jogo (30 de hitstop dentro), 600 de pausa, 300 em Jogo, 120 de Bênção, 244 em Jogo
	m.passos(TL06_JOGO_ANTES_DA_PAUSA)
	m.orq.pedir_estado(E.PAUSA)
	m.passos(TL06_PAUSA)
	m.orq.retomar()
	m.passos(TL06_JOGO_ENTRE)
	m.orq.pedir_estado(E.BENCAO)
	m.passos(TL06_BENCAO)
	m.orq.pedir_estado(E.JOGO)
	m.passos(TL06_JOGO_FINAL)

	# Assert
	var diferenca := m.orq.passos_em_jogo() - inicio
	assert_int(diferenca).is_equal(TL06_TOTAL_JOGO)
	assert_float(OrquestradorDoPasso.duracao_s(diferenca)).is_equal_approx(TL06_DURACAO_S, 1e-9)
	assert_int(m.orq.n_vivos()).is_equal(TL06_TOTAL_JOGO - TL06_HITSTOP)


func test_passos_em_jogo_caso_ac_rn_23_3600_passos_com_hitstop_60_s() -> void:
	var m := _montar()
	m.levar_a(E.JOGO)
	var inicio := m.orq.passos_em_jogo()
	m.hitstop.pedir(RN23_HITSTOP)

	m.passos(RN23_PASSOS)

	var diferenca := m.orq.passos_em_jogo() - inicio
	assert_int(diferenca).is_equal(RN23_PASSOS)
	assert_float(OrquestradorDoPasso.duracao_s(diferenca)).is_equal_approx(RN23_DURACAO_S, 1e-9)
	assert_int(m.orq.n_vivos()).is_equal(RN23_PASSOS - RN23_HITSTOP)


func test_t_vivo_e_n_vivos_sobre_60_e_para_no_hitstop() -> void:
	# Arrange
	var m := _montar()
	m.levar_a(E.JOGO)
	m.passos(3)
	var antes := m.orq.t_vivo()
	m.hitstop.pedir(2)

	# Act — 2 passos congelados
	m.passos(2)

	# Assert
	assert_float(antes).is_equal(3 / 60.0)
	assert_float(m.orq.t_vivo()).is_equal(antes)
	assert_int(m.orq.passos_em_jogo()).is_equal(5)
	m.passos(1)
	assert_float(m.orq.t_vivo()).is_equal(m.orq.n_vivos() / 60.0)
	assert_int(m.orq.n_vivos()).is_equal(4)


func test_passos_em_jogo_nao_conta_fora_de_jogo() -> void:
	var m := _montar()
	m.levar_a(E.BENCAO)

	m.passos(5)

	assert_int(m.orq.passos_em_jogo()).is_equal(0)
	assert_int(m.orq.n_vivos()).is_equal(0)
