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
	for arena_id: String in ["limiar", "veio_instavel", "fosso_das_cinzas", "santuario_partido", "campus"]:
		var bg_tex := _carregar_tex("res://assets/art/environment/%s/arena_bg.png" % arena_id)
		if bg_tex != null:
			_env_textures["%s_arena_bg" % arena_id] = bg_tex
	for p_name: String in ["monolito_lore", "fonte_cura", "bau_reliquia", "estatua_guardiao", "altar_pacto", "coluna_correntes"]:
		var p_tex: Texture2D = _carregar_tex("res://assets/art/environment/props/%s.png" % p_name)
		if p_tex != null:
			_env_textures["prop_" + p_name] = p_tex

func _draw() -> void:
	if app == null or not app.ready_to_play:
		return
	_ensure_atlases()
	var session = app.session
	var data: Dictionary = app.catalog.data
	var sess_data_raw: Variant = session.get("data")
	if sess_data_raw is Dictionary and (sess_data_raw as Dictionary).has("arena"):
		data = sess_data_raw as Dictionary
	var arena_raw: Variant = data.get("arena", {})
	var arena_data: Dictionary = arena_raw if arena_raw is Dictionary else {}
	var room := Rect2(0.0, 0.0, float(arena_data.get("largura", 2400.0)), float(arena_data.get("altura", 1350.0)))
	if session.state in ["campus", "mestres"]:
		_draw_campus(room)
		return
	var reg: Dictionary = session.current_region if session.get("current_region") is Dictionary else {}
	var bg_col: Color = _cor_regiao(reg, "bg", Color("0e101a"))
	var floor_col: Color = _cor_regiao(reg, "floor", Color("1d212b"))
	var border_col: Color = _cor_regiao(reg, "border", Color("383b46"))
	var accent_col: Color = _cor_regiao(reg, "accent", Color("2b303d"))
	var reg_id: String = String(reg.get("id", "limiar"))
	var t_pres: float = float(session.presentation_time)
	draw_rect(room.grow(1000), bg_col)
	var arena_bg: Texture2D = _env_textures.get("%s_arena_bg" % reg_id, null)
	if arena_bg != null:
		# Ilustração pintada completa da câmara (piso + muralha norte + braseiros + falésia sul sobre o abismo)
		var sx: float = room.size.x / 2400.0
		var sy: float = room.size.y / 1350.0
		var bg_rect := Rect2(room.position.x - 240.0 * sx, room.position.y - 520.0 * sy, room.size.x + 480.0 * sx, room.size.y + 1430.0 * sy)
		draw_texture_rect(arena_bg, bg_rect, false)
	else:
		_draw_abyss_backdrop(room, bg_col, accent_col, border_col, t_pres)
		# Arquitetura de parede superior com profundidade 2.5D, contrafortes e nichos
		var wall_h: float = 136.0
		_draw_north_wall(room, wall_h, border_col, accent_col, reg_id, t_pres)
		draw_rect(room.grow(34), INK)
		# Falésia / paredão frontal de pedra 2.5D mergulhando no abismo (borda sul)
		_draw_south_cliff(room, border_col, accent_col, reg_id, t_pres)
		draw_rect(room, floor_col)
		# Lajes contínuas cobrindo 100% do piso sem frestas, com leve variação orgânica de luz
		for gx in range(0, int(room.size.x), 240):
			for gy in range(0, int(room.size.y), 240):
				var tile_tex: Texture2D = null
				var col_i: int = gx / 240
				var row_i: int = gy / 240
				var hash_v: int = (col_i * 7 + row_i * 13) % 4
				if reg_id != "limiar":
					var b_idx: int = (col_i + row_i) % 2 + 1
					tile_tex = _env_textures.get("%s_chao_0%d" % [reg_id, b_idx], null)
				if tile_tex == null:
					var tile_idx: int = (col_i + row_i) % 4 + 1
					tile_tex = _env_textures.get("chao_laje_0%d" % tile_idx, null)
				var tile_rect := Rect2(gx, gy, 242, 242)
				if tile_tex != null:
					var shade: float = 0.86 + float(hash_v) * 0.045
					var tile_alpha: float = 0.72 if reg_id != "limiar" else 0.58
					draw_texture_rect(tile_tex, tile_rect, false, Color(shade, shade, shade, tile_alpha))
				else:
					draw_rect(tile_rect, floor_col.darkened(0.06 if hash_v % 2 == 0 else 0.0))
					draw_rect(tile_rect, Color(border_col.r, border_col.g, border_col.b, 0.16), false, 1.5)
		# Quebra orgânica da grade do piso: manchas de desgaste, rachaduras sutis e sombras direcionais
		_draw_floor_organic_layers(room, floor_col, border_col)
		# Iluminação atmosférica suave no centro + vinheta emoldurando as 4 bordas internas
		var center := room.get_center()
		draw_circle(center, 620.0, Color(accent_col.r, accent_col.g, accent_col.b, 0.09))
		draw_circle(center, 360.0, Color(accent_col.r, accent_col.g, accent_col.b, 0.07))
		# Sombras projetadas direcionais das paredes norte e oeste (luz vinda do topo-esquerda)
		draw_rect(Rect2(room.position.x, room.position.y, room.size.x, 86.0), Color(INK.r, INK.g, INK.b, 0.22))
		draw_rect(Rect2(room.position.x, room.position.y, room.size.x, 48.0), Color(INK.r, INK.g, INK.b, 0.30))
		draw_rect(Rect2(room.position.x, room.position.y, 76.0, room.size.y), Color(INK.r, INK.g, INK.b, 0.20))
		draw_rect(Rect2(room.position.x, room.position.y, 38.0, room.size.y), Color(INK.r, INK.g, INK.b, 0.28))
		# Vinheta atmosférica suave nas 4 bordas internas da arena
		var vig_bands: Array[Array] = [[96.0, 0.10], [52.0, 0.16], [24.0, 0.24]]
		for vb: Array in vig_bands:
			var bw: float = float(vb[0])
			var ba: float = float(vb[1])
			var vcol := Color(INK.r, INK.g, INK.b, ba)
			draw_rect(Rect2(room.position.x, room.position.y, room.size.x, bw), vcol)
			draw_rect(Rect2(room.position.x, room.end.y - bw, room.size.x, bw), vcol)
			draw_rect(Rect2(room.position.x, room.position.y, bw, room.size.y), vcol)
			draw_rect(Rect2(room.end.x - bw, room.position.y, bw, room.size.y), vcol)
		# 4 Braseiros acesos na muralha norte com halos banhando parede e chão abaixo
		_draw_north_braziers(room, border_col, reg_id, t_pres)
		draw_rect(room.grow(-14), border_col, false, 4.0)
		draw_rect(room.grow(-28), Color(border_col.r, border_col.g, border_col.b, 0.42), false, 2.0)
		# 4 Pilastras de canto ancorando a arquitetura da câmara
		for corner: Vector2 in [room.position, Vector2(room.end.x, room.position.y), Vector2(room.position.x, room.end.y), room.end]:
			draw_rect(Rect2(corner - Vector2(26, 26), Vector2(52, 52)), INK)
			draw_rect(Rect2(corner - Vector2(20, 20), Vector2(40, 40)), border_col.darkened(0.2))
			draw_rect(Rect2(corner - Vector2(20, 20), Vector2(40, 40)), border_col.lightened(0.15), false, 2.0)
		draw_arc(center, 220, 0, TAU, 96, Color(accent_col.r, accent_col.g, accent_col.b, 0.48), 2.5, true)
		draw_arc(center, 238, 0, TAU, 96, Color(border_col.r, border_col.g, border_col.b, 0.36), 2.0, true)
		for i in range(12):
			var direction := Vector2.RIGHT.rotated(i * TAU / 12)
			draw_line(center + direction * 206, center + direction * 246, Color(border_col.r, border_col.g, border_col.b, 0.42), 2.5)
		if not reg.is_empty():
			_draw_region_details(room, reg, accent_col, t_pres)
	# Props ambientais, urnas rituais, poças de luz de tochas e vinheta cinematográfica sobre todas as arenas
	_draw_ambient_props_and_lights(room, reg_id, t_pres)
	# Partículas ambientais discretas por bioma
	var part_col: Color = Color("ff9e44") if reg_id.contains("cinza") or reg_id.contains("fosso") else (
		MAGENTA_BRIGHT if reg_id.contains("veio") else (Color("7dd3fc") if reg_id.contains("santuario") else BONE)
	)
	for p_i: int in range(18):
		var seed_x: float = fmod(float(p_i * 317 + 140), room.size.x - 160.0) + 80.0
		var seed_y: float = fmod(float(p_i * 193 + 90) - t_pres * (14.0 + float(p_i % 4) * 5.0), room.size.y - 120.0)
		if seed_y < 0.0:
			seed_y += room.size.y - 120.0
		var drift_x: float = sin(t_pres * 1.3 + float(p_i)) * 16.0
		var p_alpha: float = 0.14 + 0.10 * sin(t_pres * 2.1 + float(p_i) * 0.9)
		draw_circle(Vector2(seed_x + drift_x, seed_y + 60.0), 2.2 + float(p_i % 3) * 0.9, Color(part_col.r, part_col.g, part_col.b, p_alpha))
	# Door motif: biome ritual gate beyond the far wall (omitido quando arena_bg já pinta o portão ou há portas físicas).
	var exit_doors_raw: Variant = session.get("exit_doors")
	var has_exit_doors: bool = exit_doors_raw is Array and not (exit_doors_raw as Array).is_empty()
	if arena_bg == null and not has_exit_doors:
		var gate := Vector2(room.size.x / 2, 18)
		var gate_tex: Texture2D = null
		if reg_id != "limiar":
			gate_tex = _env_textures.get("%s_portal" % reg_id, null)
		if gate_tex == null:
			var gate_key := "porta_aberta" if session.enemies.is_empty() else "porta_fechada"
			gate_tex = _env_textures.get(gate_key, null)
		if gate_tex != null:
			draw_circle(gate + Vector2(0, -45), 96.0, Color(accent_col.r, accent_col.g, accent_col.b, 0.22))
			draw_texture_rect(gate_tex, Rect2(gate + Vector2(-95, -165), Vector2(190, 180)), false)
		else:
			draw_rect(Rect2(gate + Vector2(-90, -150), Vector2(180, 160)), INK)
			draw_line(gate + Vector2(-95, 10), gate + Vector2(-95, -150), Color("55505a"), 8)
			draw_line(gate + Vector2(95, 10), gate + Vector2(95, -150), Color("55505a"), 8)
	var dom_t_raw: Variant = session.get("domain_timer")
	var dom_t: float = float(dom_t_raw) if dom_t_raw != null else 0.0
	if dom_t > 0.0:
		var dom_w_raw: Variant = session.get("domain_weapon")
		var fallback_w: StringName = app.get("selected_weapon") if app.get("selected_weapon") != null else &"lamina"
		var dom_w: StringName = StringName(dom_w_raw) if dom_w_raw != null else fallback_w
		_draw_domain_expansion(room, dom_w, dom_t, t_pres)
	_draw_exit_doors(room, session, t_pres)
	for enemy in session.enemies:
		if enemy.get("phase", "") == "windup":
			_telegraph(enemy, true)
	var bodies: Array[Dictionary] = []
	var interpolation := Engine.get_physics_interpolation_fraction()
	var pilares_raw: Variant = arena_data.get("pilares", [])
	if pilares_raw is Array:
		var pilares_arr: Array = pilares_raw as Array
		for index: int in range(pilares_arr.size()):
			var pillar_raw: Variant = pilares_arr[index]
			if pillar_raw is Dictionary:
				var pillar: Dictionary = pillar_raw as Dictionary
				bodies.append({
					"type": "pillar",
					"pos": Vector2(float(pillar.get("x", 0.0)), float(pillar.get("y", 0.0))),
					"radius": float(pillar.get("r", 42.0)),
					"order": index,
				})
	var urns_raw: Variant = session.get("urns")
	if urns_raw is Array:
		var urn_list: Array = urns_raw as Array
		for u_idx: int in range(urn_list.size()):
			var urn_v: Variant = urn_list[u_idx]
			if urn_v is Dictionary:
				var urn_dict: Dictionary = urn_v as Dictionary
				if float(urn_dict.get("hp", 0.0)) > 0.0:
					var u_pos_v: Variant = urn_dict.get("pos", Vector2.ZERO)
					var u_pos: Vector2 = u_pos_v if u_pos_v is Vector2 else Vector2.ZERO
					bodies.append({"type": "urn", "pos": u_pos, "entity": urn_dict, "radius": float(urn_dict.get("radius", 22.0)), "order": 20 + u_idx})
	var props_raw: Variant = session.get("room_props")
	if props_raw is Array:
		var props_list: Array = props_raw as Array
		for p_idx: int in range(props_list.size()):
			var prop_v: Variant = props_list[p_idx]
			if prop_v is Dictionary:
				var prop_dict: Dictionary = prop_v as Dictionary
				var p_pos_v: Variant = prop_dict.get("pos", Vector2.ZERO)
				var p_pos: Vector2 = p_pos_v if p_pos_v is Vector2 else Vector2.ZERO
				var p_scale: float = float(prop_dict.get("scale", 1.0))
				bodies.append({"type": "prop", "pos": p_pos, "entity": prop_dict, "radius": 44.0 * p_scale, "order": 30 + p_idx})
	var inter_raw: Variant = session.get("room_interactives")
	if inter_raw is Array:
		var inter_list: Array = inter_raw as Array
		for i_idx: int in range(inter_list.size()):
			var inter_v: Variant = inter_list[i_idx]
			if inter_v is Dictionary:
				var inter_dict: Dictionary = inter_v as Dictionary
				var i_pos_v: Variant = inter_dict.get("pos", Vector2.ZERO)
				var i_pos: Vector2 = i_pos_v if i_pos_v is Vector2 else Vector2.ZERO
				bodies.append({"type": "interactive", "pos": i_pos, "entity": inter_dict, "idx": i_idx, "radius": 46.0, "order": 35 + i_idx})
	var allied_raw: Variant = session.get("allied_curses")
	var has_allied_curses: bool = false
	if allied_raw is Array:
		var allied_arr: Array = allied_raw as Array
		for a_idx: int in range(allied_arr.size()):
			var c_v: Variant = allied_arr[a_idx]
			if c_v is Dictionary:
				var c_dict: Dictionary = c_v as Dictionary
				var c_curr_v: Variant = c_dict.get("pos", Vector2.ZERO)
				var c_curr: Vector2 = c_curr_v if c_curr_v is Vector2 else Vector2.ZERO
				var c_prev_v: Variant = c_dict.get("prev", c_curr)
				var c_prev: Vector2 = c_prev_v if c_prev_v is Vector2 else c_curr
				bodies.append({
					"type": "allied_curse",
					"pos": c_prev.lerp(c_curr, interpolation),
					"entity": c_dict,
					"radius": float(c_dict.get("radius", 24.0)),
					"order": 40 + a_idx,
				})
				has_allied_curses = true
	for enemy in session.enemies:
		if enemy.hp <= 0:
			continue
		var position: Vector2 = enemy.get("prev", enemy.pos).lerp(enemy.pos, interpolation)
		bodies.append({"type": "enemy", "pos": position, "entity": enemy, "order": 100 + int(enemy.id)})
	if not session.player.is_empty():
		var position: Vector2 = session.player.prev.lerp(session.player.pos, interpolation)
		bodies.append({"type": "player", "pos": position, "entity": session.player, "order": 50})
		# Iluminação focal sutil ao redor do jogador (lanterna/presença destacando o herói no piso)
		draw_set_transform(position, 0.0, Vector2(1.0, 0.58))
		draw_circle(Vector2.ZERO, 195.0, Color(BONE.r, BONE.g, BONE.b, 0.045))
		draw_circle(Vector2.ZERO, 118.0, Color(BONE.r, BONE.g, BONE.b, 0.08))
		draw_set_transform(Vector2.ZERO)
		if not has_allied_curses and not bool(session.get("extended_campaign")) and app.get("selected_weapon") == &"pactos":
			var c_prev: Vector2 = app.get("companion_prev") if app.get("companion_prev") != null else position
			var c_curr: Vector2 = app.get("companion_pos") if app.get("companion_pos") != null else position
			bodies.append({"type": "companion", "pos": c_prev.lerp(c_curr, interpolation), "order": 49})
	for body in bodies:
		# Art Bible §5.5: Ecos never cast a contact shadow ("gramática da subtração aplicada à luz").
		if body.type == "enemy" and String(body.entity.get("kind", "")) == "eco_perdido":
			continue
		var shadow_r: float = float(body.get("radius", body.get("entity", {}).get("radius", 30.0)))
		if body.type == "pillar":
			# Sombra projetada direcional (luz do topo-esquerda -> sombra alongada para baixo-direita)
			draw_set_transform(Vector2.ZERO)
			var p_pos: Vector2 = body.pos
			var dir_shadow := PackedVector2Array([
				p_pos + Vector2(-shadow_r * 0.65, shadow_r * 0.12),
				p_pos + Vector2(shadow_r * 0.72, -shadow_r * 0.25),
				p_pos + Vector2(shadow_r * 2.35, shadow_r * 0.92),
				p_pos + Vector2(shadow_r * 1.15, shadow_r * 1.28),
			])
			draw_colored_polygon(dir_shadow, Color(INK.r, INK.g, INK.b, 0.34))
		elif body.type == "prop":
			# Sombra projetada longa para props arquitetônicos (alpha 0.55)
			draw_set_transform(Vector2.ZERO)
			var pr_pos: Vector2 = body.pos
			var prop_shadow := PackedVector2Array([
				pr_pos + Vector2(-shadow_r * 0.72, shadow_r * 0.14),
				pr_pos + Vector2(shadow_r * 0.68, -shadow_r * 0.22),
				pr_pos + Vector2(shadow_r * 2.85, shadow_r * 1.05),
				pr_pos + Vector2(shadow_r * 1.45, shadow_r * 1.42),
			])
			draw_colored_polygon(prop_shadow, Color(INK.r, INK.g, INK.b, 0.55))
		draw_set_transform(body.pos, 0, Vector2(1, 0.38))
		var contact_alpha: float = 0.62 if body.type == "interactive" else 0.68
		draw_circle(Vector2(3, 8), shadow_r * 1.28, Color(INK.r, INK.g, INK.b, contact_alpha))
	draw_set_transform(Vector2.ZERO)
	var active_inter_raw: Variant = session.get("active_interactive_index")
	var active_inter_idx: int = int(active_inter_raw) if active_inter_raw != null else -1
	bodies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y < b.pos.y if a.pos.y != b.pos.y else a.order < b.order)
	for body in bodies:
		match body.type:
			"pillar": _pillar(body.pos, body.radius, int(body.order))
			"urn": _draw_urn(body.pos, body.entity, t_pres)
			"prop": _draw_prop_entity(body.entity)
			"interactive":
				var i_idx_val: int = int(body.get("idx", -1))
				_draw_interactive_entity(body.entity, i_idx_val, i_idx_val == active_inter_idx, t_pres)
			"allied_curse": _draw_allied_curse(body.entity, body.pos, t_pres)
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
			var orb_pos: Vector2 = pos + Vector2(0, -44.0)
			var cyan := Color("7dd3fc")
			draw_circle(pos, projectile.radius * 0.55, Color(INK.r, INK.g, INK.b, 0.35))
			draw_line(orb_pos - dir * (projectile.radius * 2.4), orb_pos, Color(cyan, 0.45), projectile.radius * 0.9, true)
			draw_circle(orb_pos, projectile.radius + 7, Color(cyan, 0.28))
			draw_circle(orb_pos, projectile.radius + 3, INK)
			draw_circle(orb_pos, projectile.radius, cyan)
			draw_circle(orb_pos, projectile.radius * 0.55, GOLD)
			draw_circle(orb_pos - Vector2(3, 3), projectile.radius * 0.28, BONE)
		elif p_kind == "curse_orb":
			var curb_pos: Vector2 = pos + Vector2(0.0, -44.0)
			var r_curb: float = float(projectile.get("radius", 14.0))
			var curb_perp: Vector2 = dir.orthogonal()
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.48))
			draw_circle(Vector2.ZERO, r_curb * 0.72, Color(INK.r, INK.g, INK.b, 0.42))
			draw_set_transform(Vector2.ZERO)
			var tail_pts := PackedVector2Array()
			for ti: int in range(8):
				var tf: float = float(ti) / 7.0
				var sway: float = sin(t_pres * 16.0 + float(ti) * 1.15 + pos.x * 0.04) * (r_curb * 0.52 * tf)
				tail_pts.append(curb_pos - dir * (r_curb * 3.6 * tf) + curb_perp * sway)
			draw_polyline(tail_pts, Color(INK.r, INK.g, INK.b, 0.90), maxf(3.0, r_curb * 0.72), true)
			draw_polyline(tail_pts, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.65), maxf(2.0, r_curb * 0.32), true)
			draw_circle(curb_pos, r_curb + 9.0, Color(0.05, 0.02, 0.09, 0.52))
			draw_circle(curb_pos, r_curb + 5.0, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.34))
			draw_circle(curb_pos, r_curb + 2.0, INK)
			draw_circle(curb_pos, r_curb * 0.70, MAGENTA)
			draw_circle(curb_pos - Vector2(2.5, 2.5), r_curb * 0.30, MAGENTA_BRIGHT)
		elif p_kind == "bolt":
			var bolt_pos: Vector2 = pos + Vector2(0, -44.0)
			var r_bolt: float = float(projectile.radius)
			var tail: Vector2 = bolt_pos - dir * (r_bolt * 1.8)
			var tip: Vector2 = bolt_pos + dir * (r_bolt * 1.5)
			draw_circle(pos, r_bolt * 0.5, Color(INK.r, INK.g, INK.b, 0.32))
			draw_line(tail, tip, INK, 10.0, true)
			draw_line(tail, bolt_pos + dir * (r_bolt * 0.6), BONE, 5.0, true)
			draw_line(bolt_pos + dir * (r_bolt * 0.4), tip, GOLD, 5.0, true)
		else:
			var ep_pos: Vector2 = pos + Vector2(0, -34.0)
			draw_circle(pos, projectile.radius * 0.55, Color(INK.r, INK.g, INK.b, 0.32))
			draw_circle(ep_pos, projectile.radius + 5, INK)
			draw_circle(ep_pos, projectile.radius, MAGENTA)
			draw_circle(ep_pos - Vector2(3, 3), projectile.radius * 0.35, BONE)
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

