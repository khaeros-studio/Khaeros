extends Node2D
## Renders runtime SpriteFrames atlases (Lote 01 & Lote 02) with procedural fallback; reads simulation values without changing gameplay.

const INK := Color("0d0e14")
const STONE := Color("252936")
const BONE := Color("cfc6b4")
const MAGENTA := Color("e0259c")
const MAGENTA_BRIGHT := Color("f070c0")
const GOLD := Color("e3b23c")
const PIVOT := Vector2(200, 320)
const ACTOR_IDS := [
	"iniciado_lamina", "iniciado_pactos", "iniciado_ressonancia", "iniciado_guardiao", "iniciado_veu",
	"eco_perdido", "anomalia_menor", "fenda_errante", "elite_pecas",
	"vulto_mudo", "espreitador_da_fenda", "baluarte_de_cinza", "soberano_do_limiar",
	"chefe_soberano_limiar", "chefe_guardiao_rito", "chefe_colosso_cinza", "chefe_arconte_fenda"
]

var app: Node
var _atlases_loaded := false
var _frames_by_actor: Dictionary = {}
var _manifests_by_actor: Dictionary = {}
var _env_textures: Dictionary = {}

func _carregar_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := load(path) as Texture2D
		if res != null:
			return res
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

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
	for env_name: String in [
		"chao_laje_01", "chao_laje_02", "chao_laje_03", "chao_laje_04",
		"obstaculo_rocha_01", "obstaculo_rocha_02", "obstaculo_rocha_03", "obstaculo_coluna_04",
		"porta_fechada", "porta_aberta", "porta_chefe", "altar_santuario",
		"pedestal_pacto", "totem_bencao"
	]:
		var tex := _carregar_tex("res://assets/art/environment/limiar/%s.png" % env_name)
		if tex != null:
			_env_textures[env_name] = tex
	for bioma: String in ["veio_instavel", "fosso_das_cinzas", "santuario_partido"]:
		for peca: String in ["chao_01", "chao_02", "portal", "obstaculo_01", "obstaculo_02", "obstaculo_03"]:
			var b_tex := _carregar_tex("res://assets/art/environment/%s/%s.png" % [bioma, peca])
			if b_tex != null:
				_env_textures["%s_%s" % [bioma, peca]] = b_tex

