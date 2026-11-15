extends SceneTree

func _initialize() -> void:
	var frames := load("res://assets/art/runtime/anomalia_menor/anomalia_menor_frames_v01.tres") as SpriteFrames
	assert(frames != null)
	assert(frames.get_animation_names().size() == 16)
	var count := 0
	for animation in frames.get_animation_names():
		for index in range(frames.get_frame_count(animation)):
			var texture := frames.get_frame_texture(animation, index) as AtlasTexture
			assert(texture != null and texture.atlas != null)
			assert(texture.get_size() == Vector2(400, 400))
			assert(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region))
			count += 1
	assert(count == 44)
	var scene := load("res://scenes/art/anomalia_review.tscn") as PackedScene
	assert(scene != null)
	var instance := scene.instantiate()
	root.add_child.call_deferred(instance)
	await process_frame
	await process_frame
	assert(instance.sprites.size() == 32)
	print("ANOMALIA_VALIDATE frames=44 animations=16 preview_sprites=32 failures=0")
	instance.queue_free()
	await process_frame
	quit(0)
