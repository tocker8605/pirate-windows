extends SceneTree
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
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var attacks: Dictionary = {6:"twin",10:"twin",21:"missiles",41:"aim",42:"missiles"}
	var half_spans: Dictionary = {6:15,8:10,10:15,21:25,41:45,42:35}
	for id in [6,8,10,21,41,42]:
		for point in [Vector2(0,100),Vector2(137.25,160),Vector2(350,220)]:
			var e: Dictionary = Catalog.create(id,point)
			e.velocity = Vector2(0,100)
			var shots: Array = Fire.advance(e,0.24) if id==8 else Fire.emit(e,Vector2(175,400),attacks[id])
			var d: Dictionary = Catalog.definition(id)
			var center_x: float = e.pos.x+d.draw_offset.x+d.draw_size.x/2
			check(shots.size()==2,"entity%d atX%s emits a complete twin volley"%[id,point.x])
			if shots.size()!=2: continue
			check(is_equal_approx((shots[0].pos.x+shots[1].pos.x)/2,center_x) and is_equal_approx(shots[0].pos.y,shots[1].pos.y),"entity%d muzzle midpoint matches actual sprite centre including wide-craft draw offset"%id)
			check(is_equal_approx(absf(shots[0].pos.x-center_x),half_spans[id]) and is_equal_approx(absf(shots[1].pos.x-center_x),half_spans[id]),"entity%d preserves symmetric port separation"%id)
	var e: Dictionary = Catalog.create(6,Vector2(100,100))
	e.velocity = Vector2(-200,100)
	var shots: Array = Fire.emit(e,Vector2(175,400),"twin")
	check(shots.all(func(s): return s.kind==7 and s.velocity.distance_to(Vector2(200,7/0.03))<0.001),"swept-wing correction leaves projectile type and motion-linked trajectory unchanged")
	e = Catalog.create(8,Vector2(100,100))
	e.velocity.y = 100
	check(Fire.advance(e,0.239).is_empty(),"folding twins still wait240ms")
	shots = Fire.advance(e,0.001)
	check(shots.size()==2 and shots.all(func(s): return s.kind==1 and s.velocity.distance_to(Vector2(0,300))<0.001),"folding correction retains initial downward direction, speed and projectile type")
	var heavy: Dictionary = Catalog.create(41,Vector2(100,100))
	var player := Vector2(170,380)
	var direction: Vector2 = (player-heavy.pos).normalized()
	for sample in [[0,30],[3,10],[6,-10],[9,10],[12,30]]:
		heavy.fire_age = float(sample[0])
		shots = Fire.emit(heavy,player,"aim")
		var angle: float = deg_to_rad(sample[1])
		check(shots.size()==2 and shots[0].velocity.distance_to(direction.rotated(angle)*333.33333333333337)<0.001 and shots[1].velocity.distance_to(direction.rotated(-angle)*333.33333333333337)<0.001,"heavy cannons mirror the requested angle at %ss"%sample[0])
		check(shots.all(func(s): return s.kind==6 and absf(s.velocity.length()-333.33333333333337)<0.001),"heavy sweep retains projectile type and speed at %ss"%sample[0])
	for age in [0.0,3.0,6.0,9.0,12.0]:
		check(absf(Fire.heavy_cannon_angle(age-0.001)-Fire.heavy_cannon_angle(age+0.001))<0.001,"sweep is continuous across phase %s"%age)
	var reference: Array = Fire.advance(Catalog.create(41,Vector2(100,100)),12,player)
	check(reference.filter(func(s): return s.kind==6).size()==132 and reference.filter(func(s): return s.kind==2).size()==16,"12s preserves66 twin volleys and16missiles")
	for step in [1.0/30,1.0/60,0.2]:
		heavy = Catalog.create(41,Vector2(100,100))
		var sequence: Array = []
		for i in range(roundi(12/step)): sequence.append_array(Fire.advance(heavy,step,player))
		var same: bool = sequence.size()==reference.size()
		for i in range(mini(sequence.size(),reference.size())):
			same = same and sequence[i].kind==reference[i].kind and sequence[i].velocity.distance_to(reference[i].velocity)<0.001
		check(same,"heavy sweep uses each scheduled shot time at step %s"%step)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