func _draw() -> void:
	if app == null or not app.ready_to_play:
		return
	_ensure_atlases()
	var session = app.session
	var data: Dictionary = app.catalog.data
	var room := Rect2(0, 0, data.arena.largura, data.arena.altura)
	if session.state in ["campus", "mestres"]:
		_draw_campus(room)
		return
	var reg: Dictionary = session.current_region if session.get("current_region") is Dictionary else {}
	var bg_col: Color = _cor_regiao(reg, "bg", Color("0e101a"))
	var floor_col: Color = _cor_regiao(reg, "floor", Color("1d212b"))
	var border_col: Color = _cor_regiao(reg, "border", Color("383b46"))
	var accent_col: Color = _cor_regiao(reg, "accent", Color("2b303d"))
	draw_rect(room.grow(1000), bg_col)
	draw_rect(room.grow(36), INK)
	draw_rect(room, floor_col)
	draw_rect(room.grow(-18), border_col, false, 3)
	draw_rect(room.grow(-36), Color(border_col.r, border_col.g, border_col.b, 0.55), false, 2)
	# Quiet geometric floor + biome-specific floor slabs; detail remains below danger indicators.
	var reg_id: String = String(reg.get("id", "limiar"))
	for x in range(120, int(room.size.x), 240):
		for y in range(120, int(room.size.y), 240):
			var tile_tex: Texture2D = null
			if reg_id != "limiar":
				var b_idx := ((x / 240) + (y / 240)) % 2 + 1
				tile_tex = _env_textures.get("%s_chao_0%d" % [reg_id, b_idx], null)
			if tile_tex == null:
				var tile_idx := ((x / 240) + (y / 240)) % 4 + 1
				tile_tex = _env_textures.get("chao_laje_0%d" % tile_idx, null)
			if tile_tex != null:
				draw_texture_rect(tile_tex, Rect2(x - 110, y - 110, 220, 220), false, Color(1, 1, 1, 0.34))
			else:
				var offset := float((x / 240 + y / 240) % 3) * 12
				draw_line(Vector2(x - 45, y + offset), Vector2(x + 45, y + offset), Color("272c37"), 1)
				draw_line(Vector2(x, y - 45 + offset), Vector2(x, y + 45 + offset), Color("272c37"), 1)
	var center := room.get_center()
	draw_arc(center, 220, 0, TAU, 96, Color(accent_col.r, accent_col.g, accent_col.b, 0.65), 2, true)
	draw_arc(center, 236, 0, TAU, 96, Color(border_col.r, border_col.g, border_col.b, 0.45), 2, true)
	for i in range(12):
		var direction := Vector2.RIGHT.rotated(i * TAU / 12)
		draw_line(center + direction * 205, center + direction * 250, Color(border_col.r, border_col.g, border_col.b, 0.55), 3)
	if not reg.is_empty():
		_draw_region_details(room, reg, accent_col, float(session.presentation_time))
	# Door motif: biome ritual gate beyond the far wall.
	var gate := Vector2(room.size.x / 2, 15)
	var gate_tex: Texture2D = null
	if reg_id != "limiar":
		gate_tex = _env_textures.get("%s_portal" % reg_id, null)
	if gate_tex == null:
		var gate_key := "porta_aberta" if session.enemies.is_empty() else "porta_fechada"
		gate_tex = _env_textures.get(gate_key, null)
	if gate_tex != null:
		draw_texture_rect(gate_tex, Rect2(gate + Vector2(-95, -165), Vector2(190, 180)), false)
	else:
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
		if app.get("selected_weapon") == &"pactos":
			var c_prev: Vector2 = app.get("companion_prev") if app.get("companion_prev") != null else position
			var c_curr: Vector2 = app.get("companion_pos") if app.get("companion_pos") != null else position
			bodies.append({"type": "companion", "pos": c_prev.lerp(c_curr, interpolation), "order": 49})
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
			"pillar": _pillar(body.pos, body.radius, int(body.order))
			"player": _player(body.pos, body.entity)
			"companion": _companion(body.pos)
			"enemy": _enemy(body.pos, body.entity)
	for enemy in session.enemies:
		if enemy.get("phase", "") == "windup":
			_telegraph(enemy, false)
	for projectile in session.projectiles:
		var pos: Vector2 = projectile.get("prev", projectile.pos).lerp(projectile.pos, interpolation)
		var p_kind := String(projectile.get("kind", "enemy"))
		var vel: Vector2 = projectile.get("velocity", Vector2.RIGHT)
		var dir: Vector2 = vel.normalized() if vel != Vector2.ZERO else Vector2.RIGHT
		if p_kind == "magic_orb":
			var cyan := Color("7dd3fc")
			draw_line(pos - dir * (projectile.radius * 2.4), pos, Color(cyan, 0.45), projectile.radius * 0.9, true)
			draw_circle(pos, projectile.radius + 7, Color(cyan, 0.28))
			draw_circle(pos, projectile.radius + 3, INK)
			draw_circle(pos, projectile.radius, cyan)
			draw_circle(pos, projectile.radius * 0.55, GOLD)
			draw_circle(pos - Vector2(3, 3), projectile.radius * 0.28, BONE)
		elif p_kind == "bolt":
			var r_bolt: float = float(projectile.radius)
			var tail: Vector2 = pos - dir * (r_bolt * 1.8)
			var tip: Vector2 = pos + dir * (r_bolt * 1.5)
			draw_line(tail, tip, INK, 10.0, true)
			draw_line(tail, pos + dir * (r_bolt * 0.6), BONE, 5.0, true)
			draw_line(pos + dir * (r_bolt * 0.4), tip, GOLD, 5.0, true)
		else:
			draw_circle(pos, projectile.radius + 5, INK)
			draw_circle(pos, projectile.radius, MAGENTA)
			draw_circle(pos - Vector2(3, 3), projectile.radius * 0.35, BONE)
	for effect in session.effects:
		_effect(effect)

