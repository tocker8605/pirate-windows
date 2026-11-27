extends RefCounted
## The painted coupling point docks to a moving socket; returning never crosses above it.
const Geometry=preload("res://scripts/entity_geometry.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
enum Phase { APPROACHING, DOCKED, LAUNCHING, RETURNING }
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
	var phase: Phase=actor.get("fist_phase",Phase.APPROACHING)
	var target: Vector2=dock(actor,parent_position)
	var start: Vector2=target if phase==Phase.DOCKED else actor.pos
	if phase==Phase.DOCKED:
		actor.velocity=Vector2.ZERO
		if absf(start.x-player.x)<float(settings.trigger_x_distance):phase=Phase.LAUNCHING
	if phase==Phase.LAUNCHING:
		if start.y>float(settings.return_y):
			phase=Phase.RETURNING;actor.velocity=Vector2.ZERO
		else:actor.velocity=Vector2(0,minf(float(settings.max_speed),actor.velocity.y+float(settings.launch_acceleration)*seconds))
	if phase in [Phase.APPROACHING,Phase.RETURNING]:
		var direction: float=-1 if phase==Phase.RETURNING else signf(target.y-start.y)
		actor.velocity=Vector2(0,move_toward(actor.velocity.y,direction*float(settings.max_speed),float(settings.return_acceleration)*seconds))
	# Preserve the pre-parent-motion gap so a moving socket cannot skip the crossing.
	actor.fist_dock_gap=target.y-start.y
	actor.fist_step_origin=start
	actor.fist_phase=phase
static func advance(actor: Dictionary,parent: Dictionary,seconds: float) -> void:
	# Only this phase writes position; consume the steering snapshot exactly once.
	actor.pos=actor.get("fist_step_origin",actor.pos)
	actor.erase("fist_step_origin")
	if parent.is_empty():
		actor.pos+=actor.velocity*seconds
		return
	var target: Vector2=dock(actor,parent.pos)
	var before: float=float(actor.get("fist_dock_gap",target.y-actor.pos.y))
	actor.pos+=actor.velocity*seconds
	actor.pos.x=target.x
	var phase: Phase=actor.get("fist_phase",Phase.APPROACHING)
	if phase in [Phase.APPROACHING,Phase.RETURNING] and (absf(before)<0.00001 or before*(target.y-actor.pos.y)<=0 or (phase==Phase.RETURNING and actor.pos.y<=target.y)):
		actor.fist_phase=Phase.DOCKED
		phase=Phase.DOCKED
	if phase==Phase.LAUNCHING:actor.pos.y=maxf(actor.pos.y,target.y)
	if phase==Phase.DOCKED:
		actor.pos=target
		actor.velocity=Vector2.ZERO

	# Compatibility projection for existing timeline pattern numbers; never a state input.
	actor.pattern=LAUNCH_PATTERN if phase==Phase.LAUNCHING else RETURN_PATTERN
