extends SceneTree
## Exercises the real composition scene and its menu/context transitions.

var failed := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(description)

## Runs against the same scene launched by F6/F5.
func run() -> void:
	var packed = load("res://scenes/main.tscn")
	check(packed != null, "Main scene loads")
	if packed == null:
		quit(1)
		return
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	check(app.catalog.errors.is_empty(), "Catalog loads without errors")
	check(app.session.state == "menu", "Game starts at menu")
	app.activate(0)
	check(app.session.state == "jogo", "Enter starts a run")
	var origin: Vector2 = app.session.player.pos
	for tick in range(10):
		app.session.step({"move":Vector2.RIGHT,"aim":Vector2.RIGHT,"pressed":{},"held":{},"wants":{}})
	check(app.session.player.pos.x > origin.x, "Integrated player moves")
	app.session.pause()
	app.sync_context()
	var before: Vector2 = app.session.player.pos
	app.session.step({"move":Vector2.RIGHT,"aim":Vector2.RIGHT,"pressed":{},"held":{},"wants":{}})
	check(app.session.player.pos == before, "Pause freezes movement")
	app.activate(0)
	check(app.session.state == "jogo", "Resume returns to game")
	app.session.state = "morte"
	app.sync_context()
	app.activate(0)
	check(app.session.state == "jogo" and app.session.player.hp == app.session.player.max_hp, "Restart resets run")
	app.session.state = "vitoria"
	app.sync_context()
	app.activate(1)
	check(app.session.state == "menu", "Victory can return to menu")
	app.queue_free()
	await process_frame
	print("APP RESULT checks=", checks, " failures=", failed)
	quit(0 if failed == 0 else 1)
