extends SceneTree

const Session = preload("res://src/gameplay/game_session.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL " + label)
	else:
		print("PASS ", label)

func sample(move := Vector2.ZERO, aim := Vector2.RIGHT, wants: Dictionary = {}) -> Dictionary:
	return {"move":move, "aim":aim, "wants":wants, "pressed":wants, "held":{}}

func fresh(tuning: Dictionary):
	var session = Session.new()
	session.configure(tuning, 123)
	session.start()
	return session

func run() -> void:
	var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/integration/gameplay.json"))
	var game = fresh(tuning)
	expect(game.state == "jogo" and game.enemies.size() == tuning.ondas[0].size(), "start creates first wave")
	var origin: Vector2 = game.player.pos
	game.step(sample(Vector2.RIGHT))
	expect(game.player.pos.distance_to(origin + Vector2(6.45,0)) < 0.001, "integrated movement advances at 60Hz")
	game = fresh(tuning)
	var consumed: Array = game.step(sample(Vector2.RIGHT,Vector2.LEFT,{"esquiva":true}))
	expect(consumed.has("esquiva") and game.player.charges == 0 and game.player.inv == 12, "dash consumes charge and guarantees protection on same step")
	for n in range(8): game.step(sample())
	expect(game.player.pos.distance_to(origin + Vector2(202.5,0)) < 0.001 and game.player.dash_remaining == 0, "nine dash displacements finish with false query")
	for n in range(33): game.step(sample())
	expect(game.player.charges == 0, "charge remains absent through step41")
	game.step(sample())
	expect(game.player.charges == 1, "charge restored at42")
	game = fresh(tuning)
	game.step(sample(Vector2.RIGHT,Vector2.RIGHT,{"esquiva":true}))
	game.hitstop = 4
	var frozen: Dictionary = game.player.duplicate(true)
	for n in range(4): game.step(sample(Vector2.LEFT))
	expect(game.player.pos == frozen.pos and game.player.dash_remaining == frozen.dash_remaining and game.player.recharge == frozen.recharge and game.player.prev == game.player.pos, "hitstop freezes rule counters and collapses position history")
	game.pause()
	game.step(sample(Vector2.RIGHT))
	expect(game.state == "pausa" and game.player.pos == frozen.pos, "pause freezes rules")
	game.resume()
	expect(game.state == "jogo", "resume restores prior state")
	game = fresh(tuning)
	game.enemies[0].phase = "chase"
	game.enemies[0].pos = game.player.pos + Vector2(80,0)
	game.enemies[0].prev = game.enemies[0].pos
	var hp_before: float = game.enemies[0].hp
	game.step(sample(Vector2.ZERO,Vector2.RIGHT,{"ataque":true}))
	expect(game.enemies[0].hp < hp_before and game.hitstop > 0, "attack damages eligible enemy and requests hitstop")
	game = fresh(tuning)
	game.enemies[0].pos = game.player.pos + Vector2(80,0)
	game.step(sample(Vector2.ZERO,Vector2.RIGHT,{"ataque":true}))
	expect(game.enemies[0].hp == game.enemies[0].max_hp, "spawning enemy cannot be hit")
	game = fresh(tuning)
	game.enemies[0].phase = "windup"
	game.enemies[0].timer = 1
	game.enemies[0].pos = game.player.pos + Vector2(50,0)
	game.enemies[0].aim = Vector2.LEFT
	game.step(sample())
	expect(game.player.hp < game.player.max_hp and game.player.inv > 0, "completed enemy telegraph applies damage and hurt protection")
	game = fresh(tuning)
	game.enemies[0].phase = "windup"
	game.enemies[0].timer = 1
	game.enemies[0].pos = game.player.pos + Vector2(50,0)
	game.enemies[0].aim = Vector2.LEFT
	game.step(sample(Vector2.ZERO,Vector2.LEFT,{"esquiva":true}))
	expect(game.player.hp == game.player.max_hp, "dash protects against enemy damage in the same step")
	game = fresh(tuning)
	game.enemies[0].phase = "windup"
	game.enemies[0].timer = 1
	game.enemies[0].hp = 1.0
	game.enemies[0].pos = game.player.pos + Vector2(50,0)
	game.enemies[0].aim = Vector2.LEFT
	game.step(sample(Vector2.ZERO,Vector2.RIGHT,{"ataque":true}))
	expect(game.player.hp == game.player.max_hp and game.kills == 1, "enemy killed by player cannot finish telegraph that step")
	game = fresh(tuning)
	var ranged: Dictionary = game.enemies[2]
	ranged.phase = "windup"
	ranged.timer = 1
	ranged.aim = Vector2.DOWN
	game.step(sample())
	expect(game.projectiles.size() == 1, "ranged telegraph creates projectile")
	game.projectiles[0].pos = game.player.pos - Vector2(0,3)
	game.step(sample())
	expect(game.player.hp < game.player.max_hp and game.projectiles.is_empty(), "hostile projectile hits player and is consumed")
	game = fresh(tuning)
	game.projectiles.append({"pos":game.player.pos,"prev":game.player.pos,"radius":13.5,"velocity":Vector2.ZERO,"remaining":1,"damage":8.0})
	game.step(sample())
	expect(game.player.hp == game.player.max_hp and game.projectiles.is_empty(), "expired projectile cannot damage player at same endpoint")
	game = fresh(tuning)
	var pillar: Dictionary = tuning.arena.pilares[0]
	game.player.pos = Vector2(pillar.x-float(pillar.r)-game.player.radius,pillar.y)
	var blocked_pos := Vector2(pillar.x-float(pillar.r)-5.0,pillar.y)
	game.projectiles.append({"pos":blocked_pos,"prev":blocked_pos,"radius":13.5,"velocity":Vector2.ZERO,"remaining":10,"damage":8.0})
	game.step(sample())
	expect(game.player.hp == game.player.max_hp and game.projectiles.is_empty(), "obstacle consumes projectile before overlapping player can be hurt")
	game = fresh(tuning)
	var tapped := sample(Vector2.RIGHT,Vector2.RIGHT,{"esquiva":true})
	tapped.dash_taps = 1
	game.step(tapped)
	expect(game.player.charges == 0 and game.denied_dash_count == 0, "successful last dash charge does not emit denial")
	tapped.dash_taps = 2
	game.step(tapped)
	expect(game.denied_dash_count == 2 and game.effects.any(func(effect: Dictionary)->bool:return effect.kind == "dash_denied"), "retained new dash taps emit counted denial after recharge")
	game.step(sample())
	expect(game.denied_dash_count == 2, "old buffered dash does not repeat denial")
	game = fresh(tuning)
	game.player.charges = 0
	game.player.recharge = 41
	tapped.dash_taps = 1
	consumed = game.step(tapped)
	expect(consumed.has("esquiva") and game.denied_dash_count == 0, "charge restored in current step permits dash without stale denial")
	game = fresh(tuning)
	game.step(sample(Vector2.ZERO,Vector2.RIGHT,{"especial":true}))
	expect(game.player.lunge_remaining > 0, "special starts lunge")
	consumed = game.step(sample(Vector2.UP,Vector2.RIGHT,{"esquiva":true}))
	expect(consumed.has("esquiva") and game.player.lunge_remaining == 0, "dash cancels active lunge synchronously")
	game = fresh(tuning)
	for enemy: Dictionary in game.enemies: enemy.hp = 0.0
	game.step(sample())
	game.hitstop = 0
	game.step(sample())
	expect(game.state == "bencao", "cleared wave opens blessing")
	game.pause()
	game.resume()
	expect(game.state == "bencao", "pause returns to blessing without losing offer")
	game.choose_blessing(1)
	expect(game.state == "transicao" and game.wave_index == 0, "choice starts transition without early wave swap")
	game.advance_presentation(float(tuning.wave_transition_s)*0.1)
	expect(game.wave_index == 0, "wipe preserves old wave before midpoint")
	for n in range(10): game.advance_presentation(0.1)
	expect(game.state == "jogo" and game.wave_index == 1 and game.player.charge_max == 2, "blessing grants extra charge and opens next wave")
	expect(game.player.pos == game.player.prev and game.player.pos == origin, "wave cut resets player interpolation history at spawn")
	for wave in range(2):
		for enemy: Dictionary in game.enemies: enemy.hp = 0.0
		game.hitstop = 0
		game.step(sample())
		game.hitstop = 0
		game.step(sample())
		if game.state == "bencao":
			game.choose_blessing(0)
			for n in range(10): game.advance_presentation(0.1)
	expect(game.state == "vitoria", "final cleared wave ends run")
	game = fresh(tuning)
	game.player.hp = 0.0
	game.step(sample())
	expect(game.state == "morte", "zero player life ends run")
	game.start()
	expect(game.state == "jogo" and game.player.hp == game.player.max_hp and game.kills == 0, "restart resets run state")
	var another = fresh(tuning)
	for n in range(180):
		game.step(sample(Vector2.RIGHT if n < 30 else Vector2.ZERO))
		another.step(sample(Vector2.RIGHT if n < 30 else Vector2.ZERO))
	expect(game.player == another.player and game.enemies == another.enemies, "same seed and input produce same integrated state")
	var hunt_result = run_hunt(tuning)
	expect(hunt_result.state == "vitoria" and hunt_result.kills == 13, "scripted input completes all three waves without changing HP or enemies")
	print("HUNT state=",hunt_result.state," kills=",hunt_result.kills," hp=",hunt_result.player.hp," live_steps=",hunt_result.live_steps)
	print("RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)

func run_hunt(tuning: Dictionary):
	var game = fresh(tuning)
	for tick in range(18000):
		game.advance_presentation(1.0/60.0)
		if game.state in ["vitoria","morte"]: break
		if game.state == "bencao":
			game.choose_blessing(1 if game.wave_index == 0 else 0)
			continue
		if game.state != "jogo":
			game.step(sample())
			continue
		var target: Dictionary = {}
		var nearest := INF
		for enemy: Dictionary in game.enemies:
			var distance: float = game.player.pos.distance_to(enemy.pos)
			if distance < nearest:
				nearest = distance
				target = enemy
		if target.is_empty():
			game.step(sample())
			continue
		var direction: Vector2 = (target.pos-game.player.pos).normalized()
		var move: Vector2 = direction if nearest > 100.0 else Vector2.ZERO
		for pillar: Dictionary in tuning.arena.pilares:
			var toward: Vector2 = Vector2(pillar.x,pillar.y)-game.player.pos
			var ahead := toward.dot(direction)
			if ahead > 0 and ahead < 180.0 and absf(toward.cross(direction)) < float(pillar.r)+game.player.radius+30.0:
				move = (direction+direction.rotated(PI/2)*2.0).normalized()
		var wants: Dictionary = {"ataque":true}
		if nearest > 110 and nearest < 360: wants.especial = true
		if target.phase == "windup" and target.timer <= 5 and nearest < 180 and game.player.inv == 0:
			wants.esquiva = true
			move = direction.rotated(PI/2)
		game.step(sample(move,direction,wants))
	return game