func _draw_abyss_backdrop(room: Rect2, bg_col: Color, accent_col: Color, border_col: Color, t: float) -> void:
	# Silhuetas sutis de rochas e pilares distantes mergulhados no abismo abaixo/ao redor da plataforma
	var spire_far: Color = bg_col.darkened(0.38)
	var spire_mid: Color = bg_col.darkened(0.22)
	var spire_rim: Color = Color(border_col.r, border_col.g, border_col.b, 0.14)
	var monoliths: Array[Array] = [
		[room.position.x - 360.0, room.end.y + 110.0, 120.0, 520.0, 0],
		[room.position.x + 140.0, room.end.y + 170.0, 150.0, 480.0, 1],
		[room.position.x + 680.0, room.end.y + 140.0, 110.0, 540.0, 0],
		[room.position.x + 1220.0, room.end.y + 190.0, 165.0, 460.0, 1],
		[room.position.x + 1780.0, room.end.y + 150.0, 125.0, 520.0, 0],
		[room.end.x + 210.0, room.end.y + 100.0, 140.0, 540.0, 1],
		[room.position.x - 420.0, room.position.y + 180.0, 130.0, 620.0, 0],
		[room.end.x + 260.0, room.position.y + 140.0, 135.0, 650.0, 0],
	]
	for m_arr: Array in monoliths:
		var mx: float = float(m_arr[0])
		var my: float = float(m_arr[1])
		var mw: float = float(m_arr[2])
		var mh: float = float(m_arr[3])
		var layer_i: int = int(m_arr[4])
		var poly := PackedVector2Array([
			Vector2(mx, my + mh),
			Vector2(mx + mw * 0.12, my + 26.0),
			Vector2(mx + mw * 0.45, my),
			Vector2(mx + mw * 0.88, my + 18.0),
			Vector2(mx + mw, my + mh),
		])
		draw_colored_polygon(poly, spire_mid if layer_i == 1 else spire_far)
		draw_line(Vector2(mx + mw * 0.12, my + 26.0), Vector2(mx + mw * 0.45, my), spire_rim, 2.0, true)
	# Faixas suaves de névoa profunda do abismo derivando lentamente
	var mist_y_offsets: Array[float] = [
		room.position.y - 360.0,
		room.end.y + 140.0,
		room.end.y + 270.0,
		room.end.y + 420.0,
		room.end.y + 590.0,
	]
	for i: int in range(mist_y_offsets.size()):
		var drift_x: float = sin(t * 0.32 + float(i) * 1.4) * 90.0
		var mist_y: float = mist_y_offsets[i] + sin(t * 0.24 + float(i) * 0.9) * 14.0
		var mist_h: float = 95.0 + float(i % 2) * 45.0
		var mist_a: float = 0.045 + 0.015 * sin(t * 0.45 + float(i) * 1.7)
		var mist_col := Color(accent_col.r, accent_col.g, accent_col.b, mist_a)
		draw_rect(Rect2(room.position.x - 950.0 + drift_x, mist_y, room.size.x + 1900.0, mist_h), mist_col)

func _draw_north_wall(room: Rect2, wall_h: float, border_col: Color, accent_col: Color, reg_id: String, _t: float) -> void:
	var wall_rect := Rect2(room.position.x - 42.0, room.position.y - wall_h, room.size.x + 84.0, wall_h + 6.0)
	var wall_base: Color = border_col.darkened(0.42)
	var wall_hi: Color = border_col.lightened(0.10)
	var wall_mid: Color = border_col.darkened(0.28)
	draw_rect(wall_rect, wall_base)
	# Fiadas horizontais de alvenaria
	draw_line(Vector2(wall_rect.position.x, wall_rect.position.y + 52.0), Vector2(wall_rect.end.x, wall_rect.position.y + 52.0), Color(INK.r, INK.g, INK.b, 0.38), 2.5)
	draw_line(Vector2(wall_rect.position.x, wall_rect.position.y + 94.0), Vector2(wall_rect.end.x, wall_rect.position.y + 94.0), Color(INK.r, INK.g, INK.b, 0.38), 2.5)
	for wx: int in range(int(room.position.x), int(room.end.x), 160):
		draw_line(Vector2(float(wx), wall_rect.position.y + 18.0), Vector2(float(wx), wall_rect.end.y - 14.0), Color(INK.r, INK.g, INK.b, 0.35), 2.5)
	# Arcos / nichos sombreados ao longo da muralha (pula o vão do portal central)
	var center_x: float = room.position.x + room.size.x * 0.5
	for nx_i: int in range(1, 10):
		var nx: float = room.position.x + float(nx_i) * 240.0 - 120.0
		if absf(nx - center_x) < 165.0:
			continue
		var arch_w: float = 74.0
		var arch_top: float = wall_rect.position.y + 34.0
		var arch_bot: float = wall_rect.end.y - 14.0
		draw_rect(Rect2(nx - arch_w * 0.5, arch_top + 18.0, arch_w, arch_bot - (arch_top + 18.0)), Color(INK.r, INK.g, INK.b, 0.72))
		draw_circle(Vector2(nx, arch_top + 18.0), arch_w * 0.5, Color(INK.r, INK.g, INK.b, 0.72))
		draw_arc(Vector2(nx, arch_top + 18.0), arch_w * 0.5, PI, TAU, 16, Color(wall_hi.r, wall_hi.g, wall_hi.b, 0.24), 2.0, true)
		draw_line(Vector2(nx - arch_w * 0.5, arch_top + 18.0), Vector2(nx - arch_w * 0.5, arch_bot), Color(wall_hi.r, wall_hi.g, wall_hi.b, 0.18), 2.0)
	# Contrafortes espaçados em relevo 2.5D (luz topo-esquerda -> face esquerda iluminada, direita sombreada)
	for bx_i: int in range(0, 11):
		var bx: float = room.position.x + float(bx_i) * 240.0
		if absf(bx - center_x) < 140.0:
			continue
		var bw: float = 38.0
		var b_rect := Rect2(bx - bw * 0.5, wall_rect.position.y + 6.0, bw, wall_h - 8.0)
		# Sombra projetada do contraforte para a direita
		draw_rect(Rect2(b_rect.end.x, b_rect.position.y + 8.0, 14.0, b_rect.size.y - 8.0), Color(INK.r, INK.g, INK.b, 0.45))
		draw_rect(b_rect, wall_mid)
		draw_rect(Rect2(b_rect.position.x, b_rect.position.y, 7.0, b_rect.size.y), Color(wall_hi.r, wall_hi.g, wall_hi.b, 0.42))
		draw_rect(Rect2(b_rect.end.x - 8.0, b_rect.position.y, 8.0, b_rect.size.y), Color(INK.r, INK.g, INK.b, 0.55))
		draw_rect(Rect2(b_rect.position.x - 4.0, b_rect.position.y, b_rect.size.x + 8.0, 12.0), wall_hi)
		draw_rect(b_rect, Color(INK.r, INK.g, INK.b, 0.65), false, 2.0)
	# Cornija superior + rodapé escuro
	draw_rect(Rect2(wall_rect.position.x, wall_rect.position.y, wall_rect.size.x, 16.0), wall_hi)
	draw_rect(Rect2(wall_rect.position.x, wall_rect.position.y + 16.0, wall_rect.size.x, 6.0), Color(INK.r, INK.g, INK.b, 0.48))
	draw_rect(Rect2(wall_rect.position.x, wall_rect.end.y - 14.0, wall_rect.size.x, 14.0), INK)
	# Friso sutil do bioma na muralha
	if reg_id != "limiar":
		draw_line(Vector2(wall_rect.position.x + 20.0, wall_rect.position.y + 24.0), Vector2(wall_rect.end.x - 20.0, wall_rect.position.y + 24.0), Color(accent_col.r, accent_col.g, accent_col.b, 0.35), 2.5)

func _draw_north_braziers(room: Rect2, border_col: Color, reg_id: String, t: float) -> void:
	var flame_outer: Color = Color("e86a2c")
	var flame_mid: Color = Color("ff9e44")
	var flame_core: Color = Color("fff2c6")
	if reg_id.contains("veio"):
		flame_outer = MAGENTA
		flame_mid = MAGENTA_BRIGHT
		flame_core = Color("ffe6f7")
	elif reg_id.contains("santuario"):
		flame_outer = Color("38bdf8")
		flame_mid = Color("7dd3fc")
		flame_core = Color("f0f9ff")
	var bx_list: Array[float] = [420.0, 860.0, 1540.0, 1980.0]
	for idx: int in range(bx_list.size()):
		var bx: float = bx_list[idx]
		var by: float = room.position.y - 44.0
		var flick_a: float = sin(t * 7.2 + float(idx) * 1.9)
		var flick_b: float = sin(t * 13.5 + float(idx) * 3.1)
		var pulse: float = flick_a * 0.55 + flick_b * 0.45
		var sway: float = sin(t * 5.8 + float(idx) * 2.4) * 3.2
		# Halos grandes de luz quente/do bioma banhando o chão abaixo da muralha
		draw_set_transform(Vector2(bx, room.position.y + 56.0), 0.0, Vector2(1.0, 0.58))
		draw_circle(Vector2.ZERO, 220.0 + pulse * 14.0, Color(flame_mid.r, flame_mid.g, flame_mid.b, 0.075))
		draw_circle(Vector2.ZERO, 130.0 + pulse * 8.0, Color(flame_mid.r, flame_mid.g, flame_mid.b, 0.11))
		draw_set_transform(Vector2.ZERO)
		# Halos banhando a muralha ao redor do braseiro
		draw_circle(Vector2(bx, by - 12.0), 118.0 + pulse * 8.0, Color(flame_outer.r, flame_outer.g, flame_outer.b, 0.12))
		draw_circle(Vector2(bx, by - 14.0), 58.0 + pulse * 5.0, Color(flame_mid.r, flame_mid.g, flame_mid.b, 0.18))
		# Suporte de ferro e bacia do braseiro
		var bowl := PackedVector2Array([
			Vector2(bx - 18.0, by - 4.0),
			Vector2(bx + 18.0, by - 4.0),
			Vector2(bx + 12.0, by + 10.0),
			Vector2(bx - 12.0, by + 10.0),
		])
		draw_line(Vector2(bx, by + 10.0), Vector2(bx, by + 30.0), INK, 7.0, true)
		draw_line(Vector2(bx, by + 10.0), Vector2(bx, by + 28.0), border_col.lightened(0.05), 3.0, true)
		draw_colored_polygon(bowl, border_col.darkened(0.35))
		draw_polyline(_closed(bowl), INK, 3.0, true)
		# Chama animada deterministicamente (3 camadas)
		var f_h: float = 28.0 + pulse * 6.5
		var outer_poly := PackedVector2Array([
			Vector2(bx - 13.0, by - 4.0),
			Vector2(bx - 9.0 + sway * 0.4, by - f_h * 0.58),
			Vector2(bx + sway, by - f_h),
			Vector2(bx + 9.0 + sway * 0.4, by - f_h * 0.58),
			Vector2(bx + 13.0, by - 4.0),
		])
		draw_colored_polygon(outer_poly, Color(flame_outer.r, flame_outer.g, flame_outer.b, 0.92))
		var mid_poly := PackedVector2Array([
			Vector2(bx - 8.5, by - 4.0),
			Vector2(bx - 5.0 + sway * 0.5, by - f_h * 0.52),
			Vector2(bx + sway * 0.8, by - f_h * 0.80),
			Vector2(bx + 5.0 + sway * 0.5, by - f_h * 0.52),
			Vector2(bx + 8.5, by - 4.0),
		])
		draw_colored_polygon(mid_poly, Color(flame_mid.r, flame_mid.g, flame_mid.b, 0.95))
		draw_circle(Vector2(bx + sway * 0.3, by - 9.0), 5.2 + pulse * 0.9, flame_core)

func _draw_south_cliff(room: Rect2, border_col: Color, accent_col: Color, reg_id: String, t: float) -> void:
	var cliff_x: float = room.position.x - 34.0
	var cliff_y: float = room.end.y
	var cliff_w: float = room.size.x + 68.0
	var cliff_h: float = 88.0
	# Sombra profunda mergulhando no abismo abaixo da falésia
	draw_rect(Rect2(cliff_x + 10.0, cliff_y + cliff_h - 4.0, cliff_w - 20.0, 26.0), Color(INK.r, INK.g, INK.b, 0.72))
	draw_rect(Rect2(cliff_x + 22.0, cliff_y + cliff_h + 22.0, cliff_w - 44.0, 28.0), Color(INK.r, INK.g, INK.b, 0.42))
	draw_rect(Rect2(cliff_x + 36.0, cliff_y + cliff_h + 50.0, cliff_w - 72.0, 26.0), Color(INK.r, INK.g, INK.b, 0.18))
	# Paredão principal de pedra 2.5D
	var cliff_base: Color = border_col.darkened(0.50)
	draw_rect(Rect2(cliff_x, cliff_y, cliff_w, cliff_h), cliff_base)
	# Blocos verticais de pedra com fendas escuras determinísticas
	var block_step: float = 96.0
	var num_blocks: int = int(ceilf(cliff_w / block_step))
	for bi: int in range(num_blocks):
		var bx: float = cliff_x + float(bi) * block_step
		var bw: float = minf(block_step, cliff_x + cliff_w - bx)
		var h_var: int = (bi * 17 + 5) % 4
		var block_col: Color = cliff_base.darkened(0.08 * float(h_var)) if h_var > 1 else cliff_base.lightened(0.06 * float(2 - h_var))
		var b_top: float = cliff_y + 12.0 + float((bi * 7) % 3) * 3.0
		draw_rect(Rect2(bx + 2.0, b_top, maxf(2.0, bw - 4.0), cliff_h - (b_top - cliff_y) - 4.0), block_col)
		# Fenda escura vertical entre blocos
		draw_line(Vector2(bx, cliff_y + 10.0), Vector2(bx + (4.0 if bi % 2 == 0 else -3.0), cliff_y + cliff_h), INK, 3.0)
		# Fissura interna ocasional
		if bi % 3 == 1:
			var fx: float = bx + bw * 0.48
			draw_line(Vector2(fx, cliff_y + 16.0), Vector2(fx + 7.0, cliff_y + 48.0), Color(INK.r, INK.g, INK.b, 0.78), 2.5)
			draw_line(Vector2(fx + 7.0, cliff_y + 48.0), Vector2(fx + 2.0, cliff_y + 78.0), Color(INK.r, INK.g, INK.b, 0.70), 2.0)
		# Detalhes do bioma na face da falésia (musgo, cinzas/brasas, veios ou runas)
		if reg_id.contains("veio"):
			if bi % 2 == 0:
				var pulse_v: float = 0.28 + 0.12 * sin(t * 2.2 + float(bi) * 0.8)
				var vx: float = bx + bw * 0.52
				draw_line(Vector2(vx, cliff_y + 14.0), Vector2(vx - 8.0, cliff_y + 46.0), Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, pulse_v), 3.0, true)
				draw_line(Vector2(vx - 8.0, cliff_y + 46.0), Vector2(vx + 5.0, cliff_y + 74.0), Color(GOLD.r, GOLD.g, GOLD.b, pulse_v * 0.9), 2.0, true)
		elif reg_id.contains("cinza") or reg_id.contains("fosso"):
			if bi % 2 == 1:
				var glow_c: float = 0.26 + 0.12 * sin(t * 2.6 + float(bi) * 1.1)
				var cx: float = bx + bw * 0.44
				draw_line(Vector2(cx, cliff_y + 18.0), Vector2(cx + 6.0, cliff_y + 52.0), Color(0.91, 0.42, 0.17, glow_c), 3.0, true)
				draw_circle(Vector2(cx + 6.0, cliff_y + 52.0), 4.0, Color(1.0, 0.62, 0.27, glow_c))
		elif reg_id.contains("santuario"):
			if bi % 2 == 0:
				var sx: float = bx + bw * 0.5
				draw_rect(Rect2(sx - 10.0, cliff_y + 24.0, 20.0, 32.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.24), false, 2.0)
				draw_line(Vector2(sx, cliff_y + 28.0), Vector2(sx, cliff_y + 52.0), Color(accent_col.r, accent_col.g, accent_col.b, 0.30), 2.0)
		else:
			if bi % 3 == 0:
				var moss_col := Color("3b4943")
				draw_rect(Rect2(bx + 12.0, cliff_y + 10.0, bw * 0.38, 16.0 + float(bi % 4) * 5.0), Color(moss_col.r, moss_col.g, moss_col.b, 0.55))
	# Degradê de escurecimento na base da falésia + borda superior chanfrada
	draw_rect(Rect2(cliff_x, cliff_y + 48.0, cliff_w, 40.0), Color(INK.r, INK.g, INK.b, 0.44))
	draw_rect(Rect2(cliff_x, cliff_y + 72.0, cliff_w, 16.0), Color(INK.r, INK.g, INK.b, 0.68))
	draw_rect(Rect2(cliff_x, cliff_y, cliff_w, 10.0), border_col.lightened(0.06))
	draw_rect(Rect2(cliff_x, cliff_y + 10.0, cliff_w, 5.0), Color(INK.r, INK.g, INK.b, 0.65))
	draw_rect(Rect2(cliff_x, cliff_y, cliff_w, cliff_h), INK, false, 3.0)

func _draw_floor_organic_layers(room: Rect2, _floor_col: Color, border_col: Color) -> void:
	# Manchas suaves de desgaste e sombreamento quebrando a repetição de grade das lajes
	for i: int in range(16):
		var px: float = room.position.x + 140.0 + fmod(float(i * 419 + 170), maxf(100.0, room.size.x - 280.0))
		var py: float = room.position.y + 120.0 + fmod(float(i * 271 + 95), maxf(100.0, room.size.y - 240.0))
		var rx: float = 95.0 + float((i * 13) % 5) * 32.0
		var is_dark: bool = (i % 3 != 0)
		var patch_col: Color = Color(INK.r, INK.g, INK.b, 0.10) if is_dark else Color(border_col.r, border_col.g, border_col.b, 0.08)
		draw_set_transform(Vector2(px, py), 0.0, Vector2(1.0, 0.56))
		draw_circle(Vector2.ZERO, rx, patch_col)
		draw_set_transform(Vector2.ZERO)
	# Rachaduras sutis e juntas irregulares cruzando entre lajes
	for c_i: int in range(10):
		var cx: float = room.position.x + 180.0 + fmod(float(c_i * 523 + 230), maxf(100.0, room.size.x - 360.0))
		var cy: float = room.position.y + 150.0 + fmod(float(c_i * 313 + 140), maxf(100.0, room.size.y - 300.0))
		var dir_x: float = 1.0 if c_i % 2 == 0 else -1.0
		var p0 := Vector2(cx, cy)
		var p1 := p0 + Vector2(dir_x * 42.0, 18.0 + float(c_i % 3) * 8.0)
		var p2 := p1 + Vector2(dir_x * 36.0, -10.0 + float((c_i + 1) % 3) * 10.0)
		draw_line(p0, p1, Color(INK.r, INK.g, INK.b, 0.34), 2.5, true)
		draw_line(p1, p2, Color(INK.r, INK.g, INK.b, 0.28), 2.0, true)
		draw_line(p0 + Vector2(0.0, 2.0), p1 + Vector2(0.0, 2.0), Color(border_col.r, border_col.g, border_col.b, 0.14), 1.5, true)

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

