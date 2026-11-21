extends RefCounted
## Cosmetic streams cannot advance combat RNG. Legacy events reserve exactly one old slot.
const CombatRandom=preload("res://scripts/random.gd")
class Stream:
	extends RefCounted
	var state: int
	var first_sample: bool
	func _init(seed: int, use_seed_as_sample: bool = false) -> void:
		state=seed
		first_sample=use_seed_as_sample
	func between(low: int,high: int) -> int:
		if first_sample:first_sample=false
		else:state=(state*0x43FD43FD+0xC39EC3)&0xFFFFFF
		return low+int(floorf(float(state)/16777216.0*(high-low+1)))
static var _stream=Stream.new(0x715517)
static func between(low: int,high: int) -> int:return _stream.between(low,high)
static func legacy_event() -> Stream:
	return Stream.new(CombatRandom.reserve_legacy_visual_draw(),true)
static func reserve_transition_history() -> void:
	# Retired loading-image selection consumed one draw, even after the final stage.
	CombatRandom.reserve_legacy_visual_draw()
