extends SceneTree

const MASK: int = 0xFFFFFFFF
const INCREMENT: int = 0x6D2B79F5
const GOLDEN: int = 0x9E3779B9
var failures: int = 0
var checks: int = 0


func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		push_error("FAIL " + label)
		failures += 1


func imul(a: int, b: int) -> int:
	return (a * (b & 0xFFFF) + (((a * (b >> 16)) & 0xFFFF) << 16)) & MASK


func step(state: int) -> Array[int]:
	var next_state := (state + INCREMENT) & MASK
	var mixed := imul(next_state ^ (next_state >> 15), next_state | 1)
	mixed ^= (mixed + imul(mixed ^ (mixed >> 7), mixed | 61)) & MASK
	return [next_state, (mixed ^ (mixed >> 14)) & MASK]


func fmix32(value: int) -> int:
	value ^= value >> 16
	value = imul(value, 0x85EBCA6B)
	value ^= value >> 13
	value = imul(value, 0xC2B2AE35)
	return value ^ (value >> 16)


func mix(value: int, component: int) -> int:
	return fmix32(((value ^ component) + GOLDEN) & MASK)


func derive(seed_value: int, purpose: int, region: int, depth: int) -> int:
	return mix(mix(mix(fmix32(((seed_value & MASK) + GOLDEN) & MASK), purpose), region), depth)


func bounded(output: int, size: int) -> int:
	return (output * size) >> 32


# F6 integer branch. Bounds validated before drawing in production.
# floor(u * W / 2^32) < cumulative is exactly equivalent for integer cumulative.
func weighted(output: int, weights: Array[int]) -> int:
	var total: int = 0
	for weight in weights:
		if weight < 0 or weight > 0x80000000 - total:
			return -1
		total += weight
	if total == 0:
		return -1
	var target: int = (output * total) >> 32
	var cumulative: int = 0
	for index in weights.size():
		cumulative += weights[index]
		if target < cumulative:
			return index
	return -1


func _initialize() -> void:
	check(imul(MASK, MASK) == 1, "F1 imul maximum operands")
	var state: int = 0
	var expected_states: Array[int] = [0x6D2B79F5, 0xDA56F3EA, 0x47826DDF, 0xB4ADE7D4, 0x21D961C9]
	var expected_outputs: Array[int] = [0x4434B462, 0x00159C37, 0x39285B08, 0x256D8104, 0x77A2CBD4]
	for index in expected_outputs.size():
		var result := step(state)
		state = result[0]
		check(state == expected_states[index] and result[1] == expected_outputs[index], "F1 zero vector step " + str(index + 1))
	state = 0x3F9A07C2
	expected_outputs = [0x0865C80A, 0xD260910A, 0xB37DB9FA, 0x91FD7BCE, 0x7A515CDF]
	for index in expected_outputs.size():
		var result := step(state)
		state = result[0]
		check(result[1] == expected_outputs[index], "F1 nonzero vector step " + str(index + 1))

	check(fmix32(0) == 0 and fmix32(1) == 0x514E28B7 and fmix32(MASK) == 0x81F16F39, "F2 fmix vectors")
	var depths: Array[int] = [0x0EC3245B, 0x3043CE64, 0xCFBE45BC, 0xB0B08409, 0x83C51646]
	for depth in depths.size():
		check(derive(0x3F9A07C2, 4, 0, depth) == depths[depth], "F2 derived depth " + str(depth))
	check(derive(0, 1, 0, 0) == 0xE8A7E13D, "F2 zero seed")
	check(derive(-1, 1, 0, 0) == derive(MASK, 1, 0, 0), "F2 negative boundary mask")
	check(derive(0x100000005, 1, 0, 0) == derive(5, 1, 0, 0), "F2 oversized boundary mask")
	check(bounded(42949672, 100) == 0 and bounded(42949673, 100) == 1, "F4 adjacent threshold")
	check(bounded(0x80000000, 100) == 50 and bounded(MASK, 100) == 99, "F4 midpoint and maximum")
	check(bounded(MASK, 1 << 21) == (1 << 21) - 1, "F4 maximum supported size")
	var first := step(0xB0B08409)
	check(bounded(first[1], 100) == 13 and bounded(first[1], 6) == 0, "F4 reference stream")
	check(weighted(first[1], [3, 2, 1]) == 0 and weighted(first[1], [0, 5, 0, 1]) == 1, "F6 reference weights")
	check(weighted(MASK, [0x7FFFFFFE, 1]) == 1, "F6 sum 2^31-1 selects last positive weight")
	check(weighted(MASK, [0x7FFFFFFF, 1]) == 1, "F6 sum 2^31 selects last positive weight")
	check(weighted(0, [0, 0x80000000, 0]) == 1 and weighted(MASK, [0, 0x80000000, 0]) == 1, "F6 zero weights at full boundary")
	check(weighted(0x7FFFFFFF, [0x40000000, 0x40000000]) == 0 and weighted(0x80000000, [0x40000000, 0x40000000]) == 1, "F6 exact half boundary")
	check(weighted(MASK, [0x80000000, 1]) == -1, "F6 rejects sum above 2^31 before multiplication")
	var total_limit: int = 0x80000000
	check(MASK * total_limit == 9223372034707292160, "F6 u times maximum sum fits int64")
	check((total_limit << 32) < 0, "F6 direct shifted cumulative overflows signed int64")

	var observed_equivalence := true
	for output in [0, 1, 42949672, 0x7FFFFFFF, 0x80000000, MASK]:
		for total in [1, 6, 100, 0x7FFFFFFF]:
			for cumulative in [1, total]:
				observed_equivalence = observed_equivalence and (((output * total) >> 32) < cumulative) == (output * total < (cumulative << 32))
	check(observed_equivalence, "F6 equivalent comparisons across safe reference products")
	print("Checks: ", checks, "; failures: ", failures)
	quit(0 if failures == 0 else 1)
