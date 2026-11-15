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
var presentation_time := 0.0
var live_steps := 0
var seed_value := 1
var transition_progress := 0.0
var blessing_counts: Dictionary = {}
var _resume_state := "jogo"
var _rng_state := 1
var _next_id := 0
var _pending_hitstop := 0
var _transition_cut := false

## Installs validated data without starting the run.
func configure(tuning: Dictionary, seed: int = 1) -> void:
	data = tuning.duplicate(true)
	seed_value = seed & MASK
	state = "menu"

## Starts/restarts a clean run from its fixed seed and initial loadout.
func start() -> void:
	_rng_state = seed_value
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
	damage_multiplier = 1.0
	blessing_counts.clear()
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
		"lunge_hits":{}, "flash":0
	}
	state = "jogo"
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
	if state != "bencao" or index < 0 or index >= data.bencaos.size(): return
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
	for key in ["inv","attack_cd","special_cd","recovery","combo_window","flash"]:
		player[key] = maxi(0,int(player[key])-1)
	if player.combo_window == 0: player.combo = 0
	var aim: Vector2 = sample.get("aim",Vector2.UP)
	if aim != Vector2.ZERO: player.aim = aim.normalized()
	var move: Vector2 = sample.get("move",Vector2.ZERO)
	var wants: Dictionary = sample.get("wants",{})
	Movement.recharge(player,Movement.ticks(data.esquiva.recarga_s))
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
		player.pos += move.normalized() * minf(1.0,move.length()) * float(data.jogador.velocidade) * recovery / TICK_RATE
	if dashed: _dash_cut()
	player.pos = Movement.resolve(player.pos,player.radius,data.arena)
	if player.lunge_remaining > 0:
		_lunge_hits()
		player.lunge_remaining -= 1
	elif player.dash_remaining == 0:
		if wants.get("especial",false) and player.special_cd == 0:
			_start_lunge()
			consumed.append("especial")
		elif wants.get("ataque",false) and player.attack_cd == 0:
			_attack()
			consumed.append("ataque")
	for enemy: Dictionary in enemies:
		if enemy.hp > 0: _enemy_step(enemy)
	_projectile_step()
	_remove_dead()
	hitstop = maxi(hitstop,_pending_hitstop)
	if player.hp <= 0:
		state = "morte"
	elif enemies.is_empty() and hitstop == 0:
		projectiles.clear()
		state = "vitoria" if wave_index + 1 >= data.ondas.size() else "bencao"
	return consumed

func _freeze() -> void:
	Movement.freeze(player)
	for enemy: Dictionary in enemies: enemy.prev = enemy.pos
	for projectile: Dictionary in projectiles: projectile.prev = projectile.pos

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
	var combo: Array = data.corte.combo
	var multiplier: float = combo[int(player.combo) % combo.size()]
	player.combo = (int(player.combo)+1) % combo.size()
	player.combo_window = Movement.ticks(data.combate.janela_combo_s)
	player.attack_cd = Movement.ticks(data.corte.recarga_s)
	player.recovery = mini(Movement.ticks(data.combate.recuperacao_max_s),roundi(player.attack_cd*float(data.combate.fator_recuperacao_golpe)))
	var heavy := multiplier > float(data.combate.limiar_finalizador)
	var push: float = maxf(float(data.corte.empurrao)*multiplier,float(data.combate.empurrao_pesado)) if heavy else float(data.corte.empurrao)
	var effect := _effect("attack",player.pos,player.aim,float(data.combate.flash_acerto_s)*2.0)
	effect["radius"] = float(data.corte.alcance_px)
	effect["angle"] = deg_to_rad(float(data.corte.meio_angulo_graus))
	effect["heavy"] = heavy
	for enemy: Dictionary in enemies:
		if not _hittable(enemy): continue
		var delta: Vector2 = enemy.pos-player.pos
		if delta.length() > float(data.corte.alcance_px)+enemy.radius: continue
		var touching: bool = delta.length() < player.radius+enemy.radius+float(data.combate.folga_encostado_px)
		if touching or player.aim.dot(delta.normalized()) >= cos(deg_to_rad(float(data.corte.meio_angulo_graus))):
			_hurt_enemy(enemy,float(data.corte.dano)*multiplier*damage_multiplier,player.aim,push,heavy,true)

func _start_lunge() -> void:
	player.special_cd = Movement.ticks(data.investida.recarga_s)
	player.lunge_remaining = Movement.ticks(data.investida.duracao_s)
	player.lunge_dir = player.aim
	player.lunge_hits.clear()
	player.inv = maxi(player.inv,player.lunge_remaining+Movement.ticks(data.investida.invuln_extra_s))
	_effect("special",player.pos,player.aim,float(data.investida.duracao_s))
	_lunge_hits()

