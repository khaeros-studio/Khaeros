extends RefCounted
## Integrated playable chamber: pure 60Hz rules, independent of rendering/input devices.
## This first integration covers the Lamina and three authored waves, not every MVP system.

const Movement = preload("res://src/gameplay/movement.gd")
const TICK_RATE := 60.0
const MASK := 0xffffffff

var data: Dictionary = {}
var state := "menu"
var player: Dictionary = {}
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var wave_index := 0
var hitstop := 0
var kills := 0
var denied_dash_count := 0
var damage_multiplier := 1.0
var oficina_damage_mult := 1.0
var oficina_reach_mult := 1.0
var include_boss_in_final_wave := false
var weapon_id: StringName = &"lamina"
var extended_campaign: bool = false
var start_region_index: int = 0
var region_index: int = 0
var region_wave_index: int = 0
var current_region: Dictionary = {}
var current_offer: Array[Dictionary] = []
var taken_boons: Array[StringName] = []
var life_on_kill: float = 0.0
var attack_cd_mult: float = 1.0
var special_damage_mult: float = 1.0
var knockback_mult: float = 1.0
var shield_per_room: float = 0.0
var crit_chance: float = 0.0
var player_shield: float = 0.0
var speed_mult: float = 1.0
var dash_recharge_mult: float = 1.0
var reach_boon_mult: float = 1.0
var selos_usados: int = 0
var last_killed_kinds: Array[String] = []
var urns: Array[Dictionary] = []
var urns_broken_total: int = 0
var _advancing_region: bool = false
var allied_curses: Array[Dictionary] = []
var domain_timer: float = 0.0
var domain_weapon: StringName = &""
var mapa: MapaMasmorra = null
var room_cleared: bool = false
var exit_doors: Array[Dictionary] = []
var room_props: Array[Dictionary] = []
var room_interactives: Array[Dictionary] = []
var pending_lore_eco_id: String = ""
var pending_blessing_claimed: bool = false
var active_door_index: int = -1
var active_interactive_index: int = -1
var _pending_door_dest: int = -1
var _curses_spawn_seq: int = 0
var presentation_time := 0.0
var live_steps := 0
var seed_value := 1
var transition_progress := 0.0
var blessing_counts: Dictionary = {}
var _resume_state := "jogo"
## Fonte de fluxos da run (ADR-0005), recriada a cada start(); só a interface de IA
## é guardada (fluxo `ia`, região/profundidade 0 na câmara única da fatia).
var _fonte_rng: FonteDeFluxos = null
var _fluxo_ia: FluxoRng = null
var _relator_rng: RelatorDeErrosRng = null
var _next_id := 0
var _pending_hitstop := 0
var _transition_cut := false

## Installs validated data without starting the run.
## `relator_rng` recebe os diagnósticos do RNG; nulo usa avisos da engine (push_warning).
func configure(tuning: Dictionary, seed: int = 1, relator_rng: RelatorDeErrosRng = null) -> void:
	data = tuning.duplicate(true)
	seed_value = seed & MASK
	_relator_rng = relator_rng if relator_rng != null else _RelatorDeAvisosRng.new()
	state = "menu"

## Starts/restarts a clean run from its fixed seed and initial loadout.
func start() -> void:
	# Story RNG-006: a espera da IA sai do fluxo `ia` da fonte (antes, gerador próprio).
	if _relator_rng == null: _relator_rng = _RelatorDeAvisosRng.new()
	_fonte_rng = FonteDeFluxos.new(_relator_rng)
	_fonte_rng.iniciar_run(seed_value,false)
	_fluxo_ia = FluxosDeIa.new(_fonte_rng).ia(0,0)
	_next_id = 0
	wave_index = 0
	kills = 0
	denied_dash_count = 0
	hitstop = 0
	_pending_hitstop = 0
	live_steps = 0
	transition_progress = 0.0
	_transition_cut = false
	presentation_time = 0.0
	damage_multiplier = oficina_damage_mult
	blessing_counts.clear()
	taken_boons.clear()
	current_offer.clear()
	life_on_kill = 0.0
	attack_cd_mult = 1.0
	special_damage_mult = 1.0
	knockback_mult = 1.0
	shield_per_room = 0.0
	crit_chance = 0.0
	player_shield = 0.0
	speed_mult = 1.0
	dash_recharge_mult = 1.0
	reach_boon_mult = 1.0
	selos_usados = 0
	last_killed_kinds.clear()
	urns.clear()
	urns_broken_total = 0
	_advancing_region = false
	allied_curses.clear()
	domain_timer = 0.0
	domain_weapon = &""
	exit_doors.clear()
	room_props.clear()
	room_interactives.clear()
	room_cleared = false
	pending_lore_eco_id = ""
	pending_blessing_claimed = false
	active_door_index = -1
	active_interactive_index = -1
	_pending_door_dest = -1
	_curses_spawn_seq = 0
	if extended_campaign:
		var regioes: Array[Dictionary] = CatalogoCampanha.regioes()
		region_index = clampi(start_region_index, 0, maxi(0, regioes.size() - 1))
		region_wave_index = 0
		current_region = regioes[region_index] if not regioes.is_empty() else {}
	else:
		region_index = 0
		region_wave_index = 0
		current_region = {}
	projectiles.clear()
	effects.clear()
	var spawn: Array = data.jogador.spawn
	var position := Vector2(spawn[0],spawn[1])
	player = {
		"pos":position, "prev":position, "hp":float(data.jogador.vida_max),
		"max_hp":float(data.jogador.vida_max), "aim":Vector2.UP, "radius":float(data.jogador.raio),
		"charges":int(data.esquiva.cargas_base), "charge_max":int(data.esquiva.cargas_base),
		"dash_remaining":0, "dash_dir":Vector2.UP, "dash_hits":{}, "recharge":0,
		"inv":0, "attack_cd":0, "special_cd":0, "recovery":0, "combo":0,
		"combo_window":0, "lunge_remaining":0, "lunge_dir":Vector2.UP,
		"lunge_hits":{}, "flash":0,
		"flow":0.0, "flow_max":100.0, "combo_hits":0, "combo_timer":0,
		"curses_absorbed":2, "curses_max":6
	}
	state = "jogo"
	if extended_campaign:
		mapa = MapaMasmorra.new()
		_iniciar_mapa_regiao(region_index)
	else:
		mapa = null
		_spawn_wave()

## Pauses gameplay or a blessing; the overlay must preserve its prior context.
func pause() -> void:
	if state in ["jogo","bencao"]:
		_resume_state = state
		state = "pausa"

## Returns to the context from which pause was opened.
func resume() -> void:
	if state == "pausa": state = _resume_state

## Applies the chosen offered blessing and starts the following authored wave.
func choose_blessing(index: int) -> void:
	if state != "bencao": return
	if extended_campaign:
		if index < 0 or index >= current_offer.size(): return
		var carta: Dictionary = current_offer[index]
		var carta_id: String = String(carta.get("id", ""))
		if carta_id != "":
			taken_boons.append(StringName(carta_id))
			blessing_counts[carta_id] = int(blessing_counts.get(carta_id, 0)) + 1
		var efeito: String = String(carta.get("efeito", carta.get("tipo", "")))
		var valor: float = float(carta.get("valor", 0.0))
		match efeito:
			"dano_pct":
				damage_multiplier += valor
			"velocidade_pct":
				speed_mult += valor
			"vida_max_cura":
				player.max_hp = float(player.max_hp) + valor
				if bool(carta.get("cura_total", false)):
					player.hp = float(player.max_hp)
				else:
					var cura_val: float = float(carta.get("cura", valor))
					player.hp = minf(float(player.max_hp), float(player.hp) + cura_val)
			"esquiva_carga":
				var add_c: int = maxi(1, roundi(valor))
				player.charge_max = int(player.charge_max) + add_c
				player.charges = int(player.charges) + add_c
				if int(player.charges) == int(player.charge_max): player.recharge = 0
			"esquiva_recarga":
				dash_recharge_mult = maxf(0.35, dash_recharge_mult * (1.0 - valor))
			"ataque_rapido":
				attack_cd_mult = maxf(0.4, attack_cd_mult * (1.0 - valor))
			"alcance_pct":
				reach_boon_mult += valor
			"vampirismo":
				life_on_kill += valor
			"empurrao_pct":
				knockback_mult += valor
			"especial_dano":
				special_damage_mult += valor
			"escudo_camara":
				shield_per_room += valor
				player_shield = maxf(player_shield, shield_per_room)
			"critico_chance":
				crit_chance = clampf(crit_chance + valor, 0.0, 0.85)
			"corte_esquiva":
				blessing_counts["corte_esquiva"] = int(blessing_counts.get("corte_esquiva", 0)) + 1
		if mapa != null:
			state = "jogo"
			_atualizar_proximidade_sala()
			return
		transition_progress = 0.0
		_transition_cut = false
		state = "transicao"
		return
	if index < 0 or index >= data.bencaos.size(): return
	var blessing: Dictionary = data.bencaos[index]
	blessing_counts[blessing.id] = int(blessing_counts.get(blessing.id,0)) + 1
	match String(blessing.id):
		"ataque_mais": damage_multiplier += float(blessing.valor)
		"carga_mais":
			player.charge_max += int(blessing.valor)
			player.charges += int(blessing.valor)
			if player.charges == player.charge_max: player.recharge = 0
	transition_progress = 0.0
	_transition_cut = false
	state = "transicao"

