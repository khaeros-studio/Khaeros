## Testes do canal de eventos do passo (ADR-0002, story orquestrador-do-passo/001).
## Lógica pura: sem SceneTree, sem I/O. Eventos e consumidores de teste são classes internas.
extends GdUnitTestSuite


# --- Dublês -----------------------------------------------------------------

## Evento de teste com campos de valor (fixture).
class EvTesteA extends EventoDoPasso:
	const TIPO: StringName = &"teste_a"
	var alvo_id: int
	var posicao: Vector2

	func _init(p_alvo_id: int, p_posicao: Vector2) -> void:
		alvo_id = p_alvo_id
		posicao = p_posicao

	func tipo() -> StringName:
		return TIPO


## Segundo evento de teste, de outro tipo.
class EvTesteB extends EventoDoPasso:
	const TIPO: StringName = &"teste_b"
	var player_id: int
	var rotulo: StringName

	func _init(p_player_id: int, p_rotulo: StringName) -> void:
		player_id = p_player_id
		rotulo = p_rotulo

	func tipo() -> StringName:
		return TIPO


## Consumidor falso: registra o próprio nome num diário compartilhado e copia o tamanho do lote.
class ConsumidorFalso extends ConsumidorDeEventos:
	var nome: StringName
	var diario: Array[StringName]
	var tamanhos: Array[int] = []

	func _init(p_nome: StringName, p_diario: Array[StringName]) -> void:
		nome = p_nome
		diario = p_diario

	func consumir(eventos: Array[EventoDoPasso]) -> void:
		diario.append(nome)
		tamanhos.append(eventos.size())


## Consumidor que viola o contrato: tenta emitir durante a entrega.
class ConsumidorQueEmite extends ConsumidorDeEventos:
	var canal: EventosDoPasso

	func _init(p_canal: EventosDoPasso) -> void:
		canal = p_canal

	func consumir(_eventos: Array[EventoDoPasso]) -> void:
		canal.emitir(EvTesteA.new(-1, Vector2.ZERO))


## Consumidor que tira retrato dos campos de cada evento ao receber.
class ConsumidorRetrato extends ConsumidorDeEventos:
	var retratos: Array[Dictionary] = []

	func consumir(eventos: Array[EventoDoPasso]) -> void:
		for e: EventoDoPasso in eventos:
			retratos.append(Campos.de(e))


## Módulo de regra falso: num item do passo, lê do_tipo() de dois tipos e opcionalmente emite.
class ModuloFalso extends RefCounted:
	var canal: EventosDoPasso
	var le_tipos: Array[StringName]
	var emite: EventoDoPasso
	var visto: Dictionary[StringName, int] = {}

	func _init(p_canal: EventosDoPasso, p_le: Array[StringName], p_emite: EventoDoPasso) -> void:
		canal = p_canal
		le_tipos = p_le
		emite = p_emite

	func executar() -> void:
		for t: StringName in le_tipos:
			visto[t] = canal.do_tipo(t).size()
		if emite != null:
			canal.emitir(emite)


const ALVO_FIXTURE: int = 7
const OUTRO_ALVO_FIXTURE: int = 11
const PLAYER_FIXTURE: int = 0
const POS_FIXTURE := Vector2(12.5, -3.0)
const LIMITE_FIXTURE: int = 3


## Campos de script (estado) de um evento, para comparar antes/depois da entrega.
class Campos extends RefCounted:
	static func de(e: EventoDoPasso) -> Dictionary:
		var d: Dictionary = {}
		for p: Dictionary in e.get_property_list():
			if (p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
				d[p["name"]] = e.get(p["name"])
		return d


func _consumidores_na_ordem(diario: Array[StringName]) -> Array[ConsumidorDeEventos]:
	var lista: Array[ConsumidorDeEventos] = []
	for nome: StringName in [&"telemetria", &"hud", &"feedback", &"telas", &"audio"]:
		lista.append(ConsumidorFalso.new(nome, diario))
	return lista


# --- Ordem do passo: item anterior visível, item posterior não ------------------

func test_do_tipo_modulo_posterior_ve_item_anterior_e_nao_ve_posterior() -> void:
	# Arrange — itens 1, 2, 3: o 1 emite A, o 2 lê A e B, o 3 emite B
	var canal := EventosDoPasso.new()
	var item1 := ModuloFalso.new(canal, [], EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))
	var item2 := ModuloFalso.new(canal, [EvTesteA.TIPO, EvTesteB.TIPO], null)
	var item3 := ModuloFalso.new(canal, [], EvTesteB.new(PLAYER_FIXTURE, &"x"))

	# Act
	for m: ModuloFalso in [item1, item2, item3]:
		m.executar()

	# Assert
	assert_int(item2.visto[EvTesteA.TIPO]).is_equal(1)
	assert_int(item2.visto[EvTesteB.TIPO]).is_equal(0)
	assert_bool(canal.ha(EvTesteB.TIPO)).is_true()


