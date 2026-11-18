extends Node2D
## Visual review only: this scene never replaces the game's entry scene.
## Supports unified Lote 02 90px/48px review board (--capture-lote02) and per-actor 16-animation grid (--capture-art).

const CAPTURE_ANOMALIA := "res://production/qa/evidence/assets-lote-02-2026-11-14/anomalia-review.png"
const CAPTURE_LOTE02 := "res://production/qa/evidence/assets-lote-02-2026-11-14/prancha_revisao_90px_lote02.png"
const ACTORS := ["iniciado_lamina", "eco_perdido", "anomalia_menor", "fenda_errante", "elite_pecas"]
const ACTIONS := ["spawn", "idle", "run", "windup", "attack", "recover", "hurt", "death"]
const PIVOT := Vector2(200, 320)
const INK := Color("0d0e14")
const FLOOR_COLOR := Color("2b3240")
const MAGENTA := Color("e0259c")
const MAGENTA_BRIGHT := Color("f070c0")

var frames_by_actor: Dictionary = {}
var manifests_by_actor: Dictionary = {}
var sprites: Array[AnimatedSprite2D] = []
var elapsed := 0.0
var ticks := 0
var lote02_mode := true

func _ready() -> void:
	for actor_id: String in ACTORS:
		var fpath := "res://assets/art/runtime/%s/%s_frames_v01.tres" % [actor_id, actor_id]
		var mpath := "res://assets/art/runtime/%s/atlas_manifest_v01.json" % actor_id
		if ResourceLoader.exists(fpath) and FileAccess.file_exists(mpath):
			frames_by_actor[actor_id] = load(fpath)
			manifests_by_actor[actor_id] = JSON.parse_string(FileAccess.get_file_as_string(mpath))
	var args := OS.get_cmdline_user_args()
	if "--capture-art" in args and not ("--capture-lote02" in args):
		lote02_mode = false
	RenderingServer.set_default_clear_color(Color("171b24"))
	if not lote02_mode:
		_setup_anomalia_grid()
	queue_redraw()

func _setup_anomalia_grid() -> void:
	var frames: SpriteFrames = frames_by_actor["anomalia_menor"]
	var manifest: Dictionary = manifests_by_actor["anomalia_menor"]
	for row in range(4):
		for col in range(4):
			var action: String = ACTIONS[(row % 2) * 4 + col]
			var direction := "frente34" if row < 2 else "costas34"
			var animation := action + "_" + direction
			for size in [1.0, 2.0]:
				var sprite := AnimatedSprite2D.new()
				sprite.sprite_frames = frames
				sprite.animation = animation
				sprite.centered = false
				sprite.offset = -PIVOT
				sprite.scale = Vector2.ONE * float(manifest.animations[animation].scale) * size
				sprite.position = Vector2(40 + col * 470 + (100 if size == 1.0 else 310), 120 + row * 220 + 160)
				add_child(sprite)
				sprites.append(sprite)

func _process(delta: float) -> void:
	elapsed += delta
	if not lote02_mode:
		var frames: SpriteFrames = frames_by_actor["anomalia_menor"]
		for sprite in sprites:
			var animation := sprite.animation
			var count := frames.get_frame_count(animation)
			var total := 0.0
			for index in range(count):
				total += frames.get_frame_duration(animation, index)
			var cursor := fmod(elapsed * frames.get_animation_speed(animation), total)
			for index in range(count):
				cursor -= frames.get_frame_duration(animation, index)
				if cursor < 0:
					sprite.frame = index
					break
	else:
		queue_redraw()
	ticks += 1
	var args := OS.get_cmdline_user_args()
	if ("--capture-art" in args or "--capture-lote02" in args) and ticks == 30:
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var out_path := CAPTURE_LOTE02 if lote02_mode else CAPTURE_ANOMALIA
		var error := image.save_png(out_path)
		print("ART_REVIEW capture=%s error=%d mode=%s" % [out_path, error, "lote02" if lote02_mode else "anomalia"])
		get_tree().quit(error)

