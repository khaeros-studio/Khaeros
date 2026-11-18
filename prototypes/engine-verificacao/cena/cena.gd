# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends Node2D
## EX-0007-NV: mede a posição DESENHADA de um sprite a cada quadro (lendo a textura do viewport
## em frame_post_draw), com passo de 60 Hz e quadro a 144 Hz; teleporte com e sem
## reset_physics_interpolation(); pillarbox ao redimensionar a janela. Saída "EX|".

const VEL_PX_POR_PASSO: float = 3.0
const LINHA_Y: int = 180
var _sprite: Sprite2D
var _interp: bool = true
var _passo: int = 0
var _quadro: int = 0
var _xs: PackedStringArray = []
var _t0: int = 0
var _fase: String = "mov"
var _idx_tele: int = 0

func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a == "--sem-interp":
			_interp = false
	Engine.max_fps = 144
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_sprite = Sprite2D.new()
	_sprite.texture = ImageTexture.create_from_image(img)
	_sprite.centered = false
	_sprite.position = Vector2(20, LINHA_Y - 8)
	if not _interp:
		_sprite.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_sprite)
	print("EX|versao=%s interp_projeto=%s interp_sprite=%s refresh_monitor=%.1f max_fps=%d" % [Engine.get_version_info().string, get_tree().physics_interpolation, _interp, DisplayServer.screen_get_refresh_rate(), Engine.max_fps])
	RenderingServer.frame_post_draw.connect(_pos_desenho)
	_t0 = Time.get_ticks_msec()

func _physics_process(_delta: float) -> void:
	_passo += 1
	if _fase == "mov" or _fase == "tele_sem" or _fase == "tele_com":
		_sprite.position.x += VEL_PX_POR_PASSO
	if _fase == "tele_sem" and _passo == 200:
		_sprite.position.x = 20.0
		_idx_tele = _xs.size()
		_xs.append("|TELEPORTE sem reset no passo %d|" % _passo)
	if _fase == "tele_com" and _passo == 260:
		_sprite.position.x = 20.0
		_sprite.reset_physics_interpolation()
		_idx_tele = _xs.size()
		_xs.append("|TELEPORTE com reset no passo %d|" % _passo)

func _pos_desenho() -> void:
	_quadro += 1
	if _quadro < 30 or _fase == "fim" or _fase == "pillar":
		return
	var im: Image = get_viewport().get_texture().get_image()
	var x: int = -1
	for i in im.get_width():
		if im.get_pixel(i, LINHA_Y).r > 0.5:
			x = i
			break
	_xs.append("%d:%d" % [_passo, x])
	if _fase == "mov" and _xs.size() >= 60:
		print("EX|mov (passo:x_desenhado) %s" % " ".join(_xs))
		_xs.clear()
		_fase = "tele_sem"
	elif _fase == "tele_sem" and _passo > 215:
		print("EX|tele_sem %s" % " ".join(_xs.slice(maxi(0, _idx_tele - 6), _idx_tele + 12)))
		_xs.clear()
		_fase = "tele_com"
	elif _fase == "tele_com" and _passo > 275:
		print("EX|tele_com %s" % " ".join(_xs.slice(maxi(0, _idx_tele - 6), _idx_tele + 12)))
		_xs.clear()
		_fase = "pillar"
		_pillarbox()

func _pillarbox() -> void:
	for tam: Vector2i in [Vector2i(1000, 360), Vector2i(640, 600), Vector2i(1366, 768)]:
		DisplayServer.window_set_size(tam)
		for k in 10:
			await get_tree().process_frame
		var vp: Viewport = get_viewport()
		print("EX|pillar janela=%s visible_rect=%s final_transform=%s textura_vp=%s" % [DisplayServer.window_get_size(), vp.get_visible_rect(), vp.get_final_transform(), vp.get_texture().get_image().get_size()])
		if tam == Vector2i(1000, 360):
			print("EX|pillar SEGURANDO 1000x360 por 5 s para captura")
			await get_tree().create_timer(5.0).timeout
	_fase = "fim"
	get_tree().quit()
