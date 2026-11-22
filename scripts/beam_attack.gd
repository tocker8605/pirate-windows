extends RefCounted
## Data-driven persistent beam hazards. Rendering and collision consume the same segments.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Shapes=preload("res://scripts/collision_geometry.gd")
const Timeline=preload("res://scripts/beam_timeline.gd")
static func sample(owner: Dictionary,spec: Dictionary,age: float,selected: Dictionary = {}) -> Array:
	if owner.get("hp",0)<=0:return []
	var pattern: Dictionary=Timeline.phase_for(owner,spec) if selected.is_empty() else selected
	var exposure: Dictionary=Timeline.exposure(spec,pattern,age)
	if exposure.is_empty():return []
	var continuous: bool=pattern.continuous
	var telegraph: bool=exposure.telegraph
	var active_age: float=exposure.active_age
	var progress: float=exposure.progress
	var visible_width: float=float(spec.telegraph_width) if telegraph else float(spec.width)
	var transition: float=float(spec.width_transition_seconds)
	if not telegraph and transition>0:
		var edge_time: float=active_age if continuous else minf(active_age,float(spec.active_seconds)-active_age)
		visible_width=lerpf(float(spec.telegraph_width),float(spec.width),smoothstep(0,transition,edge_time))
	var origin: Vector2=Geometry.world_point(owner,spec.origin)
	var result: Array=[]
	var swing: float=0 if telegraph else sin(TAU*active_age/float(pattern.swing_period_seconds))*float(pattern.swing_radians)
	for sweep in pattern.beams:
		# Do not wrap/shortest-path interpolate: the signed span specifies the sweep direction.
		var angle: float=lerpf(float(sweep.from_radians),float(sweep.to_radians),progress)+swing
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
		var clock: Dictionary=states.get(spec.name,Timeline.new_clock())
		if not Timeline.advance(clock,owner,spec,seconds,scroll_stopped):continue
		states[spec.name]=clock
		result.append_array(sample(owner,spec,Timeline.sample_age(clock),clock.phase))
	owner.beam_states=states
	return result
static func advance_world(g: Node,seconds: float) -> void:
	g.enemy_beams.clear()
	if g.boss_death_remaining_seconds>0:return
	var stopped: bool=absf(g.scroll_speed)<Timeline.EPSILON
	if not g.boss.is_empty():g.enemy_beams.append_array(advance(g.boss,seconds,stopped))
	for actor in g.enemies:g.enemy_beams.append_array(advance(actor,seconds,stopped))
static func alive(beam: Dictionary) -> bool:return beam.source.get("hp",0)>0
static func hits(beam: Dictionary,center: Vector2,radius: float) -> bool:
	return beam.damaging and alive(beam) and Shapes.circle_segment_hits(center,radius,beam.origin,beam.end,float(beam.width))
