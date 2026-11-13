# PROTOTYPE - NOT FOR PRODUCTION
# Question: o combate de uma camara (Lamina, telegrafo, esquiva) e legivel e justo em Godot a 60 passos/s?
# Date: 2026-11-12
extends Node2D

const EVID_DIR: String = "res://production/qa/evidence/"
const TUNING_PATH: String = "res://prototypes/combate-camara-concept/data/tuning.json"

var T: Dictionary = {}
var rng := RandomNumberGenerator.new()
var bot_rng := RandomNumberGenerator.new()
var is_bot: bool = false
var batch_n: int = 0
var profile_name: String = "reativo"
var profile: Dictionary = {}
var seed_base: int = 1
var tag: String = "run"
var forced_bless: int = -1

var state: String = "play"
var step_n: int = 0
var hitstop: int = 0
var hit_req: int = 0
var P: Dictionary = {}
var enemies: Array = []
var projs: Array = []
var swings: Array = []
var buf: Dictionary = {"dash": 0, "atk": 0, "spec": 0}
var bless: Dictionary = {"ataque_mais": false, "carga_mais": false, "corte_esquiva": false}
var bless_timer: int = 0
var wave_idx: int = 0
var M: Dictionary = {}
var shot_done: Dictionary = {}
var shot_queue: Array = []
var capturing: bool = false
var dash_prev: bool = false
var spec_prev: bool = false
var ended: bool = false
var rec_lines: PackedStringArray = PackedStringArray()


func st(sec: float) -> int:
	return maxi(1, roundi(sec * 60.0))


func _ready() -> void:
	var f := FileAccess.open(TUNING_PATH, FileAccess.READ)
	T = JSON.parse_string(f.get_as_text())
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a in args:
		if a == "--bot":
			is_bot = true
		elif a == "--teste":
			batch_n = -1
			is_bot = true
		elif a.begins_with("--batch="):
			batch_n = int(a.substr(8))
			is_bot = true
		elif a.begins_with("--bencao="):
			forced_bless = int(a.substr(9))
		elif a.begins_with("--profile="):
			profile_name = a.substr(10)
		elif a.begins_with("--seed="):
			seed_base = int(a.substr(7))
		elif a.begins_with("--tag="):
			tag = a.substr(6)
	profile = T.bot.perfis[profile_name]
	var w: Window = get_window()
	w.content_scale_size = Vector2i(1920, 1080)
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVID_DIR))
	if forced_bless >= 0:
		apply_bless(forced_bless)
	if batch_n == -1:
		run_tests()
		get_tree().quit()
		return
	if batch_n > 0:
		run_batch()
		get_tree().quit()
		return
	reset_chamber(seed_base)


# ---------------------------------------------------------------- setup

func reset_chamber(seed_value: int) -> void:
	rng.seed = seed_value
	bot_rng.seed = seed_value * 7919 + 13
	state = "play"
	step_n = 0
	hitstop = 0
	hit_req = 0
	enemies.clear()
	projs.clear()
	swings.clear()
	buf = {"dash": 0, "atk": 0, "spec": 0}
	bless_timer = 0
	ended = false
	var sp: Array = T.jogador.spawn
	var cmax: int = int(T.esquiva.cargas_base) + (1 if bless.carga_mais else 0)
	P = {
		"pos": Vector2(sp[0], sp[1]), "hp": float(T.jogador.vida_max), "inv": 0,
		"facing": Vector2.UP, "charges": cmax, "cmax": cmax, "rec_p": 0,
		"dash_steps": 0, "dash_dir": Vector2.UP, "dash_hit": [],
		"atk_cd": 0, "spec_cd": 0, "combo_idx": 0, "combo_win": 0, "rec": 0,
		"lunge_steps": 0, "lunge_dir": Vector2.UP, "lunge_hit": [], "flash": 0,
	}
	wave_idx = 0
	spawn_wave()
	M = {
		"hits_taken": 0, "dmg_taken": 0.0, "dodged_fires": 0, "dashes": 0, "attacks": 0,
		"specials": 0, "kills": 0, "dmg_dealt": 0.0, "breaks": 0, "proj_hits": 0, "melee_hits": 0,
		"fires_melee": 0, "fires_ranged": 0, "min_tele_age_on_hit": 9999,
		"kill_log": [], "corte_log": [], "hitstop_total": 0, "clear_step": -1, "result": "em_curso",
	}


func spawn_wave() -> void:
	for w in T.ondas[wave_idx]:
		enemies.append(make_enemy(w.id, Vector2(w.x, w.y), bool(w.get("elite", false))))


func make_enemy(id: String, pos: Vector2, elite: bool) -> Dictionary:
	var d: Dictionary = (T.inimigos[id] as Dictionary).duplicate()
	var hp: float = float(d.vida) * (1.0 + float(T.elite.vida_por_profundidade) * float(T.profundidade))
	var kbf: float = 1.0
	if elite:
		hp = roundf(hp * float(T.elite.vida_x))
		d.dano = float(d.dano) * float(T.elite.dano_x)
		d.raio = float(d.raio) * float(T.elite.raio_x)
		kbf = float(T.elite.empurrao_x)
	return {
		"id": id, "def": d, "pos": pos, "hp": hp, "maxhp": hp, "elite": elite, "kbf": kbf, "phase": "surgindo",
		"timer": st(T.ia.surgimento_s), "kb": Vector2.ZERO, "stagger": 0, "flash": 0,
		"tele": {}, "tele_flash": 0, "crack": 0, "alive": true, "hits": 0,
		"orbit": 1.0 if rng.randf() < 0.5 else -1.0,
	}


# ---------------------------------------------------------------- loop

