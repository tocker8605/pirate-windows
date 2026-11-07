extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const FX = preload("res://scripts/combat_vfx.gd")
func percentile(values: Array,p: float) -> float:
	values.sort()
	return values[mini(values.size()-1,int(values.size()*p))]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	Engine.max_fps = 0
	for mode in ["baseline","clouds","laser_shield","energy_100","missiles_100","fireballs_100","explosions_12","explosions_12_particles","charge_4","smoke_120"]:
		g._load_stage(1)
		g.events = []
		g.boss = {}
		g.enemies.clear()
		g.bullets.clear()
		g.shots.clear()
		g.items.clear()
		g.explosions.clear()
		g.banner_ticks = 0
		g.player = Vector2(175,390)
		g.clouds = [Vector2(10,100),Vector2(100,230)] if mode=="clouds" else [Vector2(-500,-500),Vector2(-500,-500)]
		g.view.vfx.reset()
		if mode=="laser_shield":
			g.laser_render_ticks = 10
			g.shield_render_ticks = 100
			g.shield_center = Vector2(200,330)
		if mode in ["energy_100","missiles_100","fireballs_100"]:
			for i in range(100): g._bullet(Vector2(20+i%10*38,80+int(i/10)*32),Vector2(1,3),{"energy_100":5,"missiles_100":2,"fireballs_100":8}[mode])
		if mode.begins_with("explosions_12"):
			for i in range(12):
				g._explosion(Vector2(20+i%4*100,70+int(i/4)*100),35)
				g.explosions[-1].render_ticks = 28
			g.explosions[-1].ticks = 28
			if mode.ends_with("particles"):
				g.view.vfx.observe(g)
		if mode=="charge_4":
			for i in range(4): g.enemies.append(Catalog.create(22,Vector2(30+i%2*220,100+int(i/2)*130)))
		if mode=="smoke_120":
			for i in range(120): g.view.vfx.emit(Vector2(20+i%12*32,80+int(i/12)*32),Vector2.ZERO,28,16,FX.SMOKE_COLOR,true)
		g.view.vfx.last_stage = g.stage
		g.view.vfx.last_frame = g.frame
		var times: Array = []
		var calls: Array = []
		for i in range(150):
			var start: int = Time.get_ticks_usec()
			g._redraw()
			await RenderingServer.frame_post_draw
			if i<30: continue
			times.append((Time.get_ticks_usec()-start)/1000.0)
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		print("EFFECT_AUDIT: "+JSON.stringify({"mode":mode,"frame_p50_ms":percentile(times,0.5),"frame_p95_ms":percentile(times,0.95),"draw_calls_p50":percentile(calls,0.5),"particles":g.view.vfx.particles.size()}))
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