## Advances cosmetic time only. Pause and blessing preserve presentation state.
func advance_presentation(delta: float) -> void:
	var dt := minf(delta, float(data.get("presentation",{}).get("delta_max",0.1)))
	if state == "transicao":
		transition_progress = minf(1.0,transition_progress+dt/float(data.wave_transition_s))
		if transition_progress >= 0.5 and not _transition_cut:
			_transition_cut = true
			if extended_campaign and mapa != null:
				player.lunge_remaining = 0
				player.recovery = 0
				hitstop = 0
				presentation_time = 0.0
				if _advancing_region:
					region_index = mini(3, region_index + 1)
					region_wave_index = 0
					_advancing_region = false
					var regioes: Array[Dictionary] = CatalogoCampanha.regioes()
					if region_index < regioes.size():
						current_region = regioes[region_index]
					wave_index += 1
					_iniciar_mapa_regiao(region_index)
				elif _pending_door_dest >= 0:
					var dest_idx: int = _pending_door_dest
					_pending_door_dest = -1
					mapa.avancar_para(dest_idx)
					wave_index += 1
					_carregar_sala_do_mapa()
			else:
				if extended_campaign:
					if _advancing_region:
						region_index = mini(3, region_index + 1)
						region_wave_index = 0
						_advancing_region = false
						var regioes: Array[Dictionary] = CatalogoCampanha.regioes()
						if region_index < regioes.size():
							current_region = regioes[region_index]
					else:
						region_wave_index += 1
					wave_index += 1
				else:
					wave_index += 1
				projectiles.clear()
				effects.clear()
				player.lunge_remaining = 0
				player.recovery = 0
				hitstop = 0
				Movement.teleport(player,Vector2(data.jogador.spawn[0],data.jogador.spawn[1]))
				presentation_time = 0.0
				_spawn_wave()
		if transition_progress >= 1.0: state = "jogo"
		return
	if state not in ["jogo","morte","vitoria"]: return
	presentation_time += dt
	if domain_timer > 0.0:
		domain_timer = maxf(0.0, domain_timer - dt)
		if domain_timer == 0.0:
			domain_weapon = &""
	for effect: Dictionary in effects: effect.age += dt
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.age < effect.duration)

## Runs one fixed step and returns exactly the gameplay commands executed.
func step(sample: Dictionary) -> Array[String]:
	var consumed: Array[String] = []
	if player.is_empty(): return consumed
	if state != "jogo":
		_freeze()
		return consumed
	if hitstop > 0:
		hitstop -= 1
		_freeze()
		return consumed
	live_steps += 1
	_pending_hitstop = 0
	player.prev = player.pos
	for enemy: Dictionary in enemies: enemy.prev = enemy.pos
	for projectile: Dictionary in projectiles: projectile.prev = projectile.pos
	for key in ["inv","attack_cd","special_cd","recovery","combo_window","flash","combo_timer"]:
		player[key] = maxi(0,int(player[key])-1)
	if player.combo_window == 0: player.combo = 0
	if int(player.combo_timer) == 0: player.combo_hits = 0
	var aim: Vector2 = sample.get("aim",Vector2.UP)
	if aim != Vector2.ZERO: player.aim = aim.normalized()
	var move: Vector2 = sample.get("move",Vector2.ZERO)
	var wants: Dictionary = sample.get("wants",{})
	var dash_recarga_ticks: int = maxi(1, roundi(float(Movement.ticks(data.esquiva.recarga_s)) * dash_recharge_mult))
	Movement.recharge(player, dash_recarga_ticks)
	# The input collector retains new taps during hitstop and drains them once here.
	# Classify denial before spending: a successful final charge never creates denial.
	var dash_taps := maxi(0,int(sample.get("dash_taps",0)))
	if player.charges == 0 and dash_taps > 0:
		denied_dash_count += dash_taps
		_effect("dash_denied",player.pos,player.aim,float(data.esquiva.duracao_s))
	if wants.get("esquiva",false) and player.charges > 0 and player.dash_remaining == 0:
		_start_dash(move)
		consumed.append("esquiva")
	var dashed := false
	if player.dash_remaining > 0:
		player.pos += player.dash_dir * float(data.esquiva.velocidade_pxs) / TICK_RATE
		player.dash_remaining -= 1
		dashed = true
	elif player.lunge_remaining > 0:
		player.pos += player.lunge_dir * float(data.investida.distancia_px) / Movement.ticks(data.investida.duracao_s)
	else:
		var recovery := float(data.jogador.fator_recuperacao) if player.recovery > 0 else 1.0
		var domain_speed_mult: float = 1.18 if domain_timer > 0.0 else 1.0
		player.pos += move.normalized() * minf(1.0,move.length()) * float(data.jogador.velocidade) * speed_mult * domain_speed_mult * recovery / TICK_RATE
	if dashed: _dash_cut()
	player.pos = Movement.resolve(player.pos,player.radius,data.arena)
	if player.lunge_remaining > 0:
		_lunge_hits()
		player.lunge_remaining -= 1
	elif player.dash_remaining == 0:
		if bool(wants.get("selo", false)) and float(player.flow) >= 100.0:
			player.flow = 0.0
			selos_usados += 1
			player.inv = maxi(int(player.inv), 36)
			_selo_ultimate()
			consumed.append("selo")
		elif wants.get("especial",false) and player.special_cd == 0:
			_special()
			consumed.append("especial")
		elif wants.get("ataque",false) and player.attack_cd == 0:
			_attack()
			consumed.append("ataque")
	for enemy: Dictionary in enemies:
		if enemy.hp > 0: _enemy_step(enemy)
	_projectile_step()
	_step_allied_curses()
	_remove_dead()
	hitstop = maxi(hitstop,_pending_hitstop)
	if player.hp <= 0:
		state = "morte"
	elif enemies.is_empty() and hitstop == 0:
		if extended_campaign and mapa != null:
			if not room_cleared:
				projectiles.clear()
				var sala_now: Dictionary = mapa.sala_atual()
				var tipo_now: String = String(sala_now.get("tipo", ""))
				if tipo_now == "chefe" and region_index >= 3:
					state = "vitoria"
				else:
					room_cleared = true
					mapa.marcar_limpa()
					exit_doors = mapa.portas_da_sala_atual()
					if tipo_now == "chefe":
						var cura_chefe: float = float(player.max_hp) * 0.35
						player.hp = minf(float(player.max_hp), float(player.hp) + cura_chefe)
						_advancing_region = true
					if not pending_blessing_claimed and tipo_now in ["combate", "emboscada", "combate_denso", "elite_guarda", "chefe"]:
						pending_blessing_claimed = true
						current_offer = _sortear_oferta_campanha(tipo_now == "chefe")
						state = "bencao"
		elif extended_campaign:
			projectiles.clear()
			if region_wave_index >= 2:
				if region_index >= 3:
					state = "vitoria"
				else:
					var cura_chefe: float = float(player.max_hp) * 0.35
					player.hp = minf(float(player.max_hp), float(player.hp) + cura_chefe)
					_advancing_region = true
					current_offer = _sortear_oferta_campanha(true)
					state = "bencao"
			else:
				_advancing_region = false
				current_offer = _sortear_oferta_campanha(false)
				state = "bencao"
		else:
			projectiles.clear()
			state = "vitoria" if wave_index + 1 >= data.ondas.size() else "bencao"
	if extended_campaign and state == "jogo":
		_atualizar_proximidade_sala()
	else:
		active_interactive_index = -1
		active_door_index = -1
	return consumed

func _freeze() -> void:
	Movement.freeze(player)
	for enemy: Dictionary in enemies: enemy.prev = enemy.pos
	for projectile: Dictionary in projectiles: projectile.prev = projectile.pos
	for curse: Dictionary in allied_curses: curse["prev"] = curse["pos"]

func _start_dash(move: Vector2) -> void:
	player.dash_dir = move.normalized() if move != Vector2.ZERO else player.aim
	player.charges -= 1
	player.dash_remaining = Movement.ticks(data.esquiva.duracao_s)
	player.lunge_remaining = 0
	player.recovery = 0
	player.inv = maxi(player.inv,player.dash_remaining + Movement.ticks(data.esquiva.invuln_extra_s))
	player.dash_hits.clear()
	_effect("dash",player.pos,player.dash_dir,float(data.esquiva.duracao_s))

