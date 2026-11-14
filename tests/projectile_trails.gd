extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(4)
	g.delta_seconds = 0.03
	g.events = []
	g.enemies.clear()
	g.death_remaining_seconds = 0.03
	g.scroll_speed = (0/0.03)
	g.boss = Catalog.create(94,Vector2(200,30))
	g.boss.hp = 300
	g.bullets.clear()
	g._bullet(Vector2(50,100),(Vector2(0,-2))/0.03,8)
	g._bullet(Vector2(150,100),(Vector2.DOWN)/0.03,1)
	g.shots.replace_all([{"pos":Vector2(250,100),"kind":1,"impact_remaining_seconds":-1,"alive":true}])
	g.delta_seconds = 0.03
	var fx = g.view.vfx
	fx.reset()
	var gameplay_rng: int = Rng.state
	for frame in range(1,9):
		g.frame = frame
		fx.observe(g)
	var flame := 0
	var regular := 0
	var player := 0
	var smoke := 0
	for p in fx.particles:
		if p.smoke: smoke += 1
		elif p.p.x<100: flame += 1
		elif p.p.x<200: regular += 1
		else: player += 1
	check(flame==2,"fireball emits two embers over eight authored units instead of twelve")
	check(regular==2 and player==2,"enemy and friendly projectile tail cadence is halved")
	check(smoke==24,"damaged boss retains six smoke particles every two authored units")
	check(Rng.state==gameplay_rng,"reduced visual tails do not consume gameplay RNG")
	fx.reset()
	check(fx.projectile_trail_clock==0 and fx.trail_clock==0,"stage/reset clears independent projectile and smoke clocks")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
