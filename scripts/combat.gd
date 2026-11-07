class_name PirateCombat
extends RefCounted
## Collision geometry is explicit metadata; preserve strict authored point edges.
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const DAMAGE: Array = [0,3,10,4,6,5,6,7,4]
static func between(value: float, low: float, high: float) -> bool: return value>low and value<high
static func _shot_hits(pos: Vector2, actor: Dictionary, definition: Dictionary) -> bool:
	if not definition.get("damageable",false): return false
	var bounds: Array = definition.collision.shot_bounds
	var local: Vector2 = pos-actor.pos
	return between(local.x,bounds[0],bounds[2]) and between(local.y,bounds[1],bounds[3])
static func shot_hits(pos: Vector2, e: Dictionary) -> bool:
	return _shot_hits(pos,e,Catalog.definition(int(e.kind)))
static func shot_hits_boss(pos: Vector2, boss: Dictionary) -> bool:
	return not boss.is_empty() and _shot_hits(pos,boss,Catalog.for_actor(boss))
static func _beam_hits(player: Vector2, actor: Dictionary, definition: Dictionary) -> bool:
	if actor.pos.y>=player.y or not definition.get("damageable",false): return false
	var bounds: Array = definition.collision.beam_bounds
	return between(actor.pos.x,player.x+bounds[0],player.x+bounds[1])
static func beam_hits(player: Vector2, e: Dictionary) -> bool:
	return _beam_hits(player,e,Catalog.definition(int(e.kind)))
static func beam_hits_boss(player: Vector2, boss: Dictionary) -> bool:
	return not boss.is_empty() and _beam_hits(player,boss,Catalog.for_actor(boss))
static func hurts_player(player: Vector2, point: Vector2) -> bool:
	return Pilot.hits(player,point)
static func collects_item(player: Vector2, point: Vector2) -> bool:
	return between(point.x,player.x-5,player.x+55) and between(point.y,player.y-5,player.y+55)