func _attack() -> void:
	if weapon_id == &"ressonancia":
		_attack_ressonancia()
		return
	if weapon_id == &"pactos":
		_attack_pactos()
		return
	if weapon_id == &"guardiao":
		_attack_guardiao()
		return
	if weapon_id == &"veu":
		_attack_veu()
		return
	var combo: Array = data.corte.combo
	var multiplier: float = combo[int(player.combo) % combo.size()]
	player.combo = (int(player.combo)+1) % combo.size()
	player.combo_window = Movement.ticks(data.combate.janela_combo_s)
	player.attack_cd = maxi(1, roundi(float(Movement.ticks(data.corte.recarga_s)) * attack_cd_mult))
	player.recovery = mini(Movement.ticks(data.combate.recuperacao_max_s),roundi(player.attack_cd*float(data.combate.fator_recuperacao_golpe)))
	var heavy := multiplier > float(data.combate.limiar_finalizador)
	var push: float = maxf(float(data.corte.empurrao)*multiplier,float(data.combate.empurrao_pesado)) if heavy else float(data.corte.empurrao)
	var reach: float = float(data.corte.alcance_px) * oficina_reach_mult * reach_boon_mult
	var effect := _effect("attack",player.pos,player.aim,float(data.combate.flash_acerto_s)*2.0)
	effect["radius"] = reach
	effect["angle"] = deg_to_rad(float(data.corte.meio_angulo_graus))
	effect["heavy"] = heavy
	for enemy: Dictionary in enemies:
		if not _hittable(enemy): continue
		var delta: Vector2 = enemy.pos-player.pos
		if delta.length() > reach+enemy.radius: continue
		var touching: bool = delta.length() < player.radius+enemy.radius+float(data.combate.folga_encostado_px)
		if touching or player.aim.dot(delta.normalized()) >= cos(deg_to_rad(float(data.corte.meio_angulo_graus))):
			_hurt_enemy(enemy,float(data.corte.dano)*multiplier*damage_multiplier,player.aim,push,heavy,true)
	_break_urns_in_radius(player.pos, reach)

func _attack_guardiao() -> void:
	player.combo = (int(player.combo) + 1) % 2
	player.combo_window = Movement.ticks(data.combate.janela_combo_s)
	player.attack_cd = maxi(1, roundi(float(Movement.ticks(0.45)) * attack_cd_mult))
	player.recovery = mini(Movement.ticks(data.combate.recuperacao_max_s), roundi(player.attack_cd * float(data.combate.fator_recuperacao_golpe)))
	var reach: float = 155.0 * oficina_reach_mult * reach_boon_mult
	var half_angle := deg_to_rad(105.0)
	var effect := _effect("attack", player.pos, player.aim, 0.20)
	effect["radius"] = reach
	effect["angle"] = half_angle
	effect["heavy"] = true
	effect["weapon"] = "guardiao"
	for enemy: Dictionary in enemies:
		if not _hittable(enemy): continue
		var delta: Vector2 = enemy.pos - player.pos
		if delta.length() > reach + enemy.radius: continue
		var touching: bool = delta.length() < player.radius + enemy.radius + float(data.combate.folga_encostado_px)
		if touching or player.aim.dot(delta.normalized()) >= cos(half_angle):
			_hurt_enemy(enemy, 22.0 * damage_multiplier, player.aim, 960.0, true, true)
	_break_urns_in_radius(player.pos, reach)

func _attack_veu() -> void:
	player.combo = (int(player.combo) + 1) % 3
	player.combo_window = Movement.ticks(data.combate.janela_combo_s)
	player.attack_cd = maxi(1, roundi(float(Movement.ticks(0.16)) * attack_cd_mult))
	player.recovery = mini(Movement.ticks(data.combate.recuperacao_max_s), roundi(player.attack_cd * float(data.combate.fator_recuperacao_golpe)))
	var reach: float = 115.0 * oficina_reach_mult * reach_boon_mult
	var half_angle := deg_to_rad(50.0)
	var heavy := int(player.combo) == 0
	var effect := _effect("attack", player.pos, player.aim, 0.12)
	effect["radius"] = reach
	effect["angle"] = half_angle
	effect["heavy"] = heavy
	effect["weapon"] = "veu"
	for enemy: Dictionary in enemies:
		if not _hittable(enemy): continue
		var delta: Vector2 = enemy.pos - player.pos
		if delta.length() > reach + enemy.radius: continue
		var touching: bool = delta.length() < player.radius + enemy.radius + float(data.combate.folga_encostado_px)
		if touching or player.aim.dot(delta.normalized()) >= cos(half_angle):
			_hurt_enemy(enemy, (15.0 if heavy else 10.5) * damage_multiplier, player.aim, 420.0 if heavy else 260.0, heavy, true)
	_break_urns_in_radius(player.pos, reach)

func _attack_ressonancia() -> void:
	player.attack_cd = maxi(1, roundi(float(Movement.ticks(0.233)) * attack_cd_mult))
	player.recovery = mini(Movement.ticks(data.combate.recuperacao_max_s),roundi(player.attack_cd*float(data.combate.fator_recuperacao_golpe)))
	var spawn_pos: Vector2 = player.pos + player.aim * 28.0
	projectiles.append({
		"owner": "player",
		"kind": "magic_orb",
		"pos": spawn_pos,
		"prev": spawn_pos,
		"velocity": player.aim * 990.0,
		"radius": 15.0,
		"damage": 12.0 * damage_multiplier,
		"push": 540.0,
		"remaining": Movement.ticks(0.833)
	})
	_effect("magic_cast", spawn_pos, player.aim, 0.14)

func _attack_pactos() -> void:
	player.attack_cd = maxi(1, roundi(float(Movement.ticks(0.24)) * attack_cd_mult))
	player.recovery = mini(Movement.ticks(data.combate.recuperacao_max_s), roundi(player.attack_cd * float(data.combate.fator_recuperacao_golpe)))
	var ppos: Vector2 = player["pos"] as Vector2
	var paim: Vector2 = player["aim"] as Vector2
	var spawn_pos: Vector2 = ppos + paim * 28.0
	projectiles.append({
		"owner": "player",
		"kind": "curse_orb",
		"pos": spawn_pos,
		"prev": spawn_pos,
		"velocity": paim * 940.0,
		"radius": 15.0,
		"damage": 11.5 * damage_multiplier,
		"push": 380.0,
		"remaining": Movement.ticks(0.85)
	})
	_effect("curse_cast", spawn_pos, paim, 0.16)

func _special() -> void:
	if weapon_id == &"ressonancia":
		_special_ressonancia()
	elif weapon_id == &"pactos":
		_special_pactos()
	elif weapon_id == &"guardiao":
		_special_guardiao()
	elif weapon_id == &"veu":
		_special_veu()
	else:
		_start_lunge()

func _special_ressonancia() -> void:
	player.special_cd = Movement.ticks(1.5)
	var pulse_radius: float = 195.0 * oficina_reach_mult * reach_boon_mult
	var pulse := _effect("magic_pulse", player.pos, player.aim, 0.35)
	pulse["radius"] = pulse_radius
	for enemy: Dictionary in enemies:
		if not _hittable(enemy): continue
		var delta: Vector2 = enemy.pos - player.pos
		if delta.length() <= pulse_radius + enemy.radius:
			var dir: Vector2 = delta.normalized() if delta != Vector2.ZERO else player.aim
			_hurt_enemy(enemy, 30.0 * damage_multiplier * special_damage_mult, dir, 1260.0, true, true)
	_break_urns_in_radius(player.pos, pulse_radius)

func _special_pactos() -> void:
	player.special_cd = Movement.ticks(1.35)
	if allied_curses.size() >= 3:
		allied_curses.pop_front()
	var sp_pool: Array[String] = ["vulto_mudo", "espreitador_da_fenda", "anomalia_menor"]
	var sp: String = "vulto_mudo"
	if int(player.get("curses_absorbed", 0)) > 0:
		player["curses_absorbed"] = int(player["curses_absorbed"]) - 1
		sp = sp_pool[_curses_spawn_seq % sp_pool.size()]
		_curses_spawn_seq += 1
	_next_id += 1
	var ppos: Vector2 = player["pos"] as Vector2
	var paim: Vector2 = player["aim"] as Vector2
	var c_pos: Vector2 = Movement.resolve(ppos + paim * 84.0, 22.0, data.arena)
	allied_curses.append({
		"id": _next_id,
		"species": sp,
		"pos": c_pos,
		"prev": c_pos,
		"aim": paim,
		"ttl": 720,
		"attack_cd": 12
	})
	var fx: Dictionary = _effect("pact_call", c_pos, paim, 0.35)
	fx["target_pos"] = c_pos

