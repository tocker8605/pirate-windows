extends RefCounted
## Volley geometry only: all velocities are pixels/second. Timers and gates live elsewhere.
const Rng=preload("res://scripts/random.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
static func vector(v: Array) -> Vector2:return Vector2(v[0],v[1])
static func add(result: Array,pos: Vector2,velocity: Vector2,kind: int) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})
static func heavy_cannon_angle(age: float) -> float:
	var phase: float=fposmod(age,8.0)
	return deg_to_rad(lerpf(-10.0,20.0,(1+cos(PI*phase/4.0))/2))
static func random_component(spec: Dictionary) -> float:
	return float(spec.base)+Rng.between(0,int(spec.count)-1)*float(spec.step)
static func aimed_fan(muzzle: Vector2,target: Vector2,count: int,arc: float,speed: float,kind: int) -> Array:
	var result: Array=[]
	var angle: float=(target-muzzle).angle() if target!=muzzle else PI/2
	for i in range(count):
		var offset: float=lerpf(-arc/2,arc/2,float(i)/(count-1)) if count>1 else 0
		add(result,muzzle,Vector2.from_angle(angle+offset)*speed,kind)
	return result
static func emit(e: Dictionary,player: Vector2,channel: Dictionary,boss: Dictionary = {},fired_at: float = -1,body_attack: Dictionary = {}) -> Array:
	var v: Dictionary=channel.get("volley",{})
	var result: Array=[]
	if v.is_empty():return result
	var p: Vector2=e.pos
	var direction: Vector2=(player-p).normalized()
	var kind: int=int(v.get("projectile_kind",channel.get("projectile_kind",1)))
	var ports: Array=v.get("ports",[])
	match str(v.type):
		"aimed":
			for port in ports:
				for degrees in v.get("angles_degrees",[0]):add(result,p+vector(port),direction.rotated(deg_to_rad(degrees))*float(v.speed),kind)
		"fixed":
			for port in ports:add(result,p+vector(port),vector(v.velocity),kind)
		"fixed_pair":
			for i in range(ports.size()):add(result,p+vector(ports[i]),vector(v.velocities[i]),kind)
		"motion_deflection":add(result,p+vector(ports[0]),Vector2(-e.velocity.x,float(v.down_speed)-absf(e.velocity.x)),kind)
		"height_sweep":add(result,p+vector(ports[0]),Vector2((10-absf(20-int(p.y)%41))*11.111111111111112,v.speed_y),kind)
		"motion_or_aim":
			var velocity: Vector2=Vector2(-e.velocity.x,float(v.speed_y)) if e.velocity.y>0 else direction*float(v.speed)
			for port in ports:add(result,p+vector(port),velocity,kind)
		"random":
			for port in ports:
				var origin: Vector2=p+vector(port)
				if v.has("origin_x_random"):origin.x+=random_component(v.origin_x_random)
				var vx: float=random_component(v.x_random)
				var vy: float=random_component(v.y_random) if v.has("y_random") else float(v.speed_y)+absf(vx)*float(v.get("abs_x_factor",0))
				add(result,origin,Vector2(vx,vy),kind)
		"pod_twin":
			add(result,p+vector(ports[0]),Vector2(-e.velocity.x/2,300),7)
			add(result,p+vector(ports[0]),Vector2(-e.velocity.x/3,200),5)
		"aimed_sequence":
			# One sequence per actor and named channel, advancing only when a volley fires.
			var steps: Dictionary=e.get("volley_steps",{})
			var key: String=channel.name
			var index: int=int(steps.get(key,0))
			var angle: float=deg_to_rad(float(v.angles_degrees[index%v.angles_degrees.size()]))
			for port in ports:add(result,p+vector(port),direction.rotated(angle)*float(v.speed),kind)
			steps[key]=(index+1)%v.angles_degrees.size()
			e.volley_steps=steps
		"sweeping_pair":
			var angle: float=heavy_cannon_angle(float(e.get("fire_age",0)) if fired_at<0 else fired_at)
			add(result,p+vector(ports[0]),direction.rotated(angle)*float(v.speed),kind)
			add(result,p+vector(ports[1]),direction.rotated(-angle)*float(v.speed),kind)
		"inherited_fan":
			for offset in v.velocity_offsets:add(result,p+vector(ports[0]),Vector2(-boss.get("velocity",Vector2.ZERO).x,0)+vector(offset),kind)
		"diving_pair":
			var vx: float=(2-floorf((p.y-280)/20))*33.333333333333336
			var vy: float=-floorf((500-p.y)/12)*33.333333333333336
			add(result,p+vector(ports[0]),Vector2(vx,vy),kind)
			add(result,p+vector(ports[0]),Vector2(-vx,vy),kind)
		"biased_aim":
			add(result,p+vector(ports[0]),direction*266.6666666666667+Vector2(-33.333333333333336,0),kind)
			add(result,p+vector(ports[0]),direction*300,kind)
			add(result,p+vector(ports[0]),direction*266.6666666666667+Vector2(33.333333333333336,0),kind)
		"rotating":
			var angle: float=float(e.get("radial_angle",deg_to_rad(channel.initial_degrees)))
			for i in range(int(channel.count)):
				var heading: float=angle+deg_to_rad(float(channel.spacing_degrees)*i)
				add(result,p+vector(ports[0]),Vector2.from_angle(heading)*float(channel.speed),int(channel.projectile_kind))
			e.radial_angle=wrapf(angle+deg_to_rad(channel.rotation_step_degrees)*float(channel.get("rotation_direction",1)),-PI,PI)
		"shoulder_fan":
			var port: Array=body_attack.ports[int(v.port_index)]
			result=aimed_fan(p+vector(port),player+Pilot.COCKPIT,int(body_attack.count),deg_to_rad(body_attack.spread_degrees),body_attack.speed,int(body_attack.projectile_kind))
	return result
