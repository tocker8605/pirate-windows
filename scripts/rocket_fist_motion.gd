extends RefCounted
## The painted coupling point docks to a moving socket; returning never crosses above it.
const Geometry=preload("res://scripts/entity_geometry.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const RETURN_PATTERN: int=2101
const LAUNCH_PATTERN: int=2102
static func active(actor: Dictionary) -> bool:
	return Catalog.for_actor(actor).has("rocket_fist")
static func dock(actor: Dictionary,parent_position: Vector2) -> Vector2:
	var definition: Dictionary=Catalog.for_actor(actor)
	var offset: Array=definition.attachment.offset
	var uv: Array=definition.rocket_fist.coupling_uv
	var coupling: Vector2=Geometry.image_point(definition,Vector2.ZERO,Vector2(uv[0],uv[1]),Geometry.sprite_native_size(definition))
	return parent_position+Vector2(offset[0],offset[1])-coupling
static func steer(actor: Dictionary,player: Vector2,parent_position: Vector2,seconds: float) -> void:
	var settings: Dictionary=Catalog.for_actor(actor).rocket_fist
	var phase: String=actor.get("fist_phase","approaching")
	var target: Vector2=dock(actor,parent_position)
	if phase=="docked":
		actor.pos=target
		actor.velocity=Vector2.ZERO
		if absf(actor.pos.x-player.x)<float(settings.trigger_x_distance):phase="launching"
	if phase=="launching":
		if actor.pos.y>float(settings.return_y):
			phase="returning";actor.velocity=Vector2.ZERO
		else:actor.velocity=Vector2(0,minf(float(settings.max_speed),actor.velocity.y+float(settings.launch_acceleration)*seconds))
	if phase in ["approaching","returning"]:
		var direction: float=-1 if phase=="returning" else signf(target.y-actor.pos.y)
		actor.velocity=Vector2(0,move_toward(actor.velocity.y,direction*float(settings.max_speed),float(settings.return_acceleration)*seconds))
	# Preserve the pre-parent-motion gap so a moving socket cannot skip the crossing.
	actor.fist_dock_gap=target.y-actor.pos.y
	actor.fist_phase=phase
	actor.pattern=LAUNCH_PATTERN if phase=="launching" else RETURN_PATTERN
static func advance(actor: Dictionary,parent: Dictionary,seconds: float) -> void:
	if parent.is_empty():
		actor.pos+=actor.velocity*seconds
		return
	var target: Vector2=dock(actor,parent.pos)
	var before: float=float(actor.get("fist_dock_gap",target.y-actor.pos.y))
	actor.pos+=actor.velocity*seconds
	actor.pos.x=target.x
	var phase: String=actor.get("fist_phase","approaching")
	if phase in ["approaching","returning"] and (absf(before)<0.00001 or before*(target.y-actor.pos.y)<=0 or (phase=="returning" and actor.pos.y<=target.y)):
		actor.fist_phase="docked";actor.pattern=RETURN_PATTERN
		phase="docked"
	if phase=="launching":actor.pos.y=maxf(actor.pos.y,target.y)
	if phase=="docked":
		actor.pos=target
		actor.velocity=Vector2.ZERO