func _draw_actor_pose(actor_id: String, anim_name: String, frame_idx: int, pos: Vector2, scale_mult: float, is_elite: bool, modulate: Color) -> void:
	var frames: SpriteFrames = frames_by_actor.get(actor_id)
	var manifest: Dictionary = manifests_by_actor.get(actor_id, {})
	if frames == null or not frames.has_animation(anim_name):
		return
	var idx := clampi(frame_idx, 0, frames.get_frame_count(anim_name) - 1)
	var tex := frames.get_frame_texture(anim_name, idx)
	if tex == null:
		return
	var elite_mult := 1.15 if is_elite else 1.0
	var base_scale := float(manifest.get("animations", {}).get(anim_name, {}).get("scale", 0.4)) * elite_mult * scale_mult
	if actor_id != "eco_perdido" and modulate.a > 0.5 and modulate.r > 0.1:
		draw_set_transform(pos, 0.0, Vector2(1.0, 0.38) * scale_mult * elite_mult)
		draw_circle(Vector2(3, 8), 32.0, Color(INK.r, INK.g, INK.b, 0.68))
		draw_set_transform(Vector2.ZERO)
	draw_set_transform(pos, 0.0, Vector2.ONE * base_scale)
	tex.draw_rect(get_canvas_item(), Rect2(-PIVOT, Vector2(400, 400)), false, modulate)
	draw_set_transform(Vector2.ZERO)
	if is_elite:
		_draw_elite_piece(actor_id, "placas_", pos, elite_mult * scale_mult, modulate)
	if actor_id == "anomalia_menor" and modulate.r > 0.1:
		var emitter_pos := pos + Vector2(22.0, -26.0) * elite_mult * scale_mult
		var emitter_r := (6.5 if anim_name.begins_with("windup") else 4.0) * elite_mult * scale_mult
		draw_circle(emitter_pos, emitter_r + 2.0 * scale_mult, INK)
		draw_circle(emitter_pos, emitter_r, MAGENTA_BRIGHT if anim_name.begins_with("windup") else MAGENTA)
	if is_elite:
		_draw_elite_piece(actor_id, "coroa_", pos, elite_mult * scale_mult, modulate)

