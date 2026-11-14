class_name PirateClock
extends RefCounted
const FIXED_STEP_SECONDS: float = 1.0/60.0
const MENU_STEP_SECONDS: float = 0.025
const STEERING_INTERVAL_SECONDS: float = 0.27
const ENERGY_INTERVAL_SECONDS: float = 0.12
var movement: float = 0.0
var recovery: float = 0.0
var animation: int = 0
func begin() -> Dictionary:
	var move: bool = movement>=STEERING_INTERVAL_SECONDS-0.00000003
	if move:
		movement = maxf(0,movement-STEERING_INTERVAL_SECONDS)
		animation = animation%4+1
	return {"move":move}
func finish(alive: bool, seconds: float = FIXED_STEP_SECONDS) -> bool:
	movement += seconds
	return recover(alive,seconds)
func recover(alive: bool, seconds: float = FIXED_STEP_SECONDS) -> bool:
	recovery += seconds
	if alive and recovery>=ENERGY_INTERVAL_SECONDS-0.00000003:
		recovery = maxf(0,recovery-ENERGY_INTERVAL_SECONDS) if recovery<ENERGY_INTERVAL_SECONDS*2 else 0
		return true
	return false
static func countdown(value: float, seconds: float) -> float:
	return maxf(0,value-seconds) if value-seconds>0.00000003 else 0.0