func _lunge_hits() -> void:
	for enemy: Dictionary in enemies:
		if not _hittable(enemy) or player.lunge_hits.has(enemy.id): continue
		if player.pos.distance_to(enemy.pos) <= float(data.investida.raio_px)+enemy.radius:
			player.lunge_hits[enemy.id] = true
			_hurt_enemy(enemy,float(data.investida.dano)*damage_multiplier,player.lunge_dir,float(data.investida.empurrao),true,true)

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

func _hurt_enemy(enemy: Dictionary, damage: float, direction: Vector2, push: float, heavy: bool, stop: bool) -> void:
	enemy.hp = maxf(0.0,enemy.hp-damage)
	enemy.flash = Movement.ticks(data.combate.flash_acerto_s)
	var push_scale := float(data.elite.empurrao_x) if enemy.elite else 1.0
	enemy.knockback = direction * push * push_scale
	if heavy and not enemy.elite:
		enemy.phase = "recover"
		enemy.timer = Movement.ticks(data.combate.quebrou_recuperacao_s)
	_effect("hit",enemy.pos,direction,float(data.combate.flash_acerto_s))
	if stop:
		_pending_hitstop = maxi(_pending_hitstop,Movement.ticks(data.combate.hitstop_pesado_s if heavy else data.combate.hitstop_leve_s))

func _hurt_player(damage: float, origin: Vector2) -> void:
	if player.inv > 0 or player.hp <= 0: return
	player.hp = maxf(0.0,player.hp-maxi(1,roundi(damage)))
	player.inv = Movement.ticks(data.combate.invuln_atingido_s)
	player.flash = Movement.ticks(data.combate.flash_acerto_s)
	_pending_hitstop = maxi(_pending_hitstop,Movement.ticks(data.combate.hitstop_atingido_s))
	_effect("hurt",player.pos,(player.pos-origin).normalized(),float(data.combate.flash_acerto_s)*2.0)

func _spawn_wave() -> void:
	enemies.clear()
	for spawn: Dictionary in data.ondas[wave_index]:
		var definition: Dictionary = data.inimigos[spawn.id]
		var elite: bool = spawn.get("elite",false)
		var hp: float = definition.vida
		var radius: float = definition.raio
		if elite:
			hp = roundf(hp*float(data.elite.vida_x)*(1.0+float(data.elite.vida_por_profundidade)*float(data.profundidade)))
			radius *= float(data.elite.raio_x)
		var position := Vector2(spawn.x,spawn.y)
		_next_id += 1
		enemies.append({"id":_next_id,"kind":String(spawn.id),"pos":position,"prev":position,"hp":hp,"max_hp":hp,"radius":radius,"elite":elite,"phase":"spawn","timer":Movement.ticks(data.ia.surgimento_s),"aim":Vector2.DOWN,"knockback":Vector2.ZERO,"flash":0,"wait":int(data.ia.espera_inicial_base)+_integer(int(data.ia.espera_inicial_extra)+1)})

func _enemy_step(enemy: Dictionary) -> void:
	var definition: Dictionary = data.inimigos[enemy.kind]
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
		if distance < float(data.ia.ranged_perto_px): direction = -direction
		elif distance <= float(data.ia.ranged_longe_px): direction = Vector2.ZERO
	enemy.pos = Movement.resolve(enemy.pos+direction*float(definition.velocidade)/TICK_RATE,enemy.radius,data.arena)

func _enemy_fire(enemy: Dictionary, definition: Dictionary) -> void:
	var damage: float = float(definition.dano)*(float(data.elite.dano_x) if enemy.elite else 1.0)
	if definition.comportamento == "ranged":
		var position: Vector2 = enemy.pos+enemy.aim*float(data.combate.nascimento_projetil_px)
		projectiles.append({"pos":position,"prev":position,"radius":float(definition.proj_raio_px),"velocity":enemy.aim*float(definition.proj_velocidade_pxs),"remaining":int(definition.proj_vida_passos),"damage":damage})
	else:
		var delta: Vector2 = player.pos-enemy.pos
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

func _imul(a: int, b: int) -> int:
	return (((a & 65535)*(b & 65535))+((((a >> 16)*(b & 65535)+(b >> 16)*(a & 65535)) & 65535)<<16)) & MASK

func _integer(limit: int) -> int:
	# Separate run-local cosmetic/AI timing stream; no engine-global randomness.
	_rng_state = (_rng_state+0x6d2b79f5) & MASK
	var value := _imul(_rng_state ^ (_rng_state >> 15),_rng_state | 1)
	value ^= (value+_imul(value ^ (value >> 7),value | 61)) & MASK
	value = (value ^ (value >> 14)) & MASK
	return int((value*limit) >> 32)
