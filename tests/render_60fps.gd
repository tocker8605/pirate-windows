extends SceneTree
const Game = preload("res://scripts/game.gd")
const Renewed = preload("res://scripts/renewed_art.gd")
const Boss = preload("res://scripts/boss.gd")
var checks: int = 0
var failures: int = 0
class Pods extends Node2D:
	var art = Renewed.new()
	func _draw() -> void:
		for index in range(3):
			var b = {"pos":Vector2(200,50+index*140),"velocity":Vector2.ZERO}
			for kind in [[112,111],[121,122],[131,132]][index]:
				var e = {"kind":kind,"pos":Vector2.ZERO,"velocity":Vector2.ZERO}
				Boss.attach(e,b)
				art.draw_enemy(self,e,e.pos+Vector2(0,-50),0)
class Driver extends Node:
	var game: Node
	var count: int = 0
	func _process(delta: float) -> void:
		game.automatic = true
		game._process(delta)
		game.automatic = false
		count += 1
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Engine.max_fps = 60
	var pods = Pods.new()
	root.add_child(pods)
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.save_png("res://preview-boss-symmetry-v13.png")
	for index in range(3):
		var delta: float = 0
		for y in range((60+index*140)*2,(160+index*140)*2):
			for x in range(100*2,200*2):
				var a = shot.get_pixel(x,y)
				var b = shot.get_pixel(799-x,y)
				delta = maxf(delta,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
		check(delta<=1.1/255,"stage%d pod pixels mirror around boss axis (delta %.5f)"%[index+2,delta])
	pods.queue_free()
	await process_frame
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	g.set_process(false)
	g._load_stage(1)
	g.delta_seconds = 0.03
	g.events = []
	g.invulnerability_seconds = 300.0
	var driver = Driver.new()
	driver.game = g
	root.add_child(driver)
	await create_timer(0.75).timeout
	var start: int = Time.get_ticks_usec()
	var count: int = driver.count
	var ticks: int = g.frame
	var frames: int = Engine.get_frames_drawn()
	await create_timer(2.0).timeout
	var elapsed: float = (Time.get_ticks_usec()-start)/1000000.0
	var fps: float = (driver.count-count)/elapsed
	var drawn: float = (Engine.get_frames_drawn()-frames)/elapsed
	var tick_rate: float = (g.frame-ticks)/elapsed
	print("MEASURED: %.3f seconds; %.2f process FPS; %.2f drawn FPS; %.2f gameplay ticks/s"%[elapsed,fps,drawn,tick_rate])
	check(fps>=54 and fps<=62,"actual process rate is approximately60FPS")
	check(drawn>=54 and drawn<=62,"actual rendered rate is approximately60FPS")
	check(absf(tick_rate-60.0)<1.1,"gameplay updates at60ticks/s")
	driver.set_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-60fps-v13.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	driver.queue_free()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
