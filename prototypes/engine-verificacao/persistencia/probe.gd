# PROTOTYPE - NOT FOR PRODUCTION (engine-verificacao)
extends SceneTree
## EX-0013-P1..P5 (headless) e modos de queda para P1/P2. Saída "EX|".
const RAIZ: String = "user://experimentos"

func _initialize() -> void:
	var modo: String = "tudo"
	var k: int = 0
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--modo="): modo = a.substr(7)
		if a.begins_with("--k="): k = int(a.substr(4))
	DirAccess.make_dir_recursive_absolute(RAIZ)
	match modo:
		"tudo":
			print("EX|versao=%s debug=%s user=%s" % [Engine.get_version_info().string, OS.is_debug_build(), ProjectSettings.globalize_path(RAIZ)])
			_p1_custo(300); _p1_custo(2048); _p1_erro(); _p2_rename(); _p3(); _p4(); _p5()
		"kill_p1": _kill_p1(true)
		"kill_p1_sem_flush": _kill_p1(false)
		"contar": _contar()
		"kill_p2": _kill_p2(k)
		"inspecionar": _inspecionar()
		"limpar": _limpar()
	quit()

func _linha(tam: int, i: int) -> String:
	var base: String = "{\"ev\":\"golpe\",\"i\":%d,\"pad\":\"" % i
	return base + "x".repeat(tam - base.length() - 2) + "\"}"

func _p1_custo(tam: int) -> void:
	var f := FileAccess.open(RAIZ + "/p1_%d.jsonl" % tam, FileAccess.WRITE)
	var n: int = 10000
	var t := PackedInt64Array(); t.resize(n)
	var falhas: int = 0
	for i in n:
		var l: String = _linha(tam, i)
		var t0: int = Time.get_ticks_usec()
		if not f.store_line(l): falhas += 1
		f.flush()
		t[i] = Time.get_ticks_usec() - t0
	f.close()
	var pior5: int = 0
	for i in n - 4:
		pior5 = maxi(pior5, t[i] + t[i + 1] + t[i + 2] + t[i + 3] + t[i + 4])
	var s: PackedInt64Array = t.duplicate(); s.sort()
	var soma: int = 0
	for x in s: soma += x
	print("EX|P1 linha=%dB n=%d media_us=%.1f p50=%d p99=%d max=%d pior_5_seguidas_us=%d falhas=%d tamanho_arquivo=%d" % [tam, n, float(soma) / n, s[n / 2], s[int(n * 0.99)], s[n - 1], pior5, falhas, FileAccess.get_size(RAIZ + "/p1_%d.jsonl" % tam)])

func _p1_erro() -> void:
	var p: String = RAIZ + "/p1_ro.txt"
	var f := FileAccess.open(p, FileAccess.WRITE); f.store_line("x"); f.close()
	var r := FileAccess.open(p, FileAccess.READ)
	var ok: bool = r.store_line("nao deveria")
	print("EX|P1 erro store_line em handle READ: retorno=%s get_error=%d" % [ok, r.get_error()])
	r.close()
	FileAccess.set_read_only_attribute(p, true)
	var w := FileAccess.open(p, FileAccess.WRITE)
	print("EX|P1 erro open WRITE em arquivo somente-leitura: handle_null=%s open_error=%d" % [w == null, FileAccess.get_open_error()])
	FileAccess.set_read_only_attribute(p, false)

func _escreve(p: String, t: String) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE); f.store_string(t); f.close()

func _p2_rename() -> void:
	var d := DirAccess.open(RAIZ)
	_escreve(RAIZ + "/a.tmp", "NOVO"); _escreve(RAIZ + "/a.cfg", "VELHO")
	var e1: int = d.rename("a.tmp", "a.cfg")
	print("EX|P2 rename sobre destino existente: err=%d destino=%s tmp_existe=%s" % [e1, FileAccess.get_file_as_string(RAIZ + "/a.cfg"), FileAccess.file_exists(RAIZ + "/a.tmp")])
	_escreve(RAIZ + "/b.tmp", "NOVO"); _escreve(RAIZ + "/b.cfg", "VELHO")
	var aberto := FileAccess.open(RAIZ + "/b.cfg", FileAccess.READ)
	var e2: int = d.rename("b.tmp", "b.cfg")
	aberto.close()
	print("EX|P2 rename sobre destino ABERTO (READ): err=%d destino=%s tmp_existe=%s" % [e2, FileAccess.get_file_as_string(RAIZ + "/b.cfg"), FileAccess.file_exists(RAIZ + "/b.tmp")])
	_escreve(RAIZ + "/c.tmp", "NOVO"); _escreve(RAIZ + "/c.cfg", "VELHO")
	var aberto_tmp := FileAccess.open(RAIZ + "/c.tmp", FileAccess.READ)
	var e3: int = d.rename("c.tmp", "c.cfg")
	aberto_tmp.close()
	print("EX|P2 rename com ORIGEM aberta (READ): err=%d destino=%s" % [e3, FileAccess.get_file_as_string(RAIZ + "/c.cfg")])

