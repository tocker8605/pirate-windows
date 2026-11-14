class_name PirateEnemyFire
extends RefCounted
const CoreMotion = preload("res://scripts/boss_core_motion.gd")
const AttackTimer = preload("res://scripts/attack_timer.gd")
const Boss = preload("res://scripts/boss.gd")
const Rng = preload("res://scripts/random.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
## Named volley geometry and independent per-actor attacks.
## Legacy aimed volleys retain their top-left aim formula; new fans use cockpit aim.
static func aim(enemy: Vector2, player: Vector2, speed: float) -> Vector2:
	var delta: Vector2 = player - enemy
	var denominator: float = floorf(Vector2(delta.x, delta.y + 20).length())
	# The original skipped one coincidence case but could still divide by zero.
	return delta * speed / denominator if denominator > 0 else Vector2.ZERO

static func single_muzzle(e: Dictionary, y: float = 25) -> Vector2:
	return e.pos+Vector2(25,y)

static func enabled(e: Dictionary, channel: Dictionary, boss: Dictionary = {}) -> bool:
	var v: Vector2 = e.velocity
	var y: float = e.pos.y
	var by: float = boss.get("pos",Vector2.ZERO).y
	match str(channel.gate):
		"aim_window": return v.y<(133.33333333333334 - 0.0001) and v.y> (-166.66666666666669 + 0.0001)
		"moving": return v.x!=0
		"stationary_aim": return v.x==0 and v.y> (-33.333333333333336 + 0.0001)
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

static func emit(e: Dictionary, player: Vector2, attack: String, boss: Dictionary = {}) -> Array:
	var result: Array = []
	var p: Vector2 = e.pos
	var v: Vector2 = e.velocity*0.03
	var kind: int = int(e.kind)
	var target: Vector2 = aim(p,player,1)
	match kind:
		1: _add(result,p+Vector2(25,20),(target*7)*33.333333333333336)
		2:
			if attack=="moving": _add(result,p+Vector2(25,20),(Vector2(-v.x,11-absf(v.x)))*33.333333333333336)
			else: _add(result,p+Vector2(25,20),(target*9)*33.333333333333336,3)
		3: _add(result,single_muzzle(e,30),(Vector2((10-absf(20-int(p.y)%41))/3.0,8))*33.333333333333336,5)
		4: _add(result,single_muzzle(e),(target*9)*33.333333333333336,4)
		6:
			var velocity: Vector2 = Vector2(-v.x,7) if v.y>0 else target*9
			_add(result,p+Vector2(5,30),(velocity)*33.333333333333336,7)
			_add(result,p+Vector2(35,30),(velocity)*33.333333333333336,7)
		7:
			_add(result,single_muzzle(e),(target*9)*33.333333333333336,5)
			_add(result,single_muzzle(e),(target*7+Vector2(-2,0))*33.333333333333336,5)
			_add(result,single_muzzle(e),(target*7+Vector2(2,0))*33.333333333333336,5)
		8: _add(result,p+Vector2(25,30),(Vector2(0,-1))*33.333333333333336,2)
		9: _add(result,single_muzzle(e),(Vector2(3-Rng.between(0,6),-1-Rng.between(0,2)))*33.333333333333336,8)
		10:
			if attack=="twin":
				_add(result,p+Vector2(10,40),(Vector2(0,8))*33.333333333333336)
				_add(result,p+Vector2(40,40),(Vector2(0,8))*33.333333333333336)
			else: _add(result,p+Vector2(25,20),(target*7)*33.333333333333336)
		11:
			_add(result,single_muzzle(e),(Vector2(-v.x/2,9))*33.333333333333336,7)
			_add(result,single_muzzle(e),(Vector2(-v.x/3,6))*33.333333333333336,5)
		21:
			if attack=="missiles":
				_add(result,p+Vector2(0,40),(Vector2(-1,-1))*33.333333333333336,2)
				_add(result,p+Vector2(50,40),(Vector2(1,-1))*33.333333333333336,2)
			else: _add(result,p+Vector2(25,40),(target*10)*33.333333333333336)
		22:
			if attack=="plasma": _add(result,single_muzzle(e),(target*9+Vector2(3-int(p.y)%7,0))*33.333333333333336,5)
			else: _add(result,single_muzzle(e),(target*10)*33.333333333333336,7)
		41:
			if attack=="aim":
				_add(result,p+Vector2(-20,40),(target*10)*33.333333333333336,6)
				_add(result,p+Vector2(70,40),(target*10)*33.333333333333336,6)
			else: _add(result,p+Vector2(25,40),(Vector2(0,-1))*33.333333333333336,2)
		42:
			_add(result,p+Vector2(-10,40),(Vector2(2-Rng.between(0,4),-1-Rng.between(0,2)))*33.333333333333336,2)
			_add(result,p+Vector2(60,40),(Vector2(2-Rng.between(0,4),-1-Rng.between(0,2)))*33.333333333333336,2)
		101,102:
			var vx: int = 3-Rng.between(0,6)
			_add(result,p+Vector2(25,20),(Vector2(vx,-10+absi(vx)))*33.333333333333336,5)
		111: _add(result,p+Vector2(30,55),(Vector2(-boss.get("velocity",Vector2.ZERO).x*0.03,8))*33.333333333333336)
		112:
			var vx: float = -boss.get("velocity",Vector2.ZERO).x*0.03
			_add(result,p+Vector2(20,55),(Vector2(vx,8))*33.333333333333336,7)
			_add(result,p+Vector2(20,55),(Vector2(vx-2,7))*33.333333333333336,7)
			_add(result,p+Vector2(20,55),(Vector2(vx+2,7))*33.333333333333336,7)
		113:
			var vx: float = 2-floorf((p.y-280)/20)
			var vy: float = -floorf((500-p.y)/12)
			_add(result,single_muzzle(e),(Vector2(vx,vy))*33.333333333333336,8)
			_add(result,single_muzzle(e),(Vector2(-vx,vy))*33.333333333333336,8)
		121,122:
			var muzzle: Vector2 = p+Vector2(5 if kind==121 else 45,50)
			_add(result,muzzle,(target*8+Vector2(-1,0))*33.333333333333336,5)
			_add(result,muzzle,(target*9)*33.333333333333336,5)
			_add(result,muzzle,(target*8+Vector2(1,0))*33.333333333333336,5)
		123,124: result.append_array(_rotating_volley(e,Catalog.fire_channel(kind,attack),single_muzzle(e)))
		131,132:
			if attack=="plasma": _add(result,Boss.claw_muzzle(e),(target*9+Vector2(3-int(p.y)%7,0))*33.333333333333336,5)
			else: _add(result,Boss.claw_muzzle(e),(target*10)*33.333333333333336,7)
		133:
			if attack=="radial":
				result.append_array(_rotating_volley(e,Catalog.fire_channel(kind,attack),p+Vector2(25,20)))
			else:
				var vx: int = 3-Rng.between(0,6)
				_add(result,p+Vector2(25,20),(Vector2(vx,-5+absi(vx)))*33.333333333333336,8)
	return result

# Elapsed seconds avoids quantizing the 100ms cadence to the legacy 60ms fire clock.
# Bullets fly straight; sequential emission angles form the expanding spiral.
static func advance(e: Dictionary, seconds: float, player: Vector2 = Vector2.ZERO, boss: Dictionary = {}) -> Array:
	var result: Array = []
	if e.hp<=0: return result
	var channels: Array = Catalog.definition(int(e.kind)).get("fire_channels",[])
	var events: Array = AttackTimer.advance(e,channels,seconds,func(channel): return enabled(e,channel,boss) and (channel.name=="rotating_cross" or channel.gate=="core_settled" or not (player.x==e.pos.x and player.y==e.pos.y-20)))
	for event in events: result.append_array(emit(e,player,event.name,boss))
	result.append_array(_advance_special(e,seconds,player))
	return result

static func _advance_special(e: Dictionary, seconds: float, player: Vector2) -> Array:
	var attack: Dictionary = Catalog.definition(int(e.kind)).get("attack",{})
	var result: Array = []
	if attack.is_empty() or e.hp<=0: return result
	if attack.get("type","")=="aimed_fan": return _advance_aimed_fan(e,attack,player,seconds)
	if attack.get("type","")=="speed_spread": return _advance_speed_spread(e,attack,seconds)
	if attack.get("type","")!="spiral": return result
	# Horizontal travel pauses the sweep and discards partial cadence: no queued burst on stopping.
	if attack.get("requires_stationary_x",false) and e.velocity.x!=0:
		e.attack_elapsed = 0.0
		return result
	var interval: float = attack.interval_seconds
	e.attack_elapsed = float(e.get("attack_elapsed",0.0))+seconds
	var angle: float = float(e.get("attack_angle",deg_to_rad(attack.initial_degrees)))
	while e.attack_elapsed>=interval-0.0000001:
		e.attack_elapsed = maxf(0,e.attack_elapsed-interval)
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
	if vy<=0:
		e.attack_elapsed = 0.0
		e.erase("descent_start_speed")
		return result
	if not e.has("descent_start_speed"): e.descent_start_speed = vy
	var start_speed: float = e.descent_start_speed
	var span: float = float(attack.max_vertical_speed)-start_speed
	var progress: float = clampf((vy-start_speed)/span,0,1) if span>0 else 0.0
	var spread: float = deg_to_rad(attack.max_spread_degrees)*progress
	var elapsed: float = float(e.get("attack_elapsed",0.0))+seconds
	while elapsed>=float(attack.interval_seconds)-0.0000001:
		elapsed = maxf(0,elapsed-float(attack.interval_seconds))
		for i in range(attack.ports.size()):
			var port: Array = attack.ports[i]
			var direction: float = PI/2+spread*float(attack.spread_directions[i])
			_add(result,e.pos+Vector2(port[0],port[1]),Vector2.from_angle(direction)*float(attack.speed),int(attack.projectile_kind))
	e.attack_elapsed = elapsed
	return result

static func _advance_aimed_fan(e: Dictionary,attack: Dictionary,player: Vector2,seconds: float) -> Array:
	var result: Array = []
	var elapsed: float = float(e.get("attack_elapsed",0.0))+seconds
	while elapsed>=float(attack.interval_seconds)-0.0000001:
		elapsed = maxf(0,elapsed-float(attack.interval_seconds))
		# Use the actual drawing centre, including large-craft offsets, and aim
		# the middle ray at the cockpit. Every ray starts at this same point.
		var definition: Dictionary = Catalog.definition(int(e.kind))
		var muzzle: Vector2 = e.pos+definition.draw_offset+definition.draw_size/2
		var target: Vector2 = player+Pilot.COCKPIT-muzzle
		var aim_angle: float = target.angle() if target.length_squared()>0 else PI/2
		var count: int = int(attack.count)
		var arc: float = deg_to_rad(attack.spread_degrees)
		for i in range(count):
			var offset: float = lerpf(-arc/2,arc/2,float(i)/(count-1)) if count>1 else 0.0
			_add(result,muzzle,Vector2.from_angle(aim_angle+offset)*float(attack.speed),int(attack.projectile_kind))
	e.attack_elapsed = elapsed
	return result

static func _rotating_volley(e: Dictionary, channel: Dictionary, muzzle: Vector2) -> Array:
	var result: Array = []
	var angle: float = float(e.get("radial_angle",deg_to_rad(channel.initial_degrees)))
	for i in range(int(channel.count)):
		var direction: float = angle+deg_to_rad(float(channel.spacing_degrees)*i)
		_add(result,muzzle,Vector2.from_angle(direction)*float(channel.speed),int(channel.projectile_kind))
	e.radial_angle = wrapf(angle+deg_to_rad(channel.rotation_step_degrees)*float(channel.get("rotation_direction",1)),-PI,PI)
	return result

static func _add(result: Array, pos: Vector2, velocity: Vector2, kind: int = 1) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})
