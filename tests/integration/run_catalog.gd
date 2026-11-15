extends SceneTree
## File-level schema regressions for the playable subset; never mutates gameplay.json.
const Catalog = preload("res://src/foundation/session_catalog.gd")
const FIXTURE_PATH := "res://production/qa/evidence/integracao-jogavel/catalog-fixture.json"
var checks := 0
var failed := 0
var baseline: Dictionary

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(label)

func _reject(candidate: Dictionary, label: String) -> void:
	_write(JSON.stringify(candidate))
	var catalog := Catalog.new()
	check(not catalog.load_file(FIXTURE_PATH) and catalog.data.is_empty() and catalog.fingerprint.is_empty() and not catalog.errors.is_empty(),label)

func _write(text: String) -> void:
	var file := FileAccess.open(FIXTURE_PATH,FileAccess.WRITE)
	file.store_string(text)
	file.close()

## Runs missing-field, corrupt-file and cross-field regressions through load_file.
func run() -> void:
	var catalog := Catalog.new()
	check(catalog.load_file("res://data/integration/gameplay.json"),"shipped catalog accepted")
	if catalog.data.is_empty():
		print(catalog.errors)
		quit(1)
		return
	baseline = catalog.data.duplicate(true)
	check(catalog.fingerprint.length()==64,"fingerprint recorded")
	for path in ["camera.half_life","camera.mouse_radius","camera.impulse_half_life","camera.max_impulses","input.buffer_steps","corte.recarga_s","investida.duracao_s","combate.flash_acerto_s","ia.surgimento_s","elite.raio_x"]:
		var item := baseline.duplicate(true)
		var parts: PackedStringArray = path.split(".")
		item[parts[0]].erase(parts[1])
		_reject(item,"missing "+path)
	for field in ["wave_transition_s","schema_version"]:
		var item := baseline.duplicate(true)
		item[field] = 0
		_reject(item,"invalid "+field)
	var mutations: Array[Dictionary] = [
		{"path":["corte","combo"],"value":[],"label":"empty combo"},
		{"path":["corte","combo"],"value":[1,"bad"],"label":"non-numeric combo"},
		{"path":["bencaos"],"value":[baseline.bencaos[0]],"label":"missing cards"},
		{"path":["bencaos",0,"id"],"value":"carga_mais","label":"wrong blessing order"},
		{"path":["bencaos",0,"texto"],"value":10,"label":"invalid card text"},
		{"path":["bencaos",1,"valor"],"value":1.5,"label":"fractional charges"},
		{"path":["ondas",0,0,"id"],"value":"missing","label":"unknown enemy"},
		{"path":["ondas",0,0,"x"],"value":"bad","label":"invalid spawn coordinate"},
		{"path":["ondas",0,0,"elite"],"value":1,"label":"elite type"},
		{"path":["ondas",1],"value":[],"label":"empty wave"},
		{"path":["inimigos","eco_perdido","comportamento"],"value":"ranged","label":"renderer behavior mismatch"},
		{"path":["inimigos","anomalia_menor","proj_vida_passos"],"value":0,"label":"zero projectile lifetime"},
		{"path":["arena","pilares",0,"r"],"value":-1,"label":"negative obstacle radius"},
		{"path":["arena","pilares"],"value":["bad"],"label":"invalid obstacle object"},
		{"path":["jogador","spawn"],"value":[5,5],"label":"spawn outside inset"},
		{"path":["jogador","spawn"],"value":[baseline.arena.pilares[0].x,baseline.arena.pilares[0].y],"label":"spawn inside obstacle"},
		{"path":["input","deadzone"],"value":0.99,"label":"deadzone denominator"},
		{"path":["input","trigger_release"],"value":baseline.input.trigger_press,"label":"trigger hysteresis"},
		{"path":["camera","half_life"],"value":0,"label":"zero smoothing denominator"},
		{"path":["camera","impulse_cutoff"],"value":0,"label":"unbounded impulse lifetime"},
		{"path":["ia","ranged_perto_px"],"value":2000,"label":"ranged order"}
	]
	for mutation in mutations:
		var item := baseline.duplicate(true)
		var target: Variant = item
		for i in range(mutation.path.size()-1): target = target[mutation.path[i]]
		target[mutation.path[-1]] = mutation.value
		_reject(item,mutation.label)
	_write("{\"wave_transition_s\":1e999}")
	check(not catalog.load_file(FIXTURE_PATH) and catalog.data.is_empty() and catalog.fingerprint.is_empty(),"non-finite input clears previous success")
	_write("{broken json")
	check(not catalog.load_file(FIXTURE_PATH),"malformed JSON")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH))
	check(not catalog.load_file(FIXTURE_PATH),"missing file")
	print("CATALOG RESULT checks=",checks," failures=",failed)
	quit(0 if failed==0 else 1)