func _physics_process(_delta: float) -> void:
	if batch_n > 0 or ended:
		return
	if state == "play":
		var inp: Dictionary = bot_input() if is_bot else human_input()
		step(inp)
	elif state == "bless":
		bless_timer += 1
		if is_bot:
			if bless_timer == 40:
				shot("06-tela-bencao")
			if bless_timer >= int(T.bot.espera_bencao_passos):
				apply_bless(0)
				finish_bot_run("bencao_escolhida")
	elif state == "dead":
		bless_timer += 1
		if is_bot and bless_timer > 30:
			finish_bot_run("morte")


func _process(_delta: float) -> void:
	queue_redraw()
	if shot_queue.size() > 0 and not capturing:
		do_shots()


func idle_inp() -> Dictionary:
	return {"move": Vector2.ZERO, "aim": Vector2.DOWN, "atk": false, "spec": false, "dash": false, "dash_dir": Vector2.RIGHT}


func run_tests() -> void:
	var out: PackedStringArray = PackedStringArray()
	T.profundidade = 0
	# T1: janela de esquiva contra o disparo do Eco (jogador parado dentro do setor)
	var window_ok: Array = []
	var row: String = ""
	for k in range(0, 27):
		reset_chamber(5)
		enemies.clear()
		var e: Dictionary = make_enemy("eco_perdido", Vector2(960, 830), false)
		enemies.append(e)
		P.pos = Vector2(960, 900)
		start_prep(e, Vector2.DOWN)
		var total: int = int(e.tele.total)
		var hp0: float = P.hp
		for s in range(60):
			var inp: Dictionary = idle_inp()
			if e.phase == "preparo" and int(e.tele.rem) == k:
				inp.dash = true
			step(inp)
		var hit: bool = P.hp < hp0
		if not hit:
			window_ok.append(k)
		row += "%d:%s " % [k, "acerta" if hit else "livra"]
	out.append("T1 preparo_total=%d passos; esquiva com 'rem' (passos que faltam para o disparo) = k; (livra/acerta): %s" % [int(T.inimigos.eco_perdido.preparo_s * 60.0 + 0.5), row])
	out.append("T1 janela que livra: rem de %d a %d (%d valores) = %.3f s" % [window_ok.min(), window_ok.max(), window_ok.size(), window_ok.size() / 60.0])
	# T1b: so a invulnerabilidade (jogador na parede, esquiva para a parede nao sai do setor)
	var inv_ok: Array = []
	var row2: String = ""
	for k in range(0, 27):
		reset_chamber(5)
		enemies.clear()
		var eb: Dictionary = make_enemy("eco_perdido", Vector2(960, 923), false)
		enemies.append(eb)
		P.pos = Vector2(960, 993)
		start_prep(eb, Vector2.DOWN)
		var hpb: float = P.hp
		for s in range(60):
			var inpb: Dictionary = idle_inp()
			inpb.dash_dir = Vector2.DOWN
			if eb.phase == "preparo" and int(eb.tele.rem) == k:
				inpb.dash = true
			step(inpb)
		var hitb: bool = P.hp < hpb
		if not hitb:
			inv_ok.append(k)
		row2 += "%d:%s " % [k, "acerta" if hitb else "livra"]
	out.append("T1b so invulnerabilidade (esquiva presa na parede, continua dentro do setor): %s" % row2)
	out.append("T1b janela de invulnerabilidade contra o disparo: rem de %d a %d (%d valores) = %.3f s" % [inv_ok.min(), inv_ok.max(), inv_ok.size(), inv_ok.size() / 60.0])
	# T2: combo do Corte contra um Eco parado
	reset_chamber(5)
	enemies.clear()
	var e2: Dictionary = make_enemy("eco_perdido", Vector2(960, 800), false)
	e2.phase = "recuperacao"
	e2.timer = 100000
	enemies.append(e2)
	P.pos = Vector2(960, 900)
	var first_hit: int = -1
	for s in range(80):
		var inp2: Dictionary = idle_inp()
		inp2.aim = Vector2.UP
		inp2.move = Vector2.UP
		inp2.atk = true
		step(inp2)
		if M.corte_log.size() > 0 and first_hit < 0:
			first_hit = step_n
		if not e2.alive:
			break
	var seq: PackedStringArray = PackedStringArray()
	for h in M.corte_log:
		seq.append("%.1f" % float(h.dano))
	out.append("T2 Eco (vida 30) sequencia de dano do Corte: [%s]; morto=%s no passo %d (primeiro golpe no passo %d); passos congelados (hitstop, contando o pendente do abate)=%d" % [", ".join(seq), str(not e2.alive), step_n, first_hit, int(M.hitstop_total) + hitstop])
	# T3: invuln apos ser atingido e teto de dano
	reset_chamber(5)
	enemies.clear()
	var e3: Dictionary = make_enemy("eco_perdido", Vector2(960, 830), false)
	enemies.append(e3)
	P.pos = Vector2(960, 900)
	start_prep(e3, Vector2.DOWN)
	var fire_steps: Array = []
	var last_fires: int = 0
	for s in range(300):
		step(idle_inp())
		if int(M.fires_melee) != last_fires:
			last_fires = int(M.fires_melee)
			fire_steps.append(step_n)
	out.append("T3 Eco ataca jogador parado por 300 passos: disparos nos passos %s, golpes recebidos=%d, vida=%.0f (invuln_atingido=%d passos)" % [str(fire_steps), int(M.hits_taken), float(P.hp), st(T.combate.invuln_atingido_s)])
	# T4: esquiva deve atravessar projetil
	# T5: bencaos "Corte da esquiva" e "+1 carga"
	bless.corte_esquiva = true
	bless.carga_mais = true
	reset_chamber(5)
	enemies.clear()
	var e5: Dictionary = make_enemy("eco_perdido", Vector2(960, 800), false)
	e5.phase = "recuperacao"
	e5.timer = 100000
	enemies.append(e5)
	P.pos = Vector2(960, 900)
	var charges0: int = int(P.charges)
	var hp5: float = e5.hp
	for s in range(14):
		var inp5: Dictionary = idle_inp()
		inp5.dash_dir = Vector2.UP
		inp5.dash = (s == 0 or s == 1)
		step(inp5)
	out.append("T5 cargas no inicio=%d (com +1 carga); dois toques de esquiva seguidos: esquivas feitas=%d; Corte da esquiva tirou %.1f de vida do Eco (vida %.0f -> %.0f)" % [charges0, int(M.dashes), hp5 - float(e5.hp), hp5, float(e5.hp)])
	bless.corte_esquiva = false
	bless.carga_mais = false
	out.append("T4 duracao dash D=%d passos, d_passo=%.1f px, dist_total=%.1f px, inv=%d passos, recarga R=%d passos" % [st(T.esquiva.duracao_s), float(T.esquiva.velocidade_pxs) / 60.0, st(T.esquiva.duracao_s) * float(T.esquiva.velocidade_pxs) / 60.0, st(T.esquiva.duracao_s) + st(T.esquiva.invuln_extra_s), st(T.esquiva.recarga_s)])
	for l in out:
		print(l)
	var fa := FileAccess.open(EVID_DIR + "combate-camara-testes.txt", FileAccess.WRITE)
	fa.store_string("
".join(out) + "
")


func run_batch() -> void:
	var out: PackedStringArray = PackedStringArray()
	var agg_hp: float = 0.0
	var agg_clear: int = 0
	var wins: int = 0
	var tot_hits: int = 0
	var tot_dodged: int = 0
	var tot_dashes: int = 0
	var tot_steps: int = 0
	var min_age: int = 9999
	for i in range(batch_n):
		reset_chamber(seed_base + i)
		var guard: int = 0
		while state == "play" and guard < int(T.bot.limite_passos):
			step(bot_input())
			guard += 1
		var lost: float = float(T.jogador.vida_max) - float(P.hp)
		var res: String = "limite"
		if state == "bless":
			res = "limpou"
			wins += 1
			agg_clear += step_n
		elif state == "dead":
			res = "morreu"
		agg_hp += lost
		tot_hits += int(M.hits_taken)
		tot_dodged += int(M.dodged_fires)
		tot_dashes += int(M.dashes)
		tot_steps += step_n
		min_age = mini(min_age, int(M.min_tele_age_on_hit))
		out.append("seed=%d res=%s passos=%d vida_perdida=%.0f golpes=%d esquivadas_no_disparo=%d esquivas=%d quebras=%d kills=%d disparos_melee=%d disparos_faixa=%d" % [seed_base + i, res, step_n, lost, M.hits_taken, M.dodged_fires, M.dashes, M.breaks, M.kills, M.fires_melee, M.fires_ranged])
	out.append("--- perfil=%s n=%d limpou=%d/%d vida_perdida_media=%.1f (%.0f%%) passos_medios_limpando=%.0f golpes_medios=%.2f esquivadas_no_disparo_media=%.2f esquivas_media=%.1f idade_min_telegrafo_no_golpe=%d" % [profile_name, batch_n, wins, batch_n, agg_hp / batch_n, agg_hp / batch_n, (float(agg_clear) / maxf(1.0, float(wins))), float(tot_hits) / batch_n, float(tot_dodged) / batch_n, float(tot_dashes) / batch_n, min_age])
	for l in out:
		print(l)
	var fa := FileAccess.open(EVID_DIR + "combate-camara-batch-%s.txt" % tag, FileAccess.WRITE)
	fa.store_string("\n".join(out) + "\n")


func finish_bot_run(reason: String) -> void:
	ended = true
	M.result = reason
	var fa := FileAccess.open(EVID_DIR + "combate-camara-bot-%s.json" % tag, FileAccess.WRITE)
	fa.store_string(JSON.stringify({"perfil": profile_name, "seed": seed_base, "passos": step_n, "vida_final": P.hp, "metricas": M}, "  "))
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


# ---------------------------------------------------------------- input

func human_input() -> Dictionary:
	var mv := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): mv.x += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): mv.x -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): mv.y += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): mv.y -= 1.0
	mv = mv.normalized()
	var aim: Vector2 = get_global_mouse_position() - (P.pos as Vector2)
	aim = aim.normalized() if aim.length() > 1.0 else (P.facing as Vector2)
	var dash_now: bool = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_L)
	var spec_now: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_K)
	var inp: Dictionary = {
		"move": mv, "aim": aim,
		"atk": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_J),
		"spec": spec_now and not spec_prev, "dash": dash_now and not dash_prev,
		"dash_dir": mv if mv.length() > 0.1 else aim,
	}
	dash_prev = dash_now
	spec_prev = spec_now
	return inp


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.physical_keycode == KEY_F12:
			shot_queue.append("manual-%d" % Time.get_ticks_msec())
		elif ev.physical_keycode == KEY_R and not is_bot:
			reset_chamber(rng.randi())
		elif state == "bless" and not is_bot:
			if ev.physical_keycode == KEY_1: apply_bless(0); reset_chamber(rng.randi())
			elif ev.physical_keycode == KEY_2: apply_bless(1); reset_chamber(rng.randi())
			elif ev.physical_keycode == KEY_3: apply_bless(2); reset_chamber(rng.randi())
	elif ev is InputEventMouseButton and ev.pressed and state == "bless" and not is_bot:
		for i in range(3):
			if card_rect(i).has_point(get_global_mouse_position()):
				apply_bless(i)
				reset_chamber(rng.randi())