func _step_allied_curses() -> void:
	if allied_curses.is_empty():
		return
	var survivors: Array[Dictionary] = []
	var ppos: Vector2 = player["pos"] as Vector2
	for i: int in range(allied_curses.size()):
		var curse: Dictionary = allied_curses[i]
		var c_pos: Vector2 = curse["pos"] as Vector2
		curse["prev"] = c_pos
		var ttl: int = int(curse.get("ttl", 0)) - 1
		var cd: int = maxi(0, int(curse.get("attack_cd", 0)) - 1)
		curse["ttl"] = ttl
		curse["attack_cd"] = cd
		if ttl <= 0:
			continue
		var best_enemy: Dictionary = {}
		var best_dist_sq: float = INF
		for enemy: Dictionary in enemies:
			if not _hittable(enemy):
				continue
			var d_sq: float = c_pos.distance_squared_to(enemy["pos"] as Vector2)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_enemy = enemy
		if not best_enemy.is_empty():
			var e_pos: Vector2 = best_enemy["pos"] as Vector2
			var delta: Vector2 = e_pos - c_pos
			var dist: float = delta.length()
			var aim_fallback_raw: Variant = curse.get("aim", Vector2.UP)
			var aim_fallback: Vector2 = aim_fallback_raw as Vector2 if aim_fallback_raw is Vector2 else Vector2.UP
			var dir: Vector2 = delta.normalized() if dist > 0.001 else aim_fallback
			curse["aim"] = dir
			if dist > 58.0:
				var step_len: float = minf(dist - 58.0, 280.0 / TICK_RATE)
				c_pos = Movement.resolve(c_pos + dir * step_len, 22.0, data.arena)
				curse["pos"] = c_pos
				dist = c_pos.distance_to(e_pos)
			if dist <= 85.0 and cd <= 0:
				_hurt_enemy(best_enemy, 10.0 * damage_multiplier * special_damage_mult, dir, 320.0, false, false, false, false)
				curse["attack_cd"] = 50
				var fx: Dictionary = _effect("pact_call", e_pos, dir, 0.25)
				fx["target_pos"] = e_pos
		else:
			var angle: float = float(live_steps) * 0.045 + float(i) * (TAU / 3.0)
			var orbit_target: Vector2 = Movement.resolve(ppos + Vector2(cos(angle), sin(angle)) * 78.0, 22.0, data.arena)
			var to_orbit: Vector2 = orbit_target - c_pos
			var orbit_dist: float = to_orbit.length()
			if orbit_dist > 2.0:
				var o_dir: Vector2 = to_orbit / orbit_dist
				var o_step: float = minf(orbit_dist, 280.0 / TICK_RATE)
				curse["pos"] = Movement.resolve(c_pos + o_dir * o_step, 22.0, data.arena)
				curse["aim"] = o_dir
		survivors.append(curse)
	allied_curses = survivors

func _special_guardiao() -> void:
	player.special_cd = Movement.ticks(1.8)
	player.inv = maxi(player.inv, Movement.ticks(0.65))
	var shock_radius: float = 180.0 * oficina_reach_mult * reach_boon_mult
	var fx := _effect("guardiao_bastion", player.pos, player.aim, 0.35)
	fx["radius"] = shock_radius
	for enemy: Dictionary in enemies:
		if not _hittable(enemy): continue
		var delta: Vector2 = enemy.pos - player.pos
		if delta.length() <= shock_radius + enemy.radius:
			var dir: Vector2 = delta.normalized() if delta != Vector2.ZERO else player.aim
			_hurt_enemy(enemy, 22.0 * damage_multiplier * special_damage_mult, dir, 1350.0, true, true)
	_break_urns_in_radius(player.pos, shock_radius)

func _special_veu() -> void:
	player.special_cd = Movement.ticks(1.0)
	player.lunge_remaining = Movement.ticks(0.15)
	player.lunge_dir = player.aim
	player.lunge_hits.clear()
	player.inv = maxi(player.inv, player.lunge_remaining + Movement.ticks(0.08))
	_effect("veu_blink", player.pos, player.aim, 0.24)
	_lunge_hits()

func _start_lunge() -> void:
	player.special_cd = Movement.ticks(data.investida.recarga_s)
	player.lunge_remaining = Movement.ticks(data.investida.duracao_s)
	player.lunge_dir = player.aim
	player.lunge_hits.clear()
	player.inv = maxi(player.inv,player.lunge_remaining+Movement.ticks(data.investida.invuln_extra_s))
	_effect("special",player.pos,player.aim,float(data.investida.duracao_s))
	_lunge_hits()

func _lunge_hits() -> void:
	var is_veu := weapon_id == &"veu"
	var lunge_radius: float = (78.0 if is_veu else float(data.investida.raio_px)) * oficina_reach_mult * reach_boon_mult
	var lunge_dmg: float = (22.0 if is_veu else float(data.investida.dano)) * damage_multiplier * special_damage_mult
	var lunge_push := 640.0 if is_veu else float(data.investida.empurrao)
	for enemy: Dictionary in enemies:
		if not _hittable(enemy) or player.lunge_hits.has(enemy.id): continue
		if player.pos.distance_to(enemy.pos) <= lunge_radius+enemy.radius:
			player.lunge_hits[enemy.id] = true
			_hurt_enemy(enemy,lunge_dmg,player.lunge_dir,lunge_push,true,true)
	_break_urns_in_radius(player.pos, lunge_radius)

func _selo_ultimate() -> void:
	domain_timer = 4.5
	domain_weapon = weapon_id
	var ppos: Vector2 = player.pos
	var paim: Vector2 = player.aim
	if weapon_id == &"ressonancia":
		for i: int in range(8):
			var ang: float = TAU * float(i) / 8.0
			var dir_orb: Vector2 = paim.rotated(ang)
			var spawn_pos: Vector2 = ppos + dir_orb * 28.0
			projectiles.append({
				"owner": "player",
				"kind": "magic_orb",
				"pos": spawn_pos,
				"prev": spawn_pos,
				"velocity": dir_orb * 990.0,
				"radius": 15.0,
				"damage": 16.0 * damage_multiplier,
				"push": 540.0,
				"remaining": Movement.ticks(0.85)
			})
		var radius_r: float = 260.0
		var fx_r: Dictionary = _effect("selo_ressonancia", ppos, paim, 0.55)
		fx_r["radius"] = radius_r
		for enemy: Dictionary in enemies:
			if not _hittable(enemy): continue
			var delta_r: Vector2 = enemy.pos - ppos
			if delta_r.length() <= radius_r + float(enemy.radius):
				var dir_r: Vector2 = delta_r.normalized() if delta_r != Vector2.ZERO else paim
				_hurt_enemy(enemy, 45.0 * damage_multiplier, dir_r, 1200.0, true, true, false, false)
		_break_urns_in_radius(ppos, radius_r)
	elif weapon_id == &"pactos":
		var cargas: int = maxi(1, int(player.get("curses_absorbed", 0)))
		player["curses_absorbed"] = 0
		var aoe_radius: float = 320.0
		var aoe_dmg: float = (48.0 + float(cargas) * 18.0) * damage_multiplier
		for enemy: Dictionary in enemies:
			if not _hittable(enemy):
				continue
			var delta_p: Vector2 = (enemy["pos"] as Vector2) - ppos
			if delta_p.length() <= aoe_radius + float(enemy["radius"]):
				var dir_p: Vector2 = delta_p.normalized() if delta_p != Vector2.ZERO else paim
				_hurt_enemy(enemy, aoe_dmg, dir_p, 900.0, true, true, false, false)
		_break_urns_in_radius(ppos, aoe_radius)
		for i: int in range(6):
			var ang_o: float = TAU * float(i) / 6.0
			var dir_orb: Vector2 = paim.rotated(ang_o)
			var spawn_pos: Vector2 = ppos + dir_orb * 28.0
			projectiles.append({
				"owner": "player",
				"kind": "curse_orb",
				"pos": spawn_pos,
				"prev": spawn_pos,
				"velocity": dir_orb * 940.0,
				"radius": 15.0,
				"damage": 11.5 * damage_multiplier,
				"push": 380.0,
				"remaining": Movement.ticks(0.85)
			})
		var sp_pool_u: Array[String] = ["vulto_mudo", "espreitador_da_fenda", "anomalia_menor"]
		for s_i: int in range(2):
			if allied_curses.size() >= 3:
				allied_curses.pop_front()
			var sp_u: String = sp_pool_u[_curses_spawn_seq % sp_pool_u.size()]
			_curses_spawn_seq += 1
			_next_id += 1
			var offset_dir: Vector2 = paim.rotated(0.6 if s_i == 0 else -0.6)
			var c_pos_u: Vector2 = Movement.resolve(ppos + offset_dir * 84.0, 22.0, data.arena)
			allied_curses.append({
				"id": _next_id,
				"species": sp_u,
				"pos": c_pos_u,
				"prev": c_pos_u,
				"aim": offset_dir,
				"ttl": 720,
				"attack_cd": 12
			})
		var fx_p: Dictionary = _effect("selo_pactos", ppos, paim, 0.65)
		fx_p["radius"] = aoe_radius
		fx_p["charges"] = cargas
	elif weapon_id == &"guardiao":
		player_shield += 45.0
		var radius_g: float = 310.0
		var fx_g: Dictionary = _effect("selo_guardiao", ppos, paim, 0.6)
		fx_g["radius"] = radius_g
		for enemy: Dictionary in enemies:
			if not _hittable(enemy): continue
			var delta_g: Vector2 = enemy.pos - ppos
			if delta_g.length() <= radius_g + float(enemy.radius):
				var dir_g: Vector2 = delta_g.normalized() if delta_g != Vector2.ZERO else paim
				_hurt_enemy(enemy, 46.0 * damage_multiplier, dir_g, 1600.0, true, true, false, false)
		_break_urns_in_radius(ppos, radius_g)
	elif weapon_id == &"veu":
		var radius_v: float = 460.0
		var candidates_v: Array[Dictionary] = []
		for enemy: Dictionary in enemies:
			if not _hittable(enemy): continue
			if ppos.distance_to(enemy.pos) <= radius_v + float(enemy.radius):
				candidates_v.append(enemy)
		candidates_v.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return ppos.distance_squared_to(a.pos) < ppos.distance_squared_to(b.pos)
		)
		var targets_v: Array[Vector2] = []
		var count_v: int = mini(5, candidates_v.size())
		for idx_v: int in range(count_v):
			var target_v: Dictionary = candidates_v[idx_v]
			var tpos_v: Vector2 = target_v.pos
			targets_v.append(tpos_v)
			var delta_v: Vector2 = tpos_v - ppos
			var dir_v: Vector2 = delta_v.normalized() if delta_v != Vector2.ZERO else paim
			_hurt_enemy(target_v, 48.0 * damage_multiplier, dir_v, 480.0, true, true, true, false)
		var fx_v: Dictionary = _effect("selo_veu", ppos, paim, 0.5)
		fx_v["targets"] = targets_v
	else:
		var radius_l: float = 320.0
		var fx_l: Dictionary = _effect("selo_lamina", ppos, paim, 0.55)
		fx_l["radius"] = radius_l
		for enemy: Dictionary in enemies:
			if not _hittable(enemy): continue
			var delta_l: Vector2 = enemy.pos - ppos
			if delta_l.length() <= radius_l + float(enemy.radius):
				var dir_l: Vector2 = delta_l.normalized() if delta_l != Vector2.ZERO else paim
				_hurt_enemy(enemy, 58.0 * damage_multiplier, dir_l, 1400.0, true, true, false, false)
		_break_urns_in_radius(ppos, radius_l)

