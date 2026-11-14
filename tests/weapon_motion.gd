extends SceneTree
const Weapons = preload("res://scripts/player_weapons.gd")
const Clock = preload("res://scripts/timing.gd")
const Preview = preload("res://scripts/weapon_preview.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void:
	var player := Vector2(100,400)
	var units: float = Clock.FIXED_STEP_SECONDS
	for power in [3,4]:
		var spread: Array = Weapons.volley(player,1,power)
		var straight: Array = Weapons.volley(player,2,power)
		var higher: Array = Weapons.volley(player,1,5)
		check(spread[0].pos.x==higher[0].pos.x and spread[1].pos.x==higher[1].pos.x,"power%d wide ports match the higher-power spread origins"%power)
		check(spread[1].pos.x-spread[0].pos.x==30 and absf(straight[0].pos.x-straight[1].pos.x)==12,"power%d spread origins are2.5times the straight weapon gap"%power)
	for power in range(1,8):
		var shots: Array = Weapons.volley(player,3,power,Preview.DemoRandom.new())
		var fixed: bool = true
		for shot in shots:
			var x: float = shot.pos.x
			for i in range(90):
				Weapons.advance(shot,Vector2(100+sin(i)*900,400),units)
				fixed = fixed and shot.pos.x==x
		check(fixed,"type3 power%d X stays fixed despite large pilot horizontal motion"%power)
	var a = {"kind":4,"pos":Vector2(111,400)}
	var b: Dictionary = a.duplicate()
	var first: float = a.pos.y
	Weapons.advance(a,Vector2(-10000,400),units)
	Weapons.advance(b,Vector2(10000,400),units)
	check(a.pos==b.pos,"type3 trajectory is independent of pilot X")
	var early: float = first-a.pos.y
	for i in range(35): Weapons.advance(a,player,units)
	var before: float = a.pos.y
	Weapons.advance(a,player,units)
	check(before-a.pos.y>early*2,"type3 accelerates vertically after launch")
	a = {"kind":4,"pos":Vector2(111,400)}
	b = a.duplicate()
	Weapons.advance(a,Vector2(100,400),units)
	Weapons.advance(b,Vector2(100,450),units)
	check(b.pos.y<a.pos.y and a.pos.x==b.pos.x,"pilot Y still determines the intended vertical acceleration")
	var preview = Preview.new()
	Rng.state = 0x50000
	for weapon in range(1,4):
		for power in [4,7]:
			var paths: Array = preview.trajectory_paths(weapon,power)
			var actual: Array = Weapons.volley(Vector2.ZERO,weapon,power,Preview.DemoRandom.new())
			var matches: bool = paths.size()==actual.size()
			for i in range(actual.size()):
				matches = matches and paths[i].points.size()==Preview.TRACE_TICKS+1
				for tick in range(Preview.TRACE_TICKS): Weapons.advance(actual[i],Vector2.ZERO,units)
				matches = matches and paths[i].points[-1].distance_to(actual[i].pos+Vector2(15,12))<0.001
			check(matches,"type%d power%d legend uses the real native-tick trajectory"%[weapon,power])
	check(Rng.state==0x50000,"all trajectory legends preserve gameplay RNG state")
	for i in range(20): preview.trajectory_paths(3,7)
	check(preview.path_cache.size()==6,"legend paths are cached rather than simulated every draw")
	check(Preview.displayed_power(12)==4 and Preview.displayed_power(112)==7,"large legend alternates power4 and7 examples")
	for weapon in [2,3]:
		var straight: bool = true
		for path in preview.trajectory_paths(weapon):
			for point in path.points: straight = straight and is_equal_approx(point.x,path.points[0].x)
		check(straight,"type%d legend has genuinely vertical lanes"%weapon)
	var accel_points: PackedVector2Array = preview.trajectory_paths(3)[0].points
	check(accel_points[0].y-accel_points[6].y<accel_points[30].y-accel_points[36].y,"equal-time legend dots visibly separate as type3 accelerates")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
