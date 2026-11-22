extends RefCounted
## Data-driven persistent beam hazards. Rendering and collision consume the same segments.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Shapes=preload("res://scripts/collision_geometry.gd")
const EPSILON: float=0.0000001
static func sample(owner: Dictionary,spec: Dictionary,age: float) -> Array:
	if owner.get("hp",0)<=0:return []
	var phase: float=fposmod(age+EPSILON,float(spec.period_seconds))
	var telegraph: bool=phase<float(spec.telegraph_seconds)
	if not telegraph and phase>=float(spec.telegraph_seconds)+float(spec.active_seconds):return []
	var progress: float=0.0 if telegraph else clampf((phase-float(spec.telegraph_seconds))/float(spec.active_seconds),0,1)
	var visible_width: float=float(spec.telegraph_width) if telegraph else float(spec.width)
	var transition: float=float(spec.width_transition_seconds)
	if not telegraph and transition>0:
		var active_age: float=phase-float(spec.telegraph_seconds)
		var edge_time: float=minf(active_age,float(spec.active_seconds)-active_age)
		visible_width=lerpf(float(spec.telegraph_width),float(spec.width),smoothstep(0,transition,edge_time))
	var origin: Vector2=Geometry.world_point(owner,spec.origin)
	var result: Array=[]
	for sweep in spec.beams:
		# Do not wrap/shortest-path interpolate: the signed span specifies the sweep direction.
		var angle: float=lerpf(float(sweep.from_radians),float(sweep.to_radians),progress)
		var direction: Vector2=Vector2.UP.rotated(angle+float(owner.get("pose_angle",0)))
		result.append({"source":owner,"name":spec.name,"origin":origin,"end":origin+direction*float(spec.length),
			"width":float(spec.telegraph_width) if telegraph else float(spec.width),"visual_width":visible_width,"damaging":not telegraph,
			"color":spec.color,"damage_scale":float(spec.damage_scale),"age":age})
	return result
static func advance(owner: Dictionary,seconds: float,scroll_stopped: bool) -> Array:
	if owner.is_empty() or owner.get("hp",0)<=0:return []
	var specs: Array=Catalog.for_actor(owner).get("beam_profiles",[])
	if specs.is_empty():return []
	var states: Dictionary=owner.get("beam_states",{})
	var result: Array=[]
	for spec in specs:
		var clock: Dictionary=states.get(spec.name,{"started":false,"age":0.0})
		if not clock.started:
			if spec.gate=="scroll_stopped" and not scroll_stopped:continue
			clock.started=true # One-shot start gate; later scroll changes do not reset the cycle.
		else:clock.age=float(clock.age)+seconds
		states[spec.name]=clock
		result.append_array(sample(owner,spec,float(clock.age)))
	owner.beam_states=states
	return result
static func advance_world(g: Node,seconds: float) -> void:
	g.enemy_beams.clear()
	if g.boss_death_remaining_seconds>0:return
	var stopped: bool=absf(g.scroll_speed)<EPSILON
	if not g.boss.is_empty():g.enemy_beams.append_array(advance(g.boss,seconds,stopped))
	for actor in g.enemies:g.enemy_beams.append_array(advance(actor,seconds,stopped))
static func alive(beam: Dictionary) -> bool:return beam.source.get("hp",0)>0
static func hits(beam: Dictionary,center: Vector2,radius: float) -> bool:
	return beam.damaging and alive(beam) and Shapes.circle_segment_hits(center,radius,beam.origin,beam.end,float(beam.width))
