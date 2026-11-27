extends RefCounted
## Volley geometry only: all velocities are pixels/second. Timers and gates live elsewhere.
const Formation=preload("res://scripts/projectile_formation.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const PoseMotion=preload("res://scripts/entity_pose_motion.gd")
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
	var pose_angle: float=PoseMotion.angle_at_event(e,fired_at)
	var p: Vector2=e.pos
	var direction: Vector2=(player-p).normalized()
	var kind: int=int(v.get("projectile_kind",channel.get("projectile_kind",1)))
	var ports: Array=v.get("ports",[])
	match str(v.type):
		"aimed":
			for port in ports:
				var origin: Vector2=Geometry.world_point(e,vector(port),pose_angle)
				var heading: Vector2=(player+Pilot.COCKPIT-origin).normalized() if v.get("aim_from_muzzle",false) else direction
				if heading==Vector2.ZERO and v.has("zero_aim_direction"):heading=vector(v.zero_aim_direction).normalized()
				for degrees in v.get("angles_degrees",[0]):add(result,origin,heading.rotated(deg_to_rad(degrees))*float(v.speed),kind)
		"oscillating":
			var age: float=float(e.get("fire_age",0)) if fired_at<0 else fired_at
			var progress: float=(1-cos(TAU*fposmod(age,float(v.period_seconds))/float(v.period_seconds)))/2
			for i in range(ports.size()):
				var span: Array=v.sweep_degrees[i]
				var angle: float=deg_to_rad(lerpf(float(span[0]),float(span[1]),progress))
				add(result,Geometry.world_point(e,vector(ports[i]),pose_angle),Vector2.DOWN.rotated(angle+pose_angle)*float(v.speed),kind)
		"expanding_ring":
			var heading: Vector2=Vector2.DOWN.rotated(pose_angle)
			for port in ports:
				var center: Vector2=Geometry.world_point(e,vector(port),pose_angle)
				for i in range(int(v.count)):
					var radial: Vector2=Vector2.from_angle(TAU*i/float(v.count)+pose_angle)
					result.append({"pos":center+radial*float(v.start_radius),"velocity":heading*float(v.speed),"kind":kind,
						"formation":Formation.state(v.formation_profile,radial)})
		"fixed":
			for port in ports:add(result,Geometry.world_point(e,vector(port),pose_angle),vector(v.velocity),kind)
		"fixed_pair":
			for i in range(ports.size()):add(result,Geometry.world_point(e,vector(ports[i]),pose_angle),vector(v.velocities[i]),kind)
		"motion_deflection":add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2(-e.velocity.x,float(v.down_speed)-absf(e.velocity.x)),kind)
		"height_sweep":add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2((10-absf(20-int(p.y)%41))*11.111111111111112,v.speed_y),kind)
		"motion_or_aim":
			var velocity: Vector2=Vector2(-e.velocity.x,float(v.speed_y)) if e.velocity.y>0 else direction*float(v.speed)
			for port in ports:add(result,Geometry.world_point(e,vector(port),pose_angle),velocity,kind)
		"random":
			for port in ports:
				var origin: Vector2=Geometry.world_point(e,vector(port),pose_angle)
				if v.has("origin_x_random"):origin.x+=random_component(v.origin_x_random)
				var vx: float=random_component(v.x_random)
				var vy: float=random_component(v.y_random) if v.has("y_random") else float(v.speed_y)+absf(vx)*float(v.get("abs_x_factor",0))
				add(result,origin,Vector2(vx,vy),kind)
		"pod_twin":
			add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2(-e.velocity.x/2,300),7)
			add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2(-e.velocity.x/3,200),5)
		"aimed_sequence":
			# One sequence per actor and named channel, advancing only when a volley fires.
			var steps: Dictionary=e.get("volley_steps",{})
			var key: String=channel.name
			var index: int=int(steps.get(key,0))
			var angle: float=deg_to_rad(float(v.angles_degrees[index%v.angles_degrees.size()]))
			for port in ports:add(result,Geometry.world_point(e,vector(port),pose_angle),direction.rotated(angle)*float(v.speed),kind)
			steps[key]=(index+1)%v.angles_degrees.size()
			e.volley_steps=steps
		"sweeping_pair":
			var angle: float=heavy_cannon_angle(float(e.get("fire_age",0)) if fired_at<0 else fired_at)
			add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),direction.rotated(angle)*float(v.speed),kind)
			add(result,Geometry.world_point(e,vector(ports[1]),pose_angle),direction.rotated(-angle)*float(v.speed),kind)
		"inherited_fan":
			for offset in v.velocity_offsets:add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2(-boss.get("velocity",Vector2.ZERO).x,0)+vector(offset),kind)
		"diving_pair":
			var vx: float=(2-floorf((p.y-280)/20))*33.333333333333336
			var vy: float=-floorf((500-p.y)/12)*33.333333333333336
			add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2(vx,vy),kind)
			add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2(-vx,vy),kind)
		"rotating":
			var angles: Dictionary=e.get("radial_angles",{})
			var angle: float=float(angles.get(channel.name,deg_to_rad(channel.initial_degrees)))
			for i in range(int(channel.count)):
				var heading: float=angle+deg_to_rad(float(channel.spacing_degrees)*i)
				add(result,Geometry.world_point(e,vector(ports[0]),pose_angle),Vector2.from_angle(heading)*float(channel.speed),int(channel.projectile_kind))
			angles[channel.name]=wrapf(angle+deg_to_rad(channel.rotation_step_degrees)*float(channel.get("rotation_direction",1)),-PI,PI)
			e.radial_angles=angles
		"shoulder_fan":
			var port: Array=body_attack.ports[int(v.port_index)]
			result=aimed_fan(Geometry.world_point(e,vector(port),pose_angle),player+Pilot.COCKPIT,int(body_attack.count),deg_to_rad(body_attack.spread_degrees),body_attack.speed,int(body_attack.projectile_kind))
	return result
