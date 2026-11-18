## Story orquestrador-007: a fatia jogável passa pelo OrquestradorDoPasso e emite eventos tipados
## (ADR-0001/0002 §Migration Plan).
extends GdUnitTestSuite

const CENA := "res://scenes/main.tscn"


## Sessão falsa: um passo executa "ataque" e fere o jogador.
class SessaoFalsa extends RefCounted:
	var state := "jogo"
	var player: Dictionary = {"hp": 10.0}
	var enemies: Array = []
	var hitstop := 0
	var transition_progress := 0.0
	var passos := 0

	func step(_amostra: Dictionary) -> Array[String]:
		passos += 1
		player.hp -= 1.0
		var r: Array[String] = ["ataque"]
		return r


func _nova_app() -> Node:
	var app: Node = auto_free(load(CENA).instantiate())
	add_child(app)
	return app


func test_passo_vivo_orquestrador_chama_step_uma_vez() -> void:
	var app := _nova_app()
	app.activate(0)
	var vivos_antes: int = app.session.live_steps
	var em_jogo_antes: int = app.orquestrador.passos_em_jogo()
	for i: int in 5:
		app._physics_process(1.0 / 60.0)
	assert_int(app.session.live_steps - vivos_antes).is_equal(5)
	assert_int(app.orquestrador.passos_em_jogo() - em_jogo_antes).is_equal(5)
	assert_int(app.orquestrador.n_vivos()).is_equal(5)


func test_hitstop_da_fatia_consultado_pelo_orquestrador_congela() -> void:
	var app := _nova_app()
	app.activate(0)
	app.session.hitstop = 3
	assert_bool(app.orquestrador.hitstop_ativo()).is_true()
	var vivos: int = app.session.live_steps
	app._physics_process(1.0 / 60.0)
	assert_int(app.session.hitstop).is_equal(2)
	assert_int(app.session.live_steps).is_equal(vivos)
	assert_int(app.orquestrador.n_vivos()).is_equal(0)
	assert_int(app.orquestrador.passos_em_jogo()).is_equal(1)


func test_pausa_fora_de_jogo_nao_avanca_regra() -> void:
	var app := _nova_app()
	app.activate(0)
	app.session.pause()
	app._espelhar_estado()
	var vivos: int = app.session.live_steps
	app._physics_process(1.0 / 60.0)
	assert_int(app.session.live_steps).is_equal(vivos)
	assert_int(app.orquestrador.estado()).is_equal(EstadoDeJogo.Valor.PAUSA)


func test_passo_da_fatia_textos_viram_eventos_tipados() -> void:
	var eventos := EventosDoPasso.new()
	var s := SessaoFalsa.new()
	var consumidos: Array[String] = []
	var ctx := AdaptadoresDaFatia.Contexto.new(s, eventos, func() -> Dictionary: return {},
			func(a: String) -> void: consumidos.append(a))
	ctx.amostra = {"aim": Vector2.RIGHT}
	AdaptadoresDaFatia.PassoDaFatia.new(ctx).passo(AmostraDeEntrada.new())
	var cmds := eventos.do_tipo(EventosDaFatia.EvComandoExecutado.TIPO)
	assert_int(cmds.size()).is_equal(1)
	assert_str(String((cmds[0] as EventosDaFatia.EvComandoExecutado).acao)).is_equal("ataque")
	var golpes := eventos.do_tipo(EventosDaFatia.EvGolpeSentido.TIPO)
	assert_int(golpes.size()).is_equal(1)
	assert_bool((golpes[0] as EventosDaFatia.EvGolpeSentido).jogador_ferido).is_true()
	assert_array(consumidos).is_equal(["ataque"])


func test_movimento_da_fatia_congela_so_fora_de_jogo() -> void:
	var s := SessaoFalsa.new()
	var ctx := AdaptadoresDaFatia.Contexto.new(s, EventosDoPasso.new(), func() -> Dictionary: return {},
			func(_a: String) -> void: pass)
	var mov := AdaptadoresDaFatia.MovimentoDaFatia.new(ctx)
	mov.passo_congelado()
	assert_int(s.passos).is_equal(0)
	s.state = "pausa"
	mov.passo_congelado()
	assert_int(s.passos).is_equal(1)


func test_espelhar_caminhos_validos_da_tabela_chegam() -> void:
	var orq := OrquestradorDoPasso.new(EventosDoPasso.new())
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.MENU)).is_true()
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.JOGO)).is_true()
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.MORTE)).is_true()
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.JOGO)).is_true()
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.BENCAO)).is_true()
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.PAUSA)).is_true()
	assert_bool(AdaptadoresDaFatia.espelhar(orq, EstadoDeJogo.Valor.JOGO)).is_true()
	assert_int(orq.estado()).is_equal(EstadoDeJogo.Valor.JOGO)
