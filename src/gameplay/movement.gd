extends RefCounted
## Pure player geometry and charge/dash state, driven by the session at 60Hz.

const TICK_RATE := 60.0

## Quantizes a duration once, allowing zero for explicitly optional durations.
static func ticks(seconds: float) -> int:
	return 0 if seconds == 0.0 else maxi(1, roundi(seconds * TICK_RATE))

## Applies one ordered circle pass followed by the inset room rectangle.
static func resolve(position: Vector2, radius: float, arena: Dictionary) -> Vector2:
	for obstacle: Dictionary in arena.pilares:
		var center := Vector2(obstacle.x, obstacle.y)
		var delta := position - center
		var combined: float = radius + obstacle.r
		if delta.length_squared() < combined * combined:
			var normal := Vector2.UP if delta == Vector2.ZERO else delta.normalized()
			position = center + normal * combined
	return position.clamp(Vector2(radius,radius),Vector2(arena.largura-radius,arena.altura-radius))

## Advances recharge before a possible dash spend. Spending does not reset it.
static func recharge(player: Dictionary, duration: int) -> void:
	if player.charges >= player.charge_max:
		player.recharge = 0
		return
	player.recharge += 1
	if player.recharge >= duration:
		player.charges += 1
		player.recharge = 0

## Collapses visual history without advancing any gameplay counter.
static func freeze(player: Dictionary) -> void:
	player.prev = player.pos

## Cancels travel at a teleport while retaining charges, recharge and protection.
static func teleport(player: Dictionary, position: Vector2) -> void:
	player.pos = position
	player.prev = position
	player.dash_remaining = 0
	player.dash_hits.clear()

## Moves by an external support step without replacing the prior physics position.
static func displace(player: Dictionary, delta: Vector2, arena: Dictionary) -> void:
	player.pos = resolve(player.pos + delta, player.radius, arena)
