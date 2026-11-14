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
			var shots: Array = Fire.advance(e,0.12) if id==8 else Fire.emit(e,Vector2(175,400),attacks[id])
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
	check(Fire.advance(e,0.119).is_empty(),"folding twins still wait120ms")
	shots = Fire.advance(e,0.001)
	check(shots.size()==2 and shots.all(func(s): return s.kind==1 and s.velocity.distance_to(Vector2(0,300))<0.001),"folding correction retains initial downward direction, speed and projectile type")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