func _break_urns_in_radius(center: Vector2, radius: float) -> void:
	if urns.is_empty(): return
	var remaining_urns: Array[Dictionary] = []
	for urn: Dictionary in urns:
		var urn_pos: Vector2 = urn.pos
		if center.distance_to(urn_pos) <= radius:
			_break_urn(urn)
		else:
			remaining_urns.append(urn)
	urns = remaining_urns

func _break_urn(urn: Dictionary) -> void:
	urn.hp = 0
	urns_broken_total += 1
	var urn_pos: Vector2 = urn.pos
	var urn_kind: String = String(urn.get("kind", "frag"))
	if urn_kind == "heal":
		player.hp = minf(float(player.max_hp), float(player.hp) + 10.0)
		var heal_fx: Dictionary = _effect("dmg_num", urn_pos + Vector2(0.0, -36.0), Vector2.UP, 0.72)
		heal_fx["amount"] = 10
		heal_fx["text"] = "+10"
		heal_fx["kind_num"] = "heal"
	var break_fx: Dictionary = _effect("urn_break", urn_pos, Vector2.UP, 0.45)
	break_fx["urn_kind"] = urn_kind

func _dash_cut() -> void:
	if not blessing_counts.has("corte_esquiva"): return
	var blessing: Dictionary = {}
	for entry: Dictionary in data.bencaos:
		if entry.id == "corte_esquiva": blessing = entry
	if blessing.is_empty(): return
	for enemy: Dictionary in enemies:
		if not _hittable(enemy) or player.dash_hits.has(enemy.id): continue
		var reach: float = player.radius+enemy.radius+float(blessing.alcance_extra_px)
		if player.pos.distance_squared_to(enemy.pos) <= reach*reach:
			player.dash_hits[enemy.id] = true
			_hurt_enemy(enemy,float(blessing.valor)*int(blessing_counts.corte_esquiva)*damage_multiplier,player.dash_dir,float(blessing.empurrao),false,false)

func _hittable(enemy: Dictionary) -> bool:
	return enemy.hp > 0 and enemy.phase != "spawn"

func _hurt_enemy(enemy: Dictionary, damage: float, direction: Vector2, push: float, heavy: bool, stop: bool, force_crit: bool = false, grant_flow: bool = true) -> void:
	var final_damage: float = damage
	if domain_timer > 0.0:
		final_damage *= 1.25
	var effective_crit: float = clampf(crit_chance + (0.25 if domain_timer > 0.0 else 0.0), 0.0, 0.95)
	var is_crit: bool = false
	if force_crit:
		is_crit = true
	elif effective_crit > 0.0 and _integer(1000) < roundi(effective_crit * 1000.0):
		final_damage *= 1.8
		is_crit = true
	enemy.hp = maxf(0.0, float(enemy.hp) - final_damage)
	enemy.flash = Movement.ticks(data.combate.flash_acerto_s)
	var is_resistant: bool = bool(enemy.get("elite", false)) or bool(enemy.get("is_boss", false))
	var push_scale: float = float(data.elite.empurrao_x) if is_resistant else 1.0
	enemy.knockback = direction * push * push_scale * knockback_mult
	if heavy and not is_resistant:
		enemy.phase = "recover"
		enemy.timer = Movement.ticks(data.combate.quebrou_recuperacao_s)
	if grant_flow:
		var flow_gain: float = (14.0 if heavy else 8.0) * (1.0 + minf(0.6, float(player.combo_hits) * 0.04))
		player.flow = minf(100.0, float(player.flow) + flow_gain)
	player.combo_hits = int(player.combo_hits) + 1
	player.combo_timer = 180
	_effect("crit" if is_crit else "hit", enemy.pos, direction, float(data.combate.flash_acerto_s) * (1.8 if is_crit else 1.0))
	var dmg_fx: Dictionary = _effect("dmg_num", enemy.pos + Vector2(0.0, -52.0), Vector2.UP, 0.72)
	dmg_fx["amount"] = roundi(final_damage)
	dmg_fx["crit"] = is_crit
	dmg_fx["kind_num"] = "crit" if is_crit else "dmg"
	if stop:
		_pending_hitstop = maxi(_pending_hitstop,Movement.ticks(data.combate.hitstop_pesado_s if heavy else data.combate.hitstop_leve_s))

func _hurt_player(damage: float, origin: Vector2) -> void:
	if player.inv > 0 or player.hp <= 0: return
	var dano_final: float = float(maxi(1, roundi(damage)))
	if player_shield > 0.0:
		var absorvido: float = minf(player_shield, dano_final)
		player_shield -= absorvido
		dano_final -= absorvido
	if dano_final > 0.0:
		player.hp = maxf(0.0, float(player.hp) - dano_final)
	player.inv = Movement.ticks(data.combate.invuln_atingido_s)
	player.flash = Movement.ticks(data.combate.flash_acerto_s)
	_pending_hitstop = maxi(_pending_hitstop,Movement.ticks(data.combate.hitstop_atingido_s))
	_effect("hurt",player.pos,(player.pos-origin).normalized(),float(data.combate.flash_acerto_s)*2.0)
	var hurt_fx: Dictionary = _effect("dmg_num", player.pos + Vector2(0.0, -52.0), Vector2.UP, 0.72)
	hurt_fx["amount"] = roundi(dano_final)
	hurt_fx["kind_num"] = "player_hurt"

func enemy_def(kind: String) -> Dictionary:
	return _enemy_def(kind)

func _enemy_def(kind: String) -> Dictionary:
	if data.inimigos.has(kind):
		return data.inimigos[kind]
	match kind:
		"vulto_mudo":
			return {
				"nome": "Vulto Mudo",
				"comportamento": "melee",
				"vida": 32.0,
				"velocidade": 215.0,
				"raio": 23.0,
				"dano": 10.0,
				"preparo_s": 0.34,
				"recarga_s": 0.72,
				"execucao_passos": 8,
				"inicio_preparo_px": 105.0,
				"tele_raio_px": 115.0,
				"tele_meio_angulo_graus": 65.0,
				"pattern": "lunge",
			}
		"espreitador_da_fenda":
			return {
				"nome": "Espreitador da Fenda",
				"comportamento": "melee",
				"vida": 38.0,
				"velocidade": 190.0,
				"raio": 24.0,
				"dano": 13.0,
				"preparo_s": 0.48,
				"recarga_s": 0.95,
				"execucao_passos": 8,
				"inicio_preparo_px": 260.0,
				"tele_raio_px": 120.0,
				"tele_meio_angulo_graus": 75.0,
				"pattern": "shadow_blink",
			}
		"baluarte_de_cinza":
			return {
				"nome": "Baluarte de Cinza",
				"comportamento": "melee",
				"vida": 78.0,
				"velocidade": 96.0,
				"raio": 36.0,
				"dano": 16.0,
				"preparo_s": 0.65,
				"recarga_s": 1.15,
				"execucao_passos": 10,
				"inicio_preparo_px": 135.0,
				"tele_raio_px": 165.0,
				"tele_meio_angulo_graus": 145.0,
				"pattern": "quake",
			}
		"fenda_errante":
			return {
				"nome": "Fenda Errante",
				"comportamento": "ranged",
				"vida": 34.0,
				"velocidade": 110.0,
				"raio": 25.0,
				"dano": 9.0,
				"preparo_s": 0.62,
				"recarga_s": 1.45,
				"execucao_passos": 8,
				"proj_velocidade_pxs": 360.0,
				"proj_raio_px": 12.0,
				"proj_vida_passos": 210,
				"tele_largura_px": 70.0,
				"tele_comprimento_max_px": 1200.0,
				"boss_pattern": "ring_6",
			}
		"anomalia_maior":
			return {
				"nome": "Anomalia Maior",
				"comportamento": "melee",
				"vida": 240.0,
				"velocidade": 108.0,
				"raio": 52.0,
				"dano": 16.0,
				"preparo_s": 0.6667,
				"recarga_s": 1.0,
				"execucao_passos": 10,
				"inicio_preparo_px": 140.0,
				"tele_raio_px": 165.0,
				"tele_meio_angulo_graus": 85.0,
				"is_boss": true,
			}
		"soberano_do_limiar":
			return {
				"nome": "Soberano do Limiar",
				"comportamento": "melee",
				"vida": 700.0,
				"velocidade": 112.0,
				"raio": 52.0,
				"dano": 16.0,
				"preparo_s": 0.62,
				"recarga_s": 0.95,
				"execucao_passos": 10,
				"inicio_preparo_px": 155.0,
				"tele_raio_px": 190.0,
				"tele_meio_angulo_graus": 95.0,
				"is_boss": true,
			}
		"guardiao_do_rito":
			return {
				"nome": "Guardião do Rito",
				"comportamento": "ranged",
				"vida": 950.0,
				"velocidade": 120.0,
				"raio": 54.0,
				"dano": 14.0,
				"preparo_s": 0.58,
				"recarga_s": 1.25,
				"execucao_passos": 8,
				"proj_velocidade_pxs": 450.0,
				"proj_raio_px": 15.0,
				"proj_vida_passos": 240,
				"tele_largura_px": 90.0,
				"tele_comprimento_max_px": 1728.0,
				"boss_pattern": "fan_3",
				"is_boss": true,
			}
		"colosso_de_cinza":
			return {
				"nome": "Colosso de Cinza",
				"comportamento": "melee",
				"vida": 1150.0,
				"velocidade": 98.0,
				"raio": 64.0,
				"dano": 24.0,
				"preparo_s": 0.72,
				"recarga_s": 1.15,
				"execucao_passos": 12,
				"inicio_preparo_px": 210.0,
				"tele_raio_px": 260.0,
				"tele_meio_angulo_graus": 120.0,
				"is_boss": true,
			}
		"arconte_da_fenda":
			return {
				"nome": "Arconte da Fenda",
				"comportamento": "ranged",
				"vida": 1400.0,
				"velocidade": 128.0,
				"raio": 56.0,
				"dano": 18.0,
				"preparo_s": 0.55,
				"recarga_s": 1.20,
				"execucao_passos": 8,
				"proj_velocidade_pxs": 480.0,
				"proj_raio_px": 15.0,
				"proj_vida_passos": 240,
				"tele_largura_px": 95.0,
				"tele_comprimento_max_px": 1728.0,
				"boss_pattern": "fan_5_summon",
				"is_boss": true,
			}
	return {}

