# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends SceneTree
## EX-0004-NV: hash canônico mínimo, CACHE_MODE_IGNORE_DEEP, CSV keep, DEEP_DUPLICATE_ALL, tempo de carga.
const N_DEFS: int = 40
const DefScript: Script = preload("res://def.gd")

func _initialize() -> void:
	var modo: String = "tudo"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			modo = a.substr(7)
	print("EX|modo=%s versao=%s debug=%s ds=%s" % [modo, Engine.get_version_info().string, OS.is_debug_build(), DisplayServer.get_name()])
	match modo:
		"gerar": _gerar()
		"carga": _carga()
		"hash":
			_hash()
			_dup_const()
			_csv()
		"tudo":
			_hash()
			_dup_const()
			_cache()
			_csv()
	quit()

func _hash() -> void:
	var b := PackedByteArray()
	b.resize(16)
	b.encode_s64(0, -1234567890123)
	b.encode_double(8, 0.1)
	b.append_array("Khaeros ação vínculo".to_utf8_buffer())
	var h := HashingContext.new()
	var e: int = h.start(HashingContext.HASH_SHA256)
	h.update(b)
	print("EX|hash bytes=%s" % b.hex_encode())
	print("EX|hash sha256=%s start_err=%d" % [h.finish().hex_encode(), e])

func _dup_const() -> void:
	var consts: PackedStringArray = ClassDB.class_get_enum_constants("Resource", "DeepDuplicateMode", true)
	var vals: PackedStringArray = []
	for c: String in consts:
		vals.append("%s=%d" % [c, ClassDB.class_get_integer_constant("Resource", c)])
	print("EX|dup enum Resource.DeepDuplicateMode=%s" % ", ".join(vals))
	print("EX|dup has duplicate_deep=%s" % ClassDB.class_has_method("Resource", "duplicate_deep"))
	var filho: Resource = DefScript.new()
	filho.valor = 7
	var pai: Resource = DefScript.new()
	pai.filho = filho
	var c1: Resource = pai.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	c1.filho.valor = 99
	print("EX|dup DEEP_DUPLICATE_ALL filho_copiado=%s original=%d (sem caminho)" % [c1.filho != filho, filho.valor])
	var filho_ext: Resource = load("res://gerado/filho_00.tres")
	var pai_ext: Resource = load("res://gerado/def_00.tres")
	var c2: Resource = pai_ext.duplicate_deep()
	var c3: Resource = pai_ext.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	print("EX|dup externo: padrao_copia_filho=%s ALL_copia_filho=%s" % [c2.filho != pai_ext.filho, c3.filho != pai_ext.filho])

func _cache() -> void:
	var antes: Array[Resource] = []
	for i in N_DEFS:
		antes.append(load("res://gerado/def_%02d.tres" % i))
	var v0: int = antes[3].filho.valor
	# Edita no disco o filho externo e o pai, como um editor de texto faria.
	var p_filho: String = "res://gerado/filho_03.tres"
	var txt_filho: String = FileAccess.get_file_as_string(p_filho)
	var f := FileAccess.open(p_filho, FileAccess.WRITE)
	f.store_string(txt_filho.replace("valor = %d" % v0, "valor = 4242"))
	f.close()
	var p_pai: String = "res://gerado/def_03.tres"
	var txt_pai: String = FileAccess.get_file_as_string(p_pai)
	f = FileAccess.open(p_pai, FileAccess.WRITE)
	f.store_string(txt_pai.replace("valor = 3\n", "valor = 3003\n"))
	f.close()
	var padrao: Resource = ResourceLoader.load(p_pai)
	var deep: Resource = ResourceLoader.load(p_pai, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	print("EX|cache manifesto=%d entradas; antes pai.valor=%d filho.valor=%d" % [N_DEFS, antes[3].valor, v0])
	print("EX|cache CACHE_MODE_REUSE: pai.valor=%d filho.valor=%d mesma_instancia=%s" % [padrao.valor, padrao.filho.valor, padrao == antes[3]])
	print("EX|cache CACHE_MODE_IGNORE_DEEP: pai.valor=%d filho.valor=%d nova_instancia=%s antigo_intacto=%s" % [deep.valor, deep.filho.valor, deep != antes[3], antes[3].filho.valor == v0])
	var n_ok: int = 0
	for i in N_DEFS:
		var r: Resource = ResourceLoader.load("res://gerado/def_%02d.tres" % i, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if r != null and r.filho != null:
			n_ok += 1
	print("EX|cache recarga IGNORE_DEEP do manifesto inteiro ok=%d/%d" % [n_ok, N_DEFS])
	# Restaura os arquivos.
	f = FileAccess.open(p_filho, FileAccess.WRITE); f.store_string(txt_filho); f.close()
	f = FileAccess.open(p_pai, FileAccess.WRITE); f.store_string(txt_pai); f.close()

func _csv() -> void:
	var t: String = FileAccess.get_file_as_string("res://assets/data/canon/teste.csv")
	print("EX|csv leitura FileAccess bytes=%d err=%d conteudo=%s" % [t.to_utf8_buffer().size(), FileAccess.get_open_error(), t.c_escape()])
	var tr: PackedStringArray = []
	for nome: String in DirAccess.get_files_at("res://assets/data/canon"):
		tr.append(nome)
	print("EX|csv arquivos em canon=%s" % ", ".join(tr))

func _gerar() -> void:
	DirAccess.make_dir_recursive_absolute("res://gerado")
	for i in N_DEFS:
		var filho: Resource = DefScript.new()
		filho.id = "filho_%02d" % i
		filho.valor = 100 + i
		ResourceSaver.save(filho, "res://gerado/filho_%02d.tres" % i)
		var pai: Resource = DefScript.new()
		pai.id = "def_%02d" % i
		pai.valor = i
		var pesos := PackedFloat64Array()
		for k in 64:
			pesos.append(float(k) * 0.5)
		pai.pesos = pesos
		pai.filho = load("res://gerado/filho_%02d.tres" % i)
		ResourceSaver.save(pai, "res://gerado/def_%02d.tres" % i)
	print("EX|gerar %d pais + %d filhos externos" % [N_DEFS, N_DEFS])

func _carga() -> void:
	var t0: int = Time.get_ticks_usec()
	var n: int = 0
	for i in N_DEFS:
		var r: Resource = ResourceLoader.load("res://gerado/def_%02d.tres" % i)
		if r != null:
			n += 1
	print("EX|carga fria %d .tres (+%d filhos) ms=%.3f" % [n, n, (Time.get_ticks_usec() - t0) / 1000.0])