func _p3() -> void:
	var c := ConfigFile.new()
	c.set_value("s", "grande", 4294967296123)
	c.set_value("s", "neg", -9007199254740993)
	c.set_value("s", "sn", &"acao_golpe")
	c.set_value("s", "arr", [1, "dois", 3.5, [4]])
	c.set_value("s", "f", 0.1)
	c.set_value("s", "txt", "ação \"aspas\" = ; # [x]")
	var t: String = c.encode_to_text()
	print("EX|P3 texto=%s" % t.c_escape())
	var c2 := ConfigFile.new()
	var e: int = c2.parse(t)
	var res: PackedStringArray = []
	for k: String in ["grande", "neg", "sn", "arr", "f", "txt"]:
		var v0: Variant = c.get_value("s", k)
		var v1: Variant = c2.get_value("s", k)
		res.append("%s:%s(%s->%s)" % [k, "OK" if typeof(v0) == typeof(v1) and v0 == v1 else "DIFERE", type_string(typeof(v0)), type_string(typeof(v1))])
	print("EX|P3 parse err=%d ida_e_volta %s" % [e, " ".join(res)])
	var lixo := PackedByteArray()
	for i in 256: lixo.append((i * 37 + 11) % 256)
	var c3 := ConfigFile.new()
	var e3: int = c3.parse(lixo.get_string_from_ascii())
	var c4 := ConfigFile.new()
	var e4: int = c4.parse("[s]\nchave=1\nquebrado=[1, 2\n")
	var c5 := ConfigFile.new()
	var e5: int = c5.parse("[s]\nchave=Object(Node)\n")
	print("EX|P3 lixo_binario err=%d secoes=%s | array_truncado err=%d secoes=%s | Object() err=%d" % [e3, c3.get_sections(), e4, c4.get_sections(), e5])

func _p4() -> void:
	print("EX|P4 %s" % JSON.stringify({"i": 1, "f": 1.0, "f2": 0.1, "big": 9007199254740993, "n": null, "s": "ação ç ã é", "b": true, "arr": [1, 2.5]}))
	var back: Variant = JSON.parse_string("{\"i\":1}")
	print("EX|P4 parse de volta {i:1} -> tipo=%s" % type_string(typeof(back["i"])))

func _p5() -> void:
	print("EX|P5 get_datetime_string_from_system(true)=%s unix=%.3f" % [Time.get_datetime_string_from_system(true), Time.get_unix_time_from_system()])
	var passos_us: PackedInt64Array = []
	var ultimo: int = Time.get_ticks_usec()
	while passos_us.size() < 20:
		var a: int = Time.get_ticks_usec()
		if a != ultimo:
			passos_us.append(a - ultimo)
			ultimo = a
	print("EX|P5 ticks_msec=%d ticks_usec=%d incrementos_us=%s" % [Time.get_ticks_msec(), Time.get_ticks_usec(), str(passos_us)])

func _kill_p1(com_flush: bool) -> void:
	var f := FileAccess.open(RAIZ + "/kill_p1.jsonl", FileAccess.WRITE)
	for i in 1000:
		f.store_line(_linha(300, i))
		if com_flush: f.flush()
	print("EX|P1 kill: 1000 linhas escritas flush=%s; OS.kill no proprio processo sem close" % com_flush)
	OS.kill(OS.get_process_id())

func _contar() -> void:
	var t: String = FileAccess.get_file_as_string(RAIZ + "/kill_p1.jsonl")
	print("EX|P1 linhas sobreviventes=%d bytes=%d" % [t.count("\n"), t.length()])

func _kill_p2(k: int) -> void:
	for n: String in ["p.cfg", "p.cfg.tmp", "p.cfg.old"]:
		DirAccess.remove_absolute(RAIZ + "/" + n)
	_escreve(RAIZ + "/p.cfg", "VELHO")
	var d := DirAccess.open(RAIZ)
	_escreve(RAIZ + "/p.cfg.tmp", "NOVO")
	if k == 1: OS.kill(OS.get_process_id())
	d.rename("p.cfg", "p.cfg.old")
	if k == 2: OS.kill(OS.get_process_id())
	d.rename("p.cfg.tmp", "p.cfg")
	if k == 3: OS.kill(OS.get_process_id())
	d.remove("p.cfg.old")

func _inspecionar() -> void:
	var r: PackedStringArray = []
	for n: String in ["p.cfg", "p.cfg.tmp", "p.cfg.old"]:
		var p: String = RAIZ + "/" + n
		r.append("%s=%s" % [n, FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else "-"])
	print("EX|P2 disco: %s" % " ".join(r))

func _limpar() -> void:
	for n: String in DirAccess.get_files_at(RAIZ): DirAccess.remove_absolute(RAIZ + "/" + n)
	DirAccess.remove_absolute(RAIZ)
	print("EX|limpo existe=%s" % DirAccess.dir_exists_absolute(RAIZ))
