extends RefCounted
## Floor actors follow actual scenery displacement, including scroll easing and stops.
const Attachment=preload("res://scripts/entity_attachment.gd")
const SceneryMotion=preload("res://scripts/scenery_motion.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
static func active(actor: Dictionary) -> bool:
	return Catalog.for_actor(actor).has("ground_turret")
static func ready(actor: Dictionary) -> bool:
	return not active(actor) or (actor.get("hatch_enabled",true) and float(actor.get("deployment_progress",0))>=1.0)
static func initialize(actor: Dictionary, scenery_distance: float, start_exposed: bool = false, boss: Dictionary = {}) -> void:
	prepare(actor,boss)
	start_exposed=start_exposed and actor.hatch_enabled
	actor.ground_anchor_y = actor.pos.y
	actor.ground_anchor_distance = scenery_distance
	actor.deployment_progress = 1.0 if start_exposed else 0.0
	actor.deployment_started = start_exposed
	actor.ground_angle = 0.0
	var settings: Dictionary=Catalog.for_actor(actor).ground_turret
	if settings.has("rotation"):
		actor.ground_rotation_age=0.0
		actor.ground_angle=deg_to_rad(settings.rotation.initial_degrees)-PI/2
		var boss_x: float=boss.get("pos",Vector2(200,0)).x
		actor.ground_rotation_direction=1 if actor.pos.x+Geometry.vector(settings.center).x<boss_x else -1
static func prepare(actor: Dictionary,boss: Dictionary) -> void:
	var hatch: Dictionary=Catalog.for_actor(actor).ground_turret.get("boss_hatch",{})
	actor.hatch_enabled=hatch.is_empty() or (not boss.is_empty() and int(Catalog.for_actor(boss).id)==int(hatch.boss_id) and boss.hp>0 and float(boss.hp)<=float(boss.max_hp)*float(hatch.hp_ratio)+0.0000001)

# Called once before attack scheduling. Hatch animation still finishes after movement,
# preserving the existing first-shot timing and collision availability on each frame.
static func begin_step(actor: Dictionary,seconds: float,boss: Dictionary) -> void:
	prepare(actor,boss)
	advance_rotation(actor,seconds)
static func rotation_angle(actor: Dictionary,age: float) -> float:
	var rotation: Dictionary=Catalog.for_actor(actor).ground_turret.rotation
	return deg_to_rad(rotation.initial_degrees)-PI/2+TAU*age/float(rotation.period_seconds)*float(actor.get("ground_rotation_direction",1))
static func advance_rotation(actor: Dictionary,seconds: float) -> void:
	var settings: Dictionary=Catalog.for_actor(actor).ground_turret
	if not settings.has("rotation"):return
	actor.ground_rotation_previous_age=float(actor.get("ground_rotation_age",0))
	actor.ground_rotation_frame_seconds=seconds
	if ready(actor):actor.ground_rotation_age=float(actor.get("ground_rotation_age",0))+seconds
	actor.ground_angle=rotation_angle(actor,float(actor.get("ground_rotation_age",0)))
static func firing_angle(actor: Dictionary,fired_at: float) -> float:
	var age: float=float(actor.get("ground_rotation_age",0))
	if fired_at>=0:
		var seconds: float=actor.get("ground_rotation_frame_seconds",0)
		var within_frame: float=clampf(fired_at-float(actor.get("fire_age",0))+seconds,0,seconds)
		age=float(actor.get("ground_rotation_previous_age",0))+within_frame
	return rotation_angle(actor,age)
# Standalone simulation entry point (tools/tests); the game uses explicit begin/finish phases.
static func advance(actor: Dictionary,g: Node,seconds: float) -> void:
	prepare(actor,g.boss)
	finish_step(actor,g,seconds)
static func finish_step(actor: Dictionary, g: Node, seconds: float) -> void:
	if not actor.has("ground_anchor_distance"): initialize(actor,g.scenery_distance,false,g.boss)
	var settings: Dictionary = Catalog.for_actor(actor).ground_turret
	if Attachment.follows_y(actor,g.boss):Attachment.apply(actor,g.boss)
	else:actor.pos.y=SceneryMotion.y(actor.ground_anchor_y,actor.ground_anchor_distance,g.scenery_distance)
	actor.velocity = Vector2(0,g.scroll_speed)
	if settings.has("boss_hatch"):actor.deployment_started=actor.hatch_enabled
	elif actor.pos.y>float(settings.reveal_y):actor.deployment_started=true
	actor.deployment_progress=move_toward(float(actor.deployment_progress),1.0 if actor.deployment_started else 0.0,seconds/float(settings.raise_seconds))
	if not settings.has("rotation"):
		actor.ground_angle = (g.player+Pilot.COCKPIT-actor.pos-Geometry.vector(settings.center)).angle()-PI/2
static func wreck(g: Node, actor: Dictionary) -> void:
	g.ground_wrecks.append({"kind":actor.kind,"pos":actor.pos,"previous_pos":actor.pos,"anchor_y":actor.pos.y,"anchor_distance":g.scenery_distance})
static func advance_wrecks(g: Node) -> void:
	for remains in g.ground_wrecks:
		remains.previous_pos = remains.pos
		remains.pos.y=SceneryMotion.y(remains.anchor_y,remains.anchor_distance,g.scenery_distance)
	g.ground_wrecks = g.ground_wrecks.filter(func(remains):return remains.pos.y<580)
static func emit(actor: Dictionary, player: Vector2, channel: Dictionary, fired_at: float = -1) -> Array:
	if not ready(actor): return []
	var settings: Dictionary=Catalog.for_actor(actor).ground_turret
	var center: Vector2 = actor.pos+Geometry.vector(settings.center)
	var target: Vector2 = player+Pilot.COCKPIT
	var angle: float = (target-center).angle()-PI/2
	if settings.has("rotation"):
		angle=firing_angle(actor,fired_at)
	var direction: Vector2=Vector2.DOWN.rotated(angle)
	var result: Array = []
	var kinds: Array=settings.get("projectile_kinds",[])
	for i in range(settings.ports.size()):
		var port: Array=settings.ports[i]
		var origin: Vector2 = center+Vector2(port[0],port[1]).rotated(angle)
		var heading: Vector2=direction if settings.get("parallel",false) else (target-origin).normalized()
		result.append({"pos":origin,"velocity":heading*float(channel.speed),"kind":int(kinds[i]) if not kinds.is_empty() else int(channel.projectile_kind)})
	return result
