extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Ground=preload("res://scripts/ground_turret.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	for side in [-1,1]:
		var boss: Dictionary=Catalog.create(95,Vector2(200,70));boss.hp=1200
		var turret: Dictionary=Catalog.create(145,Vector2(175+side*60,215))
		Ground.initialize(turret,0,true,boss)
		var volleys: int=0
		for frame in range(360):
			var previous: float=turret.ground_angle
			var shots: Array=Fire.advance(turret,1.0/60,Vector2(0,400),boss)
			check(absf(turret.ground_angle-previous-TAU/360*(-side))<0.00001,"autocannon rotates smoothly every frame in correct direction")
			if not shots.is_empty():
				volleys+=1
				var expected: Vector2=Vector2.DOWN.rotated(TAU*volleys*0.18/6*(-side))
				check(shots.size()==2 and shots.all(func(s):return s.kind==1 and s.velocity.distance_to(expected*210)<0.001),"autocannon twin bullets follow rotation instead of aiming at player")
		check(volleys==33 and is_equal_approx(absf(turret.ground_angle),TAU),"autocannon completes six-second turn with 180ms cadence")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
