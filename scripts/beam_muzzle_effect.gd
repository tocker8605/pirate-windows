extends RefCounted
## Beam visuals only. Clocks are local; particles, budget and randomness belong to the shared pool.
const Attacks=preload("res://scripts/beam_attack.gd")
const Style=preload("res://scripts/beam_style.gd")
enum Stage { CHARGE=1, FIRING=2 }
const FIRING_PERIOD: float=0.05
var clocks: Dictionary={}
func reset() -> void:clocks.clear()
static func emitters(segments: Array) -> Array:
	var groups: Dictionary={}
	for beam in segments:
		if not Attacks.alive(beam):continue
		var key: String="%s:%s:%s"%[beam.source.get("kind",0),beam.source.get("entity_id",-1),beam.name]
		if not groups.has(key):groups[key]={"key":key,"origin":beam.origin,"color":beam.color,"stage":Stage.FIRING if beam.damaging else Stage.CHARGE,"directions":[]}
		groups[key].directions.append((beam.end-beam.origin).normalized())
	return groups.values()
func advance(segments: Array,seconds: float,pool) -> void:
	var next_clocks: Dictionary={}
	for muzzle in emitters(segments):
		var stage: int=muzzle.stage
		var key: String=muzzle.key+":"+str(stage)
		var period: float=FIRING_PERIOD if stage==Stage.FIRING else 0.08
		var elapsed: float=float(clocks.get(key,0))+seconds
		if not clocks.has(key) or elapsed>=period-0.00000003:
			elapsed=fposmod(elapsed,period) if clocks.has(key) else 0
			var color: Color=muzzle.color
			_particle(pool,muzzle.origin,Vector2.ZERO,6,12 if stage==Stage.FIRING else 4.5,Style.core_color(color,stage==Stage.FIRING),stage,true)
			for i in range(3 if stage==Stage.FIRING else 2):
				var radial: Vector2=Vector2.from_angle(pool.rng.randf()*TAU)
				var origin: Vector2=muzzle.origin+radial*(pool.rng.randf_range(1,3) if stage==Stage.FIRING else pool.rng.randf_range(9,14))
				var velocity: Vector2=radial*pool.rng.randf_range(1,2.2) if stage==Stage.FIRING else -radial*pool.rng.randf_range(1.3,1.9)
				_particle(pool,origin,velocity,pool.rng.randf_range(5,8),1.5 if stage==Stage.FIRING else 0.9,color.lightened(0.3),stage)
			if stage==Stage.FIRING:
				for direction in muzzle.directions:
					_particle(pool,muzzle.origin,direction*pool.rng.randf_range(1.6,2.5)+direction.orthogonal()*pool.rng.randf_range(-0.3,0.3),pool.rng.randf_range(5,7),1.5,color,stage)
		next_clocks[key]=elapsed
	clocks=next_clocks
func _particle(pool,pos: Vector2,velocity: Vector2,life: float,size: float,color: Color,stage: int,core: bool = false) -> void:
	var before: int=pool.particles.size()
	pool.emit(pos,velocity,life,size,color)
	if pool.particles.size()==before:return
	pool.particles[-1].enemy_beam_effect=true
	pool.particles[-1].enemy_beam_source=true
	pool.particles[-1].enemy_beam_stage=stage
	if core:
		pool.particles[-1].enemy_beam_core=true
		pool.particles[-1].halo_scale=1.6

static func draw_cores(canvas: Node2D,cores: Array,fraction: float) -> void:
	for part in cores:
		var t: float=part.age/part.life
		var p: Vector2=part.get("previous_pos",part.p).lerp(part.p,fraction)
		var opacity: float=1-smoothstep(0.5,1.0,t) if part.enemy_beam_stage==Stage.FIRING else (1-t)*0.7
		var radius: float=part.size*(0.8-0.12*t)
		canvas.draw_circle(p,radius,Color(part.color,opacity),true,-1,true)
		if part.enemy_beam_stage==Stage.FIRING:canvas.draw_circle(p,radius*0.55,Color(0.95,0.99,1,opacity),true,-1,true)
