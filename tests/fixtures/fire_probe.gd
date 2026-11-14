extends RefCounted
const Runtime = preload("res://scripts/enemy_fire.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const AttackTimer = preload("res://scripts/attack_timer.gd")
static func burst(e: Dictionary,player: Vector2,reference_phase: int,reference_timer: int,boss: Dictionary = {}) -> Array:
	var result: Array = []
	for channel in Catalog.definition(int(e.kind)).get("fire_channels",[]):
		var divisor: int = roundi(float(channel.interval_seconds)/0.06)
		if reference_phase%divisor==0 and Runtime.enabled(e,channel,boss) and AttackTimer.in_window(channel,reference_timer*0.9):
			result.append_array(Runtime.emit(e,player,channel.name,boss))
	return result
static func advance(e: Dictionary,seconds: float,player: Vector2 = Vector2.ZERO) -> Array:
	return Runtime.advance(e,seconds,player)

static func aim(enemy: Vector2,player: Vector2,speed: float) -> Vector2:
	return Runtime.aim(enemy,player,speed)