func apply_bless(i: int) -> void:
	var b: Dictionary = T.bencaos[i]
	if b.id == "ataque_mais": bless.ataque_mais = true
	elif b.id == "carga_mais": bless.carga_mais = true
	elif b.id == "corte_esquiva": bless.corte_esquiva = true
	M["bencao_escolhida"] = b.id


func card_rect(i: int) -> Rect2:
	return Rect2(360.0 + i * 400.0, 300.0, 360.0, 480.0)


# ---------------------------------------------------------------- simulation

func step(inp: Dictionary) -> void:
	if state != "play":
		return
	step_n += 1
	buffer_inputs(inp)
	if hitstop > 0:
		hitstop -= 1
		M.hitstop_total += 1
		return
	hit_req = 0
	tick_counters()
	player_step(inp)
	enemies_step()
	projs_step()
	for s in swings:
		s.age += 1
	swings = swings.filter(func(s: Dictionary) -> bool: return s.age < 6)
	hitstop = maxi(hitstop, hit_req)
	check_end()


func buffer_inputs(inp: Dictionary) -> void:
	var b: int = int(T.jogador.buffer_passos)
	if inp.dash: buf.dash = b
	if inp.spec: buf.spec = b
	if inp.atk: buf.atk = b


func tick_counters() -> void:
	P.inv = maxi(0, P.inv - 1)
	P.atk_cd = maxi(0, P.atk_cd - 1)
	P.spec_cd = maxi(0, P.spec_cd - 1)
	P.rec = maxi(0, P.rec - 1)
	P.flash = maxi(0, P.flash - 1)
	if P.combo_win > 0:
		P.combo_win -= 1
		if P.combo_win == 0:
			P.combo_idx = 0
	for k in buf:
		buf[k] = maxi(0, buf[k] - 1)
	if P.charges < P.cmax:
		P.rec_p += 1
		if P.rec_p >= st(T.esquiva.recarga_s):
			P.charges += 1
			P.rec_p = 0


