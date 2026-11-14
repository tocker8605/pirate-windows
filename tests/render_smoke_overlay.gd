extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
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
	root.content_scale_size = Vector2i(400,480)
	root.size = Vector2i(800,960)
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.delta_seconds = 0.03
	g.events = []
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.player = Vector2(175,390)
	g.boss = Catalog.create(92,Vector2(200,230))
	for row in [[4,50,100],[3,175,100],[5,285,100],[111,55,250],[112,295,250]]:
		g.enemies.append(Catalog.create(row[0],Vector2(row[1],row[2])))
	g._redraw()
	await RenderingServer.frame_post_draw
	var before: Image = root.get_texture().get_image()
	var centres: Array = [Vector2(75,125),Vector2(200,280),Vector2(80,275),g.player+Vector2(25,18)]
	g.view.vfx.particles.clear()
	for centre in centres:
		g.view.vfx.emit(centre,Vector2.ZERO,28,16,g.view.vfx.SMOKE_COLOR,true)
	g.view.vfx.emit(Vector2(300,350),Vector2.ZERO,28,16,g.view.vfx.SMOKE_COLOR,true)
	g.view.foreground.queue_redraw()
	await RenderingServer.frame_post_draw
	var after: Image = root.get_texture().get_image()
	for i in range(centres.size()):
		var covered := 0
		var c: Vector2 = centres[i]*2
		for y in range(int(c.y)-12,int(c.y)+12):
			for x in range(int(c.x)-12,int(c.x)+12):
				if before.get_pixel(x,y).get_luminance()>0.2 and before.get_pixel(x,y).get_luminance()-after.get_pixel(x,y).get_luminance()>0.12: covered += 1
		check(covered>20,"smoke overlays visible%s pixels as in v24.1"%[" enemy"," boss torso"," boss arm"," player"][i])
	check(before.get_pixel(600,700).get_luminance()>after.get_pixel(600,700).get_luminance()+0.1,"unoccluded smoke remains visible above the background")
	check(is_equal_approx(g.view.vfx.SMOKE_SIZE_SCALE,0.8),"smoke linear dimensions use80percent of the previous size")
	# Compare the same projectiles with smoke toggled, so exact overlap proves order.
	var smoke_particles: Array = g.view.vfx.particles.duplicate(true)
	g.shots.replace_all([{"pos":Vector2(60,113),"kind":1,"alive":true,"impact_remaining_seconds":-1,"visual":{"phase":"flight"}}])
	g.view.vfx.particles.clear()
	g.view.foreground.queue_redraw()
	await RenderingServer.frame_post_draw
	var allied_clear: Image = root.get_texture().get_image()
	g.view.vfx.particles = smoke_particles.duplicate(true)
	g.view.foreground.queue_redraw()
	await RenderingServer.frame_post_draw
	var allied_smoke: Image = root.get_texture().get_image()
	check(allied_clear.get_pixel(150,250).get_luminance()>allied_smoke.get_pixel(150,250).get_luminance()+0.2,"black smoke is above the overlapping allied shot")
	g._bullet(Vector2(75,125),(Vector2.DOWN)/0.03,4)
	g.view.vfx.particles.clear()
	g.view.foreground.queue_redraw()
	await RenderingServer.frame_post_draw
	var enemy_clear: Image = root.get_texture().get_image()
	g.view.vfx.particles = smoke_particles.duplicate(true)
	g.view.foreground.queue_redraw()
	await RenderingServer.frame_post_draw
	var enemy_smoke: Image = root.get_texture().get_image()
	check(absf(enemy_clear.get_pixel(150,250).get_luminance()-enemy_smoke.get_pixel(150,250).get_luminance())<0.005,"opaque enemy bullet core stays visible above black smoke")
	enemy_smoke.save_png("res://preview-smoke-layer-v24.5.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
