extends Node2D
## Renders runtime SpriteFrames atlases (Lote 01 & Lote 02) with procedural fallback; reads simulation values without changing gameplay.

const INK := Color("0d0e14")
const STONE := Color("252936")
const BONE := Color("cfc6b4")
const MAGENTA := Color("e0259c")
const MAGENTA_BRIGHT := Color("f070c0")
const GOLD := Color("e3b23c")
const PIVOT := Vector2(200, 320)
const ACTOR_IDS := ["iniciado_lamina", "eco_perdido", "anomalia_menor", "fenda_errante", "elite_pecas"]

var app: Node
var _atlases_loaded := false
var _frames_by_actor: Dictionary = {}
var _manifests_by_actor: Dictionary = {}

func _ensure_atlases() -> void:
	if _atlases_loaded:
		return
	_atlases_loaded = true
	for actor_id: String in ACTOR_IDS:
		var frames_path := "res://assets/art/runtime/%s/%s_frames_v01.tres" % [actor_id, actor_id]
		var manifest_path := "res://assets/art/runtime/%s/atlas_manifest_v01.json" % actor_id
		if ResourceLoader.exists(frames_path) and FileAccess.file_exists(manifest_path):
			var frames_res := load(frames_path) as SpriteFrames
			var manifest_parsed = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
			if frames_res != null and typeof(manifest_parsed) == TYPE_DICTIONARY:
				_frames_by_actor[actor_id] = frames_res
				_manifests_by_actor[actor_id] = manifest_parsed

func _draw() -> void:
	if app == null or not app.ready_to_play:
		return
	_ensure_atlases()
	var session = app.session
	var data: Dictionary = app.catalog.data
	var room := Rect2(0, 0, data.arena.largura, data.arena.altura)
	draw_rect(room.grow(1000), Color("0e101a"))
	draw_rect(room.grow(36), INK)
	draw_rect(room, Color("1d212b"))
	draw_rect(room.grow(-18), Color("383b46"), false, 3)
	draw_rect(room.grow(-36), Color("282d39"), false, 2)
	# Quiet geometric floor; detail remains below danger indicators.
	for x in range(120, int(room.size.x), 240):
		for y in range(120, int(room.size.y), 240):
			var offset := float((x / 240 + y / 240) % 3) * 12
			draw_line(Vector2(x - 45, y + offset), Vector2(x + 45, y + offset), Color("272c37"), 1)
			draw_line(Vector2(x, y - 45 + offset), Vector2(x, y + 45 + offset), Color("272c37"), 1)
	var center := room.get_center()
	draw_arc(center, 220, 0, TAU, 96, Color("2b303d"), 2, true)
	draw_arc(center, 236, 0, TAU, 96, Color("262b36"), 2, true)
	for i in range(12):
		var direction := Vector2.RIGHT.rotated(i * TAU / 12)
		draw_line(center + direction * 205, center + direction * 250, Color("303541"), 3)
	# Door motif: an extinguished ritual gate beyond the far wall.
	var gate := Vector2(room.size.x / 2, 15)
	draw_rect(Rect2(gate + Vector2(-90, -150), Vector2(180, 160)), INK)
	draw_line(gate + Vector2(-95, 10), gate + Vector2(-95, -150), Color("55505a"), 8)
	draw_line(gate + Vector2(95, 10), gate + Vector2(95, -150), Color("55505a"), 8)
	for enemy in session.enemies:
		if enemy.get("phase", "") == "windup":
			_telegraph(enemy, true)
	var bodies: Array[Dictionary] = []
	var interpolation := Engine.get_physics_interpolation_fraction()
	for index in data.arena.pilares.size():
		var pillar: Dictionary = data.arena.pilares[index]
		bodies.append({"type": "pillar", "pos": Vector2(pillar.x, pillar.y), "radius": pillar.r, "order": index})
	for enemy in session.enemies:
		if enemy.hp <= 0:
			continue
		var position: Vector2 = enemy.get("prev", enemy.pos).lerp(enemy.pos, interpolation)
		bodies.append({"type": "enemy", "pos": position, "entity": enemy, "order": 100 + int(enemy.id)})
	if not session.player.is_empty():
		var position: Vector2 = session.player.prev.lerp(session.player.pos, interpolation)
		bodies.append({"type": "player", "pos": position, "entity": session.player, "order": 50})
	for body in bodies:
		# Art Bible §5.5: Ecos never cast a contact shadow ("gramática da subtração aplicada à luz").
		if body.type == "enemy" and String(body.entity.get("kind", "")) == "eco_perdido":
			continue
		var shadow_r := float(body.get("radius", body.get("entity", {}).get("radius", 30.0)))
		draw_set_transform(body.pos, 0, Vector2(1, 0.38))
		draw_circle(Vector2(3, 8), shadow_r * 1.28, Color(INK.r, INK.g, INK.b, 0.68))
	draw_set_transform(Vector2.ZERO)
	bodies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y < b.pos.y if a.pos.y != b.pos.y else a.order < b.order)
	for body in bodies:
		match body.type:
			"pillar": _pillar(body.pos, body.radius)
			"player": _player(body.pos, body.entity)
			"enemy": _enemy(body.pos, body.entity)
	for enemy in session.enemies:
		if enemy.get("phase", "") == "windup":
			_telegraph(enemy, false)
	for projectile in session.projectiles:
		var pos: Vector2 = projectile.get("prev", projectile.pos).lerp(projectile.pos, interpolation)
		draw_circle(pos, projectile.radius + 5, INK)
		draw_circle(pos, projectile.radius, MAGENTA)
		draw_circle(pos - Vector2(3, 3), projectile.radius * 0.35, BONE)
	for effect in session.effects:
		_effect(effect)