func player_step(inp: Dictionary) -> void:
	var pos: Vector2 = P.pos
	var aim: Vector2 = inp.aim
	if aim.length() > 0.1:
		P.facing = aim
	# esquiva (cancela investida e recuperacao)
	if buf.dash > 0 and P.charges > 0 and P.dash_steps == 0:
		var dd: Vector2 = inp.dash_dir
		if dd.length() < 0.1:
			dd = P.facing
		P.dash_dir = dd.normalized()
		P.dash_steps = st(T.esquiva.duracao_s)
		P.dash_hit = []
		P.charges -= 1
		P.inv = maxi(P.inv, P.dash_steps + st(T.esquiva.invuln_extra_s))
		P.lunge_steps = 0
		P.rec = 0
		buf.dash = 0
		M.dashes += 1
		shot_tag_dash = 3
	if P.dash_steps > 0:
		pos += (P.dash_dir as Vector2) * (float(T.esquiva.velocidade_pxs) / 60.0)
		P.dash_steps -= 1
		pos = resolve_player_pos(pos)
		P.pos = pos
		if bless.corte_esquiva:
			dash_cut()
		if shot_tag_dash > 0:
			shot_tag_dash -= 1
			if shot_tag_dash == 0:
				shot("04-esquiva-invuln")
		return
	if P.lunge_steps > 0:
		var n: int = st(T.investida.duracao_s)
		pos += (P.lunge_dir as Vector2) * (float(T.investida.distancia_px) / float(n))
		P.lunge_steps -= 1
		pos = resolve_player_pos(pos)
		P.pos = pos
		lunge_hits()
		return
	# golpes
	if buf.spec > 0 and P.spec_cd == 0:
		P.lunge_dir = P.facing
		P.lunge_steps = st(T.investida.duracao_s)
		P.lunge_hit = []
		P.spec_cd = st(T.investida.recarga_s)
		P.inv = maxi(P.inv, P.lunge_steps + st(T.investida.invuln_extra_s))
		buf.spec = 0
		M.specials += 1
	elif buf.atk > 0 and P.atk_cd == 0:
		do_attack()
	# andar
	var mv: Vector2 = inp.move
	var f_rec: float = float(T.jogador.fator_recuperacao) if P.rec > 0 else 1.0
	pos += mv * (float(T.jogador.velocidade) / 60.0) * minf(1.0, mv.length()) * f_rec
	P.pos = resolve_player_pos(pos)


var shot_tag_dash: int = 0


func resolve_player_pos(p: Vector2) -> Vector2:
	return resolve_circle(p, float(T.jogador.raio))


func resolve_circle(p: Vector2, r: float) -> Vector2:
	var m: float = float(T.arena.margem)
	p.x = clampf(p.x, m + r, float(T.arena.largura) - m - r)
	p.y = clampf(p.y, m + r, float(T.arena.altura) - m - r)
	for pl in T.arena.pilares:
		var c := Vector2(pl.x, pl.y)
		var d: Vector2 = p - c
		var mn: float = float(pl.r) + r
		if d.length() < mn:
			p = c + (d.normalized() if d.length() > 0.001 else Vector2.RIGHT) * mn
	return p


func req_hitstop(n: int) -> void:
	hit_req = maxi(hit_req, n)


func do_attack() -> void:
	var cb: Array = T.corte.combo
	var c: float = float(cb[P.combo_idx % cb.size()])
	var idx: int = P.combo_idx
	P.combo_idx += 1
	P.combo_win = st(T.combate.janela_combo_s)
	var rcg: int = st(T.corte.recarga_s)
	P.atk_cd = rcg
	P.rec = mini(st(T.combate.recuperacao_max_s), roundi(rcg * float(T.combate.fator_recuperacao_golpe)))
	buf.atk = 0
	M.attacks += 1
	var aim: Vector2 = P.facing
	var half: float = deg_to_rad(float(T.corte.meio_angulo_graus))
	var cos_half: float = cos(half)
	var rng_px: float = float(T.corte.alcance_px)
	var fin: bool = c > float(T.combate.limiar_finalizador)
	var emp: float = maxf(float(T.corte.empurrao) * c, float(T.combate.empurrao_pesado)) if fin else float(T.corte.empurrao)
	var heavy: bool = fin or emp >= float(T.combate.empurrao_pesado)
	var m_atk: float = 1.25 if bless.ataque_mais else 1.0
	swings.append({"pos": P.pos, "dir": aim, "half": half, "range": rng_px, "age": 0, "heavy": heavy})
	var any_hit: bool = false
	for e in enemies:
		if not e.alive or e.phase == "surgindo":
			continue
		var rel: Vector2 = e.pos - (P.pos as Vector2)
		var d: float = rel.length()
		var ri: float = float(e.def.raio)
		var u: Vector2 = rel / d if d > 0.001 else aim
		var enc: bool = d < ri + float(T.jogador.raio) + float(T.combate.folga_encostado_px)
		if d <= rng_px + ri and (enc or aim.dot(u) >= cos_half):
			var dmg: float = float(T.corte.dano) * c * m_atk
			any_hit = true
			M.corte_log.append({"passo": step_n, "alvo": e.id, "combo": idx % cb.size(), "dano": dmg})
			damage_enemy(e, dmg, emp, u, heavy, st(T.combate.hitstop_pesado_s) if heavy else st(T.combate.hitstop_leve_s))
			if fin and heavy:
				shot("05-hitstop-finalizador")