func _sortear_oferta_campanha(apos_chefe: bool) -> Array[Dictionary]:
	var idx: int = region_index * 10 + region_wave_index
	var oferta: Array[Dictionary] = CatalogoCampanha.sortear_oferta(seed_value, idx, taken_boons)
	if apos_chefe:
		for tentativa: int in range(1, 7):
			var tem_alta: bool = false
			for carta: Dictionary in oferta:
				var raridade: String = String(carta.get("raridade", "comum")).to_lower()
				if raridade == "rara" or raridade == "epica":
					tem_alta = true
					break
			if tem_alta:
				break
			oferta = CatalogoCampanha.sortear_oferta(seed_value + tentativa * 97, idx + tentativa, taken_boons)
	return oferta

func _append_enemy(kind: String, pos: Vector2, elite: bool, hp_mult: float = 1.0) -> void:
	var definition: Dictionary = _enemy_def(kind)
	if definition.is_empty():
		return
	var is_boss: bool = bool(definition.get("is_boss", false))
	var hp: float = roundf(float(definition.vida) * (1.0 if is_boss else hp_mult))
	var radius: float = float(definition.raio)
	if elite and not is_boss:
		hp = roundf(hp * float(data.elite.vida_x) * (1.0 + float(data.elite.vida_por_profundidade) * float(data.profundidade)))
		radius *= float(data.elite.raio_x)
	_next_id += 1
	enemies.append({
		"id": _next_id,
		"kind": kind,
		"pos": pos,
		"prev": pos,
		"hp": hp,
		"max_hp": hp,
		"radius": radius,
		"elite": elite,
		"is_boss": is_boss,
		"boss_name": String(definition.get("nome", kind)),
		"phase": "spawn",
		"timer": Movement.ticks(data.ia.surgimento_s),
		"aim": Vector2.DOWN,
		"knockback": Vector2.ZERO,
		"flash": 0,
		"wait": int(data.ia.espera_inicial_base) + _integer(int(data.ia.espera_inicial_extra) + 1)
	})

func interagir_na_sala() -> Dictionary:
	if state != "jogo" or player.is_empty():
		return {}
	if active_interactive_index >= 0 and active_interactive_index < room_interactives.size():
		var obj: Dictionary = room_interactives[active_interactive_index]
		if not bool(obj.get("usado", false)):
			obj["usado"] = true
			active_interactive_index = -1
			var kind: String = String(obj.get("kind", ""))
			var obj_pos_raw: Variant = obj.get("pos", player["pos"])
			var obj_pos: Vector2 = obj_pos_raw as Vector2 if obj_pos_raw is Vector2 else (player["pos"] as Vector2)
			match kind:
				"monolito_lore":
					pending_lore_eco_id = String(obj.get("eco_id", ""))
					return {"tipo": "lore", "eco_id": pending_lore_eco_id}
				"fonte_cura":
					var cura: float = 45.0
					player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + cura)
					var heal_fx: Dictionary = _effect("dmg_num", (player["pos"] as Vector2) + Vector2(0.0, -36.0), Vector2.UP, 0.72)
					heal_fx["amount"] = 45
					heal_fx["text"] = "+45"
					heal_fx["kind_num"] = "heal"
					heal_fx["heal"] = true
					return {"tipo": "cura", "valor": 45}
				"bau_reliquia":
					damage_multiplier += 0.12
					_effect("crit", obj_pos, Vector2.UP, 0.35)
					return {"tipo": "bau", "frag": 25}
				"altar_pacto":
					var custo: float = minf(18.0, maxf(0.0, float(player["hp"]) - 1.0))
					player["hp"] = maxf(1.0, float(player["hp"]) - custo)
					damage_multiplier += 0.22
					crit_chance = clampf(crit_chance + 0.15, 0.0, 0.95)
					var pact_fx: Dictionary = _effect("dmg_num", (player["pos"] as Vector2) + Vector2(0.0, -52.0), Vector2.UP, 0.72)
					pact_fx["amount"] = roundi(custo)
					pact_fx["kind_num"] = "player_hurt"
					pact_fx["player_hurt"] = true
					_effect("crit", player["pos"] as Vector2, Vector2.UP, 0.35)
					return {"tipo": "pacto", "custo": roundi(custo)}
	if room_cleared and active_door_index >= 0 and active_door_index < exit_doors.size():
		var porta: Dictionary = exit_doors[active_door_index]
		if bool(porta.get("is_region_portal", false)):
			_advancing_region = true
			_pending_door_dest = -1
		else:
			_advancing_region = false
			_pending_door_dest = int(porta.get("destino_idx", -1))
		transition_progress = 0.0
		_transition_cut = false
		state = "transicao"
		return {"tipo": "porta", "porta": porta}
	return {}

func _iniciar_mapa_regiao(r_idx: int) -> void:
	if mapa == null:
		return
	var reg_id: String = String(current_region.get("id", "limiar"))
	mapa.gerar_regiao(reg_id, r_idx, seed_value + r_idx * 7919)
	_carregar_sala_do_mapa()

func _carregar_sala_do_mapa() -> void:
	if mapa == null:
		return
	var sala: Dictionary = mapa.sala_atual()
	var largura: float = float(sala.get("largura", 2800.0))
	var altura: float = float(sala.get("altura", 1560.0))
	var arena_dict: Dictionary = data["arena"] as Dictionary
	arena_dict["largura"] = largura
	arena_dict["altura"] = altura
	var pilares_copia: Array = []
	var pilares_src_raw: Variant = sala.get("pilares", [])
	if pilares_src_raw is Array:
		var pilares_src: Array = pilares_src_raw as Array
		for p_var: Variant in pilares_src:
			if p_var is Dictionary:
				pilares_copia.append((p_var as Dictionary).duplicate(true))
	arena_dict["pilares"] = pilares_copia

	var jogador_dict: Dictionary = data["jogador"] as Dictionary
	jogador_dict["spawn"] = [largura * 0.5, altura - 220.0]

	room_props.clear()
	var props_src_raw: Variant = sala.get("props", [])
	if props_src_raw is Array:
		var props_src: Array = props_src_raw as Array
		for pr_var: Variant in props_src:
			if pr_var is Dictionary:
				room_props.append((pr_var as Dictionary).duplicate(true))

	room_interactives.clear()
	var int_src_raw: Variant = sala.get("interativos", [])
	if int_src_raw is Array:
		var int_src: Array = int_src_raw as Array
		for it_var: Variant in int_src:
			if it_var is Dictionary:
				room_interactives.append((it_var as Dictionary).duplicate(true))

	var spawn_pos: Vector2 = Vector2(largura * 0.5, altura - 220.0)
	if not player.is_empty():
		Movement.teleport(player, spawn_pos)

	var tipo: String = String(sala.get("tipo", "combate"))
	if tipo == "chefe":
		region_wave_index = 2
	elif tipo in ["emboscada", "combate_denso", "elite_guarda"]:
		region_wave_index = 1
	else:
		region_wave_index = 0

	enemies.clear()
	projectiles.clear()
	effects.clear()
	allied_curses.clear()
	urns.clear()
	pending_lore_eco_id = ""
	pending_blessing_claimed = false
	active_door_index = -1
	active_interactive_index = -1

	if tipo in ["santuario_cura", "altar_pacto"]:
		room_cleared = true
		mapa.marcar_limpa()
		exit_doors = mapa.portas_da_sala_atual()
		if shield_per_room > 0.0:
			player_shield = shield_per_room
	else:
		room_cleared = false
		exit_doors.clear()
		_spawn_wave()

