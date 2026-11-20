extends RefCounted
## A run captures menu choices once; subsequent menu edits cannot change combat.
var _difficulty: int
var _weapon: int
var _boss_rush: bool
var difficulty: int:
	get: return _difficulty
var weapon: int:
	get: return _weapon
var boss_rush: bool:
	get: return _boss_rush
func _init(level: int = 3, weapon_type: int = 1, rush: bool = false) -> void:
	_difficulty = clampi(level,1,5)
	_weapon = clampi(weapon_type,1,3)
	_boss_rush = rush
func with_difficulty(level: int) -> RefCounted:
	return get_script().new(level,weapon,boss_rush)
func with_weapon(weapon_type: int) -> RefCounted:
	return get_script().new(difficulty,weapon_type,boss_rush)
func with_boss_rush(rush: bool) -> RefCounted:
	return get_script().new(difficulty,weapon,rush)
func qualifies_for_ranking() -> bool:
	return not boss_rush