func _pillar(pos: Vector2, radius: float) -> void:
	var base := PackedVector2Array([pos + Vector2(-radius, 0), pos + Vector2(-radius - 7, -105), pos + Vector2(-18, -145), pos + Vector2(radius, -124), pos + Vector2(radius + 8, -12), pos + Vector2(radius * 0.5, 14)])
	draw_colored_polygon(base, Color("303441"))
	draw_polyline(_closed(base), INK, 7, true)
	draw_line(pos + Vector2(-15, -130), pos + Vector2(-13, -6), Color("4c4d59"), 4)
	draw_line(pos + Vector2(8, -100), pos + Vector2(13, -58), Color("171c28"), 3)
	draw_line(pos + Vector2(13, -58), pos + Vector2(4, -35), Color("171c28"), 3)
	draw_arc(pos, radius, 0, PI, 18, Color("53515b"), 3, true)

func _player(pos: Vector2, player: Dictionary) -> void:
	var session = app.session
	var data: Dictionary = app.catalog.data
	var aim: Vector2 = player.get("aim", Vector2.UP)
	var dash: bool = int(player.get("dash_remaining", 0)) > 0
	var lunge: bool = int(player.get("lunge_remaining", 0)) > 0
	var facing: Vector2 = player.get("dash_dir", aim) if dash else (player.get("lunge_dir", aim) if lunge else aim)
	if dash:
		for i in range(1, 4):
			draw_line(pos - facing * i * 18 + Vector2(-12, -20), pos - facing * i * 18 + Vector2(12, -45), Color(BONE, 0.32 / float(i)), 4, true)
	if _frames_by_actor.has("iniciado_lamina"):
		var dir_suffix := "costas34" if facing.y < -0.15 else "frente34"
		var flip_x := -1.0 if facing.x < -0.05 else 1.0
		var action := "idle"
		var progress := -1.0
		if session.state == "morte" or float(player.get("hp", 1.0)) <= 0.0:
			action = "death"
			progress = clampf(session.presentation_time / 0.8, 0.0, 0.999)
		elif dash:
			action = "dash"
			var d_total := maxf(1.0, roundf(float(data.esquiva.duracao_s) * 60.0))
			progress = clampf(1.0 - float(player.dash_remaining) / d_total, 0.0, 0.999)
		elif lunge:
			action = "lunge"
			var l_total := maxf(1.0, roundf(float(data.investida.duracao_s) * 60.0))
			progress = clampf(1.0 - float(player.lunge_remaining) / l_total, 0.0, 0.999)
		elif int(player.get("attack_cd", 0)) > 0:
			var combo_idx := int(player.get("combo", 1))
			action = "attack1" if combo_idx == 1 else ("attack2" if combo_idx == 2 else "attack3")
			var a_total := maxf(1.0, roundf(float(data.corte.recarga_s) * 60.0))
			progress = clampf(1.0 - float(player.attack_cd) / a_total, 0.0, 0.999)
		elif int(player.get("flash", 0)) > 0:
			action = "hurt"
			progress = 0.0
		elif player.pos.distance_squared_to(player.get("prev", player.pos)) > 0.04:
			action = "run"
		var anim_name := action + "_" + dir_suffix
		var modulate := BONE if int(player.get("flash", 0)) > 0 else Color.WHITE
		_draw_actor_sprite("iniciado_lamina", anim_name, pos, flip_x, 1.0, session.presentation_time, progress, modulate)
		draw_arc(pos, 34, 0, TAU, 40, Color(BONE, 0.35), 1.5, true)
		if int(player.get("inv", 0)) > 0 and not dash:
			draw_arc(pos, 39, -PI * 0.8, -PI * 0.2, 15, Color(BONE, 0.65), 2, true)
		draw_line(pos + aim * 55, pos + aim * 68, Color(BONE, 0.65), 2, true)
		return
	# Procedural fallback
	var cloak := PackedVector2Array([pos + Vector2(-9, -68), pos + Vector2(12, -67), pos + Vector2(28, -15), pos + Vector2(14, -4), pos + Vector2(2, -12), pos + Vector2(-16, 0), pos + Vector2(-29, -14)])
	draw_colored_polygon(cloak, Color("a9a5a4"))
	draw_polyline(_closed(cloak), INK, 6, true)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-4, -61), pos + Vector2(12, -58), pos + Vector2(21, -15), pos + Vector2(2, -8)]), Color("525368"))
	draw_line(pos + Vector2(-10, -4), pos + Vector2(-10, 5), INK, 7)
	draw_line(pos + Vector2(12, -6), pos + Vector2(14, 5), INK, 7)
	draw_circle(pos + Vector2(0, -75), 17, INK)
	draw_circle(pos + Vector2(0, -75), 12, BONE)
	draw_line(pos + Vector2(-10, -77), pos + Vector2(10, -77), Color("474759"), 4)
	draw_line(pos + Vector2(-15, -57), pos + Vector2(19, -45), Color("353a4b"), 7)
	var hand := pos + Vector2(0, -34) + aim * 19
	var tip := hand + aim * 60
	draw_line(hand - aim * 9, tip, INK, 10, true)
	draw_line(hand, tip, BONE, 4, true)
	draw_line(hand + aim.orthogonal() * 9, hand - aim.orthogonal() * 9, GOLD, 4, true)
	draw_arc(pos, 34, 0, TAU, 40, Color(BONE, 0.35), 1.5, true)
	if player.inv > 0 and not dash:
		draw_arc(pos, 39, -PI * 0.8, -PI * 0.2, 15, Color(BONE, 0.65), 2, true)
	draw_line(pos + aim * 55, pos + aim * 68, Color(BONE, 0.65), 2, true)

