extends SceneTree
const Fire = preload("res://tests/fixtures/fire_probe.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func actor() -> Dictionary: return Catalog.create(42,Vector2(100,100))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var e: Dictionary = actor()
	var player := Vector2(100,300)
	check(Fire.advance(e,0.199,player).is_empty(),"heavy fan waits200ms")
	var shots: Array = Fire.advance(e,0.001,player)
	check(shots.size()==7,"each fan volley contains exactly7shots")
	check(shots.all(func(s): return s.pos==Vector2(125,125)),"all rays originate from the actual150x100sprite centre including draw offset")
	check(shots.all(func(s): return s.kind==6 and is_equal_approx(s.velocity.length(),10)),"fan uses heavyA cannon projectile kind6 at constant speed10")
	check(shots[3].velocity.is_equal_approx(Vector2(0,10)),"middle ray aims toward player cockpit")
	check(shots[0].velocity.is_equal_approx(Vector2(10,0)) and shots[6].velocity.is_equal_approx(Vector2(-10,0)),"outer rays span a180degree semicircle around the aimed middle ray")
	var regular := true
	for i in range(6): regular = regular and is_equal_approx(angle_difference(shots[i].velocity.angle(),shots[i+1].velocity.angle()),PI/6)
	check(regular,"seven fan rays are separated by30degrees")
	var saved: Vector2 = shots[3].velocity
	player = Vector2(300,100)
	shots = Fire.advance(e,0.2,player)
	check(shots[3].velocity.is_equal_approx((player+Pilot.COCKPIT-Vector2(125,125)).normalized()*10),"next volley retargets current player position")
	check(saved.is_equal_approx(Vector2(0,10)),"existing projectile direction is not homing")
	e = actor()
	var count := 0
	for i in range(600): count += Fire.advance(e,1.0/60,player).filter(func(s): return s.kind==6).size()
	check(count==350,"ten seconds yields50complete7way volleys without phase jitter")
	check(Fire.advance(actor(),0.6,player).filter(func(s): return s.kind==6).size()==21,"large steps retain every due complete volley")
	var rng_before: int = Rng.state
	Fire.advance(actor(),0.2,player)
	check(Rng.state==rng_before,"new fan does not consume legacy gameplay RNG")
	Rng.state = 0x50000
	var missiles: Array = Fire.burst(actor(),player,8,0)
	var missile_rng: int = Rng.state
	Rng.state = 0x50000
	Fire.advance(actor(),0.2,player)
	var after: Array = Fire.burst(actor(),player,8,0)
	check(missiles.size()==2 and after==missiles and Rng.state==missile_rng and missiles.all(func(s): return s.kind==2),"original random twin missiles remain unchanged alongside the new fan")
	shots = Fire.advance(actor(),0.2,Vector2(125,125)-Pilot.COCKPIT)
	check(shots.size()==7 and shots.all(func(s): return is_finite(s.velocity.x) and is_finite(s.velocity.y) and is_equal_approx(s.velocity.length(),10)),"coincident cockpit/muzzle is handled without zero or invalid velocities")
	e.hp = 0
	check(Fire.advance(e,1,player).is_empty(),"destroyed heavy craft cannot fire")
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	definitions.entities["42"].attack.count = 6
	check(not Catalog.validate_document(definitions).is_empty(),"fan metadata rejects an even count without a middle aiming ray")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(3)
	g.events = []
	g.clock = Clock.new()
	g.player = Vector2(100,300)
	g.enemies.append(actor())
	for i in range(11): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(g.bullets.is_empty(),"native loop waits the first200ms interval")
	g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(g.bullets.size()==7 and g.bullets.all(func(b): return b.kind==6),"native12th60Hz tick emits the complete central7way volley")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