func _cor_regiao(reg: Dictionary, key: String, fallback: Color) -> Color:
	if reg.is_empty():
		return fallback
	var fonte: Variant = reg.get("paleta", {})
	var val: Variant = null
	if fonte is Dictionary and (fonte as Dictionary).has(key):
		val = (fonte as Dictionary)[key]
	elif reg.has(key):
		val = reg[key]
	if val is Color:
		return val as Color
	if val is String and not String(val).is_empty():
		return Color(String(val))
	return fallback

func _draw_region_details(room: Rect2, reg: Dictionary, accent: Color, t: float) -> void:
	var reg_id: String = String(reg.get("id", reg.get("tema", ""))).to_lower()
	var center: Vector2 = room.get_center()
	if reg_id.contains("veio"):
		# Fissuras diagonais brilhantes em magenta/ouro
		var fissuras: Array[Array] = [
			[Vector2(260, 220), Vector2(540, 410), Vector2(690, 360)],
			[Vector2(1740, 260), Vector2(2040, 510), Vector2(2190, 470)],
			[Vector2(340, 960), Vector2(640, 1140), Vector2(820, 1080)],
			[Vector2(1620, 940), Vector2(1920, 1160), Vector2(2140, 1110)],
		]
		var pulso: float = 0.24 + 0.08 * sin(t * 2.2)
		for f: Array in fissuras:
			var p0: Vector2 = f[0]
			var p1: Vector2 = f[1]
			var p2: Vector2 = f[2]
			draw_line(p0, p1, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, pulso), 5.0, true)
			draw_line(p1, p2, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, pulso), 4.0, true)
			draw_line(p0, p1, Color(GOLD.r, GOLD.g, GOLD.b, pulso * 0.9), 2.0, true)
			draw_line(p1, p2, Color(GOLD.r, GOLD.g, GOLD.b, pulso * 0.9), 1.5, true)
	elif reg_id.contains("cinza") or reg_id.contains("fosso"):
		# Manchas de cinza e brasas alaranjadas suaves
		var manchas: Array[Vector2] = [
			Vector2(420, 340), Vector2(1980, 360), Vector2(520, 980),
			Vector2(1880, 1000), Vector2(1200, 340), Vector2(1200, 1020),
		]
		var brasa: Color = Color("e86a2c")
		var brasa_clara: Color = Color("ff9e44")
		for idx: int in range(manchas.size()):
			var mp: Vector2 = manchas[idx]
			draw_circle(mp, 92.0, Color(0.08, 0.07, 0.09, 0.28))
			draw_circle(mp + Vector2(18, -12), 54.0, Color(0.14, 0.12, 0.14, 0.22))
			var glow: float = 0.16 + 0.07 * sin(t * 2.6 + float(idx) * 1.1)
			draw_circle(mp + Vector2(-14, 8), 18.0, Color(brasa.r, brasa.g, brasa.b, glow))
			draw_circle(mp + Vector2(-14, 8), 7.0, Color(brasa_clara.r, brasa_clara.g, brasa_clara.b, glow * 1.3))
			draw_circle(mp + Vector2(26, -16), 11.0, Color(brasa.r, brasa.g, brasa.b, glow * 0.85))
	elif reg_id.contains("santuario"):
		# Anéis geométricos dourados/ciano no centro
		var cyan: Color = Color("7dd3fc")
		draw_arc(center, 310.0, 0, TAU, 96, Color(GOLD.r, GOLD.g, GOLD.b, 0.28), 2.5, true)
		draw_arc(center, 150.0, 0, TAU, 72, Color(cyan.r, cyan.g, cyan.b, 0.30), 2.0, true)
		draw_arc(center, 96.0, 0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 2.0, true)
		for i: int in range(8):
			var ang: float = float(i) * TAU / 8.0 + t * 0.06
			var d: Vector2 = Vector2.RIGHT.rotated(ang)
			draw_line(center + d * 96.0, center + d * 150.0, Color(cyan.r, cyan.g, cyan.b, 0.24), 2.0, true)
			draw_line(center + d * 240.0, center + d * 310.0, Color(accent.r, accent.g, accent.b, 0.32), 2.5, true)