func lunge_hits() -> void:
	var m_atk: float = 1.25 if bless.ataque_mais else 1.0
	var first: bool = P.lunge_hit.size() == 0
	for e in enemies:
		if not e.alive or e.phase == "surgindo" or P.lunge_hit.has(e):
			continue
		var rel: Vector2 = e.pos - (P.pos as Vector2)
		if rel.length() <= float(T.investida.raio_px) + float(e.def.raio):
			P.lunge_hit.append(e)
			var hs: int = st(T.combate.hitstop_pesado_s) if first else st(T.combate.hitstop_leve_s)
			first = false
			var u: Vector2 = rel.normalized() if rel.length() > 0.001 else (P.lunge_dir as Vector2)
			damage_enemy(e, float(T.investida.dano) * m_atk, float(T.investida.empurrao), u, true, hs)


func dash_cut() -> void:
	var b: Dictionary = T.bencaos[2]
	var m_atk: float = 1.25 if bless.ataque_mais else 1.0
	for e in enemies:
		if not e.alive or e.phase == "surgindo" or P.dash_hit.has(e):
			continue
		var rel: Vector2 = e.pos - (P.pos as Vector2)
		if rel.length() <= float(T.jogador.raio) + float(e.def.raio) + float(b.alcance_extra_px):
			P.dash_hit.append(e)
			damage_enemy(e, float(b.valor) * m_atk, float(b.empurrao), rel.normalized(), false, st(T.combate.hitstop_leve_s))


func damage_enemy(e: Dictionary, dmg: float, emp: float, dir: Vector2, heavy: bool, hs: int) -> void:
	e.hp -= dmg
	e.hits += 1
	e.flash = st(T.combate.flash_acerto_s)
	e.kb = (e.kb as Vector2) + dir * emp * float(e.kbf)
	M.dmg_dealt += dmg
	if e.hp <= 0.0:
		e.alive = false
		e.tele = {}
		M.kills += 1
		M.kill_log.append({"id": e.id, "golpes": e.hits, "passo": step_n})
		req_hitstop(maxi(hs, st(T.combate.hitstop_abate_s)))
	else:
		if not e.elite:
			e.stagger = st(T.combate.cambaleio_s)
		if heavy and e.phase == "preparo" and not e.elite:
			e.phase = "recuperacao"
			e.timer = st(T.combate.quebrou_recuperacao_s)
			e.tele = {}
			e.crack = 8
			M.breaks += 1
		req_hitstop(hs)


func hurt_player(dmg: float, tele_age: int) -> bool:
	if P.inv > 0:
		return false
	P.hp -= dmg
	P.inv = st(T.combate.invuln_atingido_s)
	P.flash = 8
	P.lunge_steps = 0
	req_hitstop(st(T.combate.hitstop_atingido_s))
	M.hits_taken += 1
	M.dmg_taken += dmg
	M.min_tele_age_on_hit = mini(int(M.min_tele_age_on_hit), tele_age)
	return true


# ---------------------------------------------------------------- enemies

func enemies_step() -> void:
	for e in enemies:
		if not e.alive:
			continue
		if e.flash > 0: e.flash -= 1
		if e.crack > 0: e.crack -= 1
		if e.tele_flash > 0:
			e.tele_flash -= 1
			if e.tele_flash == 0:
				e.tele = {}
		var def: Dictionary = e.def
		var to_p: Vector2 = (P.pos as Vector2) - (e.pos as Vector2)
		var dist: float = to_p.length()
		var dir: Vector2 = to_p / dist if dist > 0.001 else Vector2.RIGHT
		var spd: float = float(def.velocidade) / 60.0
		if e.stagger > 0:
			spd *= float(T.combate.fator_cambaleio)
			e.stagger -= 1
		var pos: Vector2 = e.pos
		match e.phase:
			"surgindo":
				e.timer -= 1
				if e.timer <= 0:
					e.phase = "aproximacao"
					e.timer = int(T.ia.espera_inicial_base) + rng.randi_range(0, int(T.ia.espera_inicial_extra) - 1)
			"aproximacao":
				e.timer -= 1
				if def.comportamento == "melee":
					pos += dir * spd
					if e.timer <= 0 and dist <= float(def.inicio_preparo_px):
						start_prep(e, dir)
				else:
					if dist < float(T.ia.ranged_perto_px):
						pos -= dir * spd
					elif dist > float(T.ia.ranged_longe_px):
						pos += dir * spd
					else:
						var perp := Vector2(-dir.y, dir.x) * float(e.orbit)
						pos += perp * spd * float(T.ia.fator_contorno)
					if e.timer <= 0 and dist < float(T.ia.ranged_ataque_px):
						start_prep(e, dir)
			"preparo":
				e.tele.rem -= 1
				if e.tele.rem <= 0:
					fire(e)
			"execucao":
				e.timer -= 1
				if e.timer <= 0:
					e.phase = "recuperacao"
					e.timer = st(def.recarga_s)
			"recuperacao":
				e.timer -= 1
				if def.comportamento != "ranged" and dist > float(T.ia.recuperacao_dist_min_px):
					pos += dir * spd * float(T.ia.fator_recuperacao_andar)
				if e.timer <= 0:
					e.phase = "aproximacao"
					e.timer = int(T.ia.espera_base) + rng.randi_range(0, int(T.ia.espera_extra) - 1)
		# empurrao
		var kb: Vector2 = e.kb
		if kb.length() > 0.0:
			pos += kb / 60.0
			kb *= float(T.combate.queda_empurrao)
			if kb.length() < float(T.combate.empurrao_zero):
				kb = Vector2.ZERO
			e.kb = kb
		e.pos = resolve_circle(pos, float(def.raio))
	# separacao
	for i in range(enemies.size()):
		var a: Dictionary = enemies[i]
		if not a.alive or a.phase == "surgindo":
			continue
		for j in range(i + 1, enemies.size()):
			var b: Dictionary = enemies[j]
			if not b.alive or b.phase == "surgindo":
				continue
			var d: Vector2 = (b.pos as Vector2) - (a.pos as Vector2)
			var mn: float = float(a.def.raio) + float(b.def.raio)
			if d.length() < mn and d.length() > 0.001:
				var push: Vector2 = d.normalized() * (mn - d.length()) * 0.5
				a.pos = (a.pos as Vector2) - push
				b.pos = (b.pos as Vector2) + push