func _draw_ambient_props_and_lights(room: Rect2, reg_id: String, t_pres: float) -> void:
	var reg_lower: String = reg_id.to_lower()
	var torch_outer: Color = Color("e86a2c")
	var torch_warm: Color = Color("ff9e44")
	var urn_glow: Color = Color("5eead4")
	if reg_lower.contains("veio"):
		torch_outer = Color("c026d3")
		torch_warm = Color("f070c0")
		urn_glow = MAGENTA_BRIGHT
	elif reg_lower.contains("cinza") or reg_lower.contains("fosso"):
		torch_outer = Color("d94e1f")
		torch_warm = Color("ff9e44")
		urn_glow = Color("ff9e44")
	elif reg_lower.contains("santuario"):
		torch_outer = Color("d99b26")
		torch_warm = Color("f6c453")
		urn_glow = Color("7dd3fc")
	# 1) Escombros e pedras quebradas próximos às bordas e zonas de pilares (sem poluir o centro)
	var rubble_anchors: Array[Vector2] = [
		Vector2(room.position.x + 210.0, room.position.y + 150.0),
		Vector2(room.position.x + 560.0, room.position.y + 118.0),
		Vector2(room.end.x - 580.0, room.position.y + 124.0),
		Vector2(room.end.x - 220.0, room.position.y + 162.0),
		Vector2(room.position.x + 148.0, room.position.y + 420.0),
		Vector2(room.end.x - 154.0, room.position.y + 450.0),
		Vector2(room.position.x + 166.0, room.end.y - 360.0),
		Vector2(room.end.x - 168.0, room.end.y - 340.0),
		Vector2(room.position.x + 280.0, room.end.y - 126.0),
		Vector2(room.position.x + 710.0, room.end.y - 114.0),
		Vector2(room.end.x - 690.0, room.end.y - 118.0),
		Vector2(room.end.x - 270.0, room.end.y - 132.0),
		Vector2(room.position.x + 410.0, room.position.y + 290.0),
		Vector2(room.end.x - 420.0, room.end.y - 255.0),
	]
	var stone_dark: Color = STONE.darkened(0.28)
	var stone_mid: Color = STONE.lightened(0.06)
	var stone_hi: Color = Color(BONE.r, BONE.g, BONE.b, 0.22)
	for r_i: int in range(rubble_anchors.size()):
		var rp: Vector2 = rubble_anchors[r_i]
		var stones_count: int = 3 + (r_i % 2)
		for s_i: int in range(stones_count):
			var ang: float = float(r_i * 5 + s_i * 11) * 0.78
			var dist: float = 0.0 if s_i == 0 else (16.0 + float((r_i + s_i * 3) % 4) * 7.5)
			var sp: Vector2 = rp + Vector2(cos(ang) * dist, sin(ang) * dist * 0.62)
			var rw: float = (13.0 if s_i == 0 else 7.5) + float((r_i * 3 + s_i) % 4) * 2.4
			var rh: float = rw * (0.58 + 0.14 * float((r_i + s_i) % 2))
			draw_set_transform(sp + Vector2(2.0, 3.0), 0.0, Vector2(1.0, 0.48))
			draw_circle(Vector2.ZERO, rw * 1.15, Color(INK.r, INK.g, INK.b, 0.34))
			draw_set_transform(Vector2.ZERO)
			var rock := PackedVector2Array([
				sp + Vector2(-rw, rh * 0.25),
				sp + Vector2(-rw * 0.52, -rh),
				sp + Vector2(rw * 0.45, -rh * 0.85),
				sp + Vector2(rw, rh * 0.18),
				sp + Vector2(rw * 0.32, rh * 0.72),
				sp + Vector2(-rw * 0.62, rh * 0.66),
			])
			draw_colored_polygon(rock, stone_mid if s_i == 0 else stone_dark)
			draw_polyline(_closed(rock), INK, 2.2, true)
			draw_line(rock[1], rock[2], stone_hi, 1.5, true)
	# 2) Urnas / ânforas rituais com brilho sutil nos 4 cantos internos da câmara
	var urn_corners: Array[Vector2] = [
		Vector2(room.position.x + 124.0, room.position.y + 116.0),
		Vector2(room.end.x - 124.0, room.position.y + 116.0),
		Vector2(room.position.x + 124.0, room.end.y - 108.0),
		Vector2(room.end.x - 124.0, room.end.y - 108.0),
	]
	for u_i: int in range(urn_corners.size()):
		var up: Vector2 = urn_corners[u_i]
		var u_pulse: float = 0.5 + 0.5 * sin(t_pres * 2.5 + float(u_i) * 1.55)
		var side_dir: float = 1.0 if (u_i % 2 == 0) else -1.0
		# Halo suave da urna sobre o piso
		draw_set_transform(up + Vector2(0.0, 6.0), 0.0, Vector2(1.0, 0.52))
		draw_circle(Vector2.ZERO, 66.0 + u_pulse * 8.0, Color(urn_glow.r, urn_glow.g, urn_glow.b, 0.065 + u_pulse * 0.03))
		draw_circle(Vector2.ZERO, 24.0, Color(INK.r, INK.g, INK.b, 0.54))
		draw_set_transform(Vector2.ZERO)
		# Urna principal (corpo cerâmico escuro + contorno em nanquim + brilho no bocal)
		var urn_body := PackedVector2Array([
			up + Vector2(-11.0, 4.0),
			up + Vector2(-18.0, -14.0),
			up + Vector2(-13.0, -34.0),
			up + Vector2(-8.0, -44.0),
			up + Vector2(8.0, -44.0),
			up + Vector2(13.0, -34.0),
			up + Vector2(18.0, -14.0),
			up + Vector2(11.0, 4.0),
		])
		draw_colored_polygon(urn_body, Color("1c202c"))
		draw_colored_polygon(PackedVector2Array([
			up + Vector2(-13.0, -14.0),
			up + Vector2(-9.0, -32.0),
			up + Vector2(-2.0, -32.0),
			up + Vector2(-4.0, -12.0),
		]), Color("2f3648"))
		draw_polyline(_closed(urn_body), INK, 3.5, true)
		# Faixa ornamental + bocal com brilho sutil
		draw_line(up + Vector2(-14.0, -22.0), up + Vector2(14.0, -22.0), Color(urn_glow.r, urn_glow.g, urn_glow.b, 0.35 + u_pulse * 0.2), 2.0, true)
		draw_rect(Rect2(up + Vector2(-11.0, -49.0), Vector2(22.0, 6.0)), Color("2c3242"))
		draw_rect(Rect2(up + Vector2(-11.0, -49.0), Vector2(22.0, 6.0)), INK, false, 2.5)
		draw_circle(up + Vector2(0.0, -47.0), 15.0 + u_pulse * 3.0, Color(urn_glow.r, urn_glow.g, urn_glow.b, 0.16 + u_pulse * 0.08))
		draw_circle(up + Vector2(0.0, -47.0), 6.0, Color(urn_glow.r, urn_glow.g, urn_glow.b, 0.72 + u_pulse * 0.22))
		draw_circle(up + Vector2(0.0, -47.0), 2.8, Color(BONE.r, BONE.g, BONE.b, 0.85))
		# Pequena ânfora secundária ao lado
		var sub_p: Vector2 = up + Vector2(side_dir * 29.0, 8.0)
		draw_set_transform(sub_p + Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.48))
		draw_circle(Vector2.ZERO, 13.0, Color(INK.r, INK.g, INK.b, 0.48))
		draw_set_transform(Vector2.ZERO)
		var sub_body := PackedVector2Array([
			sub_p + Vector2(-7.0, 2.0),
			sub_p + Vector2(-10.0, -10.0),
			sub_p + Vector2(-6.0, -24.0),
			sub_p + Vector2(6.0, -24.0),
			sub_p + Vector2(10.0, -10.0),
			sub_p + Vector2(7.0, 2.0),
		])
		draw_colored_polygon(sub_body, Color("171b26"))
		draw_polyline(_closed(sub_body), INK, 2.5, true)
		draw_circle(sub_p + Vector2(0.0, -24.0), 3.4, Color(urn_glow.r, urn_glow.g, urn_glow.b, 0.48 + u_pulse * 0.2))
	# 3) Poças de luz quente de tochas/braseiros nas 4 laterais e no topo
	var light_pools: Array[Vector2] = [
		Vector2(room.position.x + room.size.x * 0.18, room.position.y + 68.0),
		Vector2(room.position.x + room.size.x * 0.36, room.position.y + 62.0),
		Vector2(room.position.x + room.size.x * 0.64, room.position.y + 62.0),
		Vector2(room.position.x + room.size.x * 0.82, room.position.y + 68.0),
		Vector2(room.position.x + 74.0, room.position.y + room.size.y * 0.34),
		Vector2(room.position.x + 74.0, room.position.y + room.size.y * 0.68),
		Vector2(room.end.x - 74.0, room.position.y + room.size.y * 0.34),
		Vector2(room.end.x - 74.0, room.position.y + room.size.y * 0.68),
		Vector2(room.position.x + room.size.x * 0.24, room.end.y - 64.0),
		Vector2(room.position.x + room.size.x * 0.76, room.end.y - 64.0),
	]
	for l_i: int in range(light_pools.size()):
		var lp: Vector2 = light_pools[l_i]
		var flick: float = sin(t_pres * 4.2 + float(l_i) * 1.65)
		var flick_fine: float = sin(t_pres * 7.8 + float(l_i) * 2.3)
		var pulse_r: float = flick * 11.0 + flick_fine * 4.0
		var a_outer: float = 0.08 + flick * 0.012
		var a_mid: float = 0.11 + flick * 0.015
		var a_core: float = 0.135 + flick * 0.012
		draw_set_transform(lp, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, 240.0 + pulse_r, Color(torch_outer.r, torch_outer.g, torch_outer.b, a_outer))
		draw_circle(Vector2.ZERO, 152.0 + pulse_r * 0.65, Color(torch_warm.r, torch_warm.g, torch_warm.b, a_mid))
		draw_circle(Vector2.ZERO, 76.0 + pulse_r * 0.35, Color(torch_warm.r, torch_warm.g, torch_warm.b, a_core))
		draw_set_transform(Vector2.ZERO)
	# 4) Sombra atmosférica cinematográfica nas bordas (vinheta suave emoldurando o combate)
	var vignette_layers: Array[Array] = [
		[150.0, 0.075],
		[92.0, 0.115],
		[48.0, 0.165],
		[22.0, 0.23],
	]
	for vl: Array in vignette_layers:
		var vw: float = float(vl[0])
		var va: float = float(vl[1])
		var v_col := Color(INK.r, INK.g, INK.b, va)
		draw_rect(Rect2(room.position.x, room.position.y, room.size.x, vw), v_col)
		draw_rect(Rect2(room.position.x, room.end.y - vw, room.size.x, vw), v_col)
		draw_rect(Rect2(room.position.x, room.position.y, vw, room.size.y), v_col)
		draw_rect(Rect2(room.end.x - vw, room.position.y, vw, room.size.y), v_col)
	# Sombra extra suave nos 4 cantos para reforçar o foco cinematográfico no centro
	var corner_pts: Array[Vector2] = [
		room.position,
		Vector2(room.end.x, room.position.y),
		Vector2(room.position.x, room.end.y),
		room.end,
	]
	for cp: Vector2 in corner_pts:
		draw_circle(cp, 260.0, Color(INK.r, INK.g, INK.b, 0.12))
		draw_circle(cp, 145.0, Color(INK.r, INK.g, INK.b, 0.15))

