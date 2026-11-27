extends SceneTree
const RuntimeFire=preload("res://scripts/enemy_fire.gd")
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
func fan(e: Dictionary,seconds: float,player: Vector2) -> Array:
	return Fire.advance(e,seconds,player).filter(func(shot):return shot.kind==6)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var e: Dictionary = actor()
	var player := Vector2(100,300)
	check(fan(e,0.219,player).is_empty(),"heavy fan waits220ms")
	var shots: Array = fan(e,0.001,player)
	check(shots.size()==7,"each fan volley contains exactly7shots")
	check(shots.all(func(s): return s.pos==Vector2(125,125)),"all rays originate from the actual150x100sprite centre including draw offset")
	check(shots.all(func(s): return s.kind==6 and is_equal_approx(s.velocity.length(),280.0)),"fan uses heavyA cannon projectile kind6 at constant280px/s")
	check(shots[3].velocity.distance_to(Vector2(0,280))<0.001,"middle ray aims toward player cockpit")
	check(shots[0].velocity.distance_to(Vector2(280,0))<0.001 and shots[6].velocity.distance_to(Vector2(-280,0))<0.001,"outer rays span a180degree semicircle around the aimed middle ray")
	var regular := true
	for i in range(6): regular = regular and is_equal_approx(angle_difference(shots[i].velocity.angle(),shots[i+1].velocity.angle()),PI/6)
	check(regular,"seven fan rays are separated by30degrees")
	var saved: Vector2 = shots[3].velocity
	player = Vector2(300,100)
	shots = fan(e,0.22,player)
	check(shots[3].velocity.distance_to((player+Pilot.COCKPIT-Vector2(125,125)).normalized()*280)<0.001,"next volley retargets current player position")
	check(saved.distance_to(Vector2(0,280))<0.001,"existing projectile direction is not homing")
	e = actor()
	var count := 0
	for i in range(600): count += fan(e,1.0/60,player).filter(func(s): return s.kind==6).size()
	check(count==315,"ten seconds yields45complete7way volleys without phase jitter")
	check(fan(actor(),0.66,player).filter(func(s): return s.kind==6).size()==21,"large steps retain every due complete volley")
	var rng_before: int = Rng.state
	RuntimeFire._advance_aimed_fan(actor(),Catalog.definition(42).attack,player,0.22)
	check(Rng.state==rng_before,"new fan does not consume legacy gameplay RNG")
	Rng.state = 0x50000
	var missiles: Array = Fire.burst(actor(),player,8,0)
	var missile_rng: int = Rng.state
	Rng.state = 0x50000
	RuntimeFire._advance_aimed_fan(actor(),Catalog.definition(42).attack,player,0.22)
	var after: Array = Fire.burst(actor(),player,8,0)
	check(missiles.size()==2 and after==missiles and Rng.state==missile_rng and missiles.all(func(s): return s.kind==2),"original random twin missiles remain unchanged alongside the new fan")
	shots = fan(actor(),0.22,Vector2(125,125)-Pilot.COCKPIT)
	check(shots.size()==7 and shots.all(func(s): return is_finite(s.velocity.x) and is_finite(s.velocity.y) and is_equal_approx(s.velocity.length(),280.0)),"coincident cockpit/muzzle is handled without zero or invalid velocities")
	e.hp = 0
	check(fan(e,1,player).is_empty(),"destroyed heavy craft cannot fire")
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
	g.delta_seconds = 0.03
	g.events = []
	g.clock = Clock.new()
	g.player = Vector2(100,300)
	g.enemies.append(actor())
	for i in range(13): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.bullets.snapshot().filter(func(s):return s.kind==6).is_empty(),"native loop waits the first220ms interval")
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.bullets.snapshot().filter(func(s):return s.kind==6).size()==7,"native14th60Hz tick emits the complete central7way volley")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
