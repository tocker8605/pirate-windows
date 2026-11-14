extends SceneTree
const Boss = preload("res://scripts/boss.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func parts() -> Array:
	return [Catalog.create(131,Vector2.ZERO),Catalog.create(132,Vector2.ZERO),Catalog.create(133,Vector2.ZERO)]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var fists: Array = [Catalog.create(101,Vector2.ZERO),Catalog.create(102,Vector2.ZERO)]
	var first: Dictionary = Catalog.create(91,Vector2(200,100))
	check(Boss.advance(first,fists,0.3).size()==1,"stage1 body fires at fullHP with both fists alive")
	first.hp = 1
	check(Boss.advance(first,fists,0.3).size()==1,"stage1 body firing is independent of itsHP")
	check(Boss.advance(first,[],0.15).size()==1,"stage1 body fires every150ms after both fists are gone")
	var normal: Dictionary = Catalog.create(91,Vector2(200,100))
	check(Boss.advance(normal,fists,0.15).is_empty(),"stage1 with fists waits the normal300ms interval")
	var left: Array = Boss.advance(normal,fists,0.15)
	var right: Array = Boss.advance(normal,fists,1.5)
	check(left[0].pos.x==160 and right[-1].pos.x==240 and left[0].velocity==Vector2(-1,9) and right[-1].velocity==Vector2(1,9),"stage1 alternating muzzle positions and trajectories are retained")
	var slow: Dictionary = Catalog.create(91,Vector2(200,100))
	var fast: Dictionary = Catalog.create(91,Vector2(200,100))
	var slow_count := 0
	var fast_count := 0
	for i in range(360):
		slow_count += Boss.advance(slow,fists,1.0/60).size()
		fast_count += Boss.advance(fast,[],1.0/60).size()
	check(slow_count==20 and fast_count==40,"stage1 enrage exactly doubles body fire rate over six seconds")
	var transition: Dictionary = Catalog.create(91,Vector2(200,100))
	Boss.advance(transition,fists,0.29)
	check(Boss.advance(transition,[],0.01).is_empty(),"final-fist destruction does not release accumulated normal-phase shots")
	check(Boss.advance(transition,[],0.14).size()==1,"enrage starts firing150ms after final-fist destruction")
	check(Boss.advance(Catalog.create(91,Vector2(200,100)),[fists[0]],0.15).is_empty(),"one remaining fist keeps normal body cadence")
	var b: Dictionary = Catalog.create(94,Vector2(200,100))
	var all_parts: Array = parts()
	var shots: Array = []
	for i in range(5): shots.append_array(Boss.advance(b,all_parts,1.0/60))
	check(shots.is_empty(),"paired sweep waits100ms")
	shots = Boss.advance(b,all_parts,1.0/60)
	check(shots.size()==2 and shots[0].pos==Vector2(175,150) and shots[1].pos==Vector2(225,150),"sixth native tick emits one shot from each original body port")
	check(shots[0].velocity.is_equal_approx(Vector2(0,7)) and shots[1].velocity.is_equal_approx(Vector2(0,7)) and shots[0].kind==6,"paired sweep starts downward using original energy projectile kind")
	shots = Boss.advance(b,all_parts,0.1)
	check(is_equal_approx(shots[0].velocity.angle(),deg_to_rad(80)),"left port rotates counterclockwise by10degrees")
	check(is_equal_approx(shots[1].velocity.angle(),deg_to_rad(100)),"right port rotates clockwise by10degrees")
	check(is_equal_approx(shots[0].velocity.x,-shots[1].velocity.x) and is_equal_approx(shots[0].velocity.y,shots[1].velocity.y),"opposite sweeps remain left/right symmetric")
	b = Catalog.create(94,Vector2(200,100))
	var count := 0
	for i in range(600): count += Boss.advance(b,all_parts,1.0/60).size()
	check(count==200,"ten seconds emits exactly100shots per port without global-phase jitter")
	var fresh: Dictionary = Catalog.create(94,Vector2(200,100))
	check(not fresh.has("body_sweep") and Boss.advance(fresh,all_parts,0.3).size()==6,"fresh boss has independent sweep state and large steps preserve due volleys")
	check(Boss.advance(b,[],1).filter(func(s): return s.kind==6).is_empty(),"sweep stops when all living parts are gone")
	var dead: Array = parts()
	for p in dead: p.hp = 0
	check(Boss.advance(b,dead,1).filter(func(s): return s.kind==6).is_empty(),"dead parts cannot keep the paired sweep active")
	check(Boss.advance(b,[all_parts[2]],0.1).filter(func(s): return s.kind==6).size()==2,"surviving centre core keeps the paired sweep active after both arms are destroyed")
	b.pos.y = 49
	check(Boss.advance(b,all_parts,1).is_empty(),"original body entryY gate remains")
	b.pos.y = 50
	check(Boss.advance(b,all_parts,0.05).is_empty(),"entry gate does not accumulate a delayed burst")
	b.hp = 0
	check(Boss.advance(b,all_parts,1).is_empty(),"destroyed body cannot fire a sweep")
	check(Boss.advance(Catalog.create(92,Vector2.ZERO),all_parts,1).is_empty(),"other bosses do not acquire the stage4 sweep")
	b = Catalog.create(94,Vector2(200,100))
	check(Boss.advance(b,all_parts,0.01).is_empty(),"old Y-modulo body attack is removed")
	Rng.state = 0x50000
	var random_before: int = Rng.state
	Boss.advance(b,all_parts,0.1)
	check(Rng.state==random_before,"paired sweep does not disturb gameplay RNG")
	check(Boss.advance(Catalog.create(94,Vector2(200,100)),[],0.12).size()==4,"independent final fireballs and replacement cannons remain active")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(4)
	g.events = []
	g.boss = Catalog.create(94,Vector2(200,100))
	g.enemies.replace_all(parts())
	g.bullets.clear()
	g.clock = Clock.new()
	g.invulnerable = 10000
	for i in range(12): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(g.bullets.size()==4 and g.bullets.all(func(p): return p.kind==6),"actual game integrates paired sweep every native tick instead of60ms global firing phases")
	g._load_stage(1)
	g.events = []
	g.boss = Catalog.create(91,Vector2(200,100))
	g.enemies.replace_all(fists)
	g.clock = Clock.new()
	for i in range(18): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(g.bullets.size()==1 and g.bullets.at(0).kind==1,"actual stage1 loop fires at300ms with both fists alive")
	g.enemies.clear()
	g.bullets.clear()
	for i in range(9): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(g.bullets.size()==1 and g.bullets.at(0).kind==1,"actual stage1 loop switches to150ms once both fists are gone")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
