extends SceneTree

const ACTORS := {
	"anomalia_menor": {"frames": 44, "animations": 16},
	"eco_perdido": {"frames": 44, "animations": 16},
	"fenda_errante": {"frames": 44, "animations": 16},
	"iniciado_lamina": {"frames": 108, "animations": 18},
	"elite_pecas": {"frames": 6, "animations": 6},
	"vulto_mudo": {"frames": 44, "animations": 16},
	"espreitador_da_fenda": {"frames": 44, "animations": 16},
	"baluarte_de_cinza": {"frames": 44, "animations": 16},
	"soberano_do_limiar": {"frames": 44, "animations": 16},
	"chefe_soberano_limiar": {"frames": 48, "animations": 26},
	"iniciado_pactos": {"frames": 44, "animations": 8},
}

func _fail(msg: String) -> void:
	push_error("ATLAS_VALIDATE_FAIL: " + msg)
	quit(1)

func _initialize() -> void:
	var total_actors := 0
	for actor_id: String in ACTORS.keys():
		var spec: Dictionary = ACTORS[actor_id]
		var frames_path := "res://assets/art/runtime/%s/%s_frames_v01.tres" % [actor_id, actor_id]
		var manifest_path := "res://assets/art/runtime/%s/atlas_manifest_v01.json" % actor_id
		var frames := load(frames_path) as SpriteFrames
		if frames == null:
			_fail("Failed to load SpriteFrames: " + frames_path)
			return
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("animations"):
			_fail("Invalid manifest: " + manifest_path)
			return
		var manifest: Dictionary = parsed
		var anim_names := frames.get_animation_names()
		if anim_names.size() != int(spec.animations):
			_fail("%s animation count mismatch: %d != %d" % [actor_id, anim_names.size(), int(spec.animations)])
			return
		var count := 0
		for animation: String in anim_names:
			if not manifest.animations.has(animation):
				_fail("%s missing animation in manifest: %s" % [actor_id, animation])
				return
			for index in range(frames.get_frame_count(animation)):
				var texture := frames.get_frame_texture(animation, index) as AtlasTexture
				if texture == null or texture.atlas == null:
					_fail("%s null texture in %s:%d" % [actor_id, animation, index])
					return
				if texture.get_size() != Vector2(400, 400):
					_fail("%s invalid frame size in %s:%d" % [actor_id, animation, index])
					return
				if not Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region):
					_fail("%s region out of bounds in %s:%d" % [actor_id, animation, index])
					return
				count += 1
		if count != int(spec.frames):
			_fail("%s frame count mismatch: %d != %d" % [actor_id, count, int(spec.frames)])
			return
		total_actors += 1
		print("VALIDATED_ATLAS actor=%s frames=%d animations=%d" % [actor_id, count, anim_names.size()])
	print("ALL_RUNTIME_ATLASES_OK actors=%d" % total_actors)
	quit(0)
