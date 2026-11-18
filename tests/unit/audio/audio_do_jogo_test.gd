class_name AudioDoJogoTest
extends GdUnitTestSuite
## Testes unitários do nó `AudioDoJogo` e `BarramentosDeAudio` (ADR-0016 §4, story-004 e story-005).


func test_aloca_25_players_e_verifica_voz_livre_com_stream_paused() -> void:
	var audio: AudioDoJogo = auto_free(AudioDoJogo.new())
	audio.configurar(AudioTuning.new(), [])
	assert_that(audio.total_players_alocados()).is_equal(AudioDoJogo.TOTAL_PLAYERS)

	var p: AudioStreamPlayer = auto_free(AudioStreamPlayer.new())
	assert_that(AudioDoJogo.player_esta_livre(p)).is_true()
	p.stream_paused = true
	assert_that(AudioDoJogo.player_esta_livre(p)).is_false()


func test_aviso_fb2_unico_por_gancho_nao_mapeado_por_run() -> void:
	var audio: AudioDoJogo = auto_free(AudioDoJogo.new())
	var som_ok: SomDef = SomDef.new()
	som_ok.id = &"sfx_golpe"
	audio.configurar(AudioTuning.new(), [som_ok])

	var pedidos: Array[PedidoDeSom] = [
		PedidoDeSom.new(&"sfx_inexistente", 2),
		PedidoDeSom.new(&"sfx_inexistente", 1),
		PedidoDeSom.new(&"sfx_golpe", 2),
	]
	audio.consumir_passo(EstadoDeJogo.Valor.JOGO, pedidos, null, [], 0)
	audio.consumir_passo(EstadoDeJogo.Valor.JOGO, pedidos, null, [], 0)

	var avisos: Array[StringName] = audio.avisos_fb2_emitidos()
	assert_that(avisos.size()).is_equal(1)
	assert_that(avisos[0]).is_equal(&"sfx_inexistente")

	audio.iniciar_nova_run()
	assert_that(audio.avisos_fb2_emitidos().is_empty()).is_true()


func test_transicoes_pausa_bencao_e_transicao_de_camara_e_volumes() -> void:
	var audio: AudioDoJogo = auto_free(AudioDoJogo.new())
	var som_sfx: SomDef = SomDef.new()
	som_sfx.id = &"sfx_ataque"
	var som_ui: SomDef = SomDef.new()
	som_ui.id = &"ui_foco"
	audio.configurar(AudioTuning.new(), [som_sfx, som_ui])

	audio.aplicar_volumes(0.8, 0.5, 0.0, 1.0)
	assert_that(audio.volume_linear_barramento(&"Master")).is_equal_approx(0.8, 0.001)
	assert_that(audio.volume_linear_barramento(&"SFX")).is_equal_approx(0.5, 0.001)
	assert_that(BarramentosDeAudio.deve_mutar(0.0)).is_true()
	assert_that(BarramentosDeAudio.deve_mutar(0.5)).is_false()

	var v: VistaDeTelegrafo = VistaDeTelegrafo.new()
	v.slot = 0
	v.p = 0.6
	v.estado = TelegrafoTipos.Estado.CRESCENDO
	audio.consumir_passo(
		EstadoDeJogo.Valor.JOGO,
		[PedidoDeSom.new(&"sfx_ataque", 2)],
		null,
		[v],
		1
	)
	assert_that(audio.tons_ativos_no_ultimo_passo()).is_equal(1)

	# Em BENCAO, os tons de telégrafo são parados imediatamente
	audio.consumir_passo(EstadoDeJogo.Valor.BENCAO, [], null, [v], 1)
	assert_that(audio.tons_ativos_no_ultimo_passo()).is_equal(0)

	# Em TRANSICAO, o mixador é zerado
	audio.consumir_passo(EstadoDeJogo.Valor.TRANSICAO, [], null, [], 0)
	assert_that(audio.mixador().vozes_ativas()).is_equal(0)