func _draw_campus(room: Rect2) -> void:
	draw_rect(room.grow(1000), Color("0e101a"))
	var campus_bg: Texture2D = _env_textures.get("campus_arena_bg", null)
	if campus_bg != null:
		draw_texture_rect(campus_bg, room, false)
	else:
		draw_rect(room.grow(36), INK)
		draw_rect(room, Color("1a1e28"))
		for x in range(120, int(room.size.x), 240):
			for y in range(120, int(room.size.y), 240):
				var tile_idx: int = ((x / 240) + (y / 240)) % 4 + 1
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
		{"pos": Vector2(885, 315), "cor": Color("e09f5a"), "id": "halvar"},
		{"pos": Vector2(960, 295), "cor": Color("7dd3fc"), "id": "maren"},
		{"pos": Vector2(1035, 315), "cor": Color("b388eb"), "id": "oreth"},
	]
	for m: Dictionary in mestres_pos:
		var mp: Vector2 = m["pos"]
		draw_circle(mp, 16.0, INK)
		draw_circle(mp + Vector2(0, -18), 11.0, m["cor"])
		draw_arc(mp + Vector2(0, -18), 13.0, 0, TAU, 20, BONE, 1.5, true)
	# Balão de fala flutuante discreto estilo Mark of the Deep sobre o Mestre focado
	if campus != null and focada == CampusHub.ZONA_MESTRES and not bool(app.get("falar_mestre_ativo")):
		var fala_atual: Dictionary = campus.fala_mestre_atual() if campus.has_method("fala_mestre_atual") else {}
		var m_focado_id: String = String(fala_atual.get("id", "halvar"))
		var bubble_anchor: Vector2 = Vector2(960, 295)
		for m: Dictionary in mestres_pos:
			if String(m.get("id", "")) == m_focado_id:
				bubble_anchor = m["pos"]
				break
		var t_camp: float = float(app.session.presentation_time) if app != null and app.session != null else 0.0
		var bob_y: float = sin(t_camp * 3.0) * 3.5
		var b_w: float = 216.0
		var b_h: float = 34.0
		var b_center: Vector2 = bubble_anchor + Vector2(0.0, -64.0 + bob_y)
		var b_rect := Rect2(b_center.x - b_w * 0.5, b_center.y - b_h * 0.5, b_w, b_h)
		var bg_bubble := Color(0.055, 0.062, 0.095, 0.90)
		var border_bubble := Color(GOLD.r, GOLD.g, GOLD.b, 0.78)
		draw_rect(b_rect, bg_bubble)
		draw_rect(b_rect, border_bubble, false, 1.5)
		var tail_tri := PackedVector2Array([
			Vector2(b_center.x - 6.0, b_rect.end.y),
			Vector2(b_center.x + 6.0, b_rect.end.y),
			Vector2(b_center.x, b_rect.end.y + 8.0),
		])
		draw_colored_polygon(tail_tri, bg_bubble)
		draw_line(tail_tri[0], tail_tri[2], border_bubble, 1.5, true)
		draw_line(tail_tri[1], tail_tri[2], border_bubble, 1.5, true)
		var b_font: Font = ThemeDB.fallback_font
		if b_font != null:
			var msg: String = "Fale conosco, Iniciado..."
			draw_string(b_font, Vector2(b_rect.position.x + 1.0, b_center.y + 6.0), msg, HORIZONTAL_ALIGNMENT_CENTER, b_w, 14, Color(INK.r, INK.g, INK.b, 0.92))
			draw_string(b_font, Vector2(b_rect.position.x, b_center.y + 5.0), msg, HORIZONTAL_ALIGNMENT_CENTER, b_w, 14, BONE)
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
		draw_set_transform(pos, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2(0, 6), radius * 1.18, Color(INK.r, INK.g, INK.b, 0.45))
		draw_arc(Vector2(0, 4), radius * 1.12, 0, TAU, 24, Color(0.55, 0.52, 0.58, 0.25), 2.0, true)
		draw_set_transform(Vector2.ZERO)
		var w := radius * 2.65
		var h := radius * 3.45
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
	var sess_data_raw: Variant = session.get("data")
	if sess_data_raw is Dictionary and (sess_data_raw as Dictionary).has("corte"):
		data = sess_data_raw as Dictionary
	var aim: Vector2 = player.get("aim", Vector2.UP)
	var dash: bool = int(player.get("dash_remaining", 0)) > 0
	var lunge: bool = int(player.get("lunge_remaining", 0)) > 0
	var facing: Vector2 = player.get("dash_dir", aim) if dash else (player.get("lunge_dir", aim) if lunge else aim)
	if dash:
		for i in range(1, 4):
			draw_line(pos - facing * i * 18 + Vector2(-12, -20), pos - facing * i * 18 + Vector2(12, -45), Color(BONE, 0.32 / float(i)), 4, true)
	var w_id: StringName = app.get("selected_weapon") if app.get("selected_weapon") != null else &"lamina"
	var ca_raw: Variant = player.get("curses_absorbed", 0)
	var curses_n: int = clampi(int(ca_raw) if ca_raw != null else 0, 0, 6)
	var t_pres: float = float(session.presentation_time)
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
		var attack_cd_now: int = int(player.get("attack_cd", 0))
		var atk_draw_pos: Vector2 = pos
		var atk_squash := Vector2.ONE
		var atk_rot: float = 0.0
		if session.state == "morte" or float(player.get("hp", 1.0)) <= 0.0:
			action = "death"
			progress = clampf(session.presentation_time / 0.8, 0.0, 0.999)
		elif dash:
			action = "dash"
			var d_total := maxf(1.0, roundf(float(data.esquiva.duracao_s) * 60.0))
			progress = clampf(1.0 - float(player.dash_remaining) / d_total, 0.0, 0.999)
			atk_squash = Vector2(1.16, 0.88)
			atk_rot = flip_x * 0.14
		elif lunge:
			action = "lunge"
			var l_total := maxf(1.0, roundf(float(data.investida.duracao_s) * 60.0))
			progress = clampf(1.0 - float(player.lunge_remaining) / l_total, 0.0, 0.999)
			atk_squash = Vector2(1.20, 0.86)
			atk_rot = flip_x * 0.20
		elif attack_cd_now > 0:
			var combo_idx := int(player.get("combo", 1))
			var base_cd_s: float = float(data.corte.recarga_s)
			if w_id == &"guardiao":
				base_cd_s = 0.45
			elif w_id == &"veu":
				base_cd_s = 0.16
			elif w_id == &"ressonancia":
				base_cd_s = 0.233
			elif w_id == &"pactos":
				base_cd_s = 0.25
			var cd_mult: float = float(session.get("attack_cd_mult")) if session.get("attack_cd_mult") != null else 1.0
			var a_total := maxf(1.0, roundf(base_cd_s * 60.0 * cd_mult))
			var atk_prog := clampf(1.0 - float(attack_cd_now) / a_total, 0.0, 0.999)
			action = "attack1" if (w_id != &"lamina" or combo_idx == 1) else ("attack2" if combo_idx == 2 else "attack3")
			progress = atk_prog
			# Movimento corporal real do golpe (anticipation + avanco + peso + retorno)
			var swing_env: float = sin(clampf(atk_prog * 1.45, 0.0, 1.0) * PI)
			if w_id == &"guardiao":
				var thrust: float = -0.35 if atk_prog < 0.22 else swing_env
				atk_draw_pos += aim * (24.0 * thrust)
				atk_squash = Vector2(1.0 + 0.18 * maxf(0.0, thrust), 1.0 - 0.12 * maxf(0.0, thrust))
				atk_rot = flip_x * (0.22 * thrust)
			elif w_id == &"veu":
				var side_sign: float = 1.0 if (combo_idx % 2 == 0) else -0.75
				atk_draw_pos += aim * (20.0 * swing_env) + aim.orthogonal() * (8.0 * side_sign * swing_env)
				atk_squash = Vector2(1.0 + 0.16 * swing_env, 1.0 - 0.10 * swing_env)
				atk_rot = flip_x * (0.24 * side_sign * swing_env)
			elif w_id == &"lamina":
				atk_draw_pos += aim * (16.0 * swing_env)
				atk_squash = Vector2(1.0 + 0.12 * swing_env, 1.0 - 0.08 * swing_env)
				atk_rot = flip_x * (0.16 * swing_env)
			else:
				# Recuo tátil ao conjurar magia ou esferas amaldiçoadas
				var recoil: float = clampf(1.0 - atk_prog * 2.2, 0.0, 1.0)
				atk_draw_pos -= aim * (8.0 * recoil)
				atk_squash = Vector2(1.0 - 0.07 * recoil, 1.0 + 0.08 * recoil)
				atk_rot = -flip_x * (0.08 * recoil)
		elif int(player.get("flash", 0)) > 0:
			action = "hurt"
			progress = 0.0
		elif player.pos.distance_squared_to(player.get("prev", player.pos)) > 0.04:
			action = "run"
		if action == "idle":
			var breath: float = sin(float(session.presentation_time) * 2.4) * 0.018
			atk_squash = Vector2(1.0 - breath * 0.55, 1.0 + breath)
		var anim_name := action + "_" + dir_suffix
		if not _frames_by_actor[player_actor].has_animation(anim_name):
			anim_name = "attack_" + dir_suffix if action.begins_with("attack") and _frames_by_actor[player_actor].has_animation("attack_" + dir_suffix) else ("idle_" + dir_suffix)
		var facing_n: Vector2 = facing.normalized() if facing != Vector2.ZERO else Vector2.RIGHT
		# Poeira de passos determinística ao correr para aderência ao piso
		if action == "run":
			var prev_p: Vector2 = player.get("prev", player.pos)
			var step_delta: Vector2 = player.pos - prev_p
			var move_dir: Vector2 = step_delta.normalized() if step_delta.length_squared() > 0.0001 else facing_n
			var move_perp: Vector2 = move_dir.orthogonal()
			var t_run: float = float(session.presentation_time)
			for d_i: int in range(3):
				var cycle: float = fmod(t_run * 2.6 + float(d_i) * 0.33, 1.0)
				var lat_sign: float = -1.0 if d_i % 2 == 0 else 1.0
				var dust_pos: Vector2 = pos - move_dir * (10.0 + cycle * 24.0) + move_perp * (lat_sign * (5.0 + float(d_i) * 2.2)) + Vector2(0.0, -3.0 - cycle * 9.0)
				var dust_r: float = 3.5 + cycle * 6.5
				var dust_a: float = (1.0 - cycle) * 0.28
				draw_circle(dust_pos, dust_r, Color(BONE.r, BONE.g, BONE.b, dust_a))
		# Afterimages (fantasmas de silhueta) no Dash e Lunge tingidos na cor da arma
		if dash or lunge:
			var ghost_tint: Color = BONE
			if w_id == &"guardiao":
				ghost_tint = GOLD
			elif w_id == &"veu":
				ghost_tint = Color("a855f7")
			elif w_id == &"ressonancia":
				ghost_tint = Color("7dd3fc")
			elif w_id == &"pactos":
				ghost_tint = MAGENTA
			var ghost_far := Color(ghost_tint.r, ghost_tint.g, ghost_tint.b, 0.16)
			var ghost_near := Color(ghost_tint.r, ghost_tint.g, ghost_tint.b, 0.34)
			_draw_actor_sprite(player_actor, anim_name, pos - facing_n * 44.0, flip_x, 1.0, session.presentation_time, progress, ghost_far, atk_squash, atk_rot)
			_draw_actor_sprite(player_actor, anim_name, pos - facing_n * 22.0, flip_x, 1.0, session.presentation_time, progress, ghost_near, atk_squash, atk_rot)
		if w_id == &"pactos" and curses_n > 0:
			_draw_pactos_orbit_spheres(atk_draw_pos, curses_n, t_pres, false)
		var modulate := Color.WHITE
		if int(player.get("flash", 0)) > 0:
			modulate = BONE
		_draw_actor_sprite(player_actor, anim_name, atk_draw_pos, flip_x, 1.0, session.presentation_time, progress, modulate, atk_squash, atk_rot)
		if w_id == &"pactos" and curses_n > 0:
			_draw_pactos_orbit_spheres(atk_draw_pos, curses_n, t_pres, true)
		if w_id == &"guardiao":
			draw_arc(pos, 40.0, 0, TAU, 36, Color(GOLD, 0.30), 2.0, true)
		elif w_id == &"veu":
			draw_arc(pos, 38.0, 0, TAU, 36, Color(Color("5b2d8a"), 0.40), 2.0, true)
		elif w_id == &"pactos":
			draw_arc(pos, 36.0, 0, TAU, 36, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.34), 2.0, true)
		draw_arc(pos, 34, 0, TAU, 40, Color(BONE, 0.35), 1.5, true)
		if int(player.get("inv", 0)) > 0 and not dash:
			draw_arc(pos, 39, -PI * 0.8, -PI * 0.2, 15, Color(BONE, 0.65), 2, true)
		draw_line(pos + aim * 55, pos + aim * 68, Color(BONE, 0.65), 2, true)
		return
	# Procedural fallback
	if w_id == &"pactos" and curses_n > 0:
		_draw_pactos_orbit_spheres(pos, curses_n, t_pres, false)
	var cloak := PackedVector2Array([pos + Vector2(-9, -68), pos + Vector2(12, -67), pos + Vector2(28, -15), pos + Vector2(14, -4), pos + Vector2(2, -12), pos + Vector2(-16, 0), pos + Vector2(-29, -14)])
	draw_colored_polygon(cloak, Color("191722") if w_id == &"pactos" else Color("a9a5a4"))
	draw_polyline(_closed(cloak), INK, 6, true)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-4, -61), pos + Vector2(12, -58), pos + Vector2(21, -15), pos + Vector2(2, -8)]), Color("2b1b36") if w_id == &"pactos" else Color("525368"))
	draw_line(pos + Vector2(-10, -4), pos + Vector2(-10, 5), INK, 7)
	draw_line(pos + Vector2(12, -6), pos + Vector2(14, 5), INK, 7)
	draw_circle(pos + Vector2(0, -75), 17, INK)
	draw_circle(pos + Vector2(0, -75), 12, BONE)
	draw_line(pos + Vector2(-10, -77), pos + Vector2(10, -77), Color("474759"), 4)
	draw_line(pos + Vector2(-15, -57), pos + Vector2(19, -45), Color("353a4b"), 7)
	if w_id != &"pactos":
		var hand := pos + Vector2(0, -34) + aim * 19
		var tip := hand + aim * 60
		draw_line(hand - aim * 9, tip, INK, 10, true)
		draw_line(hand, tip, BONE, 4, true)
		draw_line(hand + aim.orthogonal() * 9, hand - aim.orthogonal() * 9, GOLD, 4, true)
	else:
		if curses_n > 0:
			_draw_pactos_orbit_spheres(pos, curses_n, t_pres, true)
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
		var modulate: Color = boss_modulate if is_boss else (Color(1.08, 1.02, 0.90, 1.0) if is_elite else Color.WHITE)
		if spawning:
			modulate.a = 0.65
		if int(enemy.get("flash", 0)) > 0:
			modulate = Color(1.6, 1.55, 1.42, modulate.a)
		var phase_time: float = session.presentation_time + float(int(enemy.get("id", 0))) * 0.19
		var draw_pos: Vector2 = pos
		var squash := Vector2.ONE
		var rot_angle: float = 0.0
		if action == "idle":
			var breath: float = sin(float(session.presentation_time) * 2.4) * 0.018
			squash = Vector2(1.0 - breath * 0.55, 1.0 + breath)
		# Peso fisico de ataque para todos os chefes (ergue no windup, avanca/esmaga no golpe)
		if kind == "colosso_de_cinza":
			if enemy.phase == "windup" and progress >= 0.0:
				var lift: float = clampf(progress, 0.0, 1.0)
				squash = Vector2(1.0 - 0.11 * lift, 1.0 + 0.18 * lift)
				draw_pos.y -= 22.0 * lift
				rot_angle = -flip_x * 0.12 * lift
				if lift > 0.65:
					draw_pos.x += sin(phase_time * 55.0) * 3.5
				modulate = modulate.lerp(Color(1.35, 0.92, 0.68, modulate.a), lift * 0.55)
			elif enemy.phase == "recover" and action == "attack" and progress >= 0.0:
				var slam_t: float = clampf(1.0 - progress, 0.0, 1.0)
				squash = Vector2(1.0 + 0.26 * slam_t, 1.0 - 0.24 * slam_t)
				draw_pos += look_vec * (26.0 * slam_t)
				draw_pos.y += 10.0 * slam_t
				rot_angle = flip_x * 0.18 * slam_t
			elif action == "run":
				var stomp: float = absf(sin(phase_time * 5.2))
				draw_pos.y -= stomp * 7.0
				rot_angle = sin(phase_time * 5.2) * 0.055
				squash = Vector2(1.0 + (1.0 - stomp) * 0.06, 1.0 - (1.0 - stomp) * 0.05)
		elif is_boss:
			var is_ranged_boss: bool = String(def.get("comportamento", "")) == "ranged"
			if enemy.phase == "windup" and progress >= 0.0:
				var w_p: float = clampf(progress, 0.0, 1.0)
				if is_ranged_boss:
					draw_pos.y -= 14.0 * w_p
					squash = Vector2(1.0 - 0.08 * w_p, 1.0 + 0.12 * w_p)
					modulate = modulate.lerp(Color(1.25, 1.05, 1.35, modulate.a), w_p * 0.45)
				else:
					draw_pos -= look_vec * (12.0 * w_p)
					draw_pos.y -= 10.0 * w_p
					squash = Vector2(1.0 - 0.08 * w_p, 1.0 + 0.12 * w_p)
					rot_angle = -flip_x * 0.14 * w_p
			elif enemy.phase == "recover" and action == "attack" and progress >= 0.0:
				var a_t: float = clampf(1.0 - progress, 0.0, 1.0)
				if is_ranged_boss:
					draw_pos -= look_vec * (10.0 * a_t)
					squash = Vector2(1.0 + 0.14 * a_t, 1.0 - 0.08 * a_t)
				else:
					draw_pos += look_vec * (28.0 * a_t)
					squash = Vector2(1.0 + 0.18 * a_t, 1.0 - 0.12 * a_t)
					rot_angle = flip_x * 0.20 * a_t
		if is_elite and not is_boss:
			# Selo rúnico giratório discreto ancorado no chão (substitui escudo/coroa flutuantes)
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.42))
			draw_arc(Vector2.ZERO, radius + 12.0, 0, TAU, 36, Color(GOLD.r, GOLD.g, GOLD.b, 0.62), 2.5, true)
			draw_arc(Vector2.ZERO, radius + 19.0, 0, TAU, 36, Color(GOLD.r, GOLD.g, GOLD.b, 0.22), 1.5, true)
			for m_i: int in range(4):
				var m_ang: float = phase_time * 0.9 + float(m_i) * (TAU * 0.25)
				var m_dir: Vector2 = Vector2.RIGHT.rotated(m_ang)
				draw_line(m_dir * (radius + 6.0), m_dir * (radius + 20.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.72), 2.5, true)
			draw_set_transform(Vector2.ZERO)
		var boss_intro_active: bool = false
		var boss_intro_p: float = 1.0
		if is_boss:
			var intro_raw: Variant = app.get("boss_intro_timer")
			var boss_intro_t: float = float(intro_raw) if intro_raw != null else 0.0
			if boss_intro_t > 0.0:
				boss_intro_active = true
				var dur_raw: Variant = app.get("boss_intro_duration")
				var boss_intro_dur: float = maxf(0.1, float(dur_raw) if dur_raw != null else 2.6)
				boss_intro_p = clampf(1.0 - boss_intro_t / boss_intro_dur, 0.0, 1.0)
				if kind == "soberano_do_limiar":
					if boss_intro_p < 0.38:
						var desc_t: float = clampf(boss_intro_p / 0.38, 0.0, 1.0)
						draw_pos.y -= (1.0 - desc_t) * 320.0
						squash = Vector2(lerpf(0.72, 1.0, desc_t), lerpf(1.18, 1.0, desc_t))
						modulate = Color(0.16, 0.14, 0.20, 0.40 + 0.60 * desc_t).lerp(modulate, desc_t)
				elif kind == "guardiao_do_rito":
					if boss_intro_p < 0.38:
						var form_g: float = clampf((boss_intro_p - 0.26) / 0.12, 0.0, 1.0)
						modulate.a *= form_g
				elif kind == "colosso_de_cinza":
					if boss_intro_p < 0.38:
						var fall_rem: float = 1.0 - clampf(boss_intro_p / 0.38, 0.0, 1.0)
						draw_pos.y -= pow(fall_rem, 2.0) * 620.0
						squash = Vector2(0.86, 1.18)
						modulate = modulate.lerp(Color(1.45, 0.92, 0.62, modulate.a), 0.55)
					else:
						var imp_sq: float = clampf(1.0 - (boss_intro_p - 0.38) / 0.16, 0.0, 1.0)
						if imp_sq > 0.0:
							squash = Vector2(1.0 + 0.24 * imp_sq, 1.0 - 0.22 * imp_sq)
				elif kind == "arconte_da_fenda":
					var emerge_a: float = clampf((boss_intro_p - 0.08) / 0.42, 0.0, 1.0)
					modulate.a *= emerge_a
					draw_pos.y -= 18.0 * sin(boss_intro_p * PI) + 6.0 * sin(phase_time * 3.5)
				_draw_boss_intro_back(kind, pos, draw_pos, radius, boss_aura, boss_intro_p, phase_time, sprite_kind, anim_name, flip_x, elite_scale, progress)
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.42))
			draw_arc(Vector2.ZERO, radius + 14.0, 0, TAU, 48, Color(boss_aura.r, boss_aura.g, boss_aura.b, 0.55), 3.5, true)
			draw_arc(Vector2.ZERO, radius + 26.0, 0, TAU, 48, Color(boss_aura.r, boss_aura.g, boss_aura.b, 0.22), 2.0, true)
			draw_set_transform(Vector2.ZERO)
		_draw_actor_sprite(sprite_kind, anim_name, draw_pos, flip_x, elite_scale, phase_time, progress, modulate, squash, rot_angle)
		if boss_intro_active:
			_draw_boss_intro_front(kind, pos, draw_pos, radius, boss_aura, boss_intro_p, phase_time)
		# Art Bible §3.2 & Lote 02 §3: Anomalia Menor has Magenta emitter ring & dorsal crystal accents
		if kind == "anomalia_menor":
			var emitter_pos := pos + Vector2(0, -26 * elite_scale) + look_vec * (22.0 * elite_scale)
			var emitter_r := (6.5 if enemy.phase == "windup" else 4.0) * elite_scale
			draw_circle(emitter_pos, emitter_r + 2.5, INK)
			draw_circle(emitter_pos, emitter_r, MAGENTA_BRIGHT if enemy.phase == "windup" else MAGENTA)
		if enemy.hp < enemy.max_hp:
			var bar_y := (-128.0 if is_boss else (-108.0 if kind == "eco_perdido" else -82.0)) - (8.0 if is_elite else 0.0)
			var bar_w := 96.0 if is_boss else (66.0 if is_elite else 56.0)
			draw_rect(Rect2(pos + Vector2(-bar_w * 0.5, bar_y), Vector2(bar_w, 6 if is_boss else 5)), INK)
			draw_rect(Rect2(pos + Vector2(-bar_w * 0.5, bar_y), Vector2(bar_w * maxf(0, enemy.hp / enemy.max_hp), 6 if is_boss else 5)), boss_aura if is_boss else tint)
			if is_elite and not is_boss:
				var d_pos := pos + Vector2(-bar_w * 0.5 - 9.0, bar_y + 2.5)
				draw_colored_polygon(PackedVector2Array([d_pos + Vector2(0, -5), d_pos + Vector2(5, 0), d_pos + Vector2(0, 5), d_pos + Vector2(-5, 0)]), GOLD)
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

