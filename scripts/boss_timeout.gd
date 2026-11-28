extends RefCounted
## Boss-owned deadline hazards: separate from damageable enemies and boss parts.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const Profile=preload("res://scripts/beam_profile.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
const SETTINGS_PATH: String="res://data/boss_timeout.json"
const EPSILON: float=0.0000001
var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
var owner: Dictionary={}
var elapsed: float=0
var limit: float=0
var finished: bool=false
var actors: Array=[]
var beam_profile: Dictionary={}
func _init() -> void:
	# Reuse stage5 beam width, growth envelope, color layers, particles and collision.
	var spec: Dictionary=Catalog.definition(95).beam_attacks[0].duplicate(true)
	spec.name="reaper_tracking"
	spec.gate="always"
	spec.origin=[25,7]
	spec.color=settings.beam_color
	spec.continuous=true
	spec.beams=[{"from_degrees":0,"to_degrees":0}]
	spec.erase("health_phases")
	beam_profile=Profile.prepare(spec)
func reset() -> void:
	for actor in actors:actor.hp=0
	actors.clear()
	owner={}
	elapsed=0
	limit=0
	finished=false
func start(boss: Dictionary,stage: int) -> void:
	reset()
	owner=boss
	limit=float(settings.seconds_by_stage[stage-1])
func visible() -> bool:
	return not finished and not owner.is_empty() and owner.get("hp",0)>0
func remaining() -> int:
	return maxi(0,ceili(limit-elapsed-EPSILON)) if visible() else -1
func advance(player: Vector2,seconds: float) -> Array:
	if not visible():return []
	elapsed+=seconds
	if elapsed+EPSILON<limit:return []
	if actors.is_empty():
		for i in range(settings.positions.size()):
			var point: Array=settings.positions[i]
			actors.append({"pos":Vector2(point[0],point[1]),"pose_pivot":Vector2(25,25),"pose_angle":0.0,"hp":1.0,"entity_id":-1001-i,"scale":float(settings.initial_scale),"opacity":float(settings.initial_opacity)})
	var age: float=maxf(0,elapsed-limit)
	var progress: float=clampf(age/float(settings.appearance_seconds),0,1)
	var result: Array=[]
	for actor in actors:
		var center: Vector2=actor.pos+Vector2(25,25)
		var heading: Vector2=(player+Pilot.COCKPIT-center).normalized()
		if heading==Vector2.ZERO:heading=Vector2.DOWN
		actor.pose_angle=heading.angle()+PI/2
		actor.scale=lerpf(float(settings.initial_scale),1,progress)
		actor.opacity=lerpf(float(settings.initial_opacity),1,progress)
		if age+EPSILON>=float(settings.appearance_seconds):
			result.append_array(Beams.sample(actor,beam_profile,maxf(0,age-float(settings.appearance_seconds))))
	return result
## Return explosion positions; lifecycle owns effects and sounds.
func defeat() -> Array:
	if finished:return []
	finished=true
	var positions: Array=[]
	for actor in actors:
		actor.hp=0
		positions.append(actor.pos)
	actors.clear()
	return positions