func _draw_elite_piece(kind: String, prefix: String, pos: Vector2, total_scale: float, modulate: Color) -> void:
	var frames: SpriteFrames = frames_by_actor.get("elite_pecas")
	var manifest: Dictionary = manifests_by_actor.get("elite_pecas", {})
	var anim_name := prefix + kind
	if frames == null or not frames.has_animation(anim_name):
		return
	var tex := frames.get_frame_texture(anim_name, 0)
	var meta: Dictionary = manifest.get("animations", {}).get(anim_name, {})
	var part_scale := float(meta.get("scale", 0.18)) * total_scale
	var off_arr: Array = meta.get("offset", [0.0, -60.0])
	var part_pos := pos + Vector2(float(off_arr[0]), float(off_arr[1])) * total_scale
	draw_set_transform(part_pos, 0.0, Vector2.ONE * part_scale)
	tex.draw_rect(get_canvas_item(), Rect2(-PIVOT, Vector2(400, 400)), false, modulate)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	if not lote02_mode:
		draw_string(font, Vector2(40, 45), "KHAEROS | ANOMALIA MENOR — REVISÃO DE ANIMAÇÕES", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e4dfd2"))
		draw_string(font, Vector2(40, 78), "44 poses • 16 animações • esquerda: largura-base 90 px • direita: 2× • arte revisada", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("adb4c2"))
		for row in range(4):
			for col in range(4):
				var rect := Rect2(30 + col * 470, 105 + row * 220, 455, 210)
				draw_rect(rect, Color("222833"))
				draw_rect(rect, Color("384152"), false, 1.0)
				var action: String = ACTIONS[(row % 2) * 4 + col]
				var direction := "FRENTE" if row < 2 else "COSTAS"
				draw_string(font, rect.position + Vector2(15, 29), action.to_upper() + " / " + direction, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e4dfd2"))
				draw_line(rect.position + Vector2(15, 175), rect.position + Vector2(440, 175), Color("465160"), 1.0)
		draw_string(font, Vector2(40, 1040), "Cena de revisão: ações sem loop são repetidas aqui. Não altera combate, colisão ou a cena principal.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("adb4c2"))
		return

	# Unified Lote 02 90px/48px Review Board
	draw_string(font, Vector2(40, 44), "KHAEROS | PRANCHA DE REVISÃO UNIFICADA — LOTE 02 + PEÇAS DE ELITE (X0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e4dfd2"))
	draw_string(font, Vector2(40, 74), "Faixa 1: Escala real 1× (90 px) Comuns vs. Elites (×1.15 + X0) • Faixa 2: Ações-Chave e Vistas • Faixa 3: Silhueta Sólida a 48 px", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("adb4c2"))

	# Band 1: 1x Scale Comparison on Arena Floor (#2B3240)
	var b1_rect := Rect2(35, 95, 1850, 290)
	draw_rect(b1_rect, FLOOR_COLOR)
	draw_rect(b1_rect, Color("465160"), false, 1.5)
	draw_string(font, Vector2(55, 125), "FAIXA 1 — ESCALA 1× EM COMBATE (LINHA DE CHÃO UNIFICADA • INICIADO 94 px vs COMUNS vs ELITES ×1.15 + COROA/PLACAS X0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("cfc6b4"))
	var b1_floor_y := 325.0
	draw_line(Vector2(60, b1_floor_y), Vector2(1855, b1_floor_y), Color("465160"), 1.0)
	var lineup := [
		{"id": "iniciado_lamina", "elite": false, "label": "Iniciado (1.0×)"},
		{"id": "eco_perdido", "elite": false, "label": "Eco Perdido (sem sombra)"},
		{"id": "anomalia_menor", "elite": false, "label": "Anomalia Menor"},
		{"id": "fenda_errante", "elite": false, "label": "Fenda Errante"},
		{"id": "eco_perdido", "elite": true, "label": "Eco ELITE (×1.15 + X0)"},
		{"id": "anomalia_menor", "elite": true, "label": "Anomalia ELITE (×1.15 + X0)"},
		{"id": "fenda_errante", "elite": true, "label": "Fenda ELITE (×1.15 + X0)"},
	]
	for i in range(lineup.size()):
		var item: Dictionary = lineup[i]
		var cx := 165.0 + i * 260.0
		_draw_actor_pose(item.id, "idle_frente34", 0, Vector2(cx, b1_floor_y), 1.0, item.elite, Color.WHITE)
		draw_string(font, Vector2(cx - 95, b1_floor_y + 38), item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e3b23c") if item.elite else Color("e4dfd2"))

	# Band 2: Key Combat Poses & Back Views (frente34 & costas34)
	var b2_rect := Rect2(35, 405, 1850, 340)
	draw_rect(b2_rect, Color("222833"))
	draw_rect(b2_rect, Color("465160"), false, 1.5)
	draw_string(font, Vector2(55, 435), "FAIXA 2 — LEITURA DE ESTADOS CRÍTICOS E COSTAS 3/4 (COSTAS IDLE • WINDUP • ATTACK • DEATH + VARIANTES ELITE)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("cfc6b4"))
	var b2_floor_y := 685.0
	draw_line(Vector2(60, b2_floor_y), Vector2(1855, b2_floor_y), Color("465160"), 1.0)
	var poses := [
		{"id": "eco_perdido", "anim": "idle_costas34", "frame": 0, "elite": true, "label": "Eco Elite Costas"},
		{"id": "eco_perdido", "anim": "windup_frente34", "frame": 2, "elite": true, "label": "Eco Elite Windup"},
		{"id": "anomalia_menor", "anim": "idle_costas34", "frame": 0, "elite": true, "label": "Anomalia Elite Costas"},
		{"id": "anomalia_menor", "anim": "windup_frente34", "frame": 2, "elite": true, "label": "Anomalia Elite Windup"},
		{"id": "anomalia_menor", "anim": "death_frente34", "frame": 1, "elite": false, "label": "Anomalia Death"},
		{"id": "fenda_errante", "anim": "idle_costas34", "frame": 0, "elite": true, "label": "Fenda Elite Costas"},
		{"id": "fenda_errante", "anim": "windup_frente34", "frame": 2, "elite": true, "label": "Fenda Elite Windup"},
		{"id": "fenda_errante", "anim": "death_frente34", "frame": 1, "elite": false, "label": "Fenda Death (bipartida)"},
	]
	for i in range(poses.size()):
		var p: Dictionary = poses[i]
		var cx := 155.0 + i * 228.0
		_draw_actor_pose(p.id, p.anim, p.frame, Vector2(cx, b2_floor_y), 1.0, p.elite, Color.WHITE)
		draw_string(font, Vector2(cx - 88, b2_floor_y + 38), p.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e4dfd2"))

	# Band 3: 48px Silhouette Test (#0D0E14) & 1.5x Elite Detail Showcase
	var b3_rect := Rect2(35, 765, 1850, 275)
	draw_rect(b3_rect, Color("565e6e"))
	draw_rect(b3_rect, Color("465160"), false, 1.5)
	draw_string(font, Vector2(55, 795), "FAIXA 3 — TESTE DE SILHUETA SÓLIDA A 48 px (ART BIBLE §3.1) E DETALHE DAS PEÇAS DE ELITE (1.6×)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("0d0e14"))
	var b3_floor_y := 965.0
	draw_line(Vector2(60, b3_floor_y), Vector2(1150, b3_floor_y), Color("2b3240"), 1.0)
	for i in range(lineup.size()):
		var item: Dictionary = lineup[i]
		var cx := 120.0 + i * 150.0
		_draw_actor_pose(item.id, "idle_frente34", 0, Vector2(cx, b3_floor_y), 0.52, item.elite, Color(0, 0, 0, 1))
		draw_string(font, Vector2(cx - 52, b3_floor_y + 32), item.label.split(" ")[0] + ("+" if item.elite else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("0d0e14"))

	# Right box in Band 3: 1.5x Elite closeup on dark stone
	var closeup_rect := Rect2(1180, 780, 690, 245)
	draw_rect(closeup_rect, FLOOR_COLOR)
	draw_rect(closeup_rect, Color("e3b23c"), false, 1.5)
	draw_string(font, Vector2(1200, 806), "DETALHE 1.5× — MONTAGEM DAS PEÇAS X0", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e3b23c"))
	_draw_actor_pose("eco_perdido", "idle_frente34", 0, Vector2(1300, 995), 1.45, true, Color.WHITE)
	_draw_actor_pose("anomalia_menor", "idle_frente34", 0, Vector2(1520, 995), 1.45, true, Color.WHITE)
	_draw_actor_pose("fenda_errante", "idle_frente34", 0, Vector2(1745, 995), 1.45, true, Color.WHITE)
