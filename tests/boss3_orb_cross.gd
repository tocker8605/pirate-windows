extends SceneTree
const Motion = preload("res://scripts/boss_orb_motion.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func stationary(id: int) -> Dictionary:
	var e: Dictionary = Catalog.create(id,Vector2(75 if id==123 else 275,75))
	Motion.prepare(e,{"hp":1500,"max_hp":1500})
	return e
func _initialize() -> void:
	for id in [123,124]:
		var e: Dictionary = stationary(id)
		var player := Vector2(175,380)
		var boss: Dictionary = {"pos":Vector2(200,100)}
		check(Fire.advance(e,0.299,player,boss).is_empty(),"orb%d waits300ms even above boss"%id)
		var first: Array = Fire.advance(e,0.001,player,boss)
		check(first.size()==4 and first.all(func(s): return s.kind==3 and is_equal_approx(s.velocity.length(),(9/0.03))),"orb%d emits four long orange streaks at original speed9"%id)
		check(first.all(func(s): return s.pos==Vector2(100 if id==123 else 300,100)),"orb%d cross originates at sprite centre"%id)
		check(first[0].velocity.distance_to((Vector2(0,9))/0.03)<0.001 and first[1].velocity.distance_to((Vector2(-9,0))/0.03)<0.001 and first[2].velocity.distance_to((Vector2(0,-9))/0.03)<0.001 and first[3].velocity.distance_to((Vector2(9,0))/0.03)<0.001,"orb%d first volley covers all cardinal directions"%id)
		var next: Array = Fire.advance(e,0.3,Vector2.ZERO,boss)
		var expected: float = deg_to_rad(10 if id==123 else -10)
		var rotation := true
		for i in range(4): rotation = rotation and is_equal_approx(angle_difference(first[i].velocity.angle(),next[i].velocity.angle()),expected)
		check(rotation,"orb%d entire cross rotates%ddegrees per volley independently of player"%[id,10 if id==123 else -10])
		var orthogonal := true
		for i in range(4): orthogonal = orthogonal and is_equal_approx(angle_difference(next[i].velocity.angle(),next[(i+1)%4].velocity.angle()),PI/2)
		check(orthogonal,"orb%d retains90degree cross spacing after rotation"%id)
		e = stationary(id)
		var count := 0
		var state: int = Rng.state
		for i in range(600): count += Fire.advance(e,1.0/60,player,boss).size()
		check(count==132,"orb%d emits33crosses over10seconds without cadence drift"%id)
		check(Rng.state==state,"orb%d rotation consumes no RNG"%id)
		check(Fire.advance(stationary(id),0.9,player,boss).size()==12,"orb%d catchup emits all three rotated crosses"%id)
		e.hp = 0
		check(Fire.advance(e,1,player,boss).is_empty(),"destroyed orb%d cannot emit"%id)
	var a: Dictionary = stationary(123)
	var b: Dictionary = stationary(124)
	Fire.advance(a,0.6)
	Fire.advance(b,0.3)
	check(is_equal_approx(angle_difference(deg_to_rad(90),a.radial_angle),deg_to_rad(20)) and is_equal_approx(angle_difference(deg_to_rad(90),b.radial_angle),deg_to_rad(-10)),"both orbs own independent opposite rotation states")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
