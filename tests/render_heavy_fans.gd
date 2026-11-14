extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
var checks := 0
var failures := 0
class Driver extends Node:
	var g: Node
	var count := 0
	var calls: Array = []
	var max_bullets := 0
	var max_particles := 0
	func _process(_delta: float) -> void:
		g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
		g._redraw()
		count += 1
		calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		max_bullets = maxi(max_bullets,g.bullets.size())
		max_particles = maxi(max_particles,g.view.vfx.particles.size())
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
	g._load_stage(3)
	g.delta_seconds = 0.03
	g.events = []
	g.player = Vector2(175,390)
	g.invulnerability_seconds = 30000.0
	for i in range(4): g.enemies.append(Catalog.create(42,Vector2(50+i%2*200,60+int(i/2)*140)))
	for i in range(600): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	var driver = Driver.new()
	driver.g = g
	root.add_child(driver)
	await create_timer(0.5).timeout
	driver.calls.clear()
	var start: int = Time.get_ticks_usec()
	var count: int = driver.count
	var frames: int = Engine.get_frames_drawn()
	await create_timer(3.0).timeout
	var seconds: float = (Time.get_ticks_usec()-start)/1000000.0
	var fps: float = (Engine.get_frames_drawn()-frames)/seconds
	var ticks: float = (driver.count-count)/seconds
	driver.calls.sort()
	var calls: float = driver.calls[int(driver.calls.size()*0.5)]
	print("HEAVY_FANS: %.2fFPS %.2fticks/s medianDrawCalls%.0f maxBullets%d maxParticles%d"%[fps,ticks,calls,driver.max_bullets,driver.max_particles])
	check(fps>=57 and fps<=62,"four heavy7way emitters sustain60drawnFPS")
	check(ticks>=57 and ticks<=62,"dense new fan pattern retains native60Hz simulation")
	check(driver.max_bullets>=70,"benchmark keeps all dense fan and missile projectiles active")
	check(calls<450 and driver.max_particles<1000,"shared projectile cache and trail budget retain rendering headroom")
	driver.set_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-heavy-fans-v24.11.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	driver.queue_free()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
