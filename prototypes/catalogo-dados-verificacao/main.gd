extends SceneTree

const Fixture = preload("res://fixture.gd")
var failures: int = 0


func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		push_error("FAIL " + label)
		failures += 1


func _initialize() -> void:
	var folder := OS.get_environment("TEMP").replace("\\", "/").path_join("khaeros-catalog-probe-" + str(OS.get_process_id()))
	check(DirAccess.make_dir_recursive_absolute(folder) == OK, "create isolated fixture directory")
	var child_path := folder.path_join("child.tres")
	var root_path := folder.path_join("root.tres")
	var child := Fixture.new()
	child.value = 10.0
	check(ResourceSaver.save(child, child_path) == OK, "save external child")
	var root := Fixture.new()
	root.child = ResourceLoader.load(child_path)
	check(ResourceSaver.save(root, root_path) == OK, "save parent with external child")
	var original := ResourceLoader.load(root_path)
	if original == null:
		push_error("Fixture failed to load")
		quit(1)
		return
	check(original.child.value == 10.0, "load original child")

	var default_copy := original.duplicate_deep()
	var full_copy := original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	check(default_copy != original, "default duplicate creates parent")
	check(default_copy.child == original.child, "default duplicate retains external child")
	check(full_copy.child != original.child, "ALL duplicates external child")
	full_copy.child.value = 99.0
	check(original.child.value == 10.0, "ALL mutation leaves catalog unchanged")

	var replacement := Fixture.new()
	replacement.value = 20.0
	check(ResourceSaver.save(replacement, child_path) == OK, "replace child file")
	var cached := ResourceLoader.load(root_path)
	check(cached == original and cached.child.value == 10.0, "REUSE returns old cached value")
	var refreshed := ResourceLoader.load(root_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(refreshed != original and refreshed.child != original.child, "IGNORE_DEEP isolates external dependency")
	check(refreshed.child.value == 20.0, "IGNORE_DEEP reads changed external file")
	check(original.child.value == 10.0, "IGNORE_DEEP preserves old instance")

	var hashing := HashingContext.new()
	check(hashing.start(HashingContext.HASH_SHA256) == OK, "SHA256 initializes")
	check(hashing.update("abc".to_utf8_buffer()) == OK, "SHA256 accepts UTF8 bytes")
	check(hashing.finish().hex_encode() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA256 abc vector")
	print("Fixture directory: ", folder)
	print("Failures: ", failures)
	quit(0 if failures == 0 else 1)