func _enemy(pos: Vector2, enemy: Dictionary) -> void:
	var session = app.session
	var data: Dictionary = app.catalog.data
	var kind := String(enemy.get("kind", "eco_perdido"))
	var radius: float = enemy.radius
	var spawning: bool = enemy.phase == "spawn"
	var is_elite: bool = enemy.get("elite", false)
	var tint := GOLD if is_elite else MAGENTA
	if spawning:
		draw_arc(pos, radius + 18, 0, TAU, 30, Color(tint, 0.55), 2, true)
	if _frames_by_actor.has(kind):
		var def: Dictionary = data.inimigos.get(kind, {})
		var move_delta: Vector2 = enemy.pos - enemy.get("prev", enemy.pos)
		var look_vec: Vector2 = enemy.get("aim", Vector2.DOWN)
		if enemy.phase == "chase" and not session.player.is_empty():
			var to_player: Vector2 = session.player.pos - enemy.pos
			if to_player.length_squared() > 1.0:
				look_vec = to_player.normalized()
		elif move_delta.length_squared() > 0.04:
			look_vec = move_delta.normalized()
		var dir_suffix := "costas34" if look_vec.y < -0.15 else "frente34"
		var flip_x := -1.0 if look_vec.x < -0.05 else 1.0
		var action := "idle"
		var progress := -1.0
		if int(enemy.get("flash", 0)) > 0:
			action = "hurt"
			progress = 0.0
		elif enemy.phase == "spawn":
			action = "spawn"
			var s_total := maxf(1.0, roundf(float(data.ia.surgimento_s) * 60.0))
			progress = clampf(1.0 - float(enemy.timer) / s_total, 0.0, 0.999)
		elif enemy.phase == "windup":
			action = "windup"
			var w_total := maxf(1.0, roundf(float(def.get("preparo_s", 0.5)) * 60.0))
			progress = clampf(1.0 - float(enemy.timer) / w_total, 0.0, 0.999)
		elif enemy.phase == "recover":
			var r_total := maxf(1.0, roundf(float(def.get("recarga_s", 1.0)) * 60.0))
			var elapsed_ticks := maxf(0.0, r_total - float(enemy.timer))
			var exec_ticks := maxf(1.0, float(def.get("execucao_passos", 8)))
			if elapsed_ticks < exec_ticks:
				action = "attack"
				progress = clampf(elapsed_ticks / exec_ticks, 0.0, 0.999)
			else:
				action = "recover"
				progress = clampf((elapsed_ticks - exec_ticks) / maxf(1.0, r_total - exec_ticks), 0.0, 0.999)
		elif move_delta.length_squared() > 0.04:
			action = "run"
		var anim_name := action + "_" + dir_suffix
		var elite_scale := 1.15 if is_elite else 1.0
		var modulate := Color.WHITE
		if spawning:
			modulate.a = 0.65
		if int(enemy.get("flash", 0)) > 0:
			modulate = Color(1.6, 1.55, 1.42, modulate.a)
		var phase_time: float = session.presentation_time + float(int(enemy.get("id", 0))) * 0.19
		_draw_actor_sprite(kind, anim_name, pos, flip_x, elite_scale, phase_time, progress, modulate)
		if is_elite:
			_draw_elite_part(kind, "placas_", pos, flip_x, dir_suffix, elite_scale, action, progress, modulate)
		# Art Bible §3.2 & Lote 02 §3: Anomalia Menor has Magenta emitter ring & dorsal crystal accents
		if kind == "anomalia_menor":
			var emitter_pos := pos + Vector2(0, -26 * elite_scale) + look_vec * (22.0 * elite_scale)
			var emitter_r := (6.5 if enemy.phase == "windup" else 4.0) * elite_scale
			draw_circle(emitter_pos, emitter_r + 2.5, INK)
			draw_circle(emitter_pos, emitter_r, MAGENTA_BRIGHT if enemy.phase == "windup" else MAGENTA)
		if is_elite:
			_draw_elite_part(kind, "coroa_", pos, flip_x, dir_suffix, elite_scale, action, progress, modulate)
		if enemy.hp < enemy.max_hp:
			var bar_y := (-108.0 if kind == "eco_perdido" else -82.0) - (10.0 if is_elite else 0.0)
			draw_rect(Rect2(pos + Vector2(-28, bar_y), Vector2(56, 5)), INK)
			draw_rect(Rect2(pos + Vector2(-28, bar_y), Vector2(56 * maxf(0, enemy.hp / enemy.max_hp), 5)), tint)
		return
	# Procedural fallback
	var flesh := Color("6a596e") if kind == "eco_perdido" else Color("5c4b65")
	if spawning:
		flesh.a = 0.4
	if enemy.get("flash", 0) > 0:
		flesh = BONE
	if kind == "eco_perdido":
		var shape := PackedVector2Array([pos + Vector2(-radius, 0), pos + Vector2(-radius - 5, -30), pos + Vector2(-13, -65), pos + Vector2(9, -68), pos + Vector2(radius + 4, -31), pos + Vector2(radius, 0), pos + Vector2(3, -8)])
		draw_colored_polygon(shape, flesh)
		draw_polyline(_closed(shape), INK, 6, true)
		draw_line(pos + Vector2(-10, -49), pos + Vector2(-3, -46), tint, 3, true)
		draw_line(pos + Vector2(3, -46), pos + Vector2(10, -49), tint, 3, true)
		draw_line(pos + Vector2(-radius, -22), pos + Vector2(-radius - 13, -5), INK, 7)
	else:
		var shape := PackedVector2Array([pos + Vector2(0, -74), pos + Vector2(radius + 10, -38), pos + Vector2(radius, -3), pos + Vector2(-5, 8), pos + Vector2(-radius - 12, -22), pos + Vector2(-radius, -51)])
		draw_colored_polygon(shape, flesh)
		draw_polyline(_closed(shape), INK, 6, true)
		draw_line(pos + Vector2(-4, -58), pos + Vector2(10, -30), tint, 4, true)
		draw_line(pos + Vector2(10, -30), pos + Vector2(-9, -13), tint, 4, true)
	if is_elite:
		draw_polyline(PackedVector2Array([pos + Vector2(-20, -76), pos + Vector2(-17, -92), pos + Vector2(0, -81), pos + Vector2(17, -92), pos + Vector2(20, -76)]), GOLD, 3, true)
	if enemy.hp < enemy.max_hp:
		draw_rect(Rect2(pos + Vector2(-28, -91), Vector2(56, 5)), INK)
		draw_rect(Rect2(pos + Vector2(-28, -91), Vector2(56 * maxf(0, enemy.hp / enemy.max_hp), 5)), tint)