func _draw_campus(room: Rect2) -> void:
	draw_rect(room.grow(1000), Color("0e101a"))
	draw_rect(room.grow(36), INK)
	draw_rect(room, Color("1a1e28"))
	for x in range(120, int(room.size.x), 240):
		for y in range(120, int(room.size.y), 240):
			var tile_idx := ((x / 240) + (y / 240)) % 4 + 1
			var tile_tex: Texture2D = _env_textures.get("chao_laje_0%d" % tile_idx, null)
			if tile_tex != null:
				draw_texture_rect(tile_tex, Rect2(x - 110, y - 110, 220, 220), false, Color(1, 1, 1, 0.35))
	draw_rect(CampusHub.LIMITE_CAMPUS, Color("383b46"), false, 3.0)
	var center := room.get_center()
	draw_arc(center, 220, 0, TAU, 96, Color("2b303d"), 2, true)
	var campus: CampusHub = app.get("campus") as CampusHub
	var focada := campus.zona_focada() if campus != null else &""
	var zonas_visuais: Array[Dictionary] = [
		{"id": CampusHub.ZONA_PORTAL, "pos": Vector2(960, 190), "tex": "porta_aberta", "size": Vector2(180, 170), "offset": Vector2(-90, -135)},
		{"id": CampusHub.ZONA_MESTRES, "pos": Vector2(960, 320), "tex": "altar_santuario", "size": Vector2(190, 160), "offset": Vector2(-95, -105)},
		{"id": CampusHub.ZONA_OFICINA, "pos": Vector2(420, 420), "tex": "pedestal_pacto", "size": Vector2(160, 140), "offset": Vector2(-80, -90)},
		{"id": CampusHub.ZONA_DOUTRINAS, "pos": Vector2(1500, 420), "tex": "totem_bencao", "size": Vector2(140, 160), "offset": Vector2(-70, -115)},
	]
	for z: Dictionary in zonas_visuais:
		var z_pos: Vector2 = z["pos"]
		var is_focused: bool = (z["id"] == focada)
		draw_circle(z_pos, CampusHub.RAIO_INTERACAO_PX, Color(GOLD, 0.14 if is_focused else 0.04))
		draw_arc(z_pos, CampusHub.RAIO_INTERACAO_PX, 0, TAU, 48, GOLD if is_focused else Color("3a3e4d"), 3.0 if is_focused else 1.5, true)
		var tex: Texture2D = _env_textures.get(String(z["tex"]), null)
		if tex != null:
			draw_texture_rect(tex, Rect2(z_pos + z["offset"], z["size"]), false)
		else:
			draw_circle(z_pos, 42.0, STONE)
			draw_arc(z_pos, 42.0, 0, TAU, 32, GOLD if is_focused else BONE, 3.0, true)
	# Três Mestres junto ao Altar dos Mestres (Halvar, Maren, Oreth)
	var mestres_pos: Array[Dictionary] = [
		{"pos": Vector2(885, 315), "cor": Color("e09f5a")},
		{"pos": Vector2(960, 295), "cor": Color("7dd3fc")},
		{"pos": Vector2(1035, 315), "cor": Color("b388eb")},
	]
	for m: Dictionary in mestres_pos:
		var mp: Vector2 = m["pos"]
		draw_circle(mp, 16.0, INK)
		draw_circle(mp + Vector2(0, -18), 11.0, m["cor"])
		draw_arc(mp + Vector2(0, -18), 13.0, 0, TAU, 20, BONE, 1.5, true)
	if campus != null:
		var interp := Engine.get_physics_interpolation_fraction()
		var p_pos: Vector2 = campus.prev_pos.lerp(campus.pos, interp)
		draw_set_transform(p_pos, 0, Vector2(1, 0.38))
		draw_circle(Vector2(3, 8), 38.0, Color(INK.r, INK.g, INK.b, 0.68))
		draw_set_transform(Vector2.ZERO)
		var campus_player := {
			"pos": campus.pos,
			"prev": campus.prev_pos,
			"aim": campus.aim,
			"hp": 100.0,
			"dash_remaining": 0,
			"lunge_remaining": 0,
			"attack_cd": 0,
			"flash": 0,
			"inv": 0,
		}
		_player(p_pos, campus_player)


