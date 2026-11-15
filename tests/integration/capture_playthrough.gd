extends SceneTree
## Visual QA: scripted control samples traverse the actual main scene without HP cheats.

func _initialize() -> void:
	call_deferred("run")

## Retains one live combat image and the actual result of the three-wave run.
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_physics_process(false)
	app.activate(0)
	var captured := false
	for tick in range(3600):
		await physics_frame
		var game = app.session
		if game.state in ["vitoria","morte"]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://production/qa/evidence/integracao-jogavel/resultado-real.png")
			print("VISUAL PLAYTHROUGH state=",game.state," kills=",game.kills," hp=",game.player.hp)
			quit(0 if game.state == "vitoria" else 1)
			return
		if game.state == "bencao":
			app.activate(1 if game.wave_index == 0 else 0)
			continue
		if game.state != "jogo":
			game.step({})
			continue
		var nearest := INF
		var target: Dictionary = {}
		for enemy in game.enemies:
			var distance: float = game.player.pos.distance_to(enemy.pos)
			if distance < nearest:
				nearest = distance
				target = enemy
		var direction := Vector2.UP
		var move := Vector2.ZERO
		var wants := {"ataque":true}
		if not target.is_empty():
			direction = (target.pos-game.player.pos).normalized()
			move = direction if nearest > 100 else Vector2.ZERO
			for pillar in app.catalog.data.arena.pilares:
				var toward: Vector2 = Vector2(pillar.x,pillar.y)-game.player.pos
				var ahead := toward.dot(direction)
				if ahead > 0 and ahead < 180 and absf(toward.cross(direction)) < float(pillar.r)+game.player.radius+30:
					move = (direction+direction.rotated(PI/2)*2).normalized()
			if nearest > 110 and nearest < 360:
				wants.especial = true
			if target.phase == "windup" and target.timer <= 5 and nearest < 180 and game.player.inv == 0:
				wants.esquiva = true
				move = direction.rotated(PI/2)
		var sample := {"move":move,"aim":direction,"wants":wants,"held":{},"pressed":{},"source":"analogico","aim_intensity":0.0,"cursor":Vector2.ZERO}
		app.last_sample = sample
		game.step(sample)
		app.sync_context()
		if not captured and tick > 150 and game.effects.any(func(effect:Dictionary)->bool:return effect.kind == "hit"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://production/qa/evidence/integracao-jogavel/combate-real.png")
			captured = true
	push_error("Visual playthrough timed out")
	quit(1)
