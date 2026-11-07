extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
var with_parts: bool = false
var checks := 0
var failures := 0
class Driver extends Node:
	var g: Node
	var count := 0
	var deltas: Array = []
	var calls: Array = []
	var max_particles := 0
	var max_bullets := 0
	func _process(delta: float) -> void:
		g.boss.hp = 300
		for part in g.enemies: part.hp = part.max_hp
		g.energy = 100
		for part in g.enemies: part.hp = part.max_hp
		g._tick(Vector2.ZERO,true,false,false,Clock.units_per_tick())
		g._redraw()
		count += 1
		deltas.append(delta*1000)
		calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		max_particles = maxi(max_particles,g.view.vfx.particles.size())
		max_bullets = maxi(max_bullets,g.bullets.size())
func check(ok: bool,message: String) -> void:
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
	g.events = []
	g.enemies.clear()
	g.boss = Catalog.create(94,Vector2(200,100 if with_parts else 30))
	if with_parts:
		for kind in [131,132,133]: g.enemies.append(Catalog.create(kind,Vector2.ZERO))
	g.boss.hp = 300
	g.player = Vector2(175,390)
	g.power = 7
	g.weapon = 1
	g.invulnerable = 1000000
	g.clock = Clock.new()
	g.scroll_speed = 0
	g.scroll_target = 0
	g.background_y = 480
	g.map_mode = 3
	Rng.state = 0x50000
	for i in range(600):
		g.boss.hp = 300
		g.energy = 100
		for part in g.enemies: part.hp = part.max_hp
		g._tick(Vector2.ZERO,true,false,false,Clock.units_per_tick())
	var driver = Driver.new()
	driver.g = g
	root.add_child(driver)
	await create_timer(0.75).timeout
	driver.deltas.clear()
	driver.calls.clear()
	var start: int = Time.get_ticks_usec()
	var first: int = driver.count
	var frames: int = Engine.get_frames_drawn()
	await create_timer(5.0).timeout
	var seconds: float = (Time.get_ticks_usec()-start)/1000000.0
	var fps: float = (Engine.get_frames_drawn()-frames)/seconds
	var ticks: float = (driver.count-first)/seconds
	driver.deltas.sort()
	driver.calls.sort()
	var p95: float = driver.deltas[int(driver.deltas.size()*0.95)]
	var calls: float = driver.calls[int(driver.calls.size()*0.5)]
	print(("BOSS4_SWEEP: " if with_parts else "BOSS4_FINAL: ")+"drawnFPS%.2f ticks/s%.2f frameP95%.3fms medianDrawCalls%.0f maxParticles%d maxBullets%d"%[fps,ticks,p95,calls,driver.max_particles,driver.max_bullets])
	check(fps>=57 and fps<=62,"heavy boss4 phase with smoke and power7 fire sustains60FPS")
	check(ticks>=57 and ticks<=62,"heavy boss4 phase maintains native60Hz gameplay updates")
	check(p95<24,"95percent of final-phase frames stay below24ms")
	check(calls<450,"grouped particles and cached flames keep median draw calls under450")
	check(driver.max_particles<900,"reduced projectile tails stay below900particles without reducing smoke")
	check(driver.max_bullets>=(20 if with_parts else 40),"benchmark retains the actual active boss bullet pattern")
	driver.set_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-boss4-sweep-v24.8.png" if with_parts else "res://preview-boss4-final-v24.7.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	driver.queue_free()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