func _pillar(pos: Vector2, radius: float, index: int = 0) -> void:
	var reg: Dictionary = app.session.current_region if app != null and app.session != null and app.session.get("current_region") is Dictionary else {}
	var reg_id: String = String(reg.get("id", "limiar"))
	var tex: Texture2D = null
	if reg_id != "limiar":
		var b_key := "%s_obstaculo_0%d" % [reg_id, (index % 3) + 1]
		tex = _env_textures.get(b_key, null)
	if tex == null:
		var rock_keys := ["obstaculo_rocha_01", "obstaculo_rocha_02", "obstaculo_rocha_03", "obstaculo_coluna_04"]
		tex = _env_textures.get(rock_keys[index % rock_keys.size()], null)
	if tex != null:
		var w := radius * 2.6
		var h := radius * 3.4
		draw_texture_rect(tex, Rect2(pos + Vector2(-w * 0.5, -h * 0.78), Vector2(w, h)), false)
		return
	var base := PackedVector2Array([pos + Vector2(-radius, 0), pos + Vector2(-radius - 7, -105), pos + Vector2(-18, -145), pos + Vector2(radius, -124), pos + Vector2(radius + 8, -12), pos + Vector2(radius * 0.5, 14)])
	draw_colored_polygon(base, Color("303441"))
	draw_polyline(_closed(base), INK, 7, true)
	draw_line(pos + Vector2(-15, -130), pos + Vector2(-13, -6), Color("4c4d59"), 4)
	draw_line(pos + Vector2(8, -100), pos + Vector2(13, -58), Color("171c28"), 3)
	draw_line(pos + Vector2(13, -58), pos + Vector2(4, -35), Color("171c28"), 3)
	draw_arc(pos, radius, 0, PI, 18, Color("53515b"), 3, true)

func _draw_cetro_magico(pos: Vector2, aim: Vector2, time_sec: float, casting: bool) -> void:
	var dir := aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT
	var hand := pos + Vector2(0, -34) + dir * 14.0
	var base := hand - dir * 18.0
	var ponta := hand + dir * 38.0
	var perp := dir.orthogonal()
	draw_line(base, ponta, INK, 9.0, true)
	draw_line(base, ponta, Color("494356"), 4.5, true)
	draw_line(ponta - dir * 7.0 - perp * 7.0, ponta - dir * 7.0 + perp * 7.0, GOLD, 4.0, true)
	var orb_pos := ponta + dir * (6.0 + sin(time_sec * 6.0) * 1.5)
	var orb_r := 8.0 if casting else 6.0
	var cyan := Color("7dd3fc")
	draw_circle(orb_pos, orb_r + 5.0, Color(cyan, 0.35 if casting else 0.22))
	draw_circle(orb_pos, orb_r + 2.0, INK)
	draw_circle(orb_pos, orb_r, cyan)
	draw_circle(orb_pos, orb_r * 0.45, GOLD)

