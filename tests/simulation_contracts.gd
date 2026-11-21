extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Ground=preload("res://scripts/ground_turret.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Attachment=preload("res://scripts/entity_attachment.gd")
const Scheduler=preload("res://scripts/attack_timer.gd")
const Geometry=preload("res://scripts/player_projectile_geometry.gd")
const Combat=preload("res://scripts/combat.gd")
class World extends Node:
	var boss: Dictionary={}
	var player:=Vector2(175,380)
	var scenery_distance: float=0
	var scroll_speed: float=30
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var world=World.new()
	world.boss=Catalog.create(95,Vector2(200,70))
	for kind in [51,52,145,146]:
		var standalone: Dictionary=Catalog.create(kind,Vector2(100,100))
		var phased: Dictionary=standalone.duplicate(true)
		Ground.initialize(standalone,0,false,world.boss)
		Ground.initialize(phased,0,false,world.boss)
		for frame in range(240):
			world.boss.hp=3000 if frame<40 else (2000 if frame<120 else 1000)
			world.boss.pos.y=70+frame*0.1
			world.scenery_distance=frame*0.5
			Ground.begin_step(phased,1.0/60,world.boss)
			var before: Array=[phased.deployment_progress,phased.get("ground_angle",0),phased.pos]
			var a: Array=Fire.advance_prepared(phased,1.0/60,world.player,world.boss)
			check(before==[phased.deployment_progress,phased.get("ground_angle",0),phased.pos],"attack scheduling cannot advance hatch, rotation or position")
			var b: Array=Fire.advance(standalone,1.0/60,world.player,world.boss)
			check(a==b,"explicit phases preserve standalone volley timing and direction")
			Ground.finish_step(phased,world,1.0/60)
			Ground.advance(standalone,world,1.0/60)
			check(phased.pos==standalone.pos and phased.deployment_progress==standalone.deployment_progress,"explicit phases preserve position and hatch progression")
			if kind in [145,146]:check(phased.pos.x==100 and is_equal_approx(phased.pos.y,world.boss.pos.y+Catalog.definition(kind).attachment.offset[1]),"boss-relative floor parts use one attached Y and preserve authored X")
	var owner: Dictionary={}
	check(Scheduler.periodic(owner,"a",0.19,0.2).is_empty(),"periodic attack waits the whole interval")
	check(Scheduler.periodic(owner,"b",0.1,0.2).is_empty(),"another attack clock cannot advance the first")
	check(Scheduler.periodic(owner,"a",0.01,0.2).size()==1,"first attack completes its own interval")
	check(Scheduler.periodic(owner,"b",10,0.2,false).is_empty() and Scheduler.periodic(owner,"b",0.19,0.2).is_empty(),"disabled attack discards its partial interval without banking")
	check(Scheduler.periodic(owner,"b",0.01,0.2).size()==1,"reenabled attack resumes at one complete interval")
	check(Scheduler.periodic(owner,"c",0.19,0.2).is_empty() and Scheduler.periodic(owner,"c",0.09,0.1,true,true).is_empty() and Scheduler.periodic(owner,"c",0.01,0.1,true,true).size()==1,"period change restarts cadence when explicitly requested")
	check(Scheduler.periodic({},"catchup",0.72,0.24).size()==3,"coarse step emits all complete due volleys")
	for kind in Catalog.ids():
		var actor: Dictionary=Catalog.create(kind,Vector2(200,100))
		actor.hatch_enabled=true
		actor.deployment_progress=1.0
		check(not Catalog.definition(kind).collision.has("shot_offset"),"collision metadata has no stored-projectile coordinate correction")
		for point in [Vector2(100,90),Vector2(190,125),Vector2(220,140)]:
			check(Combat.shot_hits(point,actor)==Combat.shot_point_hits(Geometry.shot_centre(point),actor),"stored-shot adapter and world-centre collision agree")
			check(Combat.beam_hits(point,actor)==Combat.beam_origin_hits(Geometry.beam_origin(point),actor),"stored-player adapter and world beam collision agree")
	world.free()
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
