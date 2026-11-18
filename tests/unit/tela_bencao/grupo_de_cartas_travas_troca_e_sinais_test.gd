class_name GrupoDeCartasTravasTrocaESinaisTest
extends GdUnitTestSuite
## Testes unitários de `GrupoDeCartas`: travas de `500 ms` e `300 ms`, precedência `trocar > aceitar` e sinais (`story-002` e `story-003`).


func _criar_3_cartas() -> Array[DadosDaCarta]:
	return [
		DadosDaCarta.criar_de_bencao(&"b1", &"sangue", 0, 0),
		DadosDaCarta.criar_de_bencao(&"b2", &"ferro", 1, 10),
		DadosDaCarta.criar_de_bencao(&"b3", &"sombra", 2, 0),
	]


func test_trava_abertura_500ms_permite_mover_foco_mas_bloqueia_confirmar() -> void:
	var tuning: TelaBencaoTuning = TelaBencaoTuning.new()
	var grupo: GrupoDeCartas = GrupoDeCartas.new(tuning)
	grupo.configurar(tuning, null, null, true) # reduzir_movimento=true entra direto em TRAVADA por 500ms
	grupo.abrir(_criar_3_cartas(), &"bencao", 1)

	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.TRAVADA)

	var cmd: ComandosDeTela = ComandosDeTela.new()
	cmd.navegar = Vector2i(1, 0)
	cmd.aceitar = true
	var res: Dictionary = grupo.processar_comandos(cmd)
	assert_that(bool(res["mudou_foco"])).is_true()
	assert_that(int(res["confirmou_indice"])).is_equal(-1)

	# Avança 500 ms -> passa para LIVRE
	grupo.avancar(0.51)
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.LIVRE)


func test_precedencia_trocar_antes_de_aceitar_trava_300ms_e_sinais_preco_e_fechamento() -> void:
	var tuning: TelaBencaoTuning = TelaBencaoTuning.new()
	var grupo: GrupoDeCartas = GrupoDeCartas.new(tuning)
	grupo.configurar(tuning, null, null, true)
	grupo.abrir(_criar_3_cartas(), &"bencao", 1)
	grupo.avancar(0.55)
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.LIVRE)

	# No mesmo passo, trocar=true e aceitar=true -> executa troca, não confirma
	var cmd: ComandosDeTela = ComandosDeTela.new()
	cmd.trocar = true
	cmd.aceitar = true
	var res_troca: Dictionary = grupo.processar_comandos(cmd)
	assert_that(bool(res_troca["trocou_oferta"])).is_true()
	assert_that(int(res_troca["confirmou_indice"])).is_equal(-1)
	assert_that(grupo.trocas_restantes()).is_equal(0)

	# Avança animação de troca -> entra na trava de 300 ms
	grupo.avancar(0.06)
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.TRAVADA)
	grupo.avancar(0.31)
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.LIVRE)

	# Agora confirma a carta em foco -> emite preco_revelado e depois tela_fechada
	cmd.limpar()
	cmd.aceitar = true
	var res_conf: Dictionary = grupo.processar_comandos(cmd)
	assert_that(int(res_conf["confirmou_indice"])).is_equal(1)
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.CONFIRMANDO)

	var ev1: Dictionary = grupo.avancar(0.10)
	assert_that(bool(ev1["preco_revelado"])).is_true()
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.SAINDO)

	var ev2: Dictionary = grupo.avancar(0.10)
	assert_that(bool(ev2["tela_fechada"])).is_true()
	assert_that(grupo.estado()).is_equal(GrupoDeCartas.Estado.FECHADA)
