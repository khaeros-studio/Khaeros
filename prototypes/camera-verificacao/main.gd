extends SceneTree

# Disposable math fixtures use exact approved GDD examples, not production tuning.
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func close_vec(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.01

func view_for(size: Vector2) -> Dictionary:
	var width := clampf(size.x / size.y * 1080.0, 1920.0, 2580.0)
	var scale := minf(size.x / width, size.y / 1080.0)
	return {"width": width, "scale": scale, "origin": (size - Vector2(width, 1080) * scale) / 2.0}

func screen_world(mouse: Vector2, view: Dictionary, camera: Vector2) -> Vector2:
	var logical: Vector2 = (mouse - view.origin) / view.scale
	logical = logical.clamp(Vector2.ZERO, Vector2(view.width, 1080))
	return camera + logical - Vector2(view.width / 2.0, 540)

func target(player: Vector2, aim: Vector2, intensity: float = -1.0, reduced: bool = false) -> Vector2:
	var amount := minf(1.0, aim.length() / 480.0) if intensity < 0 else intensity
	return player + aim.normalized() * 120.0 * amount * (0.0 if reduced else 1.0)

func smooth(position: Vector2, wanted: Vector2, delta: float) -> Vector2:
	return position.lerp(wanted, 1.0 - pow(2.0, -delta / 0.12))

func clamp_camera(wanted: Vector2, room: Rect2, width: float) -> Vector2:
	var extra := clampf((width - 1920.0) / 2.0, 0.0, 370.0)
	var x := room.get_center().x if room.size.x + 2 * extra <= width else clampf(wanted.x, room.position.x - extra + width / 2.0, room.end.x + extra - width / 2.0)
	var y := room.get_center().y if room.size.y <= 1080 else clampf(wanted.y, room.position.y + 540, room.end.y - 540)
	return Vector2(x, y)

func impulse(age: float, half_life: float, kick: float, shake: float, zoom: float, direction: Vector2, noise: Vector2, strength: float = 1.0, reduced: bool = false, intro: float = 1.0) -> Dictionary:
	var decay := pow(2.0, -age / half_life)
	return {"decay": decay, "offset": ((direction * kick + noise * shake) * decay * strength).limit_length(40), "zoom": 1.0 if reduced else minf(1.15, intro * minf(1.15, 1.0 + zoom * decay))}

func run() -> void:
	var cases := [
		[Vector2(1280,720), 1920.0, 2.0/3.0, Vector2.ZERO],
		[Vector2(2520,1080), 2520.0, 1.0, Vector2.ZERO],
		[Vector2(2560,1080), 2560.0, 1.0, Vector2.ZERO],
		[Vector2(3440,1440), 2580.0, 4.0/3.0, Vector2.ZERO],
		[Vector2(3840,1080), 2580.0, 1.0, Vector2(630,0)],
		[Vector2(1920,1200), 1920.0, 1.0, Vector2(0,60)],
		[Vector2(1440,1080), 1920.0, 0.75, Vector2(0,135)],
		[Vector2(640,360), 1920.0, 1.0/3.0, Vector2.ZERO]
	]
	for fixture: Array in cases:
		var view := view_for(fixture[0])
		check(is_equal_approx(view.width, fixture[1]) and is_equal_approx(view.scale, fixture[2]) and close_vec(view.origin, fixture[3]), "viewport math " + str(fixture[0]))
	check(close_vec(screen_world(Vector2(960,180), view_for(Vector2(1280,720)), Vector2(1500,800)), Vector2(1980,530)), "F6 canonical conversion")
	check(close_vec(screen_world(Vector2(100,540), view_for(Vector2(3840,1080)), Vector2(1500,800)), Vector2(210,800)), "pillarbox cursor clamps to left edge")
	check(close_vec(screen_world(Vector2(720,50), view_for(Vector2(1440,1080)), Vector2(1500,800)), Vector2(1500,260)), "letterbox cursor clamps to top edge")
	var base_transform := Transform2D(0, Vector2(960,540) - Vector2(1500,800))
	check(close_vec(base_transform.affine_inverse() * Vector2(1440,270), Vector2(1980,530)), "Transform2D inverse agrees with base conversion")
	var displayed_transform := Transform2D(Vector2(1.15,0), Vector2(0,1.15), Vector2(960,540) - Vector2(1540,800) * 1.15)
	check(not close_vec(displayed_transform.affine_inverse() * Vector2(1440,270), Vector2(1980,530)), "using final shaken zoomed transform would alter aim")
	check(close_vec(screen_world(Vector2(960,540), view_for(Vector2(1920,1080)), Vector2(960,540)) - Vector2(33,0), Vector2(927,540)), "AC37 aim originates at current physics position")
	var player := Vector2(1000,600)
	check(close_vec(target(player,Vector2(300,400)), Vector2(1072,696)), "F2 full mouse lookahead")
	check(close_vec(target(player,Vector2(60,80)), Vector2(1015,620)), "F2 proportional mouse lookahead")
	check(close_vec(target(player,Vector2.ZERO),player), "zero aim no lookahead")
	check(close_vec(target(player,Vector2.RIGHT,0.4),player+Vector2(48,0)), "analog intensity preserved")
	check(close_vec(target(player,Vector2.RIGHT,0.0),player), "automatic aim no lookahead")
	check(close_vec(target(player,Vector2(300,400),-1,true),player), "reduced motion no lookahead")
	var bounded := true
	for degree in range(360):
		var previous := 0.0
		for distance in range(0,2001,100):
			var length := (target(player,Vector2.RIGHT.rotated(deg_to_rad(degree))*distance)-player).length()
			bounded = bounded and length <= 120.001 and length + 0.001 >= previous
			previous = length
	check(bounded, "360 directions bounded monotonic lookahead")
	var small := Rect2(0,0,1920,1080)
	var large := Rect2(0,0,2880,1620)
	check(close_vec(clamp_camera(Vector2.ZERO,small,1920),Vector2(960,540)), "screen sized room centered")
	check(close_vec(clamp_camera(Vector2(5000,2000),small,2520),Vector2(960,540)), "ultrawide small room remains centered")
	check(close_vec(clamp_camera(Vector2.ZERO,large,1920),Vector2(960,540)), "large room lower limits")
	check(close_vec(clamp_camera(Vector2(5000,2000),large,1920),Vector2(1920,1080)), "large room upper limits")
	check(close_vec(clamp_camera(Vector2.ZERO,large,2580),Vector2(960,540)), "ultrawide excursion unchanged")
	check(close_vec(smooth(Vector2.ZERO,Vector2(100,0),0.12),Vector2(50,0)), "F3 half life")
	check(close_vec(smooth(Vector2.ZERO,Vector2(100,0),0.24),Vector2(75,0)), "F3 two half lives")
	check(close_vec(smooth(smooth(Vector2.ZERO,Vector2(100,0),0.05),Vector2(100,0),0.05),smooth(Vector2.ZERO,Vector2(100,0),0.1)), "F3 split delta invariant")
	check(close_vec(smooth(Vector2(30,0),Vector2(100,0),0),Vector2(30,0)), "frozen presentation clock does not smooth")
	var no_overshoot := true
	for milliseconds in range(1,5001):
		var x := smooth(Vector2.ZERO,Vector2(100,0),milliseconds/1000.0).x
		no_overshoot = no_overshoot and x >= 0 and x <= 100
	check(no_overshoot, "F3 does not overshoot up to five seconds")
	var heavy := impulse(0.1,0.1,20,8,0.04,Vector2.RIGHT,Vector2(0.5,-1),0.5)
	check(close_vec(heavy.offset,Vector2(6,-2)), "F5 heavy canonical kick and shake")
	var boss := impulse(0.6,0.3,32,14,0.1,Vector2.RIGHT,Vector2.ZERO)
	check(is_equal_approx(boss.zoom,1.025), "F5 boss zoom decay")
	check(is_equal_approx(impulse(0.6,0.3,32,14,0.1,Vector2.RIGHT,Vector2.ZERO,1,true,1.15).zoom,1.0), "reduced motion disables all zoom")
	var shake_off := impulse(0.6,0.3,32,14,0.1,Vector2.RIGHT,Vector2.ZERO,0)
	check(close_vec(shake_off.offset,Vector2.ZERO) and is_equal_approx(shake_off.zoom,1.025), "shake zero retains zoom")
	check(is_equal_approx(impulse(0,0.1,20,8,0.04,Vector2.RIGHT,Vector2.ZERO,1,false,1.1).zoom,1.144), "intro and impact zoom multiply")
	check(is_equal_approx(impulse(0,0.1,20,8,0.04,Vector2.RIGHT,Vector2.ZERO,1,false,1.15).zoom,1.15), "combined zoom ceiling")
	check(close_vec((Vector2(64,0)).limit_length(40),Vector2(40,0)), "multiple kicks capped preserving direction")
	check(pow(2.0,-0.21/0.05)>=0.05 and pow(2.0,-0.22/0.05)<0.05, "light expires between .21 and .22 presentation seconds")
	check(close_vec((large.size-Vector2(1920,1080))/2*0.2+Vector2(40,40)*0.2,Vector2(104,62)), "F7 large room drift")
	check(close_vec((small.size-Vector2(1920,1080))/2*0.2+Vector2(40,40)*0.2,Vector2(8,8)), "F7 screen room drift")
	check(close_vec((1.0-1.2)*Vector2(480,0),Vector2(-96,0)), "F7 anchored parallax sign")
	check(close_vec(Vector2.ZERO.lerp(Vector2(10,0),0.25),Vector2(2.5,0)), "manual interpolated player")
	var old_player := Vector2(300,300)
	var new_player := Vector2(2200,1200)
	old_player = new_player
	check(close_vec(old_player.lerp(new_player,0.25),new_player), "teleport collapses both physics endpoints")
	# Native API smoke checks are distinct from scripted mathematical policy.
	check(ProjectSettings.get_setting("physics/common/physics_interpolation") == true, "project physics interpolation enabled")
	var camera := Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	root.add_child(camera)
	check(camera.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "camera interpolation explicitly off")
	camera.reset_physics_interpolation()
	check(Engine.get_physics_interpolation_fraction() >= 0.0 and Engine.get_physics_interpolation_fraction() <= 1.0, "engine interpolation fraction API returns bounded value")
	camera.enabled = false
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(2580,1080)
	root.size = Vector2i(3840,1080)
	check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP and root.content_scale_size == Vector2i(2580,1080), "native ultrawide policy properties")
	print("OBS viewport32:9 rect=",root.get_visible_rect()," final=",root.get_final_transform())
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	root.content_scale_size = Vector2i(1920,1080)
	root.size = Vector2i(2560,1080)
	check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT and root.content_scale_size == Vector2i(1920,1080), "native return policy properties")
	print("OBS viewport2560 rect=",root.get_visible_rect()," final=",root.get_final_transform())
	for fixture: Array in cases:
		var window_size: Vector2 = fixture[0]
		var ratio := window_size.x / window_size.y
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP if ratio < 16.0/9.0 or ratio > 43.0/18.0 else Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
		root.content_scale_size = Vector2i(2580,1080) if ratio > 43.0/18.0 else Vector2i(1920,1080)
		root.size = Vector2i(window_size)
		var actual := root.get_final_transform()
		check(close_vec(root.get_visible_rect().size,Vector2(fixture[1],1080)) and close_vec(actual.origin,fixture[3]) and is_equal_approx(actual.x.length(),fixture[2]), "native viewport transform " + str(window_size))
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i(1920,1080)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var layer := CanvasLayer.new()
	layer.follow_viewport_enabled = true
	layer.follow_viewport_scale = 1.2
	root.add_child(layer)
	root.canvas_transform = Transform2D(0,Vector2(-100,-50))
	check(layer.follow_viewport_enabled and is_equal_approx(layer.follow_viewport_scale,1.2), "CanvasLayer follow properties accepted")
	print("OBS canvas follow1.2 final=",layer.get_final_transform())
	check(close_vec(layer.get_final_transform().origin,Vector2(-100,-50)) and is_equal_approx(layer.get_final_transform().x.length(),1.2), "follow scale scales basis not translation: not F7 parallax")
	layer.follow_viewport_enabled = false
	print("OBS canvas screen fixed final=",layer.get_final_transform())
	layer.layer = 50
	check(layer.get_final_transform().is_equal_approx(Transform2D.IDENTITY) and layer.layer == 50, "screen-fixed post layer unaffected by world transform")
	var world_layer := Node2D.new()
	world_layer.z_index = 10
	world_layer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	world_layer.position = (1.0-1.2)*Vector2(480,0)
	root.add_child(world_layer)
	check(close_vec(world_layer.global_position,Vector2(-96,0)) and world_layer.z_index == 10, "manual foreground layer offset and z accepted")
	var sort_root := Node2D.new()
	sort_root.y_sort_enabled = false
	root.add_child(sort_root)
	var first := Node2D.new()
	var second := Node2D.new()
	sort_root.add_child(first)
	sort_root.add_child(second)
	sort_root.move_child(second,0)
	check(second.get_index() == 0 and first.get_index() == 1 and not sort_root.y_sort_enabled, "manual sibling order accepted without native y-sort")
	var parallax := Parallax2D.new()
	parallax.ignore_camera_scroll = true
	parallax.screen_offset = Vector2(100,50)
	root.add_child(parallax)
	check(parallax.ignore_camera_scroll and close_vec(parallax.screen_offset,Vector2(100,50)), "Parallax2D explicit scroll API accepted")
	check(parallax.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "Parallax2D interpolation default off")
	# Scripted cut transaction fixture: not production orchestration or visual evidence.
	var cut_done := false
	var cut_count := 0
	var position := Vector2(960,540)
	var active_impulses := 1
	var last_presentation_time := 8.0
	var old_room_retained := true
	var cut_exact := true
	for frame in range(11):
		var progress := frame/10.0
		if progress >= 0.5 and not cut_done:
			cut_done = true
			cut_count += 1
			position = clamp_camera(new_player,large,1920)
			active_impulses = 0
			last_presentation_time = 0.0
		if frame < 5:
			old_room_retained = old_room_retained and close_vec(position,Vector2(960,540))
		if frame == 5:
			cut_exact = close_vec(position,Vector2(1920,1080)) and active_impulses == 0 and is_zero_approx(last_presentation_time)
	check(old_room_retained, "scripted wipe retains old camera before midpoint")
	check(cut_exact, "scripted midpoint cuts and clears impulses and clock baseline together")
	check(cut_count == 1, "scripted cut transaction occurs exactly once")
	print("RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