func ray_to_wall(p: Vector2, dir: Vector2) -> float:
	var m: float = float(T.arena.margem)
	var best: float = 100000.0
	if dir.x > 0.001: best = minf(best, (float(T.arena.largura) - m - p.x) / dir.x)
	if dir.x < -0.001: best = minf(best, (m - p.x) / dir.x)
	if dir.y > 0.001: best = minf(best, (float(T.arena.altura) - m - p.y) / dir.y)
	if dir.y < -0.001: best = minf(best, (m - p.y) / dir.y)
	return best


func start_prep(e: Dictionary, dir: Vector2) -> void:
	var def: Dictionary = e.def
	var total: int = st(def.preparo_s)
	e.phase = "preparo"
	var t: Dictionary = {"aim": dir, "total": total, "rem": total, "state": "crescendo",
		"ignora": bot_rng.randf() < float(profile.falha)}
	if def.comportamento == "melee":
		t["shape"] = "setor"
		t["radius"] = float(def.tele_raio_px)
		t["cos_half"] = cos(deg_to_rad(float(def.tele_meio_angulo_graus)))
		t["half"] = deg_to_rad(float(def.tele_meio_angulo_graus))
	else:
		t["shape"] = "faixa"
		t["length"] = minf(float(def.tele_comprimento_max_px), ray_to_wall(e.pos, dir))
		t["width"] = float(def.tele_largura_px)
	e.tele = t


func in_tele(e: Dictionary, pos: Vector2) -> bool:
	var t: Dictionary = e.tele
	if t.is_empty():
		return false
	var rel: Vector2 = pos - (e.pos as Vector2)
	var aim: Vector2 = t.aim
	if t.shape == "setor":
		var d: float = rel.length()
		if d > float(t.radius):
			return false
		if d < 0.001:
			return true
		return aim.dot(rel / d) >= float(t.cos_half)
	var along: float = rel.dot(aim)
	var perp: float = absf(rel.cross(aim))
	return along >= 0.0 and along <= float(t.length) and perp <= float(t.width) * 0.5


func fire(e: Dictionary) -> void:
	var def: Dictionary = e.def
	var t: Dictionary = e.tele
	var age: int = int(t.total)
	if def.comportamento == "melee":
		M.fires_melee += 1
		if in_tele(e, P.pos):
			if hurt_player(float(def.dano), age):
				M.melee_hits += 1
			else:
				M.dodged_fires += 1
		e.timer = int(def.execucao_passos)
	else:
		M.fires_ranged += 1
		var aim: Vector2 = t.aim
		projs.append({"pos": (e.pos as Vector2) + aim * float(T.combate.nascimento_projetil_px),
			"vel": aim * (float(def.proj_velocidade_pxs) / 60.0), "life": int(def.proj_vida_passos),
			"r": float(def.proj_raio_px), "dmg": float(def.dano), "age": age})
		e.timer = int(def.execucao_passos)
	t.state = "disparo"
	e.tele_flash = int(T.ia.telegrafo_flash_passos)
	e.phase = "execucao"


func projs_step() -> void:
	var keep: Array = []
	for pr in projs:
		pr.pos = (pr.pos as Vector2) + (pr.vel as Vector2)
		pr.life -= 1
		var p: Vector2 = pr.pos
		var m: float = float(T.arena.margem)
		var dead: bool = pr.life <= 0 or p.x < m or p.x > float(T.arena.largura) - m or p.y < m or p.y > float(T.arena.altura) - m
		for pl in T.arena.pilares:
			if p.distance_to(Vector2(pl.x, pl.y)) < float(pl.r) * 0.5 + float(pr.r):
				dead = true
		if not dead and p.distance_to(P.pos) <= float(pr.r) + float(T.jogador.raio):
			if hurt_player(float(pr.dmg), int(pr.age)):
				M.proj_hits += 1
				dead = true
		if not dead:
			keep.append(pr)
	projs = keep


func check_end() -> void:
	if P.hp <= 0.0:
		state = "dead"
		bless_timer = 0
		M.result = "morte"
		return
	var alive: int = 0
	for e in enemies:
		if e.alive:
			alive += 1
	if alive == 0 and wave_idx < T.ondas.size() - 1:
		wave_idx += 1
		projs.clear()
		M["ondas"] = wave_idx + 1
		spawn_wave()
		return
	if alive == 0:
		state = "bless"
		bless_timer = 0
		M.clear_step = step_n
		M.result = "limpou"
		projs.clear()


# ---------------------------------------------------------------- bot

