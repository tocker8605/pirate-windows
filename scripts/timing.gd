class_name PirateClock
extends RefCounted
## Global fm_a/fm_b/fm_ki counters survive stage loading, as in the VB6 module.
var movement: float = 0
var firing: float = 0
var recovery: float = 0
var phase: int = 1
var animation: int = 0
func begin() -> Dictionary:
	var move: bool = movement>=9-0.000001
	var fire: bool = firing>=2-0.000001
	if move:
		movement = maxf(0,movement-9)
		animation = animation%4+1
	var phases: Array = []
	while firing>=2-0.000001:
		firing = maxf(0,firing-2)
		phase = phase%25+1
		phases.append(phase)
	return {"move":move,"fire":fire,"phases":phases}
func finish(alive: bool, units: float = 1.0) -> bool:
	movement += units
	firing += units
	return recover(alive,units)
func recover(alive: bool, units: float = 1.0) -> bool:
	recovery += units
	if alive and recovery>=4-0.000001:
		recovery = maxf(0,recovery-4) if recovery<8 else 0
		return true
	return false

# Native60Hz gameplay. Metadata integration preserves the v10 tuned wall-clock speed.
# Menu artwork retains its original independent animation cadence.
const PLAYBACK_TIME_SCALE: float = 1.2
static func interval(speed: int, gameplay: bool = true) -> float:
	var original: float = (30.0-5.0*clampi(speed,1,5))/1000.0
	return 1.0/60.0 if gameplay else original

# Authored metadata uses the previous 30ms reference unit. Convert at integration,
# so every real 60Hz tick moves/collides and fractional periods retain their remainder.
static func units_per_tick(speed: int = 1) -> float:
	return (1.0/60.0)/((30.0-5.0*clampi(speed,1,5))/1000.0*PLAYBACK_TIME_SCALE)
static func countdown(value: float, units: float) -> float:
	return maxf(0,value-units) if value-units>0.000001 else 0.0