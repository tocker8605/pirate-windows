class_name PirateCombat
extends RefCounted
## Collision geometry is explicit metadata; preserve strict authored point edges.
const ProjectileGeometry=preload("res://scripts/player_projectile_geometry.gd")
const Ground = preload("res://scripts/ground_turret.gd")
const Depth = preload("res://scripts/enemy_depth.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
static func incoming_damage(difficulty: int) -> float:
	return 6+clampi(difficulty,1,5)*6
static func between(value: float, low: float, high: float) -> bool: return value>low and value<high
## Point/origin inputs below are world coordinates, shared by every entity definition.
static func shot_point_hits(point: Vector2,actor: Dictionary) -> bool:
	if actor.is_empty():return false
	var definition: Dictionary=Catalog.for_actor(actor)
	if not definition.get("damageable",false) or not Ground.ready(actor):return false
	var bounds: Array=definition.collision.shot_bounds
	var local: Vector2=point-actor.pos
	return between(local.x,bounds[0],bounds[2]) and between(local.y,bounds[1],bounds[3])
static func beam_origin_hits(origin: Vector2,actor: Dictionary) -> bool:
	if actor.is_empty() or actor.pos.y>=origin.y:return false
	var definition: Dictionary=Catalog.for_actor(actor)
	if not definition.get("damageable",false) or not Ground.ready(actor):return false
	var bounds: Array=definition.collision.beam_bounds
	return between(origin.x-actor.pos.x,bounds[0],bounds[1])
# Stored-position convenience adapters for tools and existing callers. No entity-specific offsets.
static func shot_hits(pos: Vector2,e: Dictionary) -> bool:
	return shot_point_hits(ProjectileGeometry.shot_centre(pos),e)
static func shot_hits_boss(pos: Vector2,boss: Dictionary) -> bool:
	return shot_point_hits(ProjectileGeometry.shot_centre(pos),boss)
static func beam_hits(player: Vector2,e: Dictionary) -> bool:
	return beam_origin_hits(ProjectileGeometry.beam_origin(player),e)
static func beam_hits_boss(player: Vector2,boss: Dictionary) -> bool:
	return beam_origin_hits(ProjectileGeometry.beam_origin(player),boss)
static func hurts_player(player: Vector2, point: Vector2) -> bool:
	return Pilot.hits(player,point)
static func touches_player(player: Vector2, actor: Dictionary) -> bool:
	if actor.is_empty() or actor.get("hp",0)<=0: return false
	var definition: Dictionary = Catalog.for_actor(actor)
	if definition.has("ground_turret") or definition.get("role","")=="supply" or Depth.is_below(actor): return false
	var bounds: Array = definition.collision.contact_bounds
	var local: Vector2 = player+Pilot.COCKPIT-actor.pos
	var closest := Vector2(clampf(local.x,bounds[0],bounds[2]),clampf(local.y,bounds[1],bounds[3]))
	return local.distance_squared_to(closest)<Pilot.HIT_RADIUS*Pilot.HIT_RADIUS
static func collects_item(player: Vector2, point: Vector2) -> bool:
	return between(point.x,player.x-5,player.x+55) and between(point.y,player.y-5,player.y+55)