func bot_input() -> Dictionary:
	var pos: Vector2 = P.pos
	var inp: Dictionary = {"move": Vector2.ZERO, "aim": P.facing, "atk": false, "spec": false, "dash": false, "dash_dir": P.facing}
	var react: int = int(profile.reacao_passos)
	var lead: int = int(profile.esquiva_antecedencia)
	var want_move: Vector2 = Vector2.ZERO
	var dodging: bool = false
	# 1) telegrafos percebidos
	for e in enemies:
		if not e.alive or e.phase != "preparo":
			continue
		var t: Dictionary = e.tele
		if t.ignora:
			continue
		var elapsed: int = int(t.total) - int(t.rem)
		if elapsed < react:
			continue
		if not in_tele(e, pos):
			continue
		var away: Vector2 = (pos - (e.pos as Vector2))
		away = away.normalized() if away.length() > 0.001 else Vector2.DOWN
		var side: Vector2
		if t.shape == "setor":
			side = away
		else:
			var aim: Vector2 = t.aim
			var perp := Vector2(-aim.y, aim.x)
			side = perp if (pos - (e.pos as Vector2)).dot(perp) >= 0.0 else -perp
		dodging = true
		want_move = side
		if int(t.rem) <= lead and P.charges > 0 and P.inv <= 0:
			inp.dash = true
			inp.dash_dir = side
	# 2) projeteis em voo
	if not dodging:
		for pr in projs:
			var rel: Vector2 = pos - (pr.pos as Vector2)
			var v: Vector2 = pr.vel
			if rel.length() < 160.0 and v.dot(rel) > 0.0:
				var vn: Vector2 = v.normalized()
				var perp_d: float = absf(rel.cross(vn))
				if perp_d < 52.0:
					var perp := Vector2(-vn.y, vn.x)
					var side2: Vector2 = perp if rel.dot(perp) >= 0.0 else -perp
					want_move = side2
					dodging = true
					if rel.length() < 90.0 and P.charges > 0 and P.inv <= 0 and bot_rng.randf() >= float(profile.falha):
						inp.dash = true
						inp.dash_dir = side2
	# 3) ataque
	var target: Dictionary = {}
	var best: float = 100000.0
	for e in enemies:
		if not e.alive or e.phase == "surgindo":
			continue
		var d: float = pos.distance_to(e.pos)
		if d < best:
			best = d
			target = e
	if not target.is_empty():
		var rel_t: Vector2 = (target.pos as Vector2) - pos
		var dn: Vector2 = rel_t.normalized()
		inp.aim = dn
		var ri: float = float(target.def.raio)
		var reach: float = float(T.corte.alcance_px) + ri - 14.0
		if best <= reach:
			inp.atk = true
		if best > 190.0 and best < 320.0 and P.spec_cd == 0 and not dodging:
			inp.spec = true
		if not dodging and best > reach - 30.0:
			want_move = dn
		elif not dodging and best <= reach - 30.0:
			want_move = Vector2.ZERO
	inp.move = want_move.normalized() if want_move.length() > 0.01 else Vector2.ZERO
	# primeira marca de screenshot: telegrafos
	for e in enemies:
		if e.alive and e.phase == "preparo" and not e.tele.is_empty() and e.tele.rem <= 10:
			shot("02-telegrafo-melee" if e.tele.shape == "setor" else "03-telegrafo-faixa")
	if step_n == 70:
		shot("01-camara-inicio")
	return inp


# ---------------------------------------------------------------- screenshots

func shot(name: String) -> void:
	if batch_n > 0 or DisplayServer.get_name() == "headless":
		return
	if shot_done.has(name):
		return
	shot_done[name] = true
	shot_queue.append("%s-%s" % [name, tag])


