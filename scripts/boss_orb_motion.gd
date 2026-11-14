extends RefCounted
## Stage3 orbs enter fixed upper stations, then slowly track body X in the lower phase.
const Catalog = preload("res://scripts/enemy_catalog.gd")
static func active(e: Dictionary) -> bool:
	return Catalog.definition(int(e.kind)).get("motion",{}).get("type","")=="boss_health_stations"
static func prepare(e: Dictionary, boss: Dictionary) -> void:
	var definition: Dictionary = Catalog.definition(int(e.kind))
	var settings: Dictionary = definition.motion
	var maximum: float = float(boss.get("max_hp",0))
	if maximum>0 and float(boss.get("hp",maximum))<=maximum*float(settings.lower_below_ratio): e.orb_lowered = true
	var lowered: bool = e.get("orb_lowered",false)
	var point: Array = settings.lower_center if lowered else settings.upper_center
	var centre := Vector2(point[0],point[1])
	var follow: Dictionary = settings.get("lower_follow",{})
	e.orb_following = lowered and not follow.is_empty()
	if e.orb_following and boss.has("pos"): centre.x = boss.pos.x+float(follow.x_offset)
	e.orb_target = centre-definition.draw_offset-definition.draw_size/2
	_update_state(e,settings)
static func advance(e: Dictionary, seconds: float) -> void:
	var settings: Dictionary = Catalog.definition(int(e.kind)).motion
	var step: float = maxf(0,seconds)
	if e.get("orb_following",false):
		# Separate axes: slow X chase never changes the lower row's Y travel/arrival.
		_advance_follow_x(e,settings.lower_follow,step)
		e.pos.y = move_toward(e.pos.y,e.orb_target.y,float(settings.speed)*step)
	else: e.pos = e.pos.move_toward(e.orb_target,float(settings.speed)*step)
	_update_state(e,settings)
static func _update_state(e: Dictionary,settings: Dictionary) -> void:
	e.orb_stationary = e.pos==e.orb_target
	e.orb_y_stationary = e.pos.y==e.orb_target.y
	if e.get("orb_following",false):
		e.velocity = Vector2(float(e.get("orb_follow_velocity_x",0)),signf(e.orb_target.y-e.pos.y)*float(settings.speed))
	else: e.velocity = Vector2.ZERO if e.orb_stationary else e.pos.direction_to(e.orb_target)*float(settings.speed)

static func _advance_follow_x(e: Dictionary,follow: Dictionary,seconds: float) -> void:
	# Keep momentum between target updates. Integrate the linear ramp analytically,
	# including a speed-cap crossing, so acceleration does not depend on frame size.
	var before: float = float(e.get("orb_follow_velocity_x",0))
	var distance: float = e.orb_target.x-e.pos.x
	if distance==0:
		e.orb_follow_velocity_x = 0.0
		return
	var desired: float = signf(distance)*float(follow.speed)
	var acceleration: float = float(follow.speed)/float(follow.acceleration_seconds)
	var ramp: float = minf(seconds,absf(desired-before)/acceleration)
	var after: float = move_toward(before,desired,acceleration*seconds)
	var displacement: float = ((before+after)*0.5*ramp+after*(seconds-ramp))
	if signf(displacement)==signf(distance) and absf(displacement)>=absf(distance):
		e.pos.x = e.orb_target.x
		e.orb_follow_velocity_x = 0.0
	else:
		e.pos.x += displacement
		e.orb_follow_velocity_x = after