func _draw_actor_sprite(actor_id: String, anim_name: String, pos: Vector2, flip_x: float, scale_mult: float, time_sec: float, norm_progress: float, modulate: Color, extra_scale: Vector2 = Vector2.ONE, rot: float = 0.0) -> void:
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
	draw_set_transform(pos, rot, Vector2(flip_x * base_scale * extra_scale.x, base_scale * extra_scale.y))
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
	if kind_str == "colosso_de_cinza":
		var brasa_col: Color = Color("e86a2c")
		var slam_prog := clampf(1.0 - float(enemy.timer) / maxf(1.0, roundf(float(data.get("preparo_s", 0.72)) * 60.0)), 0.01, 1.0)
		var angle := deg_to_rad(float(data.get("tele_meio_angulo_graus", 120.0)))
		var slam_r := float(data.get("tele_raio_px", 260.0))
		var poly := _sector(pos, direction.angle(), angle, slam_r)
		var impact_pt: Vector2 = pos + direction * 96.0
		if fill:
			draw_colored_polygon(poly, Color(brasa_col.r, brasa_col.g, brasa_col.b, 0.14 + 0.12 * slam_prog))
			draw_circle(impact_pt, 56.0 * (1.35 - 0.55 * slam_prog), Color(Color("ff9e44"), 0.22 * slam_prog))
		else:
			draw_polyline(_closed(poly), Color(brasa_col, 0.92), 3.5, true)
			draw_arc(impact_pt, maxf(18.0, 92.0 * (1.0 - slam_prog * 0.75)), 0, TAU, 32, Color("ff9e44"), 3.5, true)
			draw_arc(pos, enemy.radius + 12, -PI / 2, -PI / 2 + TAU * slam_prog, 30, Color("ff9e44"), 4.5, true)
		return
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
			var radius: float = float(effect.get("radius", 142.5))
			var angle: float = float(effect.get("angle", 1.21))
			var w_tag: String = String(effect.get("weapon", "lamina"))
			var is_heavy: bool = bool(effect.get("heavy", false))
			var slash_pos: Vector2 = pos + Vector2(0, -38.0)
			var base_ang: float = direction.angle()
			var sweep: float = clampf(progress * 1.65, 0.08, 1.0)
			var a_start: float = base_ang - angle
			var a_end: float = a_start + (angle * 2.0) * sweep
			var atk_col := BONE
			var core_col := GOLD
			if w_tag == "guardiao":
				atk_col = GOLD
				core_col = BONE
			elif w_tag == "veu":
				atk_col = Color("a855f7")
				core_col = Color("7dd3fc")
			elif is_heavy:
				atk_col = GOLD
				core_col = BONE
			# Crescente de corte preenchido varrendo o arco na altura das maos
			var crescent := PackedVector2Array()
			var segs: int = 16
			for i: int in range(segs + 1):
				var t_s: float = float(i) / float(segs)
				var a_i: float = lerpf(a_start, a_end, t_s)
				var r_out: float = radius * (0.94 + 0.08 * sin(t_s * PI))
				crescent.append(slash_pos + Vector2.RIGHT.rotated(a_i) * r_out)
			var inner_ratio: float = 0.54 if w_tag == "guardiao" else (0.64 if is_heavy else 0.72)
			for i: int in range(segs, -1, -1):
				var t_s: float = float(i) / float(segs)
				var a_i: float = lerpf(a_start, a_end, t_s)
				var r_in: float = radius * lerpf(0.95, inner_ratio, sin(t_s * PI))
				crescent.append(slash_pos + Vector2.RIGHT.rotated(a_i) * r_in)
			draw_colored_polygon(crescent, Color(atk_col.r, atk_col.g, atk_col.b, alpha * 0.42))
			draw_arc(slash_pos, radius, a_start, a_end, 28, Color(atk_col.r, atk_col.g, atk_col.b, alpha * 0.95), 9.0 if w_tag == "guardiao" else 6.5, true)
			draw_arc(slash_pos, radius - 7.0, lerpf(a_start, a_end, 0.25), a_end, 20, Color(core_col.r, core_col.g, core_col.b, alpha), 3.5, true)
			# Ponta da arma / golpe pesado com impacto frontal
			var tip_dir: Vector2 = Vector2.RIGHT.rotated(a_end)
			var tip_pt: Vector2 = slash_pos + tip_dir * radius
			draw_line(slash_pos + tip_dir * (radius * 0.45), tip_pt, Color(core_col.r, core_col.g, core_col.b, alpha * 0.9), 4.0, true)
			if w_tag == "guardiao":
				var bash_pt: Vector2 = slash_pos + direction * (radius * 0.72)
				draw_arc(bash_pt, 24.0 + 38.0 * progress, base_ang - 1.1, base_ang + 1.1, 18, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.85), 5.0, true)
			elif w_tag == "veu":
				draw_arc(slash_pos, radius * 0.84, a_end - angle * 1.1, a_end, 16, Color(core_col.r, core_col.g, core_col.b, alpha * 0.8), 3.0, true)
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
			# Pulso de dissipação etérea expandindo no chão
			var pulse_r: float = 18.0 + 78.0 * progress
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.44))
			draw_circle(Vector2.ZERO, pulse_r * 0.85, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.14))
			draw_arc(Vector2.ZERO, pulse_r, 0.0, TAU, 36, Color(BONE.r, BONE.g, BONE.b, alpha * 0.78), 3.5, true)
			draw_arc(Vector2.ZERO, pulse_r * 0.68, 0.0, TAU, 28, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, alpha * 0.62), 2.0, true)
			draw_set_transform(Vector2.ZERO)
			var actor_kind: String = String(effect.get("actor_kind", ""))
			if _frames_by_actor.has(actor_kind):
				var dir_suffix := "costas34" if direction.y < -0.15 else "frente34"
				var flip_x := -1.0 if direction.x < -0.05 else 1.0
				var is_elite_death: bool = bool(effect.get("elite", false))
				var elite_scale: float = 1.15 if is_elite_death else 1.0
				var death_mod := Color(1, 1, 1, alpha)
				_draw_actor_sprite(actor_kind, "death_" + dir_suffix, pos, flip_x, elite_scale, 0.0, progress, death_mod)
			# Estilhaços de sombra e brasa subindo deterministicamente
			for s_i: int in range(10):
				var s_ang: float = float(s_i) * (TAU / 10.0) + 0.25
				var spread_x: float = cos(s_ang) * (16.0 + 28.0 * progress) + sin(progress * 8.0 + float(s_i) * 1.3) * 6.0
				var rise_y: float = -12.0 - progress * (58.0 + float(s_i % 3) * 22.0)
				var shard_pos: Vector2 = pos + Vector2(spread_x, rise_y)
				var shard_sz: float = (4.8 - 2.6 * progress) * (1.1 if s_i % 2 == 0 else 0.85)
				if s_i % 2 == 0:
					var shard_poly := PackedVector2Array([
						shard_pos + Vector2(0.0, -shard_sz * 1.4),
						shard_pos + Vector2(shard_sz, 0.0),
						shard_pos + Vector2(0.0, shard_sz * 1.4),
						shard_pos + Vector2(-shard_sz, 0.0),
					])
					draw_colored_polygon(shard_poly, Color(INK.r, INK.g, INK.b, alpha * 0.88))
					draw_polyline(_closed(shard_poly), Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, alpha * 0.72), 1.5, true)
				else:
					draw_circle(shard_pos, maxf(1.5, shard_sz * 0.75), Color(1.0, 0.62, 0.27, alpha * 0.90))
			for i: int in range(7):
				var ray := Vector2.RIGHT.rotated(float(i) * TAU / 7.0 + 0.3)
				draw_line(pos + ray * (8.0 + 30.0 * (1.0 - alpha)), pos + ray * (19.0 + 40.0 * (1.0 - alpha)), Color(BONE, alpha), 3.0, true)
		"crit":
			var crit_pos: Vector2 = pos + Vector2(0.0, -34.0)
			var crit_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
			var crit_ang: float = crit_dir.angle()
			# Anel de choque elíptico + núcleo branco-dourado brilhante na altura do torso
			draw_set_transform(crit_pos, 0.0, Vector2(1.0, 0.58))
			draw_arc(Vector2.ZERO, 16.0 + 48.0 * progress, 0.0, TAU, 32, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.92), 4.5, true)
			draw_arc(Vector2.ZERO, 10.0 + 30.0 * progress, 0.0, TAU, 24, Color(1.0, 0.98, 0.88, alpha), 2.5, true)
			draw_set_transform(Vector2.ZERO)
			draw_circle(crit_pos, 26.0 * alpha, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.44))
			draw_circle(crit_pos, 13.5 * alpha, Color(1.0, 0.98, 0.90, alpha * 0.96))
			# Faíscas direcionais disparadas no sentido do golpe
			for sp_i: int in range(7):
				var sp_off: float = (float(sp_i) - 3.0) * 0.24
				var sp_dir: Vector2 = Vector2.RIGHT.rotated(crit_ang + sp_off)
				var sp_spd: float = 54.0 + float((sp_i * 7) % 3) * 26.0
				var sp_start: Vector2 = crit_pos + sp_dir * (10.0 + sp_spd * progress * 0.62)
				var sp_end: Vector2 = crit_pos + sp_dir * (24.0 + sp_spd * progress)
				var sp_col: Color = Color(1.0, 0.98, 0.88, alpha) if sp_i % 2 == 0 else Color(GOLD.r, GOLD.g, GOLD.b, alpha)
				draw_line(sp_start, sp_end, sp_col, 3.2, true)
			for i: int in range(9):
				var ray := Vector2.RIGHT.rotated(float(i) * TAU / 9.0 + 0.15)
				draw_line(crit_pos + ray * (10.0 + 38.0 * (1.0 - alpha)), crit_pos + ray * (26.0 + 52.0 * (1.0 - alpha)), Color(GOLD, alpha), 4.0, true)
		"hit", "hurt":
			var is_hurt: bool = String(effect.get("kind", "")) == "hurt"
			var tint: Color = MAGENTA if is_hurt else BONE
			var spark_col: Color = MAGENTA_BRIGHT if is_hurt else GOLD
			var hit_pos: Vector2 = pos + Vector2(0.0, -34.0)
			var hit_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
			var hit_ang: float = hit_dir.angle()
			# Anel de choque elíptico na altura do torso
			draw_set_transform(hit_pos, 0.0, Vector2(1.0, 0.58))
			draw_arc(Vector2.ZERO, 12.0 + 34.0 * progress, 0.0, TAU, 24, Color(tint.r, tint.g, tint.b, alpha * 0.85), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			# Faíscas direcionais disparadas no sentido do golpe
			for sp_i: int in range(5):
				var sp_off: float = (float(sp_i) - 2.0) * 0.28
				var sp_dir: Vector2 = Vector2.RIGHT.rotated(hit_ang + sp_off)
				var sp_spd: float = 42.0 + float((sp_i * 5) % 3) * 20.0
				var sp_start: Vector2 = hit_pos + sp_dir * (8.0 + sp_spd * progress * 0.58)
				var sp_end: Vector2 = hit_pos + sp_dir * (18.0 + sp_spd * progress)
				draw_line(sp_start, sp_end, Color(spark_col.r, spark_col.g, spark_col.b, alpha * 0.95), 2.5, true)
			for i: int in range(7):
				var ray := Vector2.RIGHT.rotated(float(i) * TAU / 7.0 + 0.3)
				draw_line(hit_pos + ray * (8.0 + 30.0 * (1.0 - alpha)), hit_pos + ray * (19.0 + 40.0 * (1.0 - alpha)), Color(tint, alpha), 3.0, true)
		"special":
			draw_line(pos - direction * 45, pos + direction * 45, Color(BONE, alpha * .6), 8, true)
		"magic_cast":
			var cast_pos: Vector2 = pos + Vector2(0, -44.0)
			var cyan := Color("7dd3fc")
			draw_circle(cast_pos, 14.0 * (1.0 - progress * 0.4), Color(cyan, alpha * 0.35))
			draw_arc(cast_pos, 10.0 + 18.0 * progress, 0, TAU, 24, Color(cyan, alpha), 3.0, true)
			draw_arc(cast_pos, 6.0 + 10.0 * progress, direction.angle() - 0.9, direction.angle() + 0.9, 16, Color(GOLD, alpha), 3.0, true)
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
			var shot_pos: Vector2 = pos + Vector2(0, -44.0)
			var perp := direction.orthogonal()
			draw_line(shot_pos, shot_pos + direction * (26.0 * (0.4 + 0.6 * progress)), Color(GOLD, alpha), 4.0, true)
			draw_line(shot_pos + perp * 8.0, shot_pos + direction * 18.0 + perp * 14.0 * progress, Color(BONE, alpha), 2.5, true)
			draw_line(shot_pos - perp * 8.0, shot_pos + direction * 18.0 - perp * 14.0 * progress, Color(BONE, alpha), 2.5, true)
		"pact_call":
			var shock_r := 20.0 + 75.0 * progress
			draw_circle(pos, shock_r, Color(INK, alpha * 0.45))
			draw_arc(pos, shock_r, 0, TAU, 32, Color(INK, alpha), 7.0, true)
			draw_arc(pos, shock_r * 0.88, 0, TAU, 32, Color(BONE, alpha), 3.5, true)
		"colosso_slam":
			var max_r: float = float(effect.get("radius", 260.0))
			var brasa := Color("e86a2c")
			var brasa_clara := Color("ffae52")
			var wave_t: float = clampf(progress * 2.2, 0.0, 1.0)
			var wave_a: float = clampf(1.0 - wave_t, 0.0, 1.0)
			# Cratera central + fissuras radiais de magma rachando o chão
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.52))
			draw_circle(Vector2.ZERO, 44.0, Color(INK.r, INK.g, INK.b, alpha * 0.72))
			draw_circle(Vector2.ZERO, 28.0, Color(brasa.r, brasa.g, brasa.b, alpha * 0.65))
			draw_circle(Vector2.ZERO, 14.0, Color(brasa_clara.r, brasa_clara.g, brasa_clara.b, alpha * 0.85))
			draw_set_transform(Vector2.ZERO)
			for c_i: int in range(8):
				var ang: float = float(c_i) * (TAU / 8.0) + 0.22
				var c_dir: Vector2 = Vector2.RIGHT.rotated(ang)
				var len_c: float = (85.0 + float(c_i % 3) * 32.0) * clampf(progress * 5.0, 0.25, 1.0)
				var mid: Vector2 = pos + c_dir * (len_c * 0.55) + c_dir.orthogonal() * (12.0 if c_i % 2 == 0 else -12.0)
				var tip: Vector2 = pos + c_dir * len_c
				draw_line(pos, mid, Color(INK.r, INK.g, INK.b, alpha * 0.9), 7.0, true)
				draw_line(mid, tip, Color(INK.r, INK.g, INK.b, alpha * 0.8), 4.5, true)
				draw_line(pos, mid, Color(brasa.r, brasa.g, brasa.b, alpha), 3.5, true)
				draw_line(mid, tip, Color(brasa_clara.r, brasa_clara.g, brasa_clara.b, alpha * 0.9), 2.0, true)
			# Duas ondas de choque sísmicas expandindo rapidamente
			if wave_a > 0.01:
				var r1: float = maxf(24.0, max_r * (0.22 + 0.78 * wave_t))
				draw_arc(pos, r1, 0, TAU, 48, Color(brasa.r, brasa.g, brasa.b, wave_a * 0.95), 9.0, true)
				draw_arc(pos, r1 * 0.84, 0, TAU, 40, Color(BONE.r, BONE.g, BONE.b, wave_a * 0.75), 4.5, true)
				for s_i: int in range(10):
					var s_ang: float = float(s_i) * (TAU / 10.0) + 0.1
					var s_dir: Vector2 = Vector2.RIGHT.rotated(s_ang)
					var s_pos: Vector2 = pos + s_dir * (22.0 + 130.0 * wave_t) + Vector2(0, -42.0 * sin(wave_t * PI))
					draw_circle(s_pos, 4.5 * wave_a, Color(brasa_clara.r, brasa_clara.g, brasa_clara.b, wave_a))
		"enemy_attack":
			var e_r: float = float(effect.get("radius", 90.0))
			var e_ang: float = float(effect.get("angle", 1.2))
			var e_pos: Vector2 = pos + Vector2(0, -34.0)
			var e_base: float = direction.angle()
			var e_sweep: float = clampf(progress * 1.7, 0.12, 1.0)
			var ea0: float = e_base - e_ang
			var ea1: float = ea0 + (e_ang * 2.0) * e_sweep
			var e_cresc := PackedVector2Array()
			for i: int in range(13):
				var ts: float = float(i) / 12.0
				e_cresc.append(e_pos + Vector2.RIGHT.rotated(lerpf(ea0, ea1, ts)) * e_r)
			for i: int in range(12, -1, -1):
				var ts: float = float(i) / 12.0
				e_cresc.append(e_pos + Vector2.RIGHT.rotated(lerpf(ea0, ea1, ts)) * (e_r * lerpf(0.95, 0.62, sin(ts * PI))))
			draw_colored_polygon(e_cresc, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.36))
			draw_arc(e_pos, e_r, ea0, ea1, 24, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha), 6.5, true)
			draw_arc(e_pos, e_r - 7.0, lerpf(ea0, ea1, 0.3), ea1, 16, Color(BONE.r, BONE.g, BONE.b, alpha * 0.8), 2.5, true)
		"dmg_num":
			var d_font: Font = ThemeDB.fallback_font
			if d_font != null:
				var d_style: String = String(effect.get("style", effect.get("tag", effect.get("subkind", "normal"))))
				var is_crit_num: bool = (d_style == "crit") or bool(effect.get("crit", false))
				var is_heal_num: bool = (d_style == "heal") or bool(effect.get("heal", false))
				var is_hurt_num: bool = (d_style == "player_hurt") or bool(effect.get("player_hurt", false))
				var txt: String = String(effect.get("text", ""))
				if txt.is_empty():
					var raw_val: float = float(effect.get("value", effect.get("amount", 0.0)))
					var iv: int = int(roundf(absf(raw_val)))
					txt = ("+%d" % iv) if is_heal_num else ("%d" % iv)
				if txt.begins_with("+"):
					is_heal_num = true
				var f_size: int = 28 if is_crit_num else (23 if is_hurt_num else (22 if is_heal_num else 20))
				var f_col: Color = GOLD if is_crit_num else (Color("34d399") if is_heal_num else (Color("fb7185") if is_hurt_num else BONE))
				var drift_x: float = sin(progress * PI) * float(effect.get("drift_x", 10.0))
				var rise_y: float = -42.0 - progress * 54.0
				var t_pos: Vector2 = pos + Vector2(drift_x, rise_y)
				var num_a: float = clampf(1.0 - maxf(0.0, (progress - 0.55) / 0.45), 0.0, 1.0)
				var box_w: float = 180.0
				var draw_x: float = t_pos.x - box_w * 0.5
				var out_col: Color = Color(INK.r, INK.g, INK.b, num_a * 0.95)
				draw_string(d_font, Vector2(draw_x - 2.0, t_pos.y), txt, HORIZONTAL_ALIGNMENT_CENTER, box_w, f_size, out_col)
				draw_string(d_font, Vector2(draw_x + 2.0, t_pos.y), txt, HORIZONTAL_ALIGNMENT_CENTER, box_w, f_size, out_col)
				draw_string(d_font, Vector2(draw_x, t_pos.y - 2.0), txt, HORIZONTAL_ALIGNMENT_CENTER, box_w, f_size, out_col)
				draw_string(d_font, Vector2(draw_x, t_pos.y + 2.0), txt, HORIZONTAL_ALIGNMENT_CENTER, box_w, f_size, out_col)
				draw_string(d_font, Vector2(draw_x, t_pos.y), txt, HORIZONTAL_ALIGNMENT_CENTER, box_w, f_size, Color(f_col.r, f_col.g, f_col.b, num_a))
		"selo_lamina":
			var max_r: float = float(effect.get("radius", 260.0))
			var center_l: Vector2 = pos + Vector2(0.0, -34.0)
			# Flash dourado central + 8 raios de julgamento
			draw_circle(center_l, 48.0 * alpha, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.32))
			draw_circle(center_l, 22.0 * alpha, Color(1.0, 0.98, 0.88, alpha * 0.85))
			for ray_i: int in range(8):
				var r_ang: float = float(ray_i) * (TAU / 8.0) + progress * 1.4
				var r_dir: Vector2 = Vector2.RIGHT.rotated(r_ang)
				var r_len: float = max_r * (0.45 + 0.65 * progress)
				draw_line(center_l + r_dir * 18.0, center_l + r_dir * r_len, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.88), 5.0 * alpha + 1.5, true)
				draw_line(center_l + r_dir * 18.0, center_l + r_dir * (r_len * 0.78), Color(BONE.r, BONE.g, BONE.b, alpha * 0.9), 2.0, true)
			# 3 anéis / crescentes dourados gigantes girando em 360°
			for ring_i: int in range(3):
				var rr: float = max_r * (0.56 + float(ring_i) * 0.22) * (0.55 + 0.45 * progress)
				var base_a: float = progress * (TAU * (1.25 if ring_i % 2 == 0 else -1.1)) + float(ring_i) * 2.1
				var span: float = PI * 1.25
				var cresc := PackedVector2Array()
				var segs_l: int = 18
				for si: int in range(segs_l + 1):
					var ts: float = float(si) / float(segs_l)
					var ai: float = base_a + span * ts
					cresc.append(center_l + Vector2.RIGHT.rotated(ai) * rr)
				for si: int in range(segs_l, -1, -1):
					var ts: float = float(si) / float(segs_l)
					var ai: float = base_a + span * ts
					var rin: float = rr * lerpf(0.96, 0.76, sin(ts * PI))
					cresc.append(center_l + Vector2.RIGHT.rotated(ai) * rin)
				draw_colored_polygon(cresc, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.42))
				draw_arc(center_l, rr, base_a, base_a + span, 28, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.95), 7.0 - float(ring_i) * 1.2, true)
				draw_arc(center_l, rr - 5.0, base_a + 0.15, base_a + span, 22, Color(BONE.r, BONE.g, BONE.b, alpha * 0.85), 2.5, true)
		"selo_ressonancia":
			var max_r: float = float(effect.get("radius", 260.0))
			var cyan_r: Color = Color("38bdf8")
			var cyan_hi: Color = Color("bae6fd")
			# Vórtice gravitacional ciano-dourado no chão + anel de runas expandindo
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.56))
			draw_circle(Vector2.ZERO, max_r * (0.42 + 0.25 * (1.0 - progress)), Color(cyan_r.r, cyan_r.g, cyan_r.b, alpha * 0.14))
			draw_circle(Vector2.ZERO, 36.0 * (0.6 + 0.4 * alpha), Color(INK.r, INK.g, INK.b, alpha * 0.78))
			draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 32, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.9), 3.0, true)
			# 6 braços espirais convergindo para o núcleo gravitacional
			for arm_i: int in range(6):
				var arm_pts := PackedVector2Array()
				var arm_base: float = float(arm_i) * (TAU / 6.0) + progress * 4.2
				for step_i: int in range(10):
					var tf: float = float(step_i) / 9.0
					var r_sp: float = lerpf(max_r * 0.95, 20.0, tf) * (1.0 - progress * 0.35)
					var a_sp: float = arm_base + tf * 2.1
					arm_pts.append(Vector2.RIGHT.rotated(a_sp) * r_sp)
				var arm_col: Color = Color(cyan_r.r, cyan_r.g, cyan_r.b, alpha * 0.85) if arm_i % 2 == 0 else Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.80)
				draw_polyline(arm_pts, arm_col, 4.0, true)
			# Anel de runas expandindo
			var rune_r: float = maxf(28.0, max_r * (0.28 + 0.72 * progress))
			draw_arc(Vector2.ZERO, rune_r, 0.0, TAU, 48, Color(cyan_hi.r, cyan_hi.g, cyan_hi.b, alpha * 0.92), 5.0, true)
			draw_arc(Vector2.ZERO, rune_r * 0.84, 0.0, TAU, 40, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.85), 3.0, true)
			for rn_i: int in range(12):
				var rn_a: float = float(rn_i) * (TAU / 12.0) - progress * 1.6
				var rn_d: Vector2 = Vector2.RIGHT.rotated(rn_a)
				draw_line(rn_d * (rune_r * 0.82), rn_d * (rune_r * 1.04), Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.9), 3.0, true)
			draw_set_transform(Vector2.ZERO)
		"selo_pactos":
			var max_r: float = float(effect.get("radius", 260.0))
			var charges_raw: Variant = effect.get("charges", 1)
			var charges: int = clampi(int(charges_raw) if charges_raw != null else 1, 1, 10)
			var expand_t: float = clampf(progress * 1.25, 0.0, 1.0)
			var cur_r: float = maxf(32.0, max_r * (0.28 + 0.72 * expand_t))
			var pact_viol: Color = Color("9333ea")
			# Poço gravitacional de Uzumaki no chão em perspectiva 3/4
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.54))
			draw_circle(Vector2.ZERO, cur_r, Color(0.05, 0.02, 0.09, alpha * 0.62))
			draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 48, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.92), 5.5, true)
			draw_arc(Vector2.ZERO, cur_r * 0.82, 0.0, TAU, 44, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.85), 3.2, true)
			draw_arc(Vector2.ZERO, cur_r * 0.56, 0.0, TAU, 36, Color(pact_viol.r, pact_viol.g, pact_viol.b, alpha * 0.80), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			# Espiral dupla gigante Uzumaki negra, magenta e dourada girando rapidamente
			var vortex_c: Vector2 = pos + Vector2(0.0, -40.0)
			var spin: float = progress * 10.5
			for arm_i: int in range(4):
				var arm_pts := PackedVector2Array()
				var arm_base: float = spin + float(arm_i) * (TAU * 0.25)
				for step_i: int in range(22):
					var tf: float = float(step_i) / 21.0
					var r_sp: float = lerpf(cur_r * 0.96, 12.0, tf)
					var a_sp: float = arm_base + tf * 4.4
					arm_pts.append(vortex_c + Vector2(cos(a_sp) * r_sp, sin(a_sp) * r_sp * 0.72))
				if arm_i % 2 == 0:
					draw_polyline(arm_pts, Color(INK.r, INK.g, INK.b, alpha * 0.95), 11.0 * alpha + 3.0, true)
					draw_polyline(arm_pts, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.92), 5.0 * alpha + 1.5, true)
				else:
					draw_polyline(arm_pts, Color(pact_viol.r, pact_viol.g, pact_viol.b, alpha * 0.88), 7.0 * alpha + 2.0, true)
					draw_polyline(arm_pts, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.92), 2.8, true)
			# Dezenas de feixes convergentes modulados pelas cargas absorvidas
			var beam_count: int = 20 + charges * 2
			for b_i: int in range(beam_count):
				var b_ang: float = float(b_i) * (TAU / float(beam_count)) + spin * 0.45
				var r_out: float = cur_r * (1.12 - 0.35 * progress + 0.12 * sin(float(b_i) * 1.9))
				var r_in: float = 16.0 + (1.0 - progress) * 28.0
				var p_out: Vector2 = vortex_c + Vector2(cos(b_ang) * r_out, sin(b_ang) * r_out * 0.74)
				var p_in: Vector2 = vortex_c + Vector2(cos(b_ang + 0.18) * r_in, sin(b_ang + 0.18) * r_in * 0.74)
				var b_col: Color = Color(INK.r, INK.g, INK.b, alpha * 0.92) if (b_i % 3 == 0) else (Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, alpha * 0.88) if (b_i % 3 == 1) else Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.86))
				draw_line(p_out, p_in, b_col, 3.6 if (b_i % 3 == 0) else 2.2, true)
			# Núcleo singularidade de Uzumaki
			draw_circle(vortex_c, 34.0 * (0.45 + 0.55 * alpha), Color(INK.r, INK.g, INK.b, alpha * 0.96))
			draw_arc(vortex_c, 36.0 * (0.45 + 0.55 * alpha), 0.0, TAU, 32, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, alpha * 0.95), 4.0, true)
			draw_arc(vortex_c, 22.0 * (0.45 + 0.55 * alpha), 0.0, TAU, 24, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.95), 2.5, true)
		"curse_cast":
			var cast_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
			var cast_pos: Vector2 = pos + Vector2(0.0, -44.0) + cast_dir * 14.0
			var r_cast: float = 10.0 + 20.0 * progress
			draw_circle(cast_pos, r_cast, Color(0.05, 0.02, 0.09, alpha * 0.55))
			draw_arc(cast_pos, r_cast, 0.0, TAU, 24, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.92), 3.0, true)
			for arm_c: int in range(3):
				var pts_c := PackedVector2Array()
				var base_c: float = progress * 8.5 + float(arm_c) * (TAU / 3.0)
				for si: int in range(7):
					var tf: float = float(si) / 6.0
					var rc: float = lerpf(r_cast * 1.1, 3.0, tf)
					var ac: float = base_c + tf * 2.2
					pts_c.append(cast_pos + Vector2.RIGHT.rotated(ac) * rc)
				draw_polyline(pts_c, Color(INK.r, INK.g, INK.b, alpha * 0.95), 4.0, true)
				draw_polyline(pts_c, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, alpha * 0.85), 1.8, true)
			draw_circle(cast_pos, 5.5 * alpha, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, alpha))
		"curse_absorb":
			var target_raw: Variant = effect.get("target", pos)
			var target_pos: Vector2 = target_raw if target_raw is Vector2 else pos
			var src_pt: Vector2 = pos + Vector2(0.0, -30.0)
			var dst_pt: Vector2 = target_pos + Vector2(0.0, -44.0)
			var to_dst: Vector2 = dst_pt - src_pt
			var perp_abs: Vector2 = to_dst.orthogonal().normalized() if to_dst.length_squared() > 1.0 else Vector2.UP
			var arc_off: float = sin(progress * PI * 2.0) * (1.0 - progress) * 26.0
			var orb_pt: Vector2 = src_pt.lerp(dst_pt, progress) + perp_abs * arc_off
			var trail_pts := PackedVector2Array()
			for ti: int in range(8):
				var tp: float = clampf(progress - float(ti) * 0.045, 0.0, 1.0)
				var t_arc: float = sin(tp * PI * 2.0) * (1.0 - tp) * 26.0
				trail_pts.append(src_pt.lerp(dst_pt, tp) + perp_abs * t_arc)
			draw_polyline(trail_pts, Color(INK.r, INK.g, INK.b, alpha * 0.90), 8.0 * (0.4 + 0.6 * alpha), true)
			draw_polyline(trail_pts, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.85), 3.6, true)
			var orb_sz: float = 11.0 * (1.0 - progress * 0.35)
			draw_circle(orb_pt, orb_sz + 5.0, Color(0.05, 0.02, 0.09, alpha * 0.45))
			draw_circle(orb_pt, orb_sz + 2.0, Color(INK.r, INK.g, INK.b, alpha * 0.98))
			draw_circle(orb_pt, orb_sz * 0.68, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, alpha * 0.95))
			draw_circle(orb_pt - Vector2(2.0, 2.0), orb_sz * 0.30, Color(BONE.r, BONE.g, BONE.b, alpha))
		"selo_guardiao":
			var max_r: float = float(effect.get("radius", 240.0))
			var dome_r: float = maxf(32.0, max_r * (0.28 + 0.72 * clampf(progress * 1.4, 0.0, 1.0)))
			var dome_c: Vector2 = pos + Vector2(0.0, -28.0)
			# Ondas sísmicas douradas no piso
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.46))
			var w1_r: float = maxf(24.0, max_r * (0.25 + 0.95 * progress))
			var w2_r: float = maxf(18.0, max_r * (0.15 + 0.70 * progress))
			draw_arc(Vector2.ZERO, w1_r, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.95), 8.0 * alpha + 2.0, true)
			draw_arc(Vector2.ZERO, w2_r, 0.0, TAU, 40, Color(BONE.r, BONE.g, BONE.b, alpha * 0.80), 4.0, true)
			draw_set_transform(Vector2.ZERO)
			# Domo / escudo hexagonal dourado expandindo
			var hex_outer := PackedVector2Array()
			var hex_inner := PackedVector2Array()
			for hi: int in range(6):
				var ha: float = float(hi) * (TAU / 6.0) - PI * 0.5 + progress * 0.35
				var hd: Vector2 = Vector2(cos(ha), sin(ha) * 0.82)
				hex_outer.append(dome_c + hd * dome_r)
				hex_inner.append(dome_c + hd * (dome_r * 0.62))
			draw_colored_polygon(hex_outer, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.18))
			draw_polyline(_closed(hex_outer), Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.95), 6.5, true)
			draw_polyline(_closed(hex_inner), Color(BONE.r, BONE.g, BONE.b, alpha * 0.80), 3.0, true)
			for hi: int in range(6):
				draw_line(hex_inner[hi], hex_outer[hi], Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.72), 2.5, true)
		"selo_veu":
			var viol_out: Color = Color("7c3aed")
			var viol_mid: Color = Color("a855f7")
			var cyan_core: Color = Color("7dd3fc")
			var pts := PackedVector2Array()
			pts.append(pos + Vector2(0.0, -34.0))
			var targets_raw: Variant = effect.get("targets", [])
			if targets_raw is Array:
				var t_arr: Array = targets_raw as Array
				for tv: Variant in t_arr:
					if tv is Vector2:
						pts.append((tv as Vector2) + Vector2(0.0, -34.0))
					elif tv is Dictionary:
						var td: Dictionary = tv as Dictionary
						var tp_v: Variant = td.get("pos", Vector2.ZERO)
						if tp_v is Vector2:
							pts.append((tp_v as Vector2) + Vector2(0.0, -34.0))
			if pts.size() < 2:
				var f_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
				var f_perp: Vector2 = f_dir.orthogonal()
				pts.append(pos + Vector2(0.0, -34.0) + f_dir * 95.0 + f_perp * 55.0)
				pts.append(pos + Vector2(0.0, -34.0) + f_dir * 190.0 - f_perp * 55.0)
				pts.append(pos + Vector2(0.0, -34.0) + f_dir * 290.0 + f_perp * 22.0)
			# Raios de corte sombrio violeta-ciano em zigue-zague conectando todos os alvos
			for seg_i: int in range(pts.size() - 1):
				var p_a: Vector2 = pts[seg_i]
				var p_b: Vector2 = pts[seg_i + 1]
				var seg_v: Vector2 = p_b - p_a
				var seg_p: Vector2 = seg_v.orthogonal().normalized() if seg_v.length_squared() > 1.0 else Vector2.UP
				var jag := PackedVector2Array([
					p_a,
					p_a.lerp(p_b, 0.32) + seg_p * (16.0 if seg_i % 2 == 0 else -16.0),
					p_a.lerp(p_b, 0.68) - seg_p * (14.0 if seg_i % 2 == 0 else -14.0),
					p_b,
				])
				draw_polyline(jag, Color(viol_out.r, viol_out.g, viol_out.b, alpha * 0.65), 14.0 * alpha + 3.0, true)
				draw_polyline(jag, Color(viol_mid.r, viol_mid.g, viol_mid.b, alpha * 0.95), 7.0 * alpha + 2.0, true)
				draw_polyline(jag, Color(cyan_core.r, cyan_core.g, cyan_core.b, alpha), 3.0, true)
				# Cruz de corte sombrio em cada alvo atingido
				var slash_r: float = 28.0 + 18.0 * progress
				draw_line(p_b + Vector2(-slash_r, -slash_r * 0.65), p_b + Vector2(slash_r, slash_r * 0.65), Color(cyan_core.r, cyan_core.g, cyan_core.b, alpha), 4.0, true)
				draw_line(p_b + Vector2(-slash_r, slash_r * 0.65), p_b + Vector2(slash_r, -slash_r * 0.65), Color(viol_mid.r, viol_mid.g, viol_mid.b, alpha * 0.92), 4.0, true)
				draw_circle(p_b, 12.0 * alpha, Color(1.0, 1.0, 1.0, alpha * 0.9))
		"urn_break":
			var u_kind: String = String(effect.get("urn_kind", effect.get("subkind", effect.get("drop", "heal"))))
			var u_col: Color = Color("34d399") if u_kind == "heal" else GOLD
			var u_hi: Color = Color("a7f3d0") if u_kind == "heal" else Color("fef08a")
			# Brilho de cura / fragmento subindo
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.48))
			draw_arc(Vector2.ZERO, 16.0 + 46.0 * progress, 0.0, TAU, 28, Color(u_col.r, u_col.g, u_col.b, alpha * 0.85), 3.5, true)
			draw_set_transform(Vector2.ZERO)
			draw_rect(Rect2(pos.x - 14.0 * alpha, pos.y - 95.0 * progress - 24.0, 28.0 * alpha, 75.0 * alpha), Color(u_col.r, u_col.g, u_col.b, alpha * 0.28))
			for orb_i: int in range(5):
				var ox: float = sin(float(orb_i) * 1.9 + progress * 6.0) * (10.0 + float(orb_i) * 3.0)
				var oy: float = -12.0 - progress * (52.0 + float(orb_i % 3) * 24.0)
				draw_circle(pos + Vector2(ox, oy), 4.2 * alpha + 1.2, Color(u_hi.r, u_hi.g, u_hi.b, alpha * 0.95))
			# 8 estilhaços de cerâmica voando e caindo
			for sh_i: int in range(8):
				var s_ang: float = float(sh_i) * (TAU / 8.0) + 0.35
				var s_spd: float = 36.0 + float((sh_i * 5) % 3) * 18.0
				var sx: float = cos(s_ang) * s_spd * progress
				var sy: float = sin(s_ang) * s_spd * 0.45 * progress - 44.0 * sin(progress * PI) + 12.0 * progress
				var sp: Vector2 = pos + Vector2(sx, sy - 10.0)
				var sz: float = (5.5 - 2.0 * progress)
				var shard := PackedVector2Array([
					sp + Vector2(-sz, -sz * 0.5),
					sp + Vector2(sz * 0.8, -sz * 0.9),
					sp + Vector2(sz, sz * 0.7),
					sp + Vector2(-sz * 0.6, sz * 0.9),
				])
				draw_colored_polygon(shard, Color("262c3b") if sh_i % 2 == 0 else Color("1a1f2b"))
				draw_polyline(_closed(shard), Color(INK.r, INK.g, INK.b, alpha), 2.0, true)