func _draw_actor_sprite(actor_id: String, anim_name: String, pos: Vector2, flip_x: float, scale_mult: float, time_sec: float, norm_progress: float, modulate: Color) -> void:
	var frames: SpriteFrames = _frames_by_actor.get(actor_id)
	var manifest: Dictionary = _manifests_by_actor.get(actor_id, {})
	if frames == null or not frames.has_animation(anim_name):
		return
	var count := frames.get_frame_count(anim_name)
	if count <= 0:
		return
	var frame_idx := 0
	if norm_progress >= 0.0:
		frame_idx = clampi(floori(norm_progress * float(count)), 0, count - 1)
	else:
		var total_dur := 0.0
		for i in range(count):
			total_dur += frames.get_frame_duration(anim_name, i)
		var speed := frames.get_animation_speed(anim_name)
		var cursor := fmod(maxf(0.0, time_sec) * speed, maxf(0.001, total_dur))
		for i in range(count):
			cursor -= frames.get_frame_duration(anim_name, i)
			if cursor < 0.0:
				frame_idx = i
				break
	var tex := frames.get_frame_texture(anim_name, frame_idx)
	if tex == null:
		return
	var anim_meta: Dictionary = manifest.get("animations", {}).get(anim_name, {})
	var base_scale := float(anim_meta.get("scale", 0.4)) * scale_mult
	draw_set_transform(pos, 0.0, Vector2(flip_x * base_scale, base_scale))
	tex.draw_rect(get_canvas_item(), Rect2(-PIVOT, Vector2(400, 400)), false, modulate)
	draw_set_transform(Vector2.ZERO)