func test_do_tipo_downcast_le_campos_da_subclasse() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	canal.emitir(EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))

	# Act
	var e := canal.do_tipo(EvTesteA.TIPO)[0] as EvTesteA

	# Assert
	assert_object(e).is_not_null()
	assert_int(e.alvo_id).is_equal(ALVO_FIXTURE)
	assert_vector(e.posicao).is_equal(POS_FIXTURE)


func test_do_tipo_emitir_dentro_do_laco_nao_altera_leitura_em_andamento() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	canal.emitir(EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))
	var lidos: int = 0

	# Act — emitir dentro do laço não aparece no laço (lista lida é cópia)
	for _e: EventoDoPasso in canal.do_tipo(EvTesteA.TIPO):
		lidos += 1
		canal.emitir(EvTesteA.new(OUTRO_ALVO_FIXTURE, POS_FIXTURE))

	# Assert
	assert_int(lidos).is_equal(1)
	assert_int(canal.do_tipo(EvTesteA.TIPO).size()).is_equal(2)


# --- Cópias e esvaziar -------------------------------------------------------

func test_do_tipo_e_todos_mutar_resultado_nao_altera_lista() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	canal.emitir(EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))
	canal.emitir(EvTesteB.new(PLAYER_FIXTURE, &"x"))

	# Act
	var por_tipo := canal.do_tipo(EvTesteA.TIPO)
	por_tipo.clear()
	var tudo := canal.todos()
	tudo.append(EvTesteA.new(OUTRO_ALVO_FIXTURE, POS_FIXTURE))
	tudo.remove_at(0)

	# Assert
	assert_int(canal.do_tipo(EvTesteA.TIPO).size()).is_equal(1)
	assert_int(canal.todos().size()).is_equal(2)
	assert_bool(canal.todos() != tudo).is_true()


func test_todos_devolve_na_ordem_de_emissao() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var a := EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE)
	var b := EvTesteB.new(PLAYER_FIXTURE, &"x")
	var c := EvTesteA.new(OUTRO_ALVO_FIXTURE, POS_FIXTURE)

	# Act
	canal.emitir(a)
	canal.emitir(b)
	canal.emitir(c)
	var tudo := canal.todos()

	# Assert
	assert_int(tudo.size()).is_equal(3)
	assert_bool(tudo[0] == a and tudo[1] == b and tudo[2] == c).is_true()


func test_esvaziar_entrega_conteudo_integro_e_deixa_lista_vazia() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var a := EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE)
	var b := EvTesteB.new(PLAYER_FIXTURE, &"x")
	canal.emitir(a)
	canal.emitir(b)

	# Act
	var lote := canal.esvaziar()
	canal.emitir(EvTesteA.new(OUTRO_ALVO_FIXTURE, POS_FIXTURE))

	# Assert — o lote devolvido não é afetado pela lista nova
	assert_int(lote.size()).is_equal(2)
	assert_bool(lote[0] == a and lote[1] == b).is_true()
	assert_int(canal.todos().size()).is_equal(1)
	assert_bool(canal.ha(EvTesteB.TIPO)).is_false()


func test_esvaziar_lista_vazia_devolve_array_vazio() -> void:
	# Arrange
	var canal := EventosDoPasso.new()

	# Act
	var lote := canal.esvaziar()

	# Assert
	assert_int(lote.size()).is_equal(0)


func test_emitir_preenche_n_passo_com_o_passo_da_entrega() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var no_passo_0 := EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE)
	var no_passo_1 := EvTesteA.new(OUTRO_ALVO_FIXTURE, POS_FIXTURE)

	# Act
	canal.emitir(no_passo_0)
	canal.esvaziar()
	canal.emitir(no_passo_1)

	# Assert
	assert_int(no_passo_0.n_passo).is_equal(0)
	assert_int(no_passo_1.n_passo).is_equal(1)
	assert_int(canal.passo_atual()).is_equal(1)


# --- Entrega à Apresentação --------------------------------------------------

func test_entregar_consumidores_recebem_na_ordem_registrada() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var diario: Array[StringName] = []
	var consumidores := _consumidores_na_ordem(diario)
	canal.emitir(EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))

	# Act
	canal.entregar(canal.esvaziar(), consumidores)

	# Assert
	assert_array(diario).contains_exactly([&"telemetria", &"hud", &"feedback", &"telas", &"audio"])
	for c: ConsumidorDeEventos in consumidores:
		assert_array((c as ConsumidorFalso).tamanhos).contains_exactly([1])


func test_entregar_lista_vazia_ainda_chama_todos_os_consumidores() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var diario: Array[StringName] = []
	var consumidores := _consumidores_na_ordem(diario)

	# Act
	canal.entregar(canal.esvaziar(), consumidores)

	# Assert
	assert_int(diario.size()).is_equal(5)


func test_entregar_lote_fica_somente_leitura() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	canal.emitir(EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))
	var lote := canal.esvaziar()

	# Act
	canal.entregar(lote, [] as Array[ConsumidorDeEventos])

	# Assert
	assert_bool(lote.is_read_only()).is_true()