func _atualizar_proximidade_sala() -> void:
	active_interactive_index = -1
	active_door_index = -1
	if player.is_empty():
		return
	var ppos: Vector2 = player["pos"] as Vector2
	for i: int in range(room_interactives.size()):
		var obj: Dictionary = room_interactives[i]
		if bool(obj.get("usado", false)):
			continue
		var obj_pos_raw: Variant = obj.get("pos", Vector2.ZERO)
		var obj_pos: Vector2 = obj_pos_raw as Vector2 if obj_pos_raw is Vector2 else Vector2.ZERO
		if ppos.distance_to(obj_pos) <= 115.0:
			active_interactive_index = i
			break
	if room_cleared:
		for j: int in range(exit_doors.size()):
			var porta: Dictionary = exit_doors[j]
			var porta_pos_raw: Variant = porta.get("pos", Vector2.ZERO)
			var porta_pos: Vector2 = porta_pos_raw as Vector2 if porta_pos_raw is Vector2 else Vector2.ZERO
			if ppos.distance_to(porta_pos) <= 125.0:
				active_door_index = j
				break

func _spawn_wave() -> void:
	enemies.clear()
	urns.clear()
	if shield_per_room > 0.0:
		player_shield = shield_per_room
	if extended_campaign:
		var arena_dict: Dictionary = data["arena"] as Dictionary
		var largura_a: float = float(arena_dict.get("largura", 2400.0))
		var altura_a: float = float(arena_dict.get("altura", 1350.0))
		urns = [
			{"pos": Vector2(300.0, 280.0), "hp": 1, "kind": "heal"},
			{"pos": Vector2(largura_a - 300.0, 280.0), "hp": 1, "kind": "frag"},
			{"pos": Vector2(300.0, altura_a - 260.0), "hp": 1, "kind": "frag"},
			{"pos": Vector2(largura_a - 300.0, altura_a - 260.0), "hp": 1, "kind": "heal"},
		]
		var cx: float = largura_a * 0.5
		var hp_mult: float = 1.0 + float(region_index) * 0.22
		var sala_tipo: String = ""
		if mapa != null:
			var sala_now: Dictionary = mapa.sala_atual()
			sala_tipo = String(sala_now.get("tipo", ""))
		if region_wave_index >= 2 or sala_tipo == "chefe":
			var boss_ids: Array[String] = ["soberano_do_limiar", "guardiao_do_rito", "colosso_de_cinza", "arconte_da_fenda"]
			var boss_id: String = boss_ids[clampi(region_index, 0, boss_ids.size() - 1)]
			var boss_pos: Vector2 = Movement.resolve(Vector2(cx, 360.0), 58.0, data.arena)
			_append_enemy(boss_id, boss_pos, false, 1.0)
			if region_index == 0:
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx - 320.0, 320.0), 26.0, data.arena), false, hp_mult)
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx + 320.0, 320.0), 26.0, data.arena), false, hp_mult)
			elif region_index == 1:
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx - 340.0, 320.0), 26.0, data.arena), false, hp_mult)
				_append_enemy("anomalia_menor", Movement.resolve(Vector2(cx + 340.0, 320.0), 26.0, data.arena), false, hp_mult)
			elif region_index == 2:
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx - 360.0, 330.0), 26.0, data.arena), false, hp_mult)
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx + 360.0, 330.0), 26.0, data.arena), false, hp_mult)
			else:
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx - 340.0, 320.0), 26.0, data.arena), false, hp_mult)
				_append_enemy("eco_perdido", Movement.resolve(Vector2(cx + 340.0, 320.0), 26.0, data.arena), false, hp_mult)
			return
		var reg_ondas_raw: Variant = current_region.get("ondas", [])
		var reg_ondas: Array = reg_ondas_raw as Array if reg_ondas_raw is Array else []
		var spawns_ext: Array = []
		if region_wave_index >= 0 and region_wave_index < reg_ondas.size():
			spawns_ext = (reg_ondas[region_wave_index] as Array).duplicate()
		else:
			var base_idx: int = clampi(region_wave_index, 0, data.ondas.size() - 1)
			spawns_ext = data.ondas[base_idx].duplicate()
		var scale_x: float = largura_a / 2400.0 if mapa != null else 1.0
		var scale_y: float = altura_a / 1350.0 if mapa != null else 1.0
		for spawn_var: Variant in spawns_ext:
			if spawn_var is Dictionary:
				var spawn_ext: Dictionary = spawn_var as Dictionary
				var raw_pos: Vector2 = Vector2(float(spawn_ext["x"]) * scale_x, float(spawn_ext["y"]) * scale_y)
				var safe_pos: Vector2 = Movement.resolve(raw_pos, 40.0, data.arena) if mapa != null else raw_pos
				_append_enemy(String(spawn_ext["id"]), safe_pos, bool(spawn_ext.get("elite", false)), hp_mult)
		if sala_tipo == "elite_guarda":
			var guarda_kind: String = "baluarte_de_cinza" if region_index >= 1 else "vulto_mudo"
			var guarda_pos: Vector2 = Movement.resolve(Vector2(cx, 260.0), 44.0, data.arena)
			_append_enemy(guarda_kind, guarda_pos, true, hp_mult)
		return
	var spawns: Array = data.ondas[wave_index].duplicate()
	if include_boss_in_final_wave and wave_index >= data.ondas.size() - 1:
		var has_boss := false
		for s: Dictionary in spawns:
			if String(s.get("id", "")) == "anomalia_maior":
				has_boss = true
				break
		if not has_boss:
			spawns.append({"id": "anomalia_maior", "x": float(data.arena.largura) * 0.5, "y": 220.0})
	for spawn: Dictionary in spawns:
		_append_enemy(String(spawn.id), Vector2(float(spawn.x), float(spawn.y)), bool(spawn.get("elite", false)), 1.0)

func _enemy_step(enemy: Dictionary) -> void:
	var definition: Dictionary = _enemy_def(enemy.kind)
	enemy.flash = maxi(0,int(enemy.flash)-1)
	if enemy.phase == "spawn":
		enemy.timer -= 1
		if enemy.timer <= 0: enemy.phase = "chase"
		return
	if enemy.knockback.length() > float(data.combate.empurrao_zero):
		enemy.pos = Movement.resolve(enemy.pos+enemy.knockback/TICK_RATE,enemy.radius,data.arena)
		enemy.knockback *= float(data.combate.queda_empurrao)
	else: enemy.knockback = Vector2.ZERO
	var delta: Vector2 = player.pos-enemy.pos
	var distance := delta.length()
	if enemy.phase == "windup":
		enemy.timer -= 1
		if enemy.timer <= 0:
			_enemy_fire(enemy,definition)
			enemy.phase = "recover"
			enemy.timer = Movement.ticks(definition.recarga_s)
		return
	if enemy.phase == "recover":
		enemy.timer -= 1
		if enemy.timer <= 0:
			enemy.phase = "chase"
			enemy.wait = int(data.ia.espera_base)+_integer(int(data.ia.espera_extra)+1)
		return
	var direction := delta.normalized()
	var attack_range: float = definition.inicio_preparo_px if definition.comportamento == "melee" else data.ia.ranged_ataque_px
	if enemy.wait > 0: enemy.wait -= 1
	if enemy.wait == 0 and distance <= attack_range:
		enemy.phase = "windup"
		enemy.timer = Movement.ticks(definition.preparo_s)
		enemy.aim = direction if direction != Vector2.ZERO else Vector2.DOWN
		return
	if definition.comportamento == "ranged":
		if distance < float(data.ia.ranged_perto_px):
			var arena_w: float = float(data.arena.largura)
			var arena_h: float = float(data.arena.altura)
			var arena_m: float = float(data.arena.margem)
			var perto_borda: bool = enemy.pos.y < arena_m + 210.0 or enemy.pos.y > arena_h - arena_m - 170.0 or enemy.pos.x < arena_m + 210.0 or enemy.pos.x > arena_w - arena_m - 210.0
			if perto_borda:
				var centro: Vector2 = Vector2(arena_w * 0.5, arena_h * 0.5)
				var para_centro: Vector2 = (centro - enemy.pos).normalized()
				var lado: float = 1.0 if (int(enemy.id) % 2 == 0) else -1.0
				var tangente: Vector2 = Vector2(-direction.y, direction.x) * lado
				direction = (tangente * 0.72 + para_centro * 0.68).normalized()
			else:
				direction = -direction
		elif distance <= float(data.ia.ranged_longe_px): direction = Vector2.ZERO
	enemy.pos = Movement.resolve(enemy.pos+direction*float(definition.velocidade)/TICK_RATE,enemy.radius,data.arena)