func _draw_urn(pos: Vector2, urn: Dictionary, t_pres: float) -> void:
	var u_kind: String = String(urn.get("kind", "heal"))
	var glow_col: Color = Color("34d399") if u_kind == "heal" else GOLD
	var glow_hi: Color = Color("a7f3d0") if u_kind == "heal" else Color("fef08a")
	var pulse: float = 0.5 + 0.5 * sin(t_pres * 3.4 + pos.x * 0.02 + pos.y * 0.015)
	# Halo luminoso no piso
	draw_set_transform(pos + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.50))
	draw_circle(Vector2.ZERO, 34.0 + pulse * 6.0, Color(glow_col.r, glow_col.g, glow_col.b, 0.14 + pulse * 0.07))
	draw_set_transform(Vector2.ZERO)
	# Corpo cerâmico estilizado em nanquim
	var body := PackedVector2Array([
		pos + Vector2(-10.0, 3.0),
		pos + Vector2(-17.0, -13.0),
		pos + Vector2(-13.0, -31.0),
		pos + Vector2(-7.5, -41.0),
		pos + Vector2(7.5, -41.0),
		pos + Vector2(13.0, -31.0),
		pos + Vector2(17.0, -13.0),
		pos + Vector2(10.0, 3.0),
	])
	draw_colored_polygon(body, Color("1d2230"))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-12.0, -13.0),
		pos + Vector2(-8.5, -29.0),
		pos + Vector2(-1.5, -29.0),
		pos + Vector2(-3.5, -11.0),
	]), Color("31394d"))
	draw_polyline(_closed(body), INK, 3.5, true)
	# Faixa rúnica brilhante + bocal luminoso
	draw_line(pos + Vector2(-14.0, -20.0), pos + Vector2(14.0, -20.0), Color(glow_col.r, glow_col.g, glow_col.b, 0.65 + pulse * 0.30), 2.5, true)
	draw_rect(Rect2(pos + Vector2(-10.5, -46.0), Vector2(21.0, 6.0)), Color("2b3244"))
	draw_rect(Rect2(pos + Vector2(-10.5, -46.0), Vector2(21.0, 6.0)), INK, false, 2.5)
	draw_circle(pos + Vector2(0.0, -45.0), 14.0 + pulse * 3.5, Color(glow_col.r, glow_col.g, glow_col.b, 0.22 + pulse * 0.12))
	draw_circle(pos + Vector2(0.0, -45.0), 6.0, Color(glow_col.r, glow_col.g, glow_col.b, 0.85 + pulse * 0.15))
	draw_circle(pos + Vector2(0.0, -45.0), 2.8, glow_hi)

func _draw_boss_intro_back(kind: String, pos: Vector2, draw_pos: Vector2, radius: float, boss_aura: Color, p: float, phase_time: float, sprite_kind: String, anim_name: String, flip_x: float, elite_scale: float, progress: float) -> void:
	var intro_fade: float = clampf(1.0 - maxf(0.0, (p - 0.78) / 0.22), 0.0, 1.0)
	match kind:
		"soberano_do_limiar":
			# Selo ritual dourado gigante no chão em 2 círculos rúnicos contra-rotativos
			var seal_open: float = clampf(p * 3.2, 0.15, 1.0)
			var r_out: float = 192.0 * seal_open
			var r_in: float = 132.0 * seal_open
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.44))
			draw_circle(Vector2.ZERO, r_out, Color(GOLD.r, GOLD.g, GOLD.b, 0.12 * intro_fade))
			draw_arc(Vector2.ZERO, r_out, 0.0, TAU, 56, Color(GOLD.r, GOLD.g, GOLD.b, 0.90 * intro_fade), 4.5, true)
			draw_arc(Vector2.ZERO, r_in, 0.0, TAU, 48, Color(BONE.r, BONE.g, BONE.b, 0.75 * intro_fade), 3.0, true)
			for i: int in range(8):
				var a_cw: float = float(i) * (TAU / 8.0) + p * 2.8
				var a_ccw: float = float(i) * (TAU / 8.0) - p * 3.6
				var d_cw: Vector2 = Vector2.RIGHT.rotated(a_cw)
				var d_ccw: Vector2 = Vector2.RIGHT.rotated(a_ccw)
				draw_line(d_cw * (r_out * 0.86), d_cw * (r_out * 1.06), Color(GOLD.r, GOLD.g, GOLD.b, 0.90 * intro_fade), 3.5, true)
				draw_line(d_ccw * (r_in * 0.78), d_ccw * (r_in * 1.04), Color(BONE.r, BONE.g, BONE.b, 0.80 * intro_fade), 2.5, true)
			draw_set_transform(Vector2.ZERO)
			# 6 pilares de fogo dourado erguendo em círculo ao redor dele
			var pillar_h: float = 270.0 * clampf(p * 2.9, 0.0, 1.0) * intro_fade
			for pi: int in range(6):
				var p_ang: float = float(pi) * (TAU / 6.0) + p * 0.45
				var p_base: Vector2 = pos + Vector2(cos(p_ang) * 155.0, sin(p_ang) * 68.0)
				var sway: float = sin(phase_time * 9.0 + float(pi) * 1.3) * 7.0
				var flame_out := PackedVector2Array([
					p_base + Vector2(-18.0, 4.0),
					p_base + Vector2(-10.0 + sway * 0.5, -pillar_h * 0.6),
					p_base + Vector2(sway, -pillar_h),
					p_base + Vector2(10.0 + sway * 0.5, -pillar_h * 0.6),
					p_base + Vector2(18.0, 4.0),
				])
				draw_colored_polygon(flame_out, Color(GOLD.r, GOLD.g, GOLD.b, 0.34 * intro_fade))
				draw_line(p_base, p_base + Vector2(sway, -pillar_h * 0.92), Color(GOLD.r, GOLD.g, GOLD.b, 0.78 * intro_fade), 9.0, true)
				draw_line(p_base, p_base + Vector2(sway * 0.7, -pillar_h * 0.78), Color(1.0, 0.98, 0.88, 0.88 * intro_fade), 3.5, true)
		"guardiao_do_rito":
			# Hexagrama arcano magenta girando no chão
			var hex_r: float = 178.0 * clampf(p * 3.0, 0.2, 1.0)
			var hex_rot: float = p * 2.4
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.46))
			draw_circle(Vector2.ZERO, hex_r, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.12 * intro_fade))
			draw_arc(Vector2.ZERO, hex_r, 0.0, TAU, 56, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, 0.88 * intro_fade), 4.0, true)
			draw_arc(Vector2.ZERO, hex_r * 0.84, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, 0.65 * intro_fade), 2.0, true)
			var tri_a := PackedVector2Array()
			var tri_b := PackedVector2Array()
			for ti: int in range(3):
				var aa: float = hex_rot + float(ti) * (TAU / 3.0)
				var ab: float = hex_rot + float(ti) * (TAU / 3.0) + PI / 3.0
				tri_a.append(Vector2.RIGHT.rotated(aa) * (hex_r * 0.94))
				tri_b.append(Vector2.RIGHT.rotated(ab) * (hex_r * 0.94))
			draw_polyline(_closed(tri_a), Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, 0.92 * intro_fade), 3.5, true)
			draw_polyline(_closed(tri_b), Color(GOLD.r, GOLD.g, GOLD.b, 0.85 * intro_fade), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			# 3 ecos/clones translúcidos convergindo em espiral de 3 direções (120°) até p == 0.38
			if p < 0.38:
				var conv_t: float = clampf(p / 0.38, 0.0, 1.0)
				var rem_c: float = 1.0 - conv_t
				for ei: int in range(3):
					var e_ang: float = float(ei) * (TAU / 3.0) + conv_t * 2.6
					var e_dist: float = rem_c * 245.0
					var e_pos: Vector2 = pos + Vector2(cos(e_ang) * e_dist, sin(e_ang) * e_dist * 0.58)
					var trail_ang: float = e_ang - 0.38
					var trail_pos: Vector2 = pos + Vector2(cos(trail_ang) * (e_dist + 42.0), sin(trail_ang) * (e_dist + 42.0) * 0.58)
					draw_line(trail_pos + Vector2(0.0, -45.0), e_pos + Vector2(0.0, -45.0), Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, 0.45), 8.0, true)
					var echo_mod := Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, 0.38 + 0.35 * conv_t)
					_draw_actor_sprite(sprite_kind, anim_name, e_pos, flip_x, elite_scale * (0.85 + 0.15 * conv_t), phase_time, progress, echo_mod)
		"colosso_de_cinza":
			var brasa_c: Color = Color("e86a2c")
			var magma_hi: Color = Color("ffae52")
			if p < 0.38:
				var fall_t: float = clampf(p / 0.38, 0.0, 1.0)
				# Sombra gigante crescendo no chão sob alvo incandescente
				draw_set_transform(pos, 0.0, Vector2(1.0, 0.44))
				var sh_r: float = lerpf(32.0, 138.0, fall_t)
				draw_circle(Vector2.ZERO, sh_r, Color(INK.r, INK.g, INK.b, 0.35 + 0.48 * fall_t))
				draw_arc(Vector2.ZERO, lerpf(170.0, 68.0, fall_t), 0.0, TAU, 44, Color(brasa_c.r, brasa_c.g, brasa_c.b, 0.45 + 0.50 * fall_t), 5.0, true)
				draw_arc(Vector2.ZERO, lerpf(125.0, 42.0, fall_t), 0.0, TAU, 36, Color(magma_hi.r, magma_hi.g, magma_hi.b, 0.55 + 0.45 * fall_t), 3.0, true)
				draw_set_transform(Vector2.ZERO)
				# Rastro flamejante de meteoro atrás do Colosso despencando
				var flame_cone := PackedVector2Array([
					draw_pos + Vector2(-62.0, -24.0),
					draw_pos + Vector2(-24.0, -290.0),
					draw_pos + Vector2(0.0, -370.0),
					draw_pos + Vector2(24.0, -290.0),
					draw_pos + Vector2(62.0, -24.0),
				])
				draw_colored_polygon(flame_cone, Color(brasa_c.r, brasa_c.g, brasa_c.b, 0.46))
				var inner_cone := PackedVector2Array([
					draw_pos + Vector2(-34.0, -20.0),
					draw_pos + Vector2(0.0, -260.0),
					draw_pos + Vector2(34.0, -20.0),
				])
				draw_colored_polygon(inner_cone, Color(magma_hi.r, magma_hi.g, magma_hi.b, 0.72))
				for tr_i: int in range(6):
					var tx: float = (float(tr_i) - 2.5) * 22.0
					var ty_top: float = -150.0 - float((tr_i * 7) % 3) * 65.0
					draw_line(draw_pos + Vector2(tx, -25.0), draw_pos + Vector2(tx * 0.4, ty_top), Color(1.0, 0.92, 0.65, 0.85), 4.0, true)
			else:
				# Cratera gigante de lava/magma rachando o piso
				var imp_t: float = clampf((p - 0.38) / 0.62, 0.0, 1.0)
				var crater_a: float = clampf(1.0 - maxf(0.0, (imp_t - 0.62) / 0.38), 0.0, 1.0)
				draw_set_transform(pos, 0.0, Vector2(1.0, 0.48))
				draw_circle(Vector2.ZERO, 118.0, Color(INK.r, INK.g, INK.b, 0.76 * crater_a))
				draw_circle(Vector2.ZERO, 82.0, Color(brasa_c.r, brasa_c.g, brasa_c.b, 0.58 * crater_a))
				draw_circle(Vector2.ZERO, 44.0, Color(magma_hi.r, magma_hi.g, magma_hi.b, 0.82 * crater_a))
				draw_set_transform(Vector2.ZERO)
				for cr_i: int in range(10):
					var c_ang: float = float(cr_i) * (TAU / 10.0) + 0.18
					var c_dir: Vector2 = Vector2.RIGHT.rotated(c_ang)
					var c_len: float = (130.0 + float(cr_i % 3) * 38.0) * clampf(imp_t * 5.0, 0.3, 1.0)
					var c_mid: Vector2 = pos + Vector2(c_dir.x * c_len * 0.55, c_dir.y * c_len * 0.55 * 0.50) + Vector2(0.0, 10.0 if cr_i % 2 == 0 else -10.0)
					var c_tip: Vector2 = pos + Vector2(c_dir.x * c_len, c_dir.y * c_len * 0.50)
					draw_line(pos, c_mid, Color(INK.r, INK.g, INK.b, 0.92 * crater_a), 8.0, true)
					draw_line(c_mid, c_tip, Color(INK.r, INK.g, INK.b, 0.82 * crater_a), 5.0, true)
					draw_line(pos, c_mid, Color(brasa_c.r, brasa_c.g, brasa_c.b, crater_a), 4.0, true)
					draw_line(c_mid, c_tip, Color(magma_hi.r, magma_hi.g, magma_hi.b, 0.92 * crater_a), 2.5, true)
		"arconte_da_fenda":
			# Fenda Vertical na Realidade (ciano/violeta/branco) abrindo atrás do spawn
			var open_w: float = clampf(p / 0.34, 0.0, 1.0) * intro_fade
			var rift_h: float = 285.0 * clampf(p * 3.5, 0.15, 1.0)
			var rift_c: Vector2 = pos + Vector2(0.0, -110.0)
			var viol_r: Color = Color("7c3aed")
			var cyan_r: Color = Color("38bdf8")
			var outer_w: float = 64.0 * open_w + sin(phase_time * 12.0) * 4.0 * open_w
			var mid_w: float = 34.0 * open_w
			var core_w: float = 12.0 * open_w
			var rift_out := PackedVector2Array([
				rift_c + Vector2(0.0, -rift_h * 0.56),
				rift_c + Vector2(outer_w * 0.72, -rift_h * 0.22),
				rift_c + Vector2(outer_w, 0.0),
				rift_c + Vector2(outer_w * 0.68, rift_h * 0.28),
				rift_c + Vector2(0.0, rift_h * 0.52),
				rift_c + Vector2(-outer_w * 0.68, rift_h * 0.28),
				rift_c + Vector2(-outer_w, 0.0),
				rift_c + Vector2(-outer_w * 0.72, -rift_h * 0.22),
			])
			draw_colored_polygon(rift_out, Color(viol_r.r, viol_r.g, viol_r.b, 0.42 * intro_fade))
			var rift_mid := PackedVector2Array([
				rift_c + Vector2(0.0, -rift_h * 0.50),
				rift_c + Vector2(mid_w, 0.0),
				rift_c + Vector2(0.0, rift_h * 0.46),
				rift_c + Vector2(-mid_w, 0.0),
			])
			draw_colored_polygon(rift_mid, Color(cyan_r.r, cyan_r.g, cyan_r.b, 0.72 * intro_fade))
			var rift_core := PackedVector2Array([
				rift_c + Vector2(0.0, -rift_h * 0.42),
				rift_c + Vector2(core_w, 0.0),
				rift_c + Vector2(0.0, rift_h * 0.38),
				rift_c + Vector2(-core_w, 0.0),
			])
			draw_colored_polygon(rift_core, Color(0.95, 0.99, 1.0, 0.95 * intro_fade))
			# 12 partículas de luz sendo sugadas para dentro da fenda (p < 0.42)
			if p < 0.45:
				var suck_t: float = clampf(p / 0.45, 0.0, 1.0)
				for pt_i: int in range(12):
					var pt_ang: float = float(pt_i) * (TAU / 12.0) + suck_t * 1.4
					var start_d: float = 175.0 + float((pt_i * 7) % 3) * 48.0
					var cur_d: float = lerpf(start_d, 8.0, suck_t)
					var prev_d: float = lerpf(start_d, 18.0, maxf(0.0, suck_t - 0.14))
					var p_now: Vector2 = rift_c + Vector2(cos(pt_ang) * cur_d, sin(pt_ang) * cur_d * 0.78)
					var p_prev: Vector2 = rift_c + Vector2(cos(pt_ang - 0.18) * prev_d, sin(pt_ang - 0.18) * prev_d * 0.78)
					var pt_col: Color = cyan_r if pt_i % 2 == 0 else Color("c4b5fd")
					draw_line(p_prev, p_now, Color(pt_col.r, pt_col.g, pt_col.b, 0.85 * (1.0 - suck_t * 0.4)), 3.0, true)
					draw_circle(p_now, 4.0 * (1.0 - suck_t * 0.3), Color(1.0, 1.0, 1.0, 0.9))
		_:
			# Fallback discreto para chefes genéricos
			var beam_h: float = 520.0
			var beam_w: float = 96.0 * intro_fade
			draw_rect(Rect2(pos.x - beam_w * 0.5, pos.y - beam_h, beam_w, beam_h + 12.0), Color(boss_aura.r, boss_aura.g, boss_aura.b, 0.22 * intro_fade))
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.42))
			draw_arc(Vector2.ZERO, radius + 160.0 * p, 0.0, TAU, 44, Color(boss_aura.r, boss_aura.g, boss_aura.b, 0.80 * intro_fade), 4.0, true)
			draw_set_transform(Vector2.ZERO)

