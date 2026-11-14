class_name PirateClock
extends RefCounted
## Movement animation and energy recovery clocks; attacks own their timers.
var movement: float = 0
var recovery: float = 0
var animation: int = 0
func begin() -> Dictionary:
	var move: bool = movement>=9-0.000001
	if move:
		movement = maxf(0,movement-9)
		animation = animation%4+1
	return {"move":move}
func finish(alive: bool, units: float = 1.0) -> bool:
	movement += units
	return recover(alive,units)
func recover(alive: bool, units: float = 1.0) -> bool:
	recovery += units
	if alive and recovery>=4-0.000001:
		recovery = maxf(0,recovery-4) if recovery<8 else 0
		return true
	return false

# Native60Hz gameplay. Metadata integration preserves the v10 tuned wall-clock speed.
# Menu artwork retains its original independent animation cadence.
const AUTHORED_TICK_SECONDS: float = 0.03
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