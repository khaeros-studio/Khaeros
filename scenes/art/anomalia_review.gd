extends Node2D
## Visual review only: this scene never replaces the game's entry scene.

const FRAMES_PATH := "res://assets/art/runtime/anomalia_menor/anomalia_menor_frames_v01.tres"
const MANIFEST_PATH := "res://assets/art/runtime/anomalia_menor/atlas_manifest_v01.json"
const ACTIONS := ["spawn", "idle", "run", "windup", "attack", "recover", "hurt", "death"]
const CAPTURE := "res://production/qa/evidence/assets-lote-02-2026-11-14/anomalia-review.png"
var frames: SpriteFrames
var manifest: Dictionary
var sprites: Array[AnimatedSprite2D] = []
var elapsed := 0.0
var ticks := 0

func _ready() -> void:
	frames = load(FRAMES_PATH)
	manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	RenderingServer.set_default_clear_color(Color("171b24"))
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
				sprite.offset = Vector2(-200, -320)
				sprite.scale = Vector2.ONE * float(manifest.animations[animation].scale) * size
				sprite.position = Vector2(40 + col * 470 + (100 if size == 1.0 else 310), 120 + row * 220 + 160)
				add_child(sprite)
				sprites.append(sprite)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
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
	ticks += 1
	if "--capture-art" in OS.get_cmdline_user_args() and ticks == 30:
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(CAPTURE)
		print("ANOMALIA_REVIEW capture=%s error=%d sprites=%d" % [CAPTURE, error, sprites.size()])
		get_tree().quit(error)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(40, 45), "KHAEROS | ANOMALIA MENOR — REVISÃO DE ANIMAÇÕES", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e4dfd2"))
	draw_string(font, Vector2(40, 78), "44 poses • 16 animações • esquerda: largura-base 90 px • direita: 2× • arte ainda em revisão", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("adb4c2"))
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
