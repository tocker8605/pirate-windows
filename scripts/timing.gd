class_name PirateClock
extends RefCounted
const FIXED_STEP_SECONDS: float = 1.0/60.0
const ANIMATION_INTERVAL_SECONDS: float = 0.27
const ENERGY_INTERVAL_SECONDS: float = 0.12
var animation_elapsed_seconds: float = 0.0
var recovery: float = 0.0
var animation: int = 0
func begin() -> Dictionary:
	var animate: bool = animation_elapsed_seconds>=ANIMATION_INTERVAL_SECONDS-0.00000003
	if animate:
		animation_elapsed_seconds = maxf(0,animation_elapsed_seconds-ANIMATION_INTERVAL_SECONDS)
		animation = animation%4+1
	return {"animation":animate}
func finish(alive: bool, seconds: float = FIXED_STEP_SECONDS) -> bool:
	animation_elapsed_seconds += seconds
	return recover(alive,seconds)
func recover(alive: bool, seconds: float = FIXED_STEP_SECONDS) -> bool:
	recovery += seconds
	if alive and recovery>=ENERGY_INTERVAL_SECONDS-0.00000003:
		recovery = maxf(0,recovery-ENERGY_INTERVAL_SECONDS) if recovery<ENERGY_INTERVAL_SECONDS*2 else 0
		return true
	return false
static func countdown(value: float, seconds: float) -> float:
	return maxf(0,value-seconds) if value-seconds>0.00000003 else 0.0
