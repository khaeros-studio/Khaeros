## Story orquestrador-006: Main como composição fina (ADR-0001 §Implementation Guidelines).
extends GdUnitTestSuite

const MainScript = preload("res://src/app/main.gd")
const CENA := "res://scenes/main.tscn"


## Nó de Apresentação falso: registra se a dependência já estava injetada no _ready.
class NoDeApresentacaoFalso extends Node:
	var app: Object = null
	var viu_app_no_ready: bool = false

	func _ready() -> void:
		viu_app_no_ready = app != null


func _nova_app() -> Node:
	var app: Node = auto_free(load(CENA).instantiate())
	add_child(app)
	return app


func test_erro_de_passo_ticks_divergentes_mensagem_ruidosa() -> void:
	assert_str(MainScript.erro_de_passo(30)).contains("30")
	assert_str(MainScript.erro_de_passo(144)).is_not_empty()
	assert_str(MainScript.erro_de_passo(OrquestradorDoPasso.PASSOS_POR_SEGUNDO)).is_empty()


func test_project_godot_ticks_e_teto_declarados_sem_autoload() -> void:
	var texto := FileAccess.get_file_as_string("res://project.godot")
	assert_bool(texto.contains("common/physics_ticks_per_second=60")).is_true()
	assert_bool(texto.contains("common/max_physics_steps_per_frame=8")).is_true()
	assert_bool(texto.contains("[autoload]")).is_false()


func test_compor_apresentacao_injeta_antes_do_add_child_ready_ve_app() -> void:
	var main: Node = auto_free(MainScript.new())
	for membro: Variant in [main.controls, main.world, main.hud, main.camera]:
		if membro is Node:
			auto_free(membro)  # filhos ainda fora da árvore: sem isso viram órfãos
	var pai: Node = auto_free(Node.new())
	add_child(pai)
	var falso: NoDeApresentacaoFalso = NoDeApresentacaoFalso.new()
	main.compor_apresentacao(falso, pai)
	assert_bool(falso.viu_app_no_ready).is_true()


func test_foco_perdido_em_jogo_vira_pausa() -> void:
	var app := _nova_app()
	app.activate(0)
	assert_str(app.session.state).is_equal("jogo")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_str(app.session.state).is_equal("pausa")
	assert_int(app.orquestrador.estado()).is_equal(EstadoDeJogo.Valor.PAUSA)


func test_foco_perdido_em_bencao_vira_pausa() -> void:
	var app := _nova_app()
	app.activate(0)
	app.session.state = "bencao"
	app._espelhar_estado()
	assert_int(app.orquestrador.estado()).is_equal(EstadoDeJogo.Valor.BENCAO)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_str(app.session.state).is_equal("pausa")
	assert_int(app.orquestrador.estado()).is_equal(EstadoDeJogo.Valor.PAUSA)
	app.activate(0)
	assert_str(app.session.state).is_equal("bencao")


func test_foco_perdido_em_menu_nao_muda() -> void:
	var app := _nova_app()
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_str(app.session.state).is_equal("menu")
	assert_int(app.orquestrador.estado()).is_equal(EstadoDeJogo.Valor.MENU)


func test_consumidores_ordem_do_adr_0002_0016_e_save() -> void:
	var app := _nova_app()
	var esperado: Array[StringName] = [&"telemetria", &"hud", &"feedback", &"telas", &"audio", &"save"]
	assert_array(app.ordem_dos_consumidores()).is_equal(esperado)


func test_save_carregado_na_composicao() -> void:
	var app := _nova_app()
	assert_int(app.save.estado()).is_not_equal(Save.Estado.NAO_CARREGADO)
