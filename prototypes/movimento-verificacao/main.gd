extends SceneTree

# Disposable fixtures: exact approved GDD examples, not production tuning.
class MovementFixture extends RefCounted:
	var position := Vector2(960, 540)
	var previous := position
	var charges := 1
	var maximum := 1
	var progress := 0
	var remaining := 0
	var direction := Vector2.RIGHT
	var starts: Array[int] = []
	var calls: Array[String] = []
	var observations: Array[bool] = []
	var invulnerability := 0
	var buffer := 0
	var live_index := -1

	func step(tap: bool = false, move: Vector2 = Vector2.ZERO, aim: Vector2 = Vector2.RIGHT, requested_maximum: int = -1) -> void:
		live_index += 1
		previous = position
		# Combat-start stub: existing protection decrements before Movement.
		invulnerability = maxi(0, invulnerability - 1)
		buffer = 10 if tap else maxi(0, buffer - 1)
		if requested_maximum > 0 and requested_maximum != maximum:
			charges = charges + requested_maximum - maximum if requested_maximum > maximum else mini(charges, requested_maximum)
			maximum = requested_maximum
			if charges == maximum:
				progress = 0
		if charges < maximum:
			progress += 1
			if progress == 42:
				charges += 1
				progress = 0
		else:
			progress = 0
		if buffer > 0 and charges > 0 and remaining == 0:
			direction = move.normalized() if not move.is_zero_approx() else aim
			charges -= 1
			remaining = 9
			calls.append("cancelar")
			calls.append("garantir_invulneravel(12)")
			invulnerability = maxi(invulnerability, 12)
			calls.append("esquiva_iniciada")
			starts.append(live_index)
			buffer = 0
		if remaining > 0:
			position += direction * 22.5
			remaining -= 1
		else:
			position += move.normalized() * minf(1, move.length()) * 387.0 / 60.0
		observations.append(remaining > 0)

	func frozen() -> void:
		previous = position

	func teleport(destination: Vector2) -> void:
		position = destination
		previous = destination
		remaining = 0

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func near(a: Vector2, b: Vector2, tolerance: float = 0.001) -> bool:
	return a.distance_to(b) <= tolerance

func steps(seconds: float) -> int:
	return 0 if seconds == 0 else maxi(1, roundi(seconds * 60))

func walk(move: Vector2, speed: float = 387, recovery: float = 1) -> Vector2:
	return move.normalized() * speed * minf(1, move.length()) * recovery / 60.0

func resolve(position: Vector2, obstacles: Array, radius: float = 27, room: Rect2 = Rect2(0, 0, 1920, 1080)) -> Vector2:
	for obstacle: Dictionary in obstacles:
		var delta: Vector2 = position - obstacle.center
		var combined: float = radius + obstacle.radius
		if delta.length_squared() < combined * combined:
			var normal := Vector2.UP if delta == Vector2.ZERO else delta.normalized()
			position = obstacle.center + normal * combined
	return position.clamp(room.position + Vector2(radius, radius), room.end - Vector2(radius, radius))