func _draw_elite_part(kind: String, part_prefix: String, pos: Vector2, flip_x: float, dir_suffix: String, elite_scale: float, action: String, progress: float, modulate: Color) -> void:
	if not _frames_by_actor.has("elite_pecas"):
		if part_prefix == "coroa_":
			var crown_y := -96.0 if kind == "eco_perdido" else -68.0
			var crown := PackedVector2Array([
				pos + Vector2(-20, crown_y),
				pos + Vector2(-17, crown_y - 16),
				pos + Vector2(0, crown_y - 5),
				pos + Vector2(17, crown_y - 16),
				pos + Vector2(20, crown_y)
			])
			draw_polyline(crown, INK, 6, true)
			draw_polyline(crown, GOLD, 3, true)
		return
	var frames: SpriteFrames = _frames_by_actor["elite_pecas"]
	var part_anim := part_prefix + kind
	if not frames.has_animation(part_anim):
		return
	var tex := frames.get_frame_texture(part_anim, 0)
	if tex == null:
		return
	var manifest: Dictionary = _manifests_by_actor.get("elite_pecas", {})
	var meta: Dictionary = manifest.get("animations", {}).get(part_anim, {})
	var part_scale := float(meta.get("scale", 0.18)) * elite_scale
	var off_arr: Array = meta.get("offset", [0.0, -60.0])
	var pose_y := 0.0
	if action == "spawn" and progress >= 0.0:
		pose_y = (1.0 - progress) * 14.0
	elif action in ["windup", "recover"]:
		pose_y = 3.0
	elif action == "death" and progress >= 0.0:
		pose_y = progress * 18.0
	var off := Vector2(float(off_arr[0]) * flip_x, float(off_arr[1]) + pose_y)
	var part_mod := modulate
	if dir_suffix == "costas34" and part_prefix == "placas_":
		off.y -= 3.0
		if kind == "eco_perdido":
			part_mod.a *= 0.88
	var part_pos := pos + off * elite_scale
	draw_set_transform(part_pos, 0.0, Vector2(flip_x * part_scale, part_scale))
	tex.draw_rect(get_canvas_item(), Rect2(-PIVOT, Vector2(400, 400)), false, part_mod)
	draw_set_transform(Vector2.ZERO)

