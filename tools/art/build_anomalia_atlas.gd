extends SceneTree
## Creates text resources only. Source PNG pixels are never modified.

const SOURCE := "res://assets/art/source/raw/"
const OUTPUT := "res://assets/art/runtime/anomalia_menor/"
const SHEETS := [
	["spawnrun_frente34_raw_v02", 6, "frente34", "movement"],
	["spawnrun_costas34_raw_v01", 6, "costas34", "movement"],
	["ataquemorte_frente34_raw_v01", 5, "frente34", "combat"],
	["ataquemorte_costas34_raw_v01", 5, "costas34", "combat"],
]
const MOVEMENT := ["spawn", "spawn", "spawn", "spawn", "idle", "idle", "run", "run", "run", "run", "run", "run"]
const COMBAT := ["windup", "windup", "windup", "attack", "attack", "recover", "recover", "hurt", "death", "death"]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var lines: Array[String] = []
	var ext: Array[String] = []
	var animations: Array[String] = []
	var manifest := {"status": "technical_preview_art_review_pending", "canvas": [400, 400], "pivot": [200, 320], "logical_idle_width": 90, "animations": {}, "sheets": []}
	var total := 0
	for sheet in SHEETS:
		var sheet_id := str(sheet[0])
		var path := SOURCE + "enm_anomalia_menor_" + sheet_id + ".png"
		var img := Image.load_from_file(path)
		assert(img != null and not img.is_empty(), path)
		assert(img.has_mipmaps() == false)
		var cols := int(sheet[1])
		var ext_id := str(manifest.sheets.size() + 1)
		ext.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % [path, ext_id])
		var bounds: Array[Rect2i] = []
		for row in range(2):
			var row_y0 := floori(float(row * img.get_height()) / 2)
			var row_y1 := floori(float((row + 1) * img.get_height()) / 2)
			var occupied: Array[bool] = []
			for x in range(img.get_width()):
				var has_pixel := false
				for y in range(row_y0, row_y1):
					if img.get_pixel(x, y).a > 0.01:
						has_pixel = true
						break
				occupied.append(has_pixel)
			var cuts: Array[int] = [0]
			for col in range(1, cols):
				var nominal := roundi(float(col * img.get_width()) / cols)
				var cut := -1
				for distance in range(60):
					for candidate in [nominal - distance, nominal + distance]:
						if not occupied[candidate]:
							cut = candidate
							break
					if cut >= 0:
						break
				assert(cut >= 0, "No transparent separator found")
				var left := cut
				var right := cut
				while left > 0 and not occupied[left - 1]:
					left -= 1
				while right + 1 < img.get_width() and not occupied[right + 1]:
					right += 1
				cuts.append(floori((left + right) / 2.0))
			cuts.append(img.get_width())
			for col in range(cols):
				var x0 := cuts[col]
				var x1 := cuts[col + 1]
				var y0 := floori(float(row * img.get_height()) / 2)
				var y1 := floori(float((row + 1) * img.get_height()) / 2)
				var used := Rect2i()
				var found := false
				for y in range(y0, y1):
					for x in range(x0, x1):
						if img.get_pixel(x, y).a > 0.01:
							if not found:
								used = Rect2i(x, y, 1, 1)
								found = true
							else:
								used = used.merge(Rect2i(x, y, 1, 1))
				assert(found, "Empty cell: " + sheet_id)
				assert(used.size.x < 400 and used.size.y < 320, "Canvas too small")
				if used.position.x <= x0 or used.end.x >= x1:
					push_warning("Cell touches boundary: %s %d,%d" % [sheet_id, row, col])
				bounds.append(used)
		var is_movement: bool = sheet[3] == "movement"
		var actions: Array = MOVEMENT if is_movement else COMBAT
		# Idle/windup1 neutral body provides one scale for all frames of a sheet.
		var neutral := bounds[4 if is_movement else 0]
		var scale_factor := 90.0 / float(neutral.size.x)
		var entries := {}
		var sheet_frames := []
		for index in range(bounds.size()):
			var rect := bounds[index]
			var action: String = actions[index]
			var animation := action + "_" + str(sheet[2])
			if not entries.has(animation):
				entries[animation] = []
			var frame_id := "frame_%02d" % total
			# Common virtual canvas and bottom-center contact point; no pixel resampling.
			var margin_x := 200 - floori(rect.size.x / 2.0)
			var margin_y := 320 - rect.size.y
			lines.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\nregion = Rect2(%d, %d, %d, %d)\nmargin = Rect2(%d, %d, %d, %d)\nfilter_clip = true\n' % [frame_id, ext_id, rect.position.x, rect.position.y, rect.size.x, rect.size.y, margin_x, margin_y, 400 - rect.size.x, 400 - rect.size.y])
			var duration := 1.0
			if action == "windup":
				duration = [2.0, 2.0, 3.0][index]
			elif action == "recover":
				duration = 9.0
			entries[animation].append('{"duration": %s, "texture": SubResource("%s")}' % [str(duration), frame_id])
			sheet_frames.append({"index": index, "action": action, "region": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "duration": duration})
			total += 1
		for animation in entries:
			var looped: bool = animation.begins_with("idle") or animation.begins_with("run")
			animations.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": 12.0}' % [", ".join(entries[animation]), str(looped).to_lower(), animation])
			manifest.animations[animation] = {"scale": scale_factor, "frames": entries[animation].size(), "loop": looped, "fps": 12}
		manifest.sheets.append({"path": path, "size": [img.get_width(), img.get_height()], "cols": cols, "rows": 2, "scale": scale_factor, "frames": sheet_frames})
	var text := '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n%s\n\n%s\n[resource]\nanimations = [%s]\n' % [1 + SHEETS.size() + total, "\n".join(ext), "\n".join(lines), ",\n".join(animations)]
	var file := FileAccess.open(OUTPUT + "anomalia_menor_frames_v01.tres", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	file = FileAccess.open(OUTPUT + "atlas_manifest_v01.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	print("ANOMALIA_ATLAS frames=%d animations=%d sheets=%d" % [total, animations.size(), SHEETS.size()])
	quit(0)