func _draw_boss_intro_front(kind: String, pos: Vector2, _draw_pos: Vector2, radius: float, _boss_aura: Color, p: float, phase_time: float) -> void:
	var intro_fade: float = clampf(1.0 - maxf(0.0, (p - 0.78) / 0.22), 0.0, 1.0)
	match kind:
		"soberano_do_limiar":
			# Ao aterrissar (p >= 0.38): onda dourada + correntes luminosas rompendo
			if p >= 0.38:
				var burst_t: float = clampf((p - 0.38) / 0.62, 0.0, 1.0)
				var burst_a: float = clampf(1.0 - burst_t, 0.0, 1.0)
				draw_set_transform(pos, 0.0, Vector2(1.0, 0.44))
				var wave_r: float = radius * 0.8 + burst_t * 270.0
				draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 56, Color(GOLD.r, GOLD.g, GOLD.b, burst_a * 0.95), 8.0 * burst_a + 2.0, true)
				draw_arc(Vector2.ZERO, wave_r * 0.82, 0.0, TAU, 48, Color(BONE.r, BONE.g, BONE.b, burst_a * 0.85), 4.0, true)
				draw_set_transform(Vector2.ZERO)
				# 6 correntes luminosas rompendo e voando para fora
				var chain_orig: Vector2 = pos + Vector2(0.0, -52.0)
				for ci: int in range(6):
					var c_ang: float = float(ci) * (TAU / 6.0) + 0.25
					var c_dir: Vector2 = Vector2.RIGHT.rotated(c_ang)
					var c_perp: Vector2 = c_dir.orthogonal()
					for link_i: int in range(4):
						var dist_l: float = 34.0 + float(link_i) * 26.0 + burst_t * (115.0 + float(link_i) * 32.0)
						var drop_y: float = burst_t * burst_t * (38.0 + float(link_i) * 14.0)
						var l_pos: Vector2 = chain_orig + c_dir * dist_l + Vector2(0.0, drop_y)
						var l_a: Vector2 = l_pos - c_dir * 9.0
						var l_b: Vector2 = l_pos + c_dir * 9.0
						draw_line(l_a + c_perp * 3.5, l_b + c_perp * 3.5, Color(GOLD.r, GOLD.g, GOLD.b, burst_a * 0.95), 3.0, true)
						draw_line(l_a - c_perp * 3.5, l_b - c_perp * 3.5, Color(BONE.r, BONE.g, BONE.b, burst_a * 0.90), 2.2, true)
		"guardiao_do_rito":
			# Explosão de relâmpagos/arcos elétricos magenta-dourados ao fundir (p >= 0.38)
			if p >= 0.38:
				var fuse_t: float = clampf((p - 0.38) / 0.62, 0.0, 1.0)
				var fuse_a: float = clampf(1.0 - fuse_t, 0.0, 1.0)
				var f_center: Vector2 = pos + Vector2(0.0, -48.0)
				draw_circle(f_center, 85.0 * fuse_a, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, fuse_a * 0.34))
				draw_circle(f_center, 36.0 * fuse_a, Color(1.0, 0.96, 0.90, fuse_a * 0.90))
				draw_set_transform(pos, 0.0, Vector2(1.0, 0.46))
				draw_arc(Vector2.ZERO, 40.0 + fuse_t * 250.0, 0.0, TAU, 52, Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, fuse_a * 0.92), 7.0 * fuse_a + 1.5, true)
				draw_set_transform(Vector2.ZERO)
				for li: int in range(8):
					var l_ang: float = float(li) * (TAU / 8.0) + 0.15
					var l_dir: Vector2 = Vector2.RIGHT.rotated(l_ang)
					var l_perp: Vector2 = l_dir.orthogonal()
					var max_len: float = 155.0 + 105.0 * fuse_t
					var bolt := PackedVector2Array()
					for seg: int in range(6):
						var sf: float = float(seg) / 5.0
						var jag: float = 0.0 if (seg == 0 or seg == 5) else sin(phase_time * 34.0 + float(li) * 2.3 + float(seg) * 1.9) * 18.0
						bolt.append(f_center + l_dir * (max_len * sf) + l_perp * jag)
					var arc_col: Color = Color(MAGENTA_BRIGHT.r, MAGENTA_BRIGHT.g, MAGENTA_BRIGHT.b, fuse_a * 0.95) if li % 2 == 0 else Color(GOLD.r, GOLD.g, GOLD.b, fuse_a * 0.95)
					draw_polyline(bolt, arc_col, 4.5 * fuse_a + 1.5, true)
					draw_polyline(bolt, Color(1.0, 0.96, 1.0, fuse_a * 0.85), 1.8, true)
		"colosso_de_cinza":
			# Ao esmagar o chão (p >= 0.38): dupla onda sísmica laranja + 14 brasas/pedras saltando
			if p >= 0.38:
				var imp_t: float = clampf((p - 0.38) / 0.62, 0.0, 1.0)
				var imp_a: float = clampf(1.0 - imp_t, 0.0, 1.0)
				var brasa_c: Color = Color("e86a2c")
				var magma_hi: Color = Color("ffae52")
				draw_set_transform(pos, 0.0, Vector2(1.0, 0.46))
				var w1_t: float = clampf(imp_t * 1.35, 0.0, 1.0)
				var w2_t: float = clampf((imp_t - 0.14) * 1.35, 0.0, 1.0)
				if w1_t < 1.0:
					var w1_a: float = 1.0 - w1_t
					draw_arc(Vector2.ZERO, 42.0 + w1_t * 290.0, 0.0, TAU, 56, Color(brasa_c.r, brasa_c.g, brasa_c.b, w1_a * 0.95), 10.0 * w1_a + 2.0, true)
				if w2_t > 0.0 and w2_t < 1.0:
					var w2_a: float = 1.0 - w2_t
					draw_arc(Vector2.ZERO, 36.0 + w2_t * 255.0, 0.0, TAU, 48, Color(magma_hi.r, magma_hi.g, magma_hi.b, w2_a * 0.90), 7.0 * w2_a + 1.5, true)
				draw_set_transform(Vector2.ZERO)
				# 14 brasas e pedras saltando para o alto em parábolas determinísticas
				for di: int in range(14):
					var d_ang: float = float(di) * (TAU / 14.0) + 0.12
					var h_spd: float = 85.0 + float((di * 7) % 4) * 42.0
					var v_jump: float = 135.0 + float((di * 5) % 3) * 58.0
					var dx: float = cos(d_ang) * h_spd * imp_t
					var dy: float = sin(d_ang) * h_spd * 0.45 * imp_t - v_jump * imp_t + 220.0 * imp_t * imp_t
					var dp: Vector2 = pos + Vector2(dx, minf(12.0, dy) - 8.0)
					if di % 2 == 0:
						var rk: float = 7.5 * (0.4 + 0.6 * imp_a)
						var rock_p := PackedVector2Array([
							dp + Vector2(-rk, -rk * 0.5),
							dp + Vector2(rk * 0.6, -rk),
							dp + Vector2(rk, rk * 0.6),
							dp + Vector2(-rk * 0.5, rk * 0.8),
						])
						draw_colored_polygon(rock_p, Color("2a252d"))
						draw_polyline(_closed(rock_p), Color(INK.r, INK.g, INK.b, imp_a), 2.0, true)
					else:
						draw_circle(dp, 5.2 * imp_a + 1.2, Color(magma_hi.r, magma_hi.g, magma_hi.b, imp_a))
						draw_circle(dp, 2.4 * imp_a + 0.6, Color(1.0, 0.96, 0.80, imp_a))
		"arconte_da_fenda":
			# 6 cristais/estrelas ciano-douradas orbitando ao redor dele
			var orbit_c: Vector2 = pos + Vector2(0.0, -78.0)
			var cyan_r: Color = Color("7dd3fc")
			var orbit_scale: float = clampf(p * 2.5, 0.2, 1.0)
			for ci: int in range(6):
				var o_ang: float = phase_time * 2.6 + float(ci) * (TAU / 6.0)
				var ox: float = cos(o_ang) * 116.0 * orbit_scale
				var oy: float = sin(o_ang) * 38.0 * orbit_scale
				var cp: Vector2 = orbit_c + Vector2(ox, oy)
				var c_col: Color = cyan_r if ci % 2 == 0 else GOLD
				var sz: float = (10.5 + 2.5 * sin(o_ang)) * intro_fade
				var star := PackedVector2Array([
					cp + Vector2(0.0, -sz * 1.45),
					cp + Vector2(sz * 0.72, 0.0),
					cp + Vector2(0.0, sz * 1.45),
					cp + Vector2(-sz * 0.72, 0.0),
				])
				draw_circle(cp, sz * 1.35, Color(c_col.r, c_col.g, c_col.b, 0.25 * intro_fade))
				draw_colored_polygon(star, Color(c_col.r, c_col.g, c_col.b, 0.95 * intro_fade))
				draw_polyline(_closed(star), Color(1.0, 1.0, 1.0, 0.90 * intro_fade), 1.6, true)

func _draw_domain_expansion(room: Rect2, weapon: StringName, dom_t: float, t_pres: float) -> void:
	var alpha: float = clampf(minf(dom_t * 1.4, (4.5 - dom_t) * 3.0 + 0.3), 0.0, 1.0)
	if alpha <= 0.005:
		return
	var center: Vector2 = room.get_center()
	var radius_base: float = minf(room.size.x, room.size.y) * 0.44
	if weapon == &"lamina":
		draw_rect(room.grow(400.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.07 * alpha))
		draw_set_transform(center, 0.0, Vector2(1.0, 0.56))
		draw_arc(Vector2.ZERO, radius_base, 0.0, TAU, 72, Color(GOLD.r, GOLD.g, GOLD.b, 0.44 * alpha), 4.0, true)
		draw_arc(Vector2.ZERO, radius_base * 0.72, 0.0, TAU, 64, Color(BONE.r, BONE.g, BONE.b, 0.34 * alpha), 2.5, true)
		draw_arc(Vector2.ZERO, radius_base * 0.42, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, 0.50 * alpha), 3.0, true)
		draw_set_transform(Vector2.ZERO)
		for b_i: int in range(12):
			var b_ang: float = float(b_i) * (TAU / 12.0) + t_pres * 0.35
			var b_dir: Vector2 = Vector2.RIGHT.rotated(b_ang)
			var b_perp: Vector2 = b_dir.orthogonal()
			var r_in: float = radius_base * 0.46
			var r_out: float = radius_base * 0.98
			var blade_poly := PackedVector2Array([
				center + Vector2(b_dir.x * r_in, b_dir.y * r_in * 0.56),
				center + Vector2((b_dir * ((r_in + r_out) * 0.5) + b_perp * 11.0).x, (b_dir * ((r_in + r_out) * 0.5) + b_perp * 11.0).y * 0.56),
				center + Vector2(b_dir.x * r_out, b_dir.y * r_out * 0.56),
				center + Vector2((b_dir * ((r_in + r_out) * 0.5) - b_perp * 11.0).x, (b_dir * ((r_in + r_out) * 0.5) - b_perp * 11.0).y * 0.56),
			])
			draw_colored_polygon(blade_poly, Color(GOLD.r, GOLD.g, GOLD.b, 0.24 * alpha))
			draw_polyline(_closed(blade_poly), Color(BONE.r, BONE.g, BONE.b, 0.46 * alpha), 2.0, true)
		for s_i: int in range(6):
			var sy: float = room.position.y + fmod(float(s_i) * 235.0 + t_pres * 48.0, room.size.y)
			var sx0: float = room.position.x + fmod(float(s_i) * 410.0, room.size.x * 0.5)
			var s_dir: Vector2 = Vector2.RIGHT.rotated(-0.35 + float(s_i % 2) * 0.7)
			draw_line(Vector2(sx0, sy) - s_dir * 260.0, Vector2(sx0, sy) + s_dir * 420.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.22 * alpha), 3.0, true)
			draw_line(Vector2(sx0, sy) - s_dir * 180.0, Vector2(sx0, sy) + s_dir * 320.0, Color(BONE.r, BONE.g, BONE.b, 0.28 * alpha), 1.5, true)
	elif weapon == &"ressonancia":
		var cyan: Color = Color("38bdf8")
		var cyan_hi: Color = Color("bae6fd")
		draw_rect(room.grow(400.0), Color(0.06, 0.16, 0.26, 0.16 * alpha))
		draw_set_transform(center, 0.0, Vector2(1.0, 0.58))
		draw_arc(Vector2.ZERO, radius_base, 0.0, TAU, 72, Color(cyan.r, cyan.g, cyan.b, 0.46 * alpha), 4.0, true)
		draw_arc(Vector2.ZERO, radius_base * 0.76, 0.0, TAU, 64, Color(GOLD.r, GOLD.g, GOLD.b, 0.42 * alpha), 2.5, true)
		draw_arc(Vector2.ZERO, radius_base * 0.48, 0.0, TAU, 48, Color(cyan_hi.r, cyan_hi.g, cyan_hi.b, 0.44 * alpha), 3.0, true)
		var sq_a := PackedVector2Array()
		var sq_b := PackedVector2Array()
		for qi: int in range(4):
			var ang_a: float = float(qi) * (TAU * 0.25) + t_pres * 0.55
			var ang_b: float = float(qi) * (TAU * 0.25) - t_pres * 0.55 + PI * 0.25
			sq_a.append(Vector2.RIGHT.rotated(ang_a) * (radius_base * 0.76))
			sq_b.append(Vector2.RIGHT.rotated(ang_b) * (radius_base * 0.76))
		draw_polyline(_closed(sq_a), Color(cyan.r, cyan.g, cyan.b, 0.45 * alpha), 3.0, true)
		draw_polyline(_closed(sq_b), Color(GOLD.r, GOLD.g, GOLD.b, 0.45 * alpha), 3.0, true)
		for oi: int in range(8):
			var oa: float = float(oi) * (TAU / 8.0) + t_pres * 1.1
			var arc_r: float = radius_base * (0.58 if oi % 2 == 0 else 0.88)
			draw_arc(Vector2.ZERO, arc_r, oa - 0.26, oa + 0.26, 12, Color(cyan_hi.r, cyan_hi.g, cyan_hi.b, 0.55 * alpha), 4.0, true)
			var orb_pt: Vector2 = Vector2.RIGHT.rotated(oa) * arc_r
			draw_circle(orb_pt, 8.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.55 * alpha))
		draw_set_transform(Vector2.ZERO)
	elif weapon == &"pactos":
		# Vórtice dos Mil Pactos: cúpula sombria, grande espiral Uzumaki no chão e olhos/sombras ao redor
		draw_rect(room.grow(400.0), Color(0.05, 0.02, 0.09, 0.34 * alpha))
		draw_set_transform(center, 0.0, Vector2(1.0, 0.56))
		draw_circle(Vector2.ZERO, radius_base * 0.92, Color(0.03, 0.01, 0.06, 0.38 * alpha))
		for arm_i: int in range(4):
			var spiral := PackedVector2Array()
			var base_ang: float = float(arm_i) * (TAU * 0.25) + t_pres * 1.35
			for si: int in range(28):
				var tf: float = float(si) / 27.0
				var sr: float = lerpf(radius_base * 0.94, 24.0, tf)
				var sa: float = base_ang + tf * 4.8
				spiral.append(Vector2.RIGHT.rotated(sa) * sr)
			var sp_col: Color = Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.44 * alpha) if arm_i % 2 == 0 else Color(GOLD.r, GOLD.g, GOLD.b, 0.36 * alpha)
			draw_polyline(spiral, Color(INK.r, INK.g, INK.b, 0.70 * alpha), 8.0, true)
			draw_polyline(spiral, sp_col, 3.2, true)
		draw_arc(Vector2.ZERO, radius_base * 0.96, 0.0, TAU, 72, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.45 * alpha), 4.0, true)
		draw_arc(Vector2.ZERO, radius_base * 0.62, 0.0, TAU, 56, Color(GOLD.r, GOLD.g, GOLD.b, 0.40 * alpha), 2.5, true)
		for ri: int in range(12):
			var ra: float = float(ri) * (TAU / 12.0) - t_pres * 0.8
			var rd: Vector2 = Vector2.RIGHT.rotated(ra)
			draw_line(rd * (radius_base * 0.56), rd * (radius_base * 0.68), Color(GOLD.r, GOLD.g, GOLD.b, 0.48 * alpha), 3.0, true)
		draw_set_transform(Vector2.ZERO)
		# Olhos e sombras sutis ao redor do perímetro da arena
		for eye_i: int in range(12):
			var e_ang: float = float(eye_i) * (TAU / 12.0) + 0.18
			var e_pos: Vector2 = center + Vector2(cos(e_ang) * (room.size.x * 0.42), sin(e_ang) * (room.size.y * 0.40))
			var blink: float = 0.45 + 0.55 * sin(t_pres * 1.9 + float(eye_i) * 1.35)
			var ew: float = 22.0
			var eh: float = 9.0 * clampf(blink, 0.18, 1.0)
			draw_circle(e_pos, 30.0, Color(0.03, 0.01, 0.06, 0.30 * alpha))
			var eye_poly := PackedVector2Array([
				e_pos + Vector2(-ew, 0.0),
				e_pos + Vector2(0.0, -eh),
				e_pos + Vector2(ew, 0.0),
				e_pos + Vector2(0.0, eh),
			])
			draw_colored_polygon(eye_poly, Color(INK.r, INK.g, INK.b, 0.68 * alpha))
			draw_polyline(_closed(eye_poly), Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.42 * alpha), 1.8, true)
			draw_circle(e_pos, 4.2, Color(GOLD.r, GOLD.g, GOLD.b, 0.62 * blink * alpha))
	elif weapon == &"guardiao":
		var bronze: Color = Color("b07d3c")
		draw_rect(room.grow(400.0), Color(0.18, 0.12, 0.04, 0.14 * alpha))
		draw_set_transform(center, 0.0, Vector2(1.0, 0.56))
		var hex_out := PackedVector2Array()
		var hex_in := PackedVector2Array()
		var rot_g: float = t_pres * 0.25
		for hi: int in range(6):
			var ha: float = rot_g + float(hi) * (TAU / 6.0)
			hex_out.append(Vector2.RIGHT.rotated(ha) * radius_base)
			hex_in.append(Vector2.RIGHT.rotated(ha + PI / 6.0) * (radius_base * 0.68))
		draw_colored_polygon(hex_out, Color(GOLD.r, GOLD.g, GOLD.b, 0.08 * alpha))
		draw_polyline(_closed(hex_out), Color(GOLD.r, GOLD.g, GOLD.b, 0.50 * alpha), 5.0, true)
		draw_polyline(_closed(hex_in), Color(bronze.r, bronze.g, bronze.b, 0.48 * alpha), 4.0, true)
		draw_arc(Vector2.ZERO, radius_base * 0.86, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, 0.38 * alpha), 3.0, true)
		for ri: int in range(16):
			var r_ang: float = float(ri) * (TAU / 16.0) - t_pres * 0.55
			draw_arc(Vector2.ZERO, radius_base * 1.06, r_ang - 0.10, r_ang + 0.10, 6, Color(bronze.r, bronze.g, bronze.b, 0.52 * alpha), 6.0, true)
			draw_arc(Vector2.ZERO, radius_base * 1.06, r_ang - 0.06, r_ang + 0.06, 4, Color(GOLD.r, GOLD.g, GOLD.b, 0.56 * alpha), 3.0, true)
		draw_set_transform(Vector2.ZERO)
	else:
		# &"veu": eclipse negro com anel violeta-ciano no centro e feixes estelares escuros
		var viol: Color = Color("7c3aed")
		var cyan_v: Color = Color("7dd3fc")
		draw_rect(room.grow(400.0), Color(0.03, 0.02, 0.07, 0.28 * alpha))
		draw_set_transform(center, 0.0, Vector2(1.0, 0.58))
		for ray_i: int in range(14):
			var r_ang: float = float(ray_i) * (TAU / 14.0) + t_pres * 0.22
			var r_dir: Vector2 = Vector2.RIGHT.rotated(r_ang)
			var r_perp: Vector2 = r_dir.orthogonal()
			var r_len: float = radius_base * (1.28 if ray_i % 2 == 0 else 1.02)
			var beam := PackedVector2Array([
				r_dir * (radius_base * 0.32) - r_perp * 10.0,
				r_dir * r_len - r_perp * 26.0,
				r_dir * r_len + r_perp * 26.0,
				r_dir * (radius_base * 0.32) + r_perp * 10.0,
			])
			draw_colored_polygon(beam, Color(INK.r, INK.g, INK.b, 0.36 * alpha))
			draw_line(r_dir * (radius_base * 0.34), r_dir * r_len, Color(cyan_v.r, cyan_v.g, cyan_v.b, 0.24 * alpha) if ray_i % 2 == 0 else Color(viol.r, viol.g, viol.b, 0.26 * alpha), 2.5, true)
		draw_circle(Vector2.ZERO, radius_base * 0.36, Color(INK.r, INK.g, INK.b, 0.72 * alpha))
		draw_arc(Vector2.ZERO, radius_base * 0.37, 0.0, TAU, 56, Color(viol.r, viol.g, viol.b, 0.62 * alpha), 5.0, true)
		draw_arc(Vector2.ZERO, radius_base * 0.40, 0.0, TAU, 56, Color(cyan_v.r, cyan_v.g, cyan_v.b, 0.48 * alpha), 2.5, true)
		draw_set_transform(Vector2.ZERO)