func _companion(pos: Vector2) -> void:
	var sp := String(app.get("companion_species") if app.get("companion_species") != null else &"vulto_mudo")
	if _frames_by_actor.has(sp):
		var c_prev: Vector2 = app.get("companion_prev") if app.get("companion_prev") != null else pos
		var c_curr: Vector2 = app.get("companion_pos") if app.get("companion_pos") != null else pos
		var delta := c_curr - c_prev
		var dir_suffix := "costas34" if delta.y < -0.15 else "frente34"
		var flip_x := -1.0 if delta.x < -0.05 else 1.0
		var action := "run" if delta.length_squared() > 0.04 else "idle"
		_draw_actor_sprite(sp, action + "_" + dir_suffix, pos, flip_x, 0.9, app.session.presentation_time, -1.0, Color.WHITE)
		return
	draw_circle(pos + Vector2(0, -24), 18, INK)
	draw_circle(pos + Vector2(0, -24), 13, BONE)

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
	var w_id: StringName = app.get("selected_weapon") if app.get("selected_weapon") != null else &"lamina"
	var player_actor := "iniciado_lamina"
	if w_id == &"ressonancia" and _frames_by_actor.has("iniciado_ressonancia"):
		player_actor = "iniciado_ressonancia"
	elif w_id == &"pactos" and _frames_by_actor.has("iniciado_pactos"):
		player_actor = "iniciado_pactos"
	elif w_id == &"guardiao" and _frames_by_actor.has("iniciado_guardiao"):
		player_actor = "iniciado_guardiao"
	elif w_id == &"veu" and _frames_by_actor.has("iniciado_veu"):
		player_actor = "iniciado_veu"
	if _frames_by_actor.has(player_actor):
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
		elif int(player.get("attack_cd", 0)) > 0 and w_id != &"pactos":
			var combo_idx := int(player.get("combo", 1))
			action = "attack1" if (w_id != &"lamina" or combo_idx == 1) else ("attack2" if combo_idx == 2 else "attack3")
			var a_total := maxf(1.0, roundf(float(data.corte.recarga_s) * 60.0))
			progress = clampf(1.0 - float(player.attack_cd) / a_total, 0.0, 0.999)
		elif int(player.get("flash", 0)) > 0:
			action = "hurt"
			progress = 0.0
		elif player.pos.distance_squared_to(player.get("prev", player.pos)) > 0.04:
			action = "run"
		var anim_name := action + "_" + dir_suffix
		if not _frames_by_actor[player_actor].has_animation(anim_name):
			anim_name = "idle_" + dir_suffix
		var modulate := Color.WHITE
		if int(player.get("flash", 0)) > 0:
			modulate = BONE
		_draw_actor_sprite(player_actor, anim_name, pos, flip_x, 1.0, session.presentation_time, progress, modulate)
		if w_id == &"guardiao":
			draw_arc(pos, 40.0, 0, TAU, 36, Color(GOLD, 0.30), 2.0, true)
		elif w_id == &"veu":
			draw_arc(pos, 38.0, 0, TAU, 36, Color(Color("5b2d8a"), 0.40), 2.0, true)
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
	var sprite_kind := kind
	var boss_scale: float = 1.0
	var is_boss: bool = bool(enemy.get("is_boss", false)) or kind in [
		"anomalia_maior", "soberano_do_limiar", "guardiao_do_rito", "colosso_de_cinza", "arconte_da_fenda"
	]
	var boss_modulate: Color = Color.WHITE
	var boss_aura: Color = MAGENTA
	if is_boss:
		match kind:
			"soberano_do_limiar":
				boss_scale = 1.55
				boss_modulate = Color.WHITE
				boss_aura = GOLD
				sprite_kind = "chefe_soberano_limiar"
			"guardiao_do_rito":
				boss_scale = 1.18
				boss_modulate = Color.WHITE
				boss_aura = MAGENTA
				sprite_kind = "chefe_guardiao_rito" if _frames_by_actor.has("chefe_guardiao_rito") else "chefe_soberano_limiar"
			"colosso_de_cinza":
				boss_scale = 1.25
				boss_modulate = Color.WHITE
				boss_aura = Color("e86a2c")
				sprite_kind = "chefe_colosso_cinza" if _frames_by_actor.has("chefe_colosso_cinza") else "chefe_soberano_limiar"
			"arconte_da_fenda":
				boss_scale = 1.22
				boss_modulate = Color.WHITE
				boss_aura = Color("7dd3fc")
				sprite_kind = "chefe_arconte_fenda" if _frames_by_actor.has("chefe_arconte_fenda") else "chefe_soberano_limiar"
			_:
				boss_scale = 1.55
				boss_modulate = Color(1.05, 0.78, 1.0, 1.0)
				boss_aura = MAGENTA
				sprite_kind = "chefe_soberano_limiar"
		if not _frames_by_actor.has(sprite_kind) and _frames_by_actor.has("anomalia_menor"):
			sprite_kind = "anomalia_menor"
	if _frames_by_actor.has(sprite_kind):
		var def: Dictionary = session.enemy_def(kind) if session.has_method("enemy_def") else data.inimigos.get(kind, {})
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
		if not _frames_by_actor[sprite_kind].has_animation(anim_name):
			anim_name = "idle_" + dir_suffix
		var elite_scale := (1.15 if is_elite else 1.0) * boss_scale
		var modulate: Color = boss_modulate if is_boss else Color.WHITE
		if spawning:
			modulate.a = 0.65
		if int(enemy.get("flash", 0)) > 0:
			modulate = Color(1.6, 1.55, 1.42, modulate.a)
		var phase_time: float = session.presentation_time + float(int(enemy.get("id", 0))) * 0.19
		_draw_actor_sprite(sprite_kind, anim_name, pos, flip_x, elite_scale, phase_time, progress, modulate)
		if is_boss:
			draw_arc(pos, radius + 14.0, 0, TAU, 48, Color(boss_aura.r, boss_aura.g, boss_aura.b, 0.52), 3.5, true)
			draw_arc(pos, radius + 24.0, 0, TAU, 48, Color(boss_aura.r, boss_aura.g, boss_aura.b, 0.22), 2.0, true)
			var crown_y: float = -112.0 * (boss_scale / 1.55)
			var crown := PackedVector2Array([
				pos + Vector2(-28, crown_y),
				pos + Vector2(-22, crown_y - 20),
				pos + Vector2(0, crown_y - 8),
				pos + Vector2(22, crown_y - 20),
				pos + Vector2(28, crown_y)
			])
			draw_polyline(crown, INK, 7.0, true)
			draw_polyline(crown, boss_aura, 3.5, true)
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
			var bar_y := (-128.0 if is_boss else (-108.0 if kind == "eco_perdido" else -82.0)) - (10.0 if is_elite else 0.0)
			var bar_w := 96.0 if is_boss else 56.0
			draw_rect(Rect2(pos + Vector2(-bar_w * 0.5, bar_y), Vector2(bar_w, 6 if is_boss else 5)), INK)
			draw_rect(Rect2(pos + Vector2(-bar_w * 0.5, bar_y), Vector2(bar_w * maxf(0, enemy.hp / enemy.max_hp), 6 if is_boss else 5)), boss_aura if is_boss else tint)
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
	var kind_str: String = String(enemy.get("kind", ""))
	var data: Dictionary = app.session.enemy_def(kind_str) if app.session.has_method("enemy_def") else app.catalog.data.inimigos.get(kind_str, {})
	var color := Color(MAGENTA, 0.13) if fill else Color(MAGENTA, 0.95)
	if kind_str == "anomalia_menor" or String(data.get("comportamento", "")) == "ranged":
		var side := direction.orthogonal() * float(data.get("tele_largura_px", 81.0)) / 2
		var end := pos + direction * float(data.get("tele_comprimento_max_px", 1728.0))
		var poly := PackedVector2Array([pos + side, end + side, end - side, pos - side])
		if fill: draw_colored_polygon(poly, color)
		else:
			draw_line(pos + side, end + side, color, 2, true)
			draw_line(pos - side, end - side, color, 2, true)
	else:
		var angle := deg_to_rad(float(data.get("tele_meio_angulo_graus", 85.0)))
		var poly := _sector(pos, direction.angle(), angle, float(data.get("tele_raio_px", 165.0)))
		if fill: draw_colored_polygon(poly, color)
		else: draw_polyline(_closed(poly), color, 3, true)
	if not fill:
		var progress := 1.0 - float(enemy.timer) / maxf(1, roundf(float(data.get("preparo_s", 0.5)) * 60))
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
			var atk_col := BONE
			if String(effect.get("weapon", "")) == "guardiao":
				atk_col = GOLD
			elif String(effect.get("weapon", "")) == "veu":
				atk_col = Color("9d6bff")
			draw_arc(pos, radius, direction.angle() - angle, direction.angle() + angle, 32, Color(atk_col, alpha), 7 if String(effect.get("weapon", "")) == "guardiao" else 6, true)
			draw_arc(pos, radius - 12, direction.angle() - angle * .8, direction.angle() + angle * .8, 24, Color(atk_col, alpha * .35), 3, true)
		"guardiao_bastion":
			var max_r: float = float(effect.get("radius", 180.0))
			var cur_r := maxf(24.0, max_r * (0.3 + 0.7 * progress))
			draw_circle(pos, cur_r, Color(GOLD, alpha * 0.16))
			draw_arc(pos, cur_r, 0, TAU, 48, Color(GOLD, alpha), 6.0, true)
			draw_arc(pos, cur_r * 0.85, 0, TAU, 40, Color(BONE, alpha * 0.8), 3.0, true)
		"veu_blink":
			var shadow_col := Color("6e39b3")
			draw_circle(pos, 22.0 + 36.0 * progress, Color(shadow_col, alpha * 0.35))
			draw_line(pos - direction * 55, pos + direction * 65, Color(shadow_col, alpha * 0.85), 10, true)
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
		"crit":
			for i in range(9):
				var ray := Vector2.RIGHT.rotated(i * TAU / 9 + 0.15)
				draw_line(pos + ray * (10 + 38 * (1 - alpha)), pos + ray * (26 + 52 * (1 - alpha)), Color(GOLD, alpha), 4, true)
		"hit", "hurt":
			var tint := MAGENTA if effect.kind == "hurt" else BONE
			for i in range(7):
				var ray := Vector2.RIGHT.rotated(i * TAU / 7 + 0.3)
				draw_line(pos + ray * (8 + 30 * (1 - alpha)), pos + ray * (19 + 40 * (1 - alpha)), Color(tint, alpha), 3, true)
		"special":
			draw_line(pos - direction * 45, pos + direction * 45, Color(BONE, alpha * .6), 8, true)
		"magic_cast":
			var cyan := Color("7dd3fc")
			draw_circle(pos, 14.0 * (1.0 - progress * 0.4), Color(cyan, alpha * 0.35))
			draw_arc(pos, 10.0 + 18.0 * progress, 0, TAU, 24, Color(cyan, alpha), 3.0, true)
			draw_arc(pos, 6.0 + 10.0 * progress, direction.angle() - 0.9, direction.angle() + 0.9, 16, Color(GOLD, alpha), 3.0, true)
		"magic_pulse":
			var max_r: float = float(effect.get("radius", 195.0))
			var cur_r := maxf(18.0, max_r * (0.25 + 0.75 * progress))
			var cyan := Color("7dd3fc")
			draw_circle(pos, cur_r, Color(cyan, alpha * 0.14))
			draw_arc(pos, cur_r, 0, TAU, 48, Color(cyan, alpha), 5.0, true)
			draw_arc(pos, cur_r * 0.82, 0, TAU, 40, Color(GOLD, alpha * 0.85), 3.0, true)
			for i in range(6):
				var a := i * TAU / 6.0 + progress * 0.8
				draw_arc(pos, cur_r * 0.91, a - 0.18, a + 0.18, 8, Color(GOLD, alpha), 4.0, true)
		"bolt_shot":
			var perp := direction.orthogonal()
			draw_line(pos, pos + direction * (26.0 * (0.4 + 0.6 * progress)), Color(GOLD, alpha), 4.0, true)
			draw_line(pos + perp * 8.0, pos + direction * 18.0 + perp * 14.0 * progress, Color(BONE, alpha), 2.5, true)
			draw_line(pos - perp * 8.0, pos + direction * 18.0 - perp * 14.0 * progress, Color(BONE, alpha), 2.5, true)
		"pact_call":
			var shock_r := 20.0 + 75.0 * progress
			draw_circle(pos, shock_r, Color(INK, alpha * 0.45))
			draw_arc(pos, shock_r, 0, TAU, 32, Color(INK, alpha), 7.0, true)
			draw_arc(pos, shock_r * 0.88, 0, TAU, 32, Color(BONE, alpha), 3.5, true)
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
