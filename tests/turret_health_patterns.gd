extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Ground=preload("res://scripts/ground_turret.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Combat=preload("res://scripts/combat.gd")
const Pool=preload("res://scripts/bullet_pool.gd")
class World extends Node:
	var boss: Dictionary={}
	var player:=Vector2(175,380)
	var scenery_distance: float=0
	var scroll_speed: float=0
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	check(Catalog.boss_definition(5).hp==3600,"stage5 boss has3600HP")
	for kind in [51,52,145,146]:check(Catalog.definition(kind).hp==(120 if kind<100 else 800),"turret%d has the requested HP"%kind)
	for kind in [51,145]:check(Catalog.fire_channel(kind,"ground_shot").interval_seconds==(0.24 if kind==51 else 0.18),"autocannon%d uses its configured240or180ms interval"%kind)
	check(Catalog.fire_channel(52,"ground_shot").interval_seconds==0.48 and Catalog.fire_channel(146,"ground_shot").interval_seconds==0.24,"energy turret cadences are480ms and240ms")
	var normal: Dictionary=Catalog.create(52,Vector2(150,150))
	Ground.initialize(normal,0,true)
	check(Fire.advance(normal,0.479,Vector2(275,350)).is_empty(),"normal energy turret waits a complete480ms")
	var shots: Array=Fire.advance(normal,0.001,Vector2(275,350))
	check(shots.size()==3 and shots.map(func(s):return s.kind)==[5,4,5],"small pink, large pink, small pink use existing distinct projectile sprites")
	check(shots[0].pos.distance_to(shots[1].pos)>7.999 and shots[1].pos.distance_to(shots[2].pos)>7.999 and shots[0].pos.distance_to(shots[1].pos)<8.001,"normal triplet has8px adjacent spacing")
	check(shots.all(func(s):return s.velocity.distance_to(shots[1].velocity)<0.001 and absf(s.velocity.length()-160)<0.001),"allthree bullets fly parallel at160px/s")
	check((Vector2(275,350)+Combat.Pilot.COCKPIT-shots[1].pos).normalized().distance_to(shots[1].velocity.normalized())<0.001,"the middle bullet aims at the current cockpit")
	var world=World.new()
	world.boss=Catalog.create(95,Vector2(200,80))
	for kind in [145,146]:
		var e: Dictionary=Catalog.create(kind,Vector2(100,215))
		world.boss.hp=world.boss.max_hp
		Ground.initialize(e,0,true,world.boss)
		Ground.advance(e,world,2)
		check(not Ground.ready(e) and e.deployment_progress==0,"turret%d stays closed despite start_exposed/Y position above bossHP gate"%kind)
		var threshold: float=1200 if kind==145 else 2400
		world.boss.hp=threshold+0.01
		Ground.advance(e,world,1)
		check(e.deployment_progress==0,"turret%d stays closed just above its threshold"%kind)
		world.boss.hp=threshold
		Ground.advance(e,world,0.4)
		check(not Ground.ready(e) and absf(e.deployment_progress-0.5)<0.001 and not Combat.shot_hits(e.pos+Vector2(25,25),e),"turret%d opens exactly at its inclusive threshold but stays invulnerable during deployment"%kind)
		Ground.advance(e,world,0.4)
		check(Ground.ready(e) and Combat.shot_hits(e.pos+Vector2(25,25),e),"turret%d becomes damageable after800ms opening"%kind)
		world.boss.hp=threshold+1
		check(Fire.advance(e,1,world.player,world.boss).is_empty() and not Ground.ready(e),"turret%d immediately disables fire and damage after boss healing"%kind)
		Ground.advance(e,world,0.8)
		check(e.deployment_progress==0,"turret%d retracts its hatch again above the threshold"%kind)
	world.boss.hp=2000
	for side in [-1,1]:
		var e: Dictionary=Catalog.create(146,Vector2(175+side*60,215))
		Ground.initialize(e,0,true,world.boss)
		for i in range(37):
			shots=Fire.advance(e,0.24,world.player,world.boss)
			var expected: Vector2=Vector2.DOWN.rotated(deg_to_rad((i+1)*0.24/8.0*360*(-side)))
			check(shots.size()==3 and shots[1].kind==4 and shots[0].kind==5 and shots[2].kind==5 and shots.all(func(s):return (s.velocity/160).distance_to(expected)<0.001),"side%d volley%d follows the continuous8second rotation in the correct direction"%[side,i])
			check(absf(shots[0].pos.distance_to(shots[1].pos)-8)<0.001 and absf(shots[1].pos.distance_to(shots[2].pos)-8)<0.001,"rotating triplet%d preserves8px spacing"%i)
	# Rotation must continue on frames without a shot, and complete exactly one turn.
	for side in [-1,1]:
		var rotor: Dictionary=Catalog.create(146,Vector2(175+side*60,215))
		Ground.initialize(rotor,0,true,world.boss)
		var emitted: int=0
		for frame in range(480):
			var previous: float=rotor.ground_angle
			var volley: Array=Fire.advance(rotor,1.0/60.0,world.player,world.boss)
			emitted+=volley.size()/3
			check(absf(float(rotor.ground_angle)-previous-TAU/480*(-side))<0.00001,"146 rotates smoothly on every frame, including between volleys")
		check(absf(absf(float(rotor.ground_angle))-TAU)<0.00001 and emitted==33,"146 completes one turn in8seconds independently of its240ms firing timer")
	# Projectile visible X and laser center must align with painted part bounds.
	for kind in [141,142,143,144]:
		var part: Dictionary=Catalog.create(kind,Vector2(200,100))
		var bounds: Array=Catalog.definition(kind).collision.shot_bounds
		var middle_y: float=(float(bounds[1])+float(bounds[3]))/2
		for edge in [0,2]:
			var x: float=float(bounds[edge])
			var inside: float=x+(0.01 if edge==0 else -0.01)
			var outside: float=x+(-0.01 if edge==0 else 0.01)
			check(Combat.shot_hits(part.pos+Vector2(inside-15,middle_y-15),part) and not Combat.shot_hits(part.pos+Vector2(outside-15,middle_y-15),part),"part%d visible bullet aligns with painted edge%d"%[kind,edge])
			check(Combat.beam_hits(Vector2(part.pos.x+inside-25,400),part) and not Combat.beam_hits(Vector2(part.pos.x+outside-25,400),part),"part%d visible laser aligns with painted edge%d"%[kind,edge])
	world.boss.hp=1000
	for kind in [51,52,145,146]:
		var channel: Dictionary=Catalog.fire_channel(kind,"ground_shot")
		var e: Dictionary=Catalog.create(kind,Vector2(150,360))
		Ground.initialize(e,0,true,world.boss)
		check(not Fire.advance(e,channel.interval_seconds,world.player,world.boss).is_empty(),"turret%d still fires at exactlyY360"%kind)
		e.pos.y=360.01
		var beyond: Array=Fire.advance(e,channel.interval_seconds,world.player,world.boss)
		check(beyond.is_empty() if kind<100 else not beyond.is_empty(),"Y360cutoff affects ordinary turrets only")
		e.pos.y=400
		check(Fire.advance(e,2,world.player,world.boss).is_empty() if kind<100 else not Fire.advance(e,2,world.player,world.boss).is_empty(),"ordinary turret stays silent while boss turret preserves oldY400fire eligibility")
		if kind<100:
			e.pos.y=360
			check(Fire.advance(e,channel.interval_seconds-0.001,world.player,world.boss).is_empty(),"disabled ordinary turret never banks shots")
			check(not Fire.advance(e,0.001,world.player,world.boss).is_empty(),"re-enabled ordinary turret waits full existing interval")
	var invalid: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	invalid.entities["51"].fire_channels[0].max_y="360"
	check(not Catalog.validate_document(invalid).is_empty(),"nonnumeric firingYlimit rejected")
	for kind in [51,52]:
		var hidden: Dictionary=Catalog.create(kind,Vector2(150,49.99))
		Ground.initialize(hidden,0,false)
		Ground.advance(hidden,world,0.4)
		check(hidden.deployment_progress==0,"ordinary turret stays hidden belowY50")
		hidden.pos.y=50;hidden.ground_anchor_y=50
		Ground.advance(hidden,world,0.4)
		check(is_equal_approx(hidden.deployment_progress,0.5) and not Ground.ready(hidden),"ordinary turret opens atY50 and remains invulnerable halfway through deployment")
		Ground.advance(hidden,world,0.4)
		check(Ground.ready(hidden),"ordinary turret completes deployment in unchanged800ms")
	world.free()
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
