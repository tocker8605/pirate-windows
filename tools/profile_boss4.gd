extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
class ProbeFX extends "res://scripts/combat_vfx.gd":
	var mode: String = "full"
	var shape_us := 0
	var particles_us := 0
	func draw_fireball(c: Node2D,p: Vector2,d: Vector2,phase: float) -> void:
		if mode in ["no_fireball_shape","no_all_vfx"]: return
		var start: int = Time.get_ticks_usec()
		super.draw_fireball(c,p,d,phase)
		shape_us += Time.get_ticks_usec()-start
	func draw_particles(c: Node2D,fraction: float = 0,layer: int = 0) -> void:
		if mode=="no_all_vfx" or (mode=="no_trails" and layer==2): return
		var start: int = Time.get_ticks_usec()
		super.draw_particles(c,fraction,layer)
		particles_us += Time.get_ticks_usec()-start
func percentile(values: Array, fraction: float) -> float:
	var sorted: Array = values.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size()-1,int(floor(sorted.size()*fraction)))]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	Engine.max_fps = 0
	var modes: Array = ["full","no_fireball_shape","no_trails","no_all_vfx"]
	for mode in modes:
		g._load_stage(4)
		g.events = []
		g.enemies.clear()
		g.boss = Catalog.create(94,Vector2(200,30))
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
		var fx = ProbeFX.new()
		fx.mode = mode
		g.view.vfx = fx
		g.view.foreground.vfx = fx
		for i in range(600):
			g.boss.hp = 300
			g.energy = 100
			g._tick(Vector2.ZERO,true,false,false,Clock.units_per_tick())
		var frame_ms: Array = []
		var tick_ms: Array = []
		var calls: Array = []
		var shape: Array = []
		var particle_cost: Array = []
		var max_bullets := 0
		var max_particles := 0
		for i in range(360):
			g.boss.hp = 300
			g.energy = 100
			fx.shape_us = 0
			fx.particles_us = 0
			var start: int = Time.get_ticks_usec()
			g._tick(Vector2.ZERO,true,false,false,Clock.units_per_tick())
			var tick: float = (Time.get_ticks_usec()-start)/1000.0
			g._redraw()
			await RenderingServer.frame_post_draw
			if i<60: continue
			frame_ms.append((Time.get_ticks_usec()-start)/1000.0)
			tick_ms.append(tick)
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			shape.append(fx.shape_us/1000.0)
			particle_cost.append(fx.particles_us/1000.0)
			max_bullets = maxi(max_bullets,g.bullets.size())
			max_particles = maxi(max_particles,fx.particles.size())
		var result := {"mode":mode,"frame_p50_ms":percentile(frame_ms,0.5),"frame_p95_ms":percentile(frame_ms,0.95),"frame_max_ms":frame_ms.max(),"tick_p50_ms":percentile(tick_ms,0.5),"draw_calls_p50":percentile(calls,0.5),"fireball_cpu_p50_ms":percentile(shape,0.5),"particles_cpu_p50_ms":percentile(particle_cost,0.5),"max_bullets":max_bullets,"max_particles":max_particles}
		print("PROFILE: "+JSON.stringify(result))
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