func run() -> void:
	check(steps(0.15) == 9 and steps(0.05) == 3 and steps(0.7) == 42, "F2/F3 quantized default durations")
	check(steps(0.14) == 8 and steps(0.14) * 22.5 == 180, "F2 duration .14 is eight steps")
	check(steps(0.158) + steps(0.058) == 12 and steps(0.216) == 13, "MV3 quantize before summing")
	check(steps(0) == 0 and steps(0.0001) == 1, "allowed zero and positive minimum one")
	check(1350.0 / 60 == 22.5 and 9 * 22.5 == 202.5, "F2 displacement and total")
	var walks := [
		[Vector2(0.6,0.8),387.0,1.0,Vector2(3.87,5.16)],
		[Vector2(0.3,0.4),387.0,1.0,Vector2(1.935,2.58)],
		[Vector2.RIGHT,433.44,1.0,Vector2(7.224,0)],
		[Vector2.RIGHT,387.0,0.45,Vector2(2.9025,0)],
		[Vector2(0.5,0),387.0,0.45,Vector2(1.45125,0)],
		[Vector2.RIGHT,387.0,0.0,Vector2.ZERO],
		[Vector2.RIGHT,387.0,1.0,Vector2(6.45,0)],
		[Vector2.ZERO,387.0,1.0,Vector2.ZERO],
		[Vector2.RIGHT,0.0,1.0,Vector2.ZERO]
	]
	for entry: Array in walks:
		check(near(walk(entry[0],entry[1],entry[2]),entry[3]), "F1 vector " + str(entry[0]) + " speed " + str(entry[1]) + " recovery " + str(entry[2]))
	var walked := Vector2(960,540)
	for tick in range(60):
		walked += walk(Vector2.RIGHT)
	check(near(walked,Vector2(1347,540),0.01), "AC03 sixty float32 walk steps")
	var obstacle := {"center": Vector2(1000,540), "radius":42.0}
	check(near(resolve(Vector2(931,540)+walk(Vector2.RIGHT),[obstacle]),Vector2(931,540)), "AC29 obstacle pushes walk back")
	check(near(resolve(Vector2(1000,540),[obstacle]),Vector2(1000,471)), "coincident centers use up normal")
	check(near(resolve(Vector2(1890,540)+walk(Vector2.RIGHT),[]),Vector2(1893,540)), "wall clamp after movement")
	check(resolve(Vector2(931,540),[obstacle]) == Vector2(931,540), "exact tangent does not push")
	check(near(resolve(Vector2(931.001,540),[obstacle]),Vector2(931,540)), "inside by .001 pushes")
	var other := {"center":Vector2(1000,640),"radius":42.0}
	check(near(resolve(Vector2(1000,590),[obstacle,other]),Vector2(1000,571)), "AC29 order A then B")
	check(near(resolve(Vector2(1000,590),[other,obstacle]),Vector2(1000,609)), "AC29 order B then A")
	check(resolve(Vector2(1000,590),[obstacle,other]).distance_to(obstacle.center) < 69, "one pass may leave overlap in invalid tight layout")
	var dash_pos := Vector2(900,540)
	var safe_axial := true
	for tick in range(9):
		dash_pos = resolve(dash_pos + Vector2(22.5,0),[obstacle])
		safe_axial = safe_axial and near(dash_pos,Vector2(922.5 if tick == 0 else 931.0,540))
	check(safe_axial, "AC30 axial nine step dash remains before obstacle")
	check(near(resolve(Vector2(925,540)+Vector2(10.5,0),[obstacle]),Vector2(931,540)), "AC58 synchronous support displacement resolves collision")
	check(near(resolve(Vector2(1910,1070),[]),Vector2(1893,1053)), "rectangle clamps both axes after obstacles")
	check(27 + 24 + 9 == 60 and 27 + 31.5 + 9 == 67.5, "F5 cut radii")
	check(Vector2(60,0).length_squared() <= 60.0*60 and not Vector2(60.0001,0).length_squared() <= 60.0*60, "F5 exact inclusive squared boundary without epsilon")
	check(is_equal_approx(10*(1+0.60+0.25),18.5) and is_equal_approx(10*(1+0.20+0.25),14.5), "F6 cut damage examples")
	check(maxi(25,9+3)==25 and maxi(0,9+3)==12, "F4 protection guarantee never shortens")
	check(42*3==126 and 42-10==32, "F3 remaining recharge formula")
	var fixture := MovementFixture.new()
	for tick in range(9):
		fixture.step(tick==0,Vector2.RIGHT if tick==0 else Vector2.ZERO)
	check(near(fixture.position,Vector2(1162.5,540)), "AC06 nine dash displacements")
	check(fixture.observations.slice(0,8).all(func(value: bool)->bool:return value) and not fixture.observations[8], "AC06 last dash movement exposes false em_esquiva")
	check(fixture.calls == ["cancelar","garantir_invulneravel(12)","esquiva_iniciada"], "AC07 synchronous combat call order once")
	fixture.step()
	check(near(fixture.position,Vector2(1162.5,540)), "no inertia after dash")
	for tick in range(10,42):
		fixture.step()
	check(fixture.charges==0 and fixture.progress==41, "AC14 charge absent through step41")
	fixture.step()
	check(fixture.charges==1 and fixture.progress==0, "AC14 recharge at42")
	fixture = MovementFixture.new()
	fixture.maximum=3
	fixture.charges=3
	var serial_charges := true
	for tick in range(127):
		fixture.step(tick in [0,9,18])
		if tick in [18,42,84,126]:
			serial_charges = serial_charges and fixture.charges == ({18:0,42:1,84:2,126:3}[tick])
	check(serial_charges and fixture.progress==0, "AC15 spending preserves recharge progress")
	fixture = MovementFixture.new()
	fixture.maximum=2
	fixture.charges=2
	for tick in range(18):
		fixture.step(tick in [0,4],Vector2.RIGHT)
	check(fixture.starts == [0,9] and near(fixture.position,Vector2(1365,540)), "AC13 buffered dash begins exactly nine steps later")
	fixture = MovementFixture.new()
	for tick in range(3):
		fixture.step(tick==0)
	var frozen_state := [fixture.position,fixture.charges,fixture.progress,fixture.remaining,fixture.invulnerability]
	for tick in range(5):
		fixture.frozen()
	check(fixture.previous==fixture.position and [fixture.position,fixture.charges,fixture.progress,fixture.remaining,fixture.invulnerability]==frozen_state, "AC52 frozen step only collapses position history")
	fixture.step()
	check(near(fixture.previous,Vector2(1027.5,540)) and near(fixture.position,Vector2(1050,540)), "AC52 first live step resumes position history")
	var before_teleport := [fixture.charges,fixture.progress,fixture.invulnerability]
	fixture.teleport(Vector2(400,300))
	check(fixture.position==fixture.previous and fixture.remaining==0 and before_teleport==[fixture.charges,fixture.progress,fixture.invulnerability], "AC32 teleport cancels dash preserving charges recharge protection")
	fixture = MovementFixture.new()
	fixture.maximum=2
	fixture.charges=2
	for tick in range(73):
		fixture.step(tick in [0,30],Vector2.ZERO,Vector2.RIGHT,1 if tick==21 else -1)
		if tick==21:
			check(fixture.charges==1 and fixture.progress==0, "AC16 maximum reduction to full resets recharge")
		if tick==71:
			check(fixture.charges==0, "AC16 second spend not recharged early")
	check(fixture.charges==1 and fixture.progress==0, "AC16 recharge after reduction returns at72")
	fixture = MovementFixture.new()
	var protection := true
	for tick in range(13):
		fixture.step(tick==0)
		protection = protection and ((fixture.invulnerability>0)==(tick<12))
	check(protection, "F4 stub protects steps0 through11 only")
	check(22.5<69 and is_equal_approx(69.0/22.5,3.0666666667), "MV1 default strict radius bound and margin")
	check(not 69.0<69.0, "MV1 equality rejected")
	# Scope probe: endpoint collision is NOT a swept-circle test.
	var grazing_start := Vector2(-10,68.5)
	var grazing_end := Vector2(10,68.5)
	var center := Vector2(1000,540)
	check(grazing_start.length()>69 and grazing_end.length()>69 and grazing_start.distance_to(grazing_end)<69, "F7 grazing endpoints outside with step below combined radius")
	check(68.5<69 and resolve(center+grazing_end,[obstacle])==center+grazing_end, "LIMIT endpoint solver misses shallow swept intersection")
	var inside_start := Vector2(995,540)
	check(resolve(inside_start+Vector2(22.5,0),[obstacle]).x>1000, "LIMIT invalid initially overlapping position can exit far side")
	print("RESULT checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
