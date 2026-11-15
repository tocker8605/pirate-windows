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
		var smooth: bool = true
		var random_before: int = Rng.state
		for shot in shots:
			var first_x: float = shot.pos.x
			smooth = smooth and absf(first_x-player.x-11-float(shot.get("fan_jitter",0))-float(shot.get("fan_lane",0))*4)<0.0001
			Weapons.advance(shot,Vector2(250,400),units)
			smooth = smooth and shot.pos.x>first_x and shot.pos.x<281
			var next_x: float = shot.pos.x
			Weapons.advance(shot,Vector2(0,400),units)
			smooth = smooth and shot.pos.x<next_x and shot.pos.x> -9
		check(smooth and Rng.state==random_before,"type3 power%d preserves random launch X and smoothly follows either pilot direction without new RNG"%power)
	check(Weapons.type3_spacing(0)==4 and Weapons.type3_spacing(90)==8 and Weapons.type3_spacing(180)==12 and Weapons.type3_spacing(1000)==12,"type3 fan spacing smoothly maps0/90/180px distance to4/8/12px and clamps")
	for power in range(3,8):
		var valid: bool = true
		for seed_value in range(20):
			var source=Preview.DemoRandom.new()
			source.rng.seed=seed_value
			var shots:Array=Weapons.volley(player,3,power,source)
			for i in range(1,shots.size()): valid=valid and is_equal_approx(shots[i].pos.x-shots[i-1].pos.x,4)
			for tick in range(120):
				for shot in shots: Weapons.advance(shot,Vector2(100+sin(tick*0.05)*100,400),units)
				var expected:float=Weapons.type3_spacing(absf(player.y-float(shots[0].guide_y)))
				for i in range(1,shots.size()):
					var gap:float=shots[i].pos.x-shots[i-1].pos.x
					valid=valid and absf(gap-expected)<0.0001 and gap>=4-0.0001 and gap<=12+0.0001
			valid=valid and absf(shots[1].pos.x-shots[0].pos.x-12)<0.0001
		check(valid,"type3 power%d launches4px apart and spreads byY distance to12px while following across20seeds"%power)
	for power in range(1,8):
		var new_rng=Preview.DemoRandom.new()
		var original_rng=Preview.DemoRandom.new()
		Weapons.volley(player,3,power,new_rng)
		if power>=3:
			for i in range(Weapons.volley_count(power)):
				original_rng.between(0,8 if power<=4 else (12 if power<=6 else 16))
				if power>=5: original_rng.between(0,1 if power<=6 else 2)
		check(new_rng.rng.state==original_rng.rng.state,"type3 power%d preserves original random draw count/order despite separated lanes"%power)
	var a = {"kind":4,"pos":Vector2(111,400)}
	var b: Dictionary = a.duplicate()
	var first: float = a.pos.y
	Weapons.advance(a,Vector2(0,400),units)
	Weapons.advance(b,Vector2(200,400),units)
	check(a.pos.x<111 and b.pos.x>111 and a.pos.y==b.pos.y,"type3 horizontal guidance does not change vertical speed")
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
				for tick in range(Preview.TRACE_TICKS): Weapons.advance(actual[i],Preview.demo_player(weapon,tick),units)
				matches = matches and paths[i].points[-1].distance_to(actual[i].pos+Vector2(15,12))<0.001
			check(matches,"type%d power%d legend uses the real native-tick trajectory"%[weapon,power])
	check(Rng.state==0x50000,"all trajectory legends preserve gameplay RNG state")
	for i in range(20): preview.trajectory_paths(3,7)
	check(preview.path_cache.size()==6,"legend paths are cached rather than simulated every draw")
	check(Preview.displayed_power(12)==4 and Preview.displayed_power(112)==7,"large legend alternates power4 and7 examples")
	for weapon in [2]:
		var straight: bool = true
		for path in preview.trajectory_paths(weapon):
			for point in path.points: straight = straight and is_equal_approx(point.x,path.points[0].x)
		check(straight,"type%d legend has genuinely vertical lanes"%weapon)
	var moving: bool = false
	for path in preview.trajectory_paths(3): moving = moving or absf(path.points[-1].x-path.points[0].x)>5
	check(moving,"type3 legend demonstrates pursuit of the moving pilot")
	var coarse := {"kind":4,"pos":Vector2(200,400)}
	var fine: Dictionary = coarse.duplicate()
	for i in range(10): Weapons.advance(coarse,Vector2(100,400),0.03)
	for i in range(18): Weapons.advance(fine,Vector2(100,400),1.0/60.0)
	check(absf(coarse.pos.x-fine.pos.x)<0.0001 and absf(coarse.pos.x-(111+89*exp(-1.0)))<0.0001,"X pursuit response is timestep independent and reaches63percent in0.3seconds")
	var accel_points: PackedVector2Array = preview.trajectory_paths(3)[0].points
	check(accel_points[0].y-accel_points[6].y<accel_points[30].y-accel_points[36].y,"equal-time legend dots visibly separate as type3 accelerates")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
