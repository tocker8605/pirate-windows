extends RefCounted
## Floor actors follow actual scenery displacement, including scroll easing and stops.
const Geometry=preload("res://scripts/entity_geometry.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
static func active(actor: Dictionary) -> bool:
	return Catalog.for_actor(actor).has("ground_turret")
static func ready(actor: Dictionary) -> bool:
	return not active(actor) or float(actor.get("deployment_progress",0))>=1.0
static func initialize(actor: Dictionary, scenery_distance: float, start_exposed: bool = false) -> void:
	actor.ground_anchor_y = actor.pos.y
	actor.ground_anchor_distance = scenery_distance
	actor.deployment_progress = 1.0 if start_exposed else 0.0
	actor.deployment_started = start_exposed
	actor.ground_angle = 0.0
static func advance(actor: Dictionary, g: Node, seconds: float) -> void:
	if not actor.has("ground_anchor_distance"): initialize(actor,g.scenery_distance)
	var settings: Dictionary = Catalog.for_actor(actor).ground_turret
	actor.pos.y = float(actor.ground_anchor_y)+g.scenery_distance-float(actor.ground_anchor_distance)
	actor.velocity = Vector2(0,g.scroll_speed)
	if actor.pos.y>float(settings.reveal_y): actor.deployment_started = true
	if actor.deployment_started:
		actor.deployment_progress = minf(1,float(actor.deployment_progress)+seconds/float(settings.raise_seconds))
	actor.ground_angle = (g.player+Pilot.COCKPIT-actor.pos-Geometry.vector(settings.center)).angle()-PI/2
static func wreck(g: Node, actor: Dictionary) -> void:
	g.ground_wrecks.append({"kind":actor.kind,"pos":actor.pos,"previous_pos":actor.pos,"anchor_y":actor.pos.y,"anchor_distance":g.scenery_distance})
static func advance_wrecks(g: Node) -> void:
	for remains in g.ground_wrecks:
		remains.previous_pos = remains.pos
		remains.pos.y = float(remains.anchor_y)+g.scenery_distance-float(remains.anchor_distance)
	g.ground_wrecks = g.ground_wrecks.filter(func(remains):return remains.pos.y<580)
static func emit(actor: Dictionary, player: Vector2, channel: Dictionary) -> Array:
	if not ready(actor): return []
	var center: Vector2 = actor.pos+Geometry.vector(Catalog.for_actor(actor).ground_turret.center)
	var target: Vector2 = player+Pilot.COCKPIT
	var angle: float = (target-center).angle()-PI/2
	var result: Array = []
	for port in Catalog.for_actor(actor).ground_turret.ports:
		var origin: Vector2 = center+Vector2(port[0],port[1]).rotated(angle)
		result.append({"pos":origin,"velocity":(target-origin).normalized()*float(channel.speed),"kind":int(channel.projectile_kind)})
	return result