func _enemy_fire(enemy: Dictionary, definition: Dictionary) -> void:
	var damage: float = float(definition.dano)*(float(data.elite.dano_x) if enemy.elite else 1.0)
	var boss_pattern: String = String(definition.get("boss_pattern", ""))
	if boss_pattern == "ring_6":
		for i: int in range(6):
			var ang: float = TAU * float(i) / 6.0
			var dir: Vector2 = enemy.aim.rotated(ang)
			var pos_p: Vector2 = enemy.pos + dir * float(data.combate.nascimento_projetil_px)
			projectiles.append({"pos": pos_p, "prev": pos_p, "radius": float(definition.proj_raio_px), "velocity": dir * float(definition.proj_velocidade_pxs), "remaining": int(definition.proj_vida_passos), "damage": damage})
		return
	if boss_pattern == "fan_3":
		for ang: float in [-0.28, 0.0, 0.28]:
			var dir: Vector2 = enemy.aim.rotated(ang)
			var pos_p: Vector2 = enemy.pos + dir * float(data.combate.nascimento_projetil_px)
			projectiles.append({"pos": pos_p, "prev": pos_p, "radius": float(definition.proj_raio_px), "velocity": dir * float(definition.proj_velocidade_pxs), "remaining": int(definition.proj_vida_passos), "damage": damage})
		return
	if boss_pattern == "fan_5_summon":
		for ang: float in [-0.44, -0.22, 0.0, 0.22, 0.44]:
			var dir: Vector2 = enemy.aim.rotated(ang)
			var pos_p: Vector2 = enemy.pos + dir * float(data.combate.nascimento_projetil_px)
			projectiles.append({"pos": pos_p, "prev": pos_p, "radius": float(definition.proj_raio_px), "velocity": dir * float(definition.proj_velocidade_pxs), "remaining": int(definition.proj_vida_passos), "damage": damage})
		if enemies.size() < 3:
			var summon_pos: Vector2 = Movement.resolve(enemy.pos + enemy.aim.orthogonal() * 110.0, 24.0, data.arena)
			_append_enemy("eco_perdido", summon_pos, false, 1.0 + float(region_index) * 0.22)
		return
	if definition.comportamento == "ranged":
		var position: Vector2 = enemy.pos+enemy.aim*float(data.combate.nascimento_projetil_px)
		projectiles.append({"pos":position,"prev":position,"radius":float(definition.proj_raio_px),"velocity":enemy.aim*float(definition.proj_velocidade_pxs),"remaining":int(definition.proj_vida_passos),"damage":damage})
	else:
		var pattern: String = String(definition.get("pattern", ""))
		if pattern == "lunge":
			enemy.pos = Movement.resolve(enemy.pos + enemy.aim * 70.0, float(enemy.radius), data.arena)
		elif pattern == "shadow_blink":
			_effect("veu_blink", enemy.pos, enemy.aim, 0.24)
			var blink_target: Vector2 = Movement.resolve(player.pos - enemy.aim * 70.0, float(enemy.radius), data.arena)
			enemy.pos = blink_target
			enemy.prev = blink_target
			var to_player: Vector2 = player.pos - enemy.pos
			if to_player != Vector2.ZERO:
				enemy.aim = to_player.normalized()
			_effect("veu_blink", enemy.pos, enemy.aim, 0.24)
		var delta: Vector2 = player.pos-enemy.pos
		if String(enemy.kind) == "colosso_de_cinza":
			var impact_pos: Vector2 = Movement.resolve(enemy.pos + enemy.aim * 96.0, 24.0, data.arena)
			var slam_fx := _effect("colosso_slam", impact_pos, enemy.aim, 0.72)
			slam_fx["radius"] = float(definition.tele_raio_px)
			slam_fx["origin"] = enemy.pos
		elif pattern == "quake":
			var impact_pos_q: Vector2 = Movement.resolve(enemy.pos + enemy.aim * 40.0, 20.0, data.arena)
			var slam_fx_q: Dictionary = _effect("colosso_slam", impact_pos_q, enemy.aim, 0.52)
			slam_fx_q["radius"] = float(definition.tele_raio_px)
			slam_fx_q["origin"] = enemy.pos
		else:
			var effect := _effect("enemy_attack",enemy.pos,enemy.aim,float(definition.execucao_passos)/TICK_RATE)
			effect["radius"] = float(definition.tele_raio_px)
			effect["angle"] = deg_to_rad(float(definition.tele_meio_angulo_graus))
		if delta.length() <= float(definition.tele_raio_px)+player.radius and (delta == Vector2.ZERO or enemy.aim.dot(delta.normalized()) >= cos(deg_to_rad(float(definition.tele_meio_angulo_graus)))):
			_hurt_player(damage,enemy.pos)

func _projectile_step() -> void:
	var survivors: Array[Dictionary] = []
	for projectile: Dictionary in projectiles:
		projectile.pos += projectile.velocity/TICK_RATE
		projectile.remaining -= 1
		var position: Vector2 = projectile.pos
		var destroyed: bool = projectile.remaining <= 0 or position.x < 0 or position.y < 0 or position.x > data.arena.largura or position.y > data.arena.altura
		for obstacle: Dictionary in data.arena.pilares:
			if position.distance_to(Vector2(obstacle.x,obstacle.y)) <= float(obstacle.r)+projectile.radius: destroyed = true
		if destroyed: continue
		if projectile.get("owner", "enemy") == "player":
			for enemy: Dictionary in enemies:
				if not _hittable(enemy): continue
				if position.distance_to(enemy.pos) <= projectile.radius+enemy.radius:
					var vel: Vector2 = projectile.get("velocity", Vector2.ZERO)
					var dir: Vector2 = vel.normalized() if vel != Vector2.ZERO else player.aim
					_hurt_enemy(enemy,float(projectile.damage),dir,float(projectile.get("push", 0.0)),false,true)
					destroyed = true
					break
			if not destroyed and not urns.is_empty():
				var remaining_urns: Array[Dictionary] = []
				var hit_urn: bool = false
				for urn: Dictionary in urns:
					var urn_pos: Vector2 = urn.pos
					if not hit_urn and position.distance_to(urn_pos) <= 32.0:
						_break_urn(urn)
						hit_urn = true
						destroyed = true
					else:
						remaining_urns.append(urn)
				if hit_urn:
					urns = remaining_urns
		else:
			if position.distance_to(player.pos) <= projectile.radius+player.radius:
				_hurt_player(projectile.damage,projectile.prev)
				destroyed = true
		if not destroyed: survivors.append(projectile)
	projectiles = survivors

func _remove_dead() -> void:
	var survivors: Array[Dictionary] = []
	for enemy: Dictionary in enemies:
		if enemy.hp <= 0:
			kills += 1
			last_killed_kinds.append(String(enemy.kind))
			if life_on_kill > 0.0 and not player.is_empty() and float(player.hp) > 0.0:
				player.hp = minf(float(player.max_hp), float(player.hp) + life_on_kill)
			if weapon_id == &"pactos" and not player.is_empty():
				player["curses_absorbed"] = mini(int(player.get("curses_max", 6)), int(player.get("curses_absorbed", 0)) + 1)
				var e_pos: Vector2 = enemy["pos"] as Vector2
				var p_pos: Vector2 = player["pos"] as Vector2
				var abs_delta: Vector2 = p_pos - e_pos
				var abs_dir: Vector2 = abs_delta.normalized() if abs_delta != Vector2.ZERO else Vector2.UP
				var abs_fx: Dictionary = _effect("curse_absorb", e_pos, abs_dir, 0.38)
				abs_fx["target"] = p_pos
			var death_fx := _effect("death",enemy.pos,enemy.aim,float(data.ia.surgimento_s))
			death_fx["actor_kind"] = enemy.kind
			death_fx["elite"] = enemy.elite
			_pending_hitstop = maxi(_pending_hitstop,Movement.ticks(data.combate.hitstop_abate_s))
		else: survivors.append(enemy)
	enemies = survivors

func _effect(kind: String, position: Vector2, direction: Vector2, duration: float) -> Dictionary:
	var value := {"kind":kind,"pos":position,"dir":direction,"age":0.0,"duration":duration}
	effects.append(value)
	return value

func _integer(limit: int) -> int:
	# Fluxo `ia` (finalidade 7): consumo não garantido, depende do combate (GDD rng-com-seed R3).
	return _fluxo_ia.inteiro(limit)

## Relator padrão quando o ponto de composição não injeta um (fatia atual).
class _RelatorDeAvisosRng extends RelatorDeErrosRng:
	func registrar_operacao_invalida(operacao: StringName, motivo: String) -> void:
		push_warning("RNG: operação %s recusada: %s" % [operacao,motivo])
	func registrar_pedido_recusado(finalidade: int, regiao: int, profundidade: int, solicitante: StringName, motivo: String) -> void:
		push_warning("RNG: fluxo (%d, %d, %d) recusado para %s: %s" % [finalidade,regiao,profundidade,solicitante,motivo])
	func registrar_aviso(mensagem: String) -> void:
		push_warning("RNG: %s" % mensagem)
