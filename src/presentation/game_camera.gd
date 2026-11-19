extends RefCounted
## Two-base camera: aiming uses the stable base, rendering adds cosmetic impulses.

var width := 1920.0
var pos := Vector2.ZERO
var follow_pos := Vector2.ZERO
var transform := Transform2D.IDENTITY
var reduced_motion := false
var shake_strength := 1.0
var aim_intensity := 1.0
var offset := Vector2.ZERO
var base_zoom: float = 1.0
var zoom := 1.0
var top_margin := 0.0
var bottom_margin := 0.0
var _tuning: Dictionary = {}
var _room := Rect2()
var _impulses: Array[Dictionary] = []
var _time := 0.0
var _resize_guard := false
var _frozen := true
var _cosmetic_rng := RandomNumberGenerator.new()

## Installs the room geometry and data-driven camera tuning.
func configure(tuning: Dictionary, room: Rect2) -> void:
	_tuning = tuning.duplicate(true)
	_room = room
	_cosmetic_rng.randomize()
	cut(room.get_center())

## Reconfigures the native viewport for narrow, normal and ultrawide windows.
func resize(window: Window) -> void:
	if _resize_guard or window.size.x <= 0 or window.size.y <= 0: return
	_resize_guard = true
	var ratio := float(window.size.x)/float(window.size.y)
	width = clampf(ratio*1080.0,1920.0,2580.0)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP if ratio < 16.0/9.0 or ratio > 43.0/18.0 else Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	window.content_scale_size = Vector2i(2580,1080) if ratio > 43.0/18.0 else Vector2i(1920,1080)
	pos = _clamp(pos)
	follow_pos = _clamp(follow_pos)
	_apply_transform()
	_resize_guard = false

## Immediately resets both bases and cosmetic state at spawn or room changes.
func cut(player_position: Vector2) -> void:
	pos = _clamp(player_position)
	follow_pos = pos
	_impulses.clear()
	offset = Vector2.ZERO
	zoom = 1.0
	_time = 0.0
	_apply_transform()

## Converts logical viewport coordinates to world without shake or impact zoom.
func screen_to_world(logical: Vector2) -> Vector2:
	return pos + (logical.clamp(Vector2.ZERO, Vector2(width, 1080)) - Vector2(width / 2.0, 540.0)) / base_zoom

## Queues a cosmetic impulse. Call only while gameplay presentation is active.
func impulse(direction: Vector2, strength: float = 1.0) -> void:
	if _tuning.is_empty() or not is_finite(strength) or strength < 0: return
	_impulses.append({"age":0.0,"direction":direction.normalized(),"strength":strength})
	while _impulses.size() > int(_tuning.max_impulses): _impulses.pop_front()

## Advances camera in presentation time; hitstop must pass frozen=false.
func update(delta: float, previous: Vector2, current: Vector2, fraction: float, aim: Vector2, source: String = "mouse", cursor: Vector2 = Vector2.ZERO, frozen: bool = false) -> void:
	_frozen = frozen
	if frozen or _tuning.is_empty():
		_impulses.clear()
		offset = Vector2.ZERO
		zoom = 1.0
		_apply_transform()
		return
	_time += maxf(0.0,delta)
	var player := previous.lerp(current,clampf(fraction,0,1))
	var smoothing := 1.0-pow(2.0,-maxf(0,delta)/float(_tuning.half_life))
	follow_pos = follow_pos.lerp(_clamp(player),smoothing)
	var look := Vector2.ZERO
	if not reduced_motion:
		if source == "mouse":
			var world_cursor := follow_pos + (cursor.clamp(Vector2.ZERO, Vector2(width, 1080)) - Vector2(width / 2.0, 540.0)) / base_zoom
			var direction := world_cursor-player
			look = direction.normalized()*float(_tuning.lookahead)*minf(1.0,direction.length()/float(_tuning.mouse_radius))
		elif source == "analogico":
			look = aim.normalized()*float(_tuning.lookahead)*clampf(aim_intensity,0,1)
	pos = pos.lerp(_clamp(player+look),smoothing)
	offset = Vector2.ZERO
	var added_zoom := 0.0
	for index in range(_impulses.size()-1,-1,-1):
		var item: Dictionary = _impulses[index]
		item.age += maxf(0,delta)
		var decay := pow(2.0,-float(item.age)/float(_tuning.impulse_half_life))
		if decay < float(_tuning.impulse_cutoff):
			_impulses.remove_at(index)
			continue
		var noise := Vector2(_cosmetic_rng.randf_range(-1,1),_cosmetic_rng.randf_range(-1,1))
		offset += (item.direction*float(_tuning.impulse_kick)+noise*float(_tuning.impulse_shake))*float(item.strength)*decay
		added_zoom += float(_tuning.impulse_zoom)*float(item.strength)*decay
	offset = (offset*clampf(shake_strength,0,1)).limit_length(float(_tuning.shake_max))
	zoom = 1.0 if reduced_motion else minf(float(_tuning.zoom_max),1.0+added_zoom)
	_apply_transform()

func _clamp(value: Vector2) -> Vector2:
	if _room.size == Vector2.ZERO: return value
	var half_w: float = (width / 2.0) / base_zoom
	var half_h: float = 540.0 / base_zoom
	var extra: float = maxf(0.0, (width - 1920.0) / 2.0) / base_zoom
	var min_x: float = _room.position.x - extra + half_w
	var max_x: float = _room.end.x + extra - half_w
	var x: float = _room.get_center().x if min_x >= max_x else clampf(value.x, min_x, max_x)
	var min_y: float = _room.position.y + half_h - top_margin
	var max_y: float = _room.end.y - half_h + bottom_margin
	var y: float = _room.get_center().y if min_y >= max_y else clampf(value.y, min_y, max_y)
	return Vector2(x, y)

func _apply_transform() -> void:
	var final_zoom: float = base_zoom * zoom
	transform = Transform2D(Vector2(final_zoom, 0.0), Vector2(0.0, final_zoom), Vector2(width / 2.0, 540.0) - (pos + offset) * final_zoom)