func _telegraph(enemy: Dictionary, fill: bool) -> void:
	var pos: Vector2 = enemy.pos
	var direction: Vector2 = enemy.aim
	var data: Dictionary = app.catalog.data.inimigos[enemy.kind]
	var color := Color(MAGENTA, 0.13) if fill else Color(MAGENTA, 0.95)
	if enemy.kind == "anomalia_menor":
		var side := direction.orthogonal() * float(data.tele_largura_px) / 2
		var end := pos + direction * float(data.tele_comprimento_max_px)
		var poly := PackedVector2Array([pos + side, end + side, end - side, pos - side])
		if fill: draw_colored_polygon(poly, color)
		else:
			draw_line(pos + side, end + side, color, 2, true)
			draw_line(pos - side, end - side, color, 2, true)
	else:
		var angle := deg_to_rad(float(data.tele_meio_angulo_graus))
		var poly := _sector(pos, direction.angle(), angle, float(data.tele_raio_px))
		if fill: draw_colored_polygon(poly, color)
		else: draw_polyline(_closed(poly), color, 3, true)
	if not fill:
		var progress := 1.0 - float(enemy.timer) / maxf(1, roundf(float(data.preparo_s) * 60))
		draw_arc(pos, enemy.radius + 10, -PI / 2, -PI / 2 + TAU * clampf(progress, 0.01, 1), 30, MAGENTA, 4, true)

func _effect(effect: Dictionary) -> void:
	var duration: float = maxf(0.001, float(effect.get("duration", 0.2)))
	var progress := clampf(float(effect.get("age", 0)) / duration, 0, 0.999)
	var alpha := clampf(1.0 - progress, 0, 1)
	var pos: Vector2 = effect.get("pos", Vector2.ZERO)
	var direction: Vector2 = effect.get("dir", Vector2.RIGHT)
	match effect.get("kind", ""):
		"attack":
			var radius: float = effect.get("radius", 142.5)
			var angle: float = effect.get("angle", 1.21)
			draw_arc(pos, radius, direction.angle() - angle, direction.angle() + angle, 32, Color(BONE, alpha), 6, true)
			draw_arc(pos, radius - 12, direction.angle() - angle * .8, direction.angle() + angle * .8, 24, Color(BONE, alpha * .35), 3, true)
		"death":
			var actor_kind := String(effect.get("actor_kind", ""))
			if _frames_by_actor.has(actor_kind):
				var dir_suffix := "costas34" if direction.y < -0.15 else "frente34"
				var flip_x := -1.0 if direction.x < -0.05 else 1.0
				var is_elite_death := bool(effect.get("elite", false))
				var elite_scale := 1.15 if is_elite_death else 1.0
				var death_mod := Color(1, 1, 1, alpha)
				_draw_actor_sprite(actor_kind, "death_" + dir_suffix, pos, flip_x, elite_scale, 0.0, progress, death_mod)
				if is_elite_death:
					_draw_elite_part(actor_kind, "placas_", pos, flip_x, dir_suffix, elite_scale, "death", progress, death_mod)
					_draw_elite_part(actor_kind, "coroa_", pos, flip_x, dir_suffix, elite_scale, "death", progress, death_mod)
			for i in range(7):
				var ray := Vector2.RIGHT.rotated(i * TAU / 7 + 0.3)
				draw_line(pos + ray * (8 + 30 * (1 - alpha)), pos + ray * (19 + 40 * (1 - alpha)), Color(BONE, alpha), 3, true)
		"hit", "hurt":
			var tint := MAGENTA if effect.kind == "hurt" else BONE
			for i in range(7):
				var ray := Vector2.RIGHT.rotated(i * TAU / 7 + 0.3)
				draw_line(pos + ray * (8 + 30 * (1 - alpha)), pos + ray * (19 + 40 * (1 - alpha)), Color(tint, alpha), 3, true)
		"special":
			draw_line(pos - direction * 45, pos + direction * 45, Color(BONE, alpha * .6), 8, true)
		"enemy_attack":
			draw_arc(pos, float(effect.get("radius", 90)), direction.angle() - 1.2, direction.angle() + 1.2, 24, Color(MAGENTA, alpha), 5, true)

func _sector(pos: Vector2, angle: float, half: float, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array([pos])
	for i in range(25):
		points.append(pos + Vector2.RIGHT.rotated(angle - half + 2 * half * i / 24) * radius)
	return points

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result