func _draw_exit_doors(room: Rect2, session: Variant, t_pres: float) -> void:
	var doors_raw: Variant = session.get("exit_doors")
	if not (doors_raw is Array):
		return
	var doors_arr: Array = doors_raw as Array
	if doors_arr.is_empty():
		return
	var cleared_raw: Variant = session.get("room_cleared")
	var room_cleared: bool = bool(cleared_raw) if cleared_raw != null else session.enemies.is_empty()
	var active_raw: Variant = session.get("active_door_index")
	var active_idx: int = int(active_raw) if active_raw != null else -1
	var font: Font = ThemeDB.fallback_font
	for d_i: int in range(doors_arr.size()):
		var porta_raw: Variant = doors_arr[d_i]
		if not (porta_raw is Dictionary):
			continue
		var porta: Dictionary = porta_raw as Dictionary
		var pos_raw: Variant = porta.get("pos", Vector2(room.size.x * 0.5, 78.0))
		var d_pos: Vector2 = pos_raw if pos_raw is Vector2 else Vector2(room.size.x * 0.5, 78.0)
		var cor_raw: Variant = porta.get("cor", GOLD)
		var d_col: Color = GOLD
		if cor_raw is Color:
			d_col = cor_raw
		elif cor_raw is String and not String(cor_raw).is_empty():
			d_col = Color(String(cor_raw))
		var nome: String = String(porta.get("nome", "Próxima Câmara"))
		var tag: String = String(porta.get("recompensa_tag", ""))
		var is_portal: bool = bool(porta.get("is_region_portal", false))
		var is_active: bool = room_cleared and (d_i == active_idx)
		var pulse: float = 0.5 + 0.5 * sin(t_pres * 3.4 + float(d_i) * 1.1)
		var arch_w: float = 148.0 if is_portal else 128.0
		var arch_h: float = 124.0 if is_portal else 112.0
		# Feixe luminoso ascendendo quando a sala está limpa
		if room_cleared:
			var beam_alpha: float = (0.28 + 0.14 * pulse) if is_active else (0.14 + 0.06 * pulse)
			var beam_poly := PackedVector2Array([
				d_pos + Vector2(-arch_w * 0.36, 4.0),
				d_pos + Vector2(-arch_w * 0.56, -220.0),
				d_pos + Vector2(arch_w * 0.56, -220.0),
				d_pos + Vector2(arch_w * 0.36, 4.0),
			])
			draw_colored_polygon(beam_poly, Color(d_col.r, d_col.g, d_col.b, beam_alpha))
			# Halo elíptico no piso diante da porta
			draw_set_transform(d_pos + Vector2(0.0, 14.0), 0.0, Vector2(1.0, 0.44))
			draw_circle(Vector2.ZERO, 96.0 + (12.0 if is_active else 0.0) + pulse * 8.0, Color(d_col.r, d_col.g, d_col.b, 0.24 if is_active else 0.12))
			if is_active:
				draw_arc(Vector2.ZERO, 88.0 + pulse * 6.0, 0.0, TAU, 36, Color(GOLD.r, GOLD.g, GOLD.b, 0.90), 3.5, true)
			draw_set_transform(Vector2.ZERO)
		# Moldura de pedra do arco do portal
		var stone_outer := Rect2(d_pos + Vector2(-arch_w * 0.5 - 14.0, -arch_h), Vector2(arch_w + 28.0, arch_h + 10.0))
		draw_rect(stone_outer, INK)
		draw_rect(Rect2(stone_outer.position + Vector2(4.0, 4.0), stone_outer.size - Vector2(8.0, 8.0)), Color("262b38"))
		draw_rect(stone_outer, GOLD if is_active else Color(d_col.r, d_col.g, d_col.b, 0.72 if room_cleared else 0.28), false, 3.0 if is_active else 2.0)
		var inner_rect := Rect2(d_pos + Vector2(-arch_w * 0.5, -arch_h + 16.0), Vector2(arch_w, arch_h - 14.0))
		if room_cleared:
			var core_a: float = (0.86 + 0.14 * pulse) if is_active else (0.58 + 0.14 * pulse)
			draw_rect(inner_rect, Color(0.05, 0.06, 0.10, 0.92))
			draw_rect(inner_rect.grow(-6.0), Color(d_col.r, d_col.g, d_col.b, core_a * 0.42))
			draw_rect(inner_rect.grow(-18.0), Color(d_col.r, d_col.g, d_col.b, core_a * 0.75))
			draw_rect(Rect2(d_pos.x - 10.0, inner_rect.position.y + 12.0, 20.0, inner_rect.size.y - 20.0), Color(1.0, 0.97, 0.88, core_a * 0.78))
		else:
			draw_rect(inner_rect, Color(INK.r, INK.g, INK.b, 0.95))
			draw_rect(inner_rect.grow(-8.0), Color(d_col.r, d_col.g, d_col.b, 0.14), false, 2.0)
		# Placa estilizada acima do portal
		if font != null:
			var plaque_w: float = 236.0
			var plaque_h: float = 48.0 if is_active else 44.0
			var plaque_pos: Vector2 = d_pos + Vector2(-plaque_w * 0.5, -arch_h - plaque_h - 8.0)
			var plaque_rect := Rect2(plaque_pos, Vector2(plaque_w, plaque_h))
			var p_alpha: float = 0.94 if room_cleared else 0.52
			draw_rect(plaque_rect, Color(0.055, 0.062, 0.095, 0.90 * p_alpha))
			draw_rect(plaque_rect, Color(GOLD.r, GOLD.g, GOLD.b, 0.95) if is_active else Color(d_col.r, d_col.g, d_col.b, 0.72 * p_alpha), false, 2.5 if is_active else 1.5)
			var tag_txt: String = "[%s]" % tag if not tag.is_empty() else "[SAÍDA]"
			var tag_col: Color = GOLD if is_portal else d_col
			draw_string(font, plaque_pos + Vector2(0.0, 19.0), tag_txt, HORIZONTAL_ALIGNMENT_CENTER, plaque_w, 15, Color(tag_col.r, tag_col.g, tag_col.b, p_alpha))
			draw_string(font, plaque_pos + Vector2(0.0, 38.0), nome, HORIZONTAL_ALIGNMENT_CENTER, plaque_w, 14, Color(BONE.r, BONE.g, BONE.b, p_alpha))
			if is_active:
				var prompt_y: float = plaque_pos.y - 8.0 - pulse * 3.0
				draw_string(font, Vector2(plaque_pos.x + 1.5, prompt_y + 1.5), "[E] ENTRAR", HORIZONTAL_ALIGNMENT_CENTER, plaque_w, 16, INK)
				draw_string(font, Vector2(plaque_pos.x, prompt_y), "[E] ENTRAR", HORIZONTAL_ALIGNMENT_CENTER, plaque_w, 16, GOLD)

func _draw_prop_entity(prop: Dictionary) -> void:
	var kind: String = String(prop.get("kind", "estatua_guardiao"))
	var pos_raw: Variant = prop.get("pos", Vector2.ZERO)
	var pos: Vector2 = pos_raw if pos_raw is Vector2 else Vector2.ZERO
	var esc: float = float(prop.get("scale", 1.0))
	var flip: bool = bool(prop.get("flip", false))
	var tex: Texture2D = _env_textures.get("prop_" + kind, null)
	if tex != null:
		var t_size: Vector2 = tex.get_size()
		var base_h: float = 212.0 if kind == "estatua_guardiao" else 204.0
		var h: float = base_h * esc
		var aspect: float = t_size.x / maxf(1.0, t_size.y)
		var w: float = h * aspect
		draw_set_transform(pos, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
		draw_texture_rect(tex, Rect2(-w * 0.5, -h + 10.0, w, h), false)
		draw_set_transform(Vector2.ZERO)
		return
	var fb_h: float = 190.0 * esc
	var fb_w: float = 46.0 * esc
	draw_rect(Rect2(pos.x - fb_w * 0.5, pos.y - fb_h, fb_w, fb_h), Color("2b303d"))
	draw_rect(Rect2(pos.x - fb_w * 0.5, pos.y - fb_h, fb_w, fb_h), INK, false, 3.0)

func _draw_interactive_entity(inter: Dictionary, _idx: int, is_active: bool, t_pres: float) -> void:
	var kind: String = String(inter.get("kind", "monolito_lore"))
	var pos_raw: Variant = inter.get("pos", Vector2.ZERO)
	var pos: Vector2 = pos_raw if pos_raw is Vector2 else Vector2.ZERO
	var usado: bool = bool(inter.get("usado", false))
	var halo_col: Color = Color("34d399")
	var prompt_txt: String = "[E] Ler Eco"
	var target_h: float = 150.0
	match kind:
		"monolito_lore":
			halo_col = Color("34d399")
			prompt_txt = "[E] Ler Eco"
			target_h = 150.0
		"fonte_cura":
			halo_col = Color("5eead4")
			prompt_txt = "[E] Beber"
			target_h = 132.0
		"bau_reliquia":
			halo_col = GOLD
			prompt_txt = "[E] Abrir"
			target_h = 132.0
		"altar_pacto":
			halo_col = MAGENTA
			prompt_txt = "[E] Selar Pacto"
			target_h = 150.0
	var pulse: float = 0.5 + 0.5 * sin(t_pres * 3.0 + pos.x * 0.015)
	if not usado:
		draw_set_transform(pos + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.46))
		draw_circle(Vector2.ZERO, 64.0 + pulse * 10.0, Color(halo_col.r, halo_col.g, halo_col.b, 0.14 + pulse * 0.08))
		if kind == "fonte_cura":
			draw_arc(Vector2.ZERO, 52.0 + pulse * 6.0, 0.0, TAU, 32, Color(GOLD.r, GOLD.g, GOLD.b, 0.45), 2.0, true)
		if is_active:
			draw_arc(Vector2.ZERO, 58.0 + pulse * 5.0, 0.0, TAU, 36, Color(GOLD.r, GOLD.g, GOLD.b, 0.92), 3.5, true)
			draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 32, Color(halo_col.r, halo_col.g, halo_col.b, 0.85), 2.0, true)
		draw_set_transform(Vector2.ZERO)
	var mod_col: Color = Color(0.62, 0.62, 0.68, 0.86) if usado else Color.WHITE
	var tex: Texture2D = _env_textures.get("prop_" + kind, null)
	if tex != null:
		var t_size: Vector2 = tex.get_size()
		var aspect: float = t_size.x / maxf(1.0, t_size.y)
		var w: float = target_h * aspect
		draw_texture_rect(tex, Rect2(pos.x - w * 0.5, pos.y - target_h + 10.0, w, target_h), false, mod_col)
	else:
		draw_circle(pos + Vector2(0.0, -48.0), 34.0, Color(halo_col.r, halo_col.g, halo_col.b, 0.35 if usado else 0.75))
		draw_arc(pos + Vector2(0.0, -48.0), 34.0, 0.0, TAU, 24, INK, 3.0, true)
	if is_active and not usado:
		var font: Font = ThemeDB.fallback_font
		if font != null:
			var bob_y: float = sin(t_pres * 4.2) * 3.5
			var b_w: float = 176.0
			var b_h: float = 30.0
			var b_rect := Rect2(pos.x - b_w * 0.5, pos.y - target_h - 32.0 + bob_y, b_w, b_h)
			draw_rect(b_rect, Color(0.055, 0.062, 0.095, 0.92))
			draw_rect(b_rect, Color(GOLD.r, GOLD.g, GOLD.b, 0.92), false, 2.0)
			draw_string(font, b_rect.position + Vector2(0.0, 21.0), prompt_txt, HORIZONTAL_ALIGNMENT_CENTER, b_w, 15, GOLD)

func _draw_pactos_orbit_spheres(center_pos: Vector2, count: int, t_pres: float, front_pass: bool) -> void:
	var orbit_c: Vector2 = center_pos + Vector2(0.0, -44.0)
	for i: int in range(count):
		var ang: float = t_pres * 1.45 + float(i) * (TAU / float(count))
		var is_front: bool = sin(ang) >= 0.0
		if is_front != front_pass:
			continue
		var bob: float = sin(t_pres * 3.0 + float(i) * 1.7) * 4.0
		var sp: Vector2 = orbit_c + Vector2(cos(ang) * 46.0, sin(ang) * 18.0 + bob)
		draw_circle(sp, 11.5, Color(0.05, 0.02, 0.09, 0.42))
		draw_circle(sp, 9.0, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.36))
		draw_circle(sp, 7.2, INK)
		draw_circle(sp, 4.4, MAGENTA)
		draw_circle(sp - Vector2(1.5, 1.5), 2.0, MAGENTA_BRIGHT)

func _draw_allied_curse(curse: Dictionary, pos: Vector2, t_pres: float) -> void:
	var species: String = String(curse.get("species", "vulto_mudo"))
	var curr_raw: Variant = curse.get("pos", pos)
	var curr_p: Vector2 = curr_raw if curr_raw is Vector2 else pos
	var prev_raw: Variant = curse.get("prev", curr_p)
	var prev_p: Vector2 = prev_raw if prev_raw is Vector2 else curr_p
	var aim_raw: Variant = curse.get("aim", Vector2.DOWN)
	var aim_v: Vector2 = aim_raw if aim_raw is Vector2 else Vector2.DOWN
	var delta: Vector2 = curr_p - prev_p
	var look: Vector2 = delta.normalized() if delta.length_squared() > 0.04 else (aim_v.normalized() if aim_v != Vector2.ZERO else Vector2.DOWN)
	var dir_suffix: String = "costas34" if look.y < -0.15 else "frente34"
	var flip_x: float = -1.0 if look.x < -0.05 else 1.0
	var action: String = "run" if delta.length_squared() > 0.04 else "idle"
	# Anel de pacto magenta-ouro sob os pés para distinguir claramente dos inimigos
	draw_set_transform(pos, 0.0, Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 32, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.72), 2.5, true)
	draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 28, Color(GOLD.r, GOLD.g, GOLD.b, 0.65), 1.8, true)
	for ti: int in range(3):
		var ta: float = t_pres * 2.2 + float(ti) * (TAU / 3.0)
		var td: Vector2 = Vector2.RIGHT.rotated(ta)
		draw_line(td * 21.0, td * 30.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.78), 2.2, true)
	draw_set_transform(Vector2.ZERO)
	if _frames_by_actor.has(species):
		var frames: SpriteFrames = _frames_by_actor[species]
		var anim_name: String = action + "_" + dir_suffix
		if not frames.has_animation(anim_name):
			anim_name = "idle_" + dir_suffix
		_draw_actor_sprite(species, anim_name, pos, flip_x, 0.88, t_pres, -1.0, Color(0.84, 0.72, 1.0, 0.94))
		return
	# Fallback estilizado de maldição aliada
	var wisp_y: float = sin(t_pres * 4.5 + pos.x * 0.03) * 4.0
	var body := PackedVector2Array([
		pos + Vector2(-18.0, -4.0),
		pos + Vector2(-22.0, -28.0 + wisp_y),
		pos + Vector2(0.0, -48.0 + wisp_y),
		pos + Vector2(22.0, -28.0 + wisp_y),
		pos + Vector2(18.0, -4.0),
	])
	draw_colored_polygon(body, Color(0.14, 0.09, 0.22, 0.95))
	draw_polyline(_closed(body), INK, 4.0, true)
	draw_polyline(_closed(body), Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.65), 1.8, true)
	draw_circle(pos + Vector2(-6.0 * flip_x, -26.0 + wisp_y), 3.0, GOLD)
	draw_circle(pos + Vector2(6.0 * flip_x, -26.0 + wisp_y), 3.0, MAGENTA_BRIGHT)

func _sector(pos: Vector2, angle: float, half: float, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array([pos])
	for i in range(25):
		points.append(pos + Vector2.RIGHT.rotated(angle - half + 2 * half * i / 24) * radius)
	return points

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result