func do_shots() -> void:
	capturing = true
	var n: String = shot_queue.pop_front()
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(EVID_DIR + "combate-camara-" + n + ".png"))
	capturing = false


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if T.is_empty():
		return
	var W: float = float(T.arena.largura)
	var H: float = float(T.arena.altura)
	var m: float = float(T.arena.margem)
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, W, H), Color(0.08, 0.07, 0.07))
	draw_rect(Rect2(m, m, W - 2 * m, H - 2 * m), Color(0.17, 0.15, 0.14))
	draw_rect(Rect2(m, m, W - 2 * m, H - 2 * m), Color(0.35, 0.3, 0.26), false, 4.0)
	for pl in T.arena.pilares:
		draw_circle(Vector2(pl.x, pl.y), float(pl.r), Color(0.3, 0.27, 0.25))
		draw_arc(Vector2(pl.x, pl.y), float(pl.r), 0, TAU, 32, Color(0.5, 0.45, 0.4), 3.0)
	# telegrafos
	for e in enemies:
		if e.alive and not e.tele.is_empty():
			draw_tele(e)
	# inimigos
	for e in enemies:
		if not e.alive:
			continue
		var r: float = float(e.def.raio)
		var col: Color = Color(0.55, 0.2, 0.2) if e.def.comportamento == "melee" else Color(0.3, 0.25, 0.6)
		if e.phase == "surgindo":
			col.a = 0.3
		if e.flash > 0:
			col = Color(1, 1, 1)
		draw_circle(e.pos, r, col)
		draw_arc(e.pos, r, 0, TAU, 24, Color(1.0, 0.8, 0.3, 1.0) if e.elite else Color(0.9, 0.85, 0.7, 0.8), 5.0 if e.elite else 2.0)
		var hpf: float = clampf(float(e.hp) / float(e.maxhp), 0.0, 1.0)
		draw_rect(Rect2((e.pos as Vector2) + Vector2(-r, -r - 14), Vector2(2 * r, 6)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2((e.pos as Vector2) + Vector2(-r, -r - 14), Vector2(2 * r * hpf, 6)), Color(0.8, 0.3, 0.3))
		if e.crack > 0:
			draw_line((e.pos as Vector2) + Vector2(-r, -r), (e.pos as Vector2) + Vector2(r, r), Color(1, 1, 1), 3.0)
	# projeteis
	for pr in projs:
		draw_circle(pr.pos, float(pr.r), Color(0.7, 0.55, 1.0))
	# golpes
	for s in swings:
		var a0: float = (s.dir as Vector2).angle() - float(s.half)
		var a1: float = (s.dir as Vector2).angle() + float(s.half)
		var al: float = 0.9 - float(s.age) * 0.14
		var col2: Color = Color(1, 0.95, 0.8, al) if not s.heavy else Color(1, 0.8, 0.4, al)
		draw_arc(s.pos, float(s.range) * 0.9, a0, a1, 24, col2, 14.0)
	# jogador
	var pp: Vector2 = P.pos
	var pr_r: float = float(T.jogador.raio)
	var pc: Color = Color(0.85, 0.8, 0.7)
	if P.flash > 0:
		pc = Color(1, 0.3, 0.3)
	if P.dash_steps > 0 or P.lunge_steps > 0:
		pc = Color(0.7, 0.9, 1.0)
	draw_circle(pp, pr_r, pc)
	if P.inv > 0:
		draw_arc(pp, pr_r + 7.0, 0, TAU, 32, Color(0.6, 0.9, 1.0, 0.9), 3.0)
	var fac: Vector2 = P.facing
	draw_line(pp, pp + fac * (pr_r + 18.0), Color(0.2, 0.2, 0.25), 5.0)
	# HUD minimo
	draw_rect(Rect2(80, 80, 300, 22), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(80, 80, 300.0 * clampf(float(P.hp) / float(T.jogador.vida_max), 0.0, 1.0), 22), Color(0.75, 0.2, 0.2))
	draw_string(font, Vector2(86, 98), "Vida %d" % int(maxf(0.0, P.hp)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1))
	for i in range(int(P.cmax)):
		var c: Color = Color(0.6, 0.9, 1.0) if i < int(P.charges) else Color(0.25, 0.3, 0.35)
		draw_circle(Vector2(96 + i * 34, 126), 12, c)
	draw_string(font, Vector2(80, 160), "Combo %d | Investida %s" % [int(P.combo_idx), "pronta" if P.spec_cd == 0 else "recarga"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.9, 0.85))
	if not is_bot:
		draw_string(font, Vector2(80, H - 80), "WASD andar | mouse mirar | clique esq. Corte (segure) | clique dir. Investida | Espaco esquiva | R reinicia | F12 foto", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.8, 0.75))
	else:
		draw_string(font, Vector2(80, H - 80), "BOT perfil=%s seed=%d passo=%d" % [profile_name, seed_base, step_n], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.8, 0.75))
	if state == "dead":
		draw_string(font, Vector2(W / 2 - 100, H / 2), "MORREU (R reinicia)", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 0.4, 0.4))
	if state == "bless":
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.65))
		draw_string(font, Vector2(W / 2 - 160, 240), "Camara limpa: escolha uma bencao", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 0.95, 0.8))
		for i in range(3):
			var rc: Rect2 = card_rect(i)
			var b: Dictionary = T.bencaos[i]
			draw_rect(rc, Color(0.2, 0.17, 0.15))
			draw_rect(rc, Color(0.75, 0.65, 0.45), false, 4.0)
			draw_string(font, rc.position + Vector2(24, 60), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.75, 0.65, 0.45))
			draw_multiline_string(font, rc.position + Vector2(24, 130), b.nome, HORIZONTAL_ALIGNMENT_LEFT, rc.size.x - 48.0, 30, 3, Color(1, 1, 1))
			draw_multiline_string(font, rc.position + Vector2(24, 210), b.texto, HORIZONTAL_ALIGNMENT_LEFT, rc.size.x - 48.0, 22, 6, Color(0.85, 0.85, 0.8))
		draw_string(font, Vector2(W / 2 - 220, 860), "[PLACEHOLDER] efeitos de teste, nao sao bencaos canonicas", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 0.7, 0.65))


func draw_tele(e: Dictionary) -> void:
	var t: Dictionary = e.tele
	var pos: Vector2 = e.pos
	var aim: Vector2 = t.aim
	var p: float = 1.0 - float(t.rem) / float(t.total)
	var fill: Color = Color(0.9, 0.35, 0.2, 0.15 + 0.5 * p)
	var line: Color = Color(1.0, 0.55, 0.3, 0.9)
	if t.state == "disparo":
		fill = Color(1, 0.95, 0.85, 0.9)
		p = 1.0
	if t.shape == "setor":
		var rad: float = float(t.radius)
		draw_poly_sector(pos, aim.angle(), float(t.half), rad * p, fill)
		draw_arc(pos, rad, aim.angle() - float(t.half), aim.angle() + float(t.half), 32, line, 3.0)
		draw_line(pos, pos + Vector2.from_angle(aim.angle() - float(t.half)) * rad, line, 3.0)
		draw_line(pos, pos + Vector2.from_angle(aim.angle() + float(t.half)) * rad, line, 3.0)
	else:
		var L: float = float(t.length)
		var hw: float = float(t.width) * 0.5
		var perp := Vector2(-aim.y, aim.x)
		var pts: PackedVector2Array = PackedVector2Array([pos + perp * hw, pos + aim * L * p + perp * hw, pos + aim * L * p - perp * hw, pos - perp * hw])
		draw_colored_polygon(pts, fill)
		var outline: PackedVector2Array = PackedVector2Array([pos + perp * hw, pos + aim * L + perp * hw, pos + aim * L - perp * hw, pos - perp * hw, pos + perp * hw])
		draw_polyline(outline, line, 3.0)


func draw_poly_sector(c: Vector2, ang: float, half: float, rad: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([c])
	var n: int = 24
	for i in range(n + 1):
		var a: float = ang - half + (2.0 * half) * float(i) / float(n)
		pts.append(c + Vector2.from_angle(a) * rad)
	draw_colored_polygon(pts, col)