func test_emitir_durante_entrega_falha_por_assert_em_debug() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var consumidores: Array[ConsumidorDeEventos] = [ConsumidorQueEmite.new(canal)]

	# Act / Assert
	await assert_error(func() -> void: canal.entregar(canal.esvaziar(), consumidores)) \
		.is_runtime_error("Assertion failed: " + EventosDoPasso.ERRO_EMITIR_NA_ENTREGA)
	assert_int(canal.todos().size()).is_equal(0)
	assert_bool(canal.entregando()).is_false()


func test_evento_de_ui_fora_do_passo_e_entregue_uma_vez_no_passo_seguinte() -> void:
	# Arrange — passo 0 fecha; clique de UI chega entre passos (estado BENCAO)
	var canal := EventosDoPasso.new()
	var diario: Array[StringName] = []
	var consumidores := _consumidores_na_ordem(diario)
	canal.entregar(canal.esvaziar(), consumidores)
	var clique := EvTesteB.new(PLAYER_FIXTURE, &"carta_2")

	# Act
	canal.emitir(clique)
	var lote_1 := canal.esvaziar()
	canal.entregar(lote_1, consumidores)
	var lote_2 := canal.esvaziar()
	canal.entregar(lote_2, consumidores)

	# Assert
	assert_int(lote_1.size()).is_equal(1)
	assert_bool(lote_1[0] == clique).is_true()
	assert_int(clique.n_passo).is_equal(1)
	assert_int(lote_2.size()).is_equal(0)


# --- Convenções: imutabilidade e liberação -----------------------------------

func test_entregar_campos_dos_eventos_iguais_antes_e_depois() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var eventos: Array[EventoDoPasso] = [
		EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE),
		EvTesteB.new(PLAYER_FIXTURE, &"x"),
		EvPassoVivo.new(ALVO_FIXTURE),
	]
	for e: EventoDoPasso in eventos:
		canal.emitir(e)
	var antes: Array[Dictionary] = []
	for e: EventoDoPasso in eventos:
		antes.append(Campos.de(e))
	var diario: Array[StringName] = []
	var consumidores := _consumidores_na_ordem(diario)
	var retrato := ConsumidorRetrato.new()
	consumidores.append(retrato)

	# Act
	canal.entregar(canal.esvaziar(), consumidores)

	# Assert
	for i: int in eventos.size():
		assert_dict(Campos.de(eventos[i])).is_equal(antes[i])
		assert_dict(retrato.retratos[i]).is_equal(antes[i])


func test_entregar_lista_e_eventos_liberados_sem_ciclo() -> void:
	# Arrange
	var canal := EventosDoPasso.new()
	var diario: Array[StringName] = []
	var consumidores := _consumidores_na_ordem(diario)
	var a := EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE)
	var b := EvPassoVivo.new(ALVO_FIXTURE)
	canal.emitir(a)
	canal.emitir(b)
	var lote := canal.esvaziar()
	canal.entregar(lote, consumidores)
	var ref_a: WeakRef = weakref(a)
	var ref_b: WeakRef = weakref(b)
	var ref_canal: WeakRef = weakref(canal)

	# Act — solta todas as referências fortes
	a = null
	b = null
	lote = []
	consumidores.clear()
	canal = null

	# Assert
	assert_object(ref_a.get_ref()).is_null()
	assert_object(ref_b.get_ref()).is_null()
	assert_object(ref_canal.get_ref()).is_null()


# --- Alerta de excesso ------------------------------------------------------

func test_emitir_acima_do_limite_gera_alerta_em_debug() -> void:
	# Arrange — limite injetado (fixture), não o provisório de produção
	var canal := EventosDoPasso.new(LIMITE_FIXTURE)
	for i: int in LIMITE_FIXTURE:
		canal.emitir(EvTesteA.new(i, POS_FIXTURE))
	var esperado := EventosDoPasso.ALERTA_EXCESSO % [LIMITE_FIXTURE + 1, 0, LIMITE_FIXTURE]

	# Act / Assert
	await assert_error(func() -> void: canal.emitir(EvTesteA.new(ALVO_FIXTURE, POS_FIXTURE))) \
		.is_push_warning(esperado)


func test_emitir_no_limite_nao_gera_alerta() -> void:
	# Arrange
	var canal := EventosDoPasso.new(LIMITE_FIXTURE)

	# Act / Assert
	await assert_error(func() -> void:
		for i: int in LIMITE_FIXTURE:
			canal.emitir(EvTesteA.new(i, POS_FIXTURE))
	).is_success()


func test_limite_padrao_e_constante_nomeada_positiva() -> void:
	# Assert
	assert_int(EventosDoPasso.LIMITE_ALERTA_PADRAO).is_greater(0)
	assert_int(EventosDoPasso.new().limite_alerta()).is_equal(EventosDoPasso.LIMITE_ALERTA_PADRAO)


# --- EvPassoVivo ------------------------------------------------------------

func test_ev_passo_vivo_tipo_e_campo() -> void:
	# Arrange / Act
	var e := EvPassoVivo.new(ALVO_FIXTURE)

	# Assert
	assert_str(String(e.tipo())).is_equal("passo_vivo")
	assert_int(e.n_vivo).is_equal(ALVO_FIXTURE)
	assert_int(e.n_passo).is_equal(EventoDoPasso.N_PASSO_NAO_EMITIDO)
