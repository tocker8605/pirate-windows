extends SceneTree
const Fire = preload("res://tests/fixtures/fire_probe.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func actor() -> Dictionary: return Catalog.create(8,Vector2(100,100))
func twins(e: Dictionary,seconds: float) -> Array: return Fire.advance(e,seconds).filter(func(s): return s.kind==1)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var e: Dictionary = actor()
	check(twins(e,1).filter(func(s): return s.kind==1).is_empty(),"folding twin shots require descent")
	e.velocity.y = (-1/0.03)
	check(twins(e,1).filter(func(s): return s.kind==1).is_empty(),"ascending folding craft emits no descent twins")
	e.velocity.y = (2/0.03)
	check(twins(e,0.119).filter(func(s): return s.kind==1).is_empty(),"descent twins wait120ms")
	var shots: Array = twins(e,0.001)
	check(shots.size()==2 and shots[0].pos==Vector2(130,125) and shots[1].pos==Vector2(110,125),"120ms twin volley retains both original muzzle positions")
	check(shots[0].velocity.distance_to((Vector2(0,9))/0.03)<0.001 and shots[1].velocity.distance_to((Vector2(0,9))/0.03)<0.001,"first descending volley points straight down")
	e.velocity.y = (6/0.03)
	shots = twins(e,0.12)
	check(shots[0].velocity.distance_to((Vector2(1,1).normalized()*9)/0.03)<0.001 and shots[1].velocity.distance_to((Vector2(-1,1).normalized()*9)/0.03)<0.001,"halfway acceleration spreads twins45degrees left and right")
	e.velocity.y = (10/0.03)
	shots = twins(e,0.12)
	check(shots[0].velocity.distance_to((Vector2(9,0))/0.03)<0.001 and shots[1].velocity.distance_to((Vector2(-9,0))/0.03)<0.001,"maximum descent speed produces horizontal left/right fire")
	check(shots[0].kind==1 and is_equal_approx(shots[0].velocity.length(),(9/0.03)),"projectile kind retained and speed stays fixed while angle changes")
	e.velocity.y = (0/0.03)
	twins(e,0.01)
	e.velocity.y = (4/0.03)
	shots = twins(e,0.12)
	check(shots.size()==2 and shots[0].velocity.distance_to((Vector2(0,9))/0.03)<0.001,"new descent resets its starting speed and downward initial direction")
	check(Fire.burst(e,Vector2(200,300),3,0).is_empty(),"legacy phase3 twin fire removed to prevent double emission")
	shots = Fire.burst(e,Vector2(200,300),10,0)
	check(shots.size()==1 and shots[0].kind==2 and shots[0].velocity.distance_to((Vector2(0,-1))/0.03)<0.001,"central upward missile pattern and phase10 cadence remain unchanged")
	e = actor()
	e.velocity.y = (2/0.03)
	var count := 0
	var state: int = Rng.state
	for i in range(600): count += twins(e,1.0/60).filter(func(s): return s.kind==1).size()
	check(count==166,"ten seconds yields83twin volleys at120ms without phase-clock drift")
	check(Rng.state==state,"speed-dependent twins do not consume gameplay RNG")
	e.hp = 0
	check(twins(e,1).filter(func(s): return s.kind==1).is_empty(),"destroyed folding craft cannot emit twins")
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
	g.bullets.clear()
	e = actor()
	e.velocity.y = (2/0.03)
	g.enemies.append(e)
	for i in range(7): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.bullets.is_empty(),"native loop does not emit folding twins before120ms")
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.bullets.size()==2 and g.bullets.all(func(b): return b.velocity.distance_to((Vector2(0,9))/0.03)<0.001),"native loop emits first downward twin on the eighth60Hz tick")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
