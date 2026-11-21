class_name PirateEnemyFire
extends RefCounted
const Geometry=preload("res://scripts/entity_geometry.gd")
const Volleys=preload("res://scripts/projectile_volley.gd")
const Ground = preload("res://scripts/ground_turret.gd")
const CoreMotion = preload("res://scripts/boss_core_motion.gd")
const AttackTimer = preload("res://scripts/attack_timer.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
## Named volley geometry and independent per-actor attacks.
## Keep legacy aim anchors, but normalize the actual direction so distance cannot amplify speed.
static func aim(enemy: Vector2, player: Vector2, speed: float) -> Vector2:
	var delta: Vector2 = player - enemy
	return delta.normalized()*speed

static func single_muzzle(e: Dictionary, y: float = 25) -> Vector2:
	return e.pos+Vector2(25,y)

static func enabled(e: Dictionary, channel: Dictionary, boss: Dictionary = {}) -> bool:
	var v: Vector2 = e.velocity
	var y: float = e.pos.y
	var by: float = boss.get("pos",Vector2.ZERO).y
	match str(channel.gate):
		"ground_ready": return Ground.ready(e) and y>=0 and y<430
		"aim_window": return v.y<(133.33333333333334 - 0.0001) and v.y> (-166.66666666666669 + 0.0001)
		"moving": return v.x!=0
		"stationary_aim": return y>=80 and v.x==0 and v.y> (-33.333333333333336 + 0.0001)
		"sweep_y": return y>20 and y<199
		"descent_or_stationary": return v.y>(0 + 0.0001) or v.x==0
		"descending": return v.y>(33.333333333333336 + 0.0001)
		"flame_y": return y<220
		"charge_y": return y>100 and y<150
		"fist_y": return y>390
		"pod_y": return y>300
		"orb_y_stationary": return e.get("orb_y_stationary",false) and e.velocity.y==0
		"orb_stationary": return e.get("orb_stationary",false) and e.velocity==Vector2.ZERO
		"orb_y": return y>by+30
		"left_claw_y": return by>40 and by<80
		"right_claw_y": return by>120
		"detached": return CoreMotion.active(e) and e.get("core_phase","")!="settled"
		"core_settled": return CoreMotion.active(e) and e.get("core_phase","")=="settled"
	return true

static func heavy_cannon_angle(age: float) -> float:return Volleys.heavy_cannon_angle(age)
static func emit(e: Dictionary, player: Vector2, attack: String, boss: Dictionary = {}, fired_at: float = -1) -> Array:
	var channel: Dictionary=Catalog.fire_channel(int(e.kind),attack)
	if Ground.active(e):return Ground.emit(e,player,channel,fired_at)
	return Volleys.emit(e,player,channel,boss,fired_at)

# Elapsed seconds avoids quantizing the 100ms cadence to the legacy 60ms fire clock.
# Bullets fly straight; sequential emission angles form the expanding spiral.
static func advance(e: Dictionary, seconds: float, player: Vector2 = Vector2.ZERO, boss: Dictionary = {}) -> Array:
	if e.hp>0 and Ground.active(e):Ground.begin_step(e,seconds,boss)
	return advance_prepared(e,seconds,player,boss)

## Schedule attacks from the frame snapshot; does not advance motion or hatch/rotation state.
static func advance_prepared(e: Dictionary,seconds: float,player: Vector2,boss: Dictionary) -> Array:
	var result: Array=[]
	if e.hp<=0:return result
	var channels: Array = Catalog.definition(int(e.kind)).get("fire_channels",[])
	var events: Array = AttackTimer.advance(e,channels,seconds,func(channel): return enabled(e,channel,boss))
	for event in events: result.append_array(emit(e,player,event.name,boss,event.at))
	result.append_array(_advance_special(e,seconds,player))
	return result

static func _advance_special(e: Dictionary, seconds: float, player: Vector2) -> Array:
	var attack: Dictionary = Catalog.definition(int(e.kind)).get("attack",{})
	var result: Array = []
	if attack.is_empty() or e.hp<=0: return result
	if attack.get("type","")=="aimed_fan": return _advance_aimed_fan(e,attack,player,seconds)
	if attack.get("type","")=="speed_spread": return _advance_speed_spread(e,attack,seconds)
	if attack.get("type","")!="spiral": return result
	# A disabled gate discards the partial interval, preserving the no-backlog rule.
	var enabled: bool=not attack.get("requires_stationary_x",false) or e.velocity.x==0
	var events: Array=AttackTimer.periodic(e,"spiral",seconds,attack.interval_seconds,enabled)
	if not enabled:return result
	var angle: float = float(e.get("attack_angle",deg_to_rad(attack.initial_degrees)))
	for _event in events:
		var velocity: Vector2 = Vector2.from_angle(angle)*float(attack.speed)
		_add(result,single_muzzle(e),velocity,int(attack.projectile_kind))
		if attack.get("opposed",false): _add(result,single_muzzle(e),-velocity,int(attack.projectile_kind))
		var direction: float = 1 if single_muzzle(e).x<=200 else -1
		angle = wrapf(angle+deg_to_rad(attack.step_degrees)*direction,-PI,PI)
	e.attack_angle = angle
	return result

static func _advance_speed_spread(e: Dictionary,attack: Dictionary,seconds: float) -> Array:
	var result: Array = []
	var vy: float = e.velocity.y
	var events: Array=AttackTimer.periodic(e,"speed_spread",seconds,attack.interval_seconds,vy>0)
	if vy<=0:
		e.erase("descent_start_speed")
		return result
	if not e.has("descent_start_speed"): e.descent_start_speed = vy
	var start_speed: float = e.descent_start_speed
	var span: float = float(attack.max_vertical_speed)-start_speed
	var progress: float = clampf((vy-start_speed)/span,0,1) if span>0 else 0.0
	var spread: float = deg_to_rad(attack.max_spread_degrees)*progress
	for _event in events:
		for i in range(attack.ports.size()):
			var port: Array = attack.ports[i]
			var direction: float = PI/2+spread*float(attack.spread_directions[i])
			_add(result,e.pos+Vector2(port[0],port[1]),Vector2.from_angle(direction)*float(attack.speed),int(attack.projectile_kind))
	return result

static func _advance_aimed_fan(e: Dictionary,attack: Dictionary,player: Vector2,seconds: float) -> Array:
	var result: Array = []
	for _event in AttackTimer.periodic(e,"aimed_fan",seconds,attack.interval_seconds):
		# Use the actual drawing centre, including large-craft offsets, and aim
		# the middle ray at the cockpit. Every ray starts at this same point.
		var definition: Dictionary = Catalog.definition(int(e.kind))
		var muzzle: Vector2 = Geometry.transform(definition,e.pos).origin
		result.append_array(Volleys.aimed_fan(muzzle,player+Pilot.COCKPIT,int(attack.count),deg_to_rad(attack.spread_degrees),float(attack.speed),int(attack.projectile_kind)))
	return result

static func _add(result: Array, pos: Vector2, velocity: Vector2, kind: int = 1) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})
