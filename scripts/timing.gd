class_name PirateClock
extends RefCounted
## Global fm_a/fm_b/fm_ki counters survive stage loading, as in the VB6 module.
var movement: int = 0
var firing: int = 0
var recovery: int = 0
var phase: int = 1
var animation: int = 0
func begin() -> Dictionary:
	var move: bool = movement>8
	var fire: bool = firing>1
	if move:
		movement = 0
		animation = animation%4+1
	if fire:
		firing = 0
		phase = phase%25+1
	return {"move":move,"fire":fire}
func finish(alive: bool) -> bool:
	movement += 1
	firing += 1
	return recover(alive)
func recover(alive: bool) -> bool:
	recovery += 1
	if alive and recovery>3:
		recovery = 0
		return true
	return false
