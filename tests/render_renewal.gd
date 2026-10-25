extends SceneTree
const Game = preload("res://scripts/game.gd")
const Regions = preload("res://scripts/background_regions.gd")
var failures: int = 0
func capture(g: Node) -> Image:
	g._redraw()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func difference(a: Image,b: Image) -> float:
	var delta: float = 0
	for y in range(90,460,17):
		for x in range(20,380,19):
			var first: Color = a.get_pixel(x*2,y*2)
			var second: Color = b.get_pixel(x*2,y*2)
			delta = maxf(delta,maxf(absf(first.r-second.r),maxf(absf(first.g-second.g),absf(first.b-second.b))))
	return delta
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(1)
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.player = Vector2(-500,-500)
	g.view.vfx.reset()
	g.background_y = 3359.9
	var before: Image = await capture(g)
	g.background_y = 3360.1
	var after: Image = await capture(g)
	var seam_delta: float = difference(before,after)
	# Test continuity by reducing the travel distance tenfold, rather than assuming
	# all detailed terrain has the same per-pixel contrast as the old image.
	g.background_y = 3359.99
	var fine_before: Image = await capture(g)
	g.background_y = 3360.01
	var fine_after: Image = await capture(g)
	var fine_delta: float = difference(fine_before,fine_after)
	if fine_delta>0.012 or fine_delta>seam_delta*0.35+1.0/255: failures += 1
	print("REGION SEAM CONVERGENCE: max RGB delta %.5f across 0.02px"%fine_delta)
	print("REGION SEAM: max RGB delta %.5f across 0.2px wrap"%seam_delta)
	g.background_y = 3001
	before = await capture(g)
	g.background_y += 480
	after = await capture(g)
	var loop_delta: float = difference(before,after)
	if loop_delta>1.1/255: failures += 1
	print("ORIGINAL LOOP: max RGB delta %.5f across 480px source reset"%loop_delta)
	var signatures: Array = []
	var distinct: bool = true
	var gallery := Image.create(960,1152,false,Image.FORMAT_RGBA8)
	gallery.fill(Color("101a28"))
	for stage in range(1,5):
		for region in range(Regions.count(stage)):
			g._load_stage(stage)
			g.background_y = ([3360,1920,960,480] if stage==4 else [3360,1920,480])[region]
			g.player = Vector2(-500,-500)
			g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
			g.view.vfx.reset()
			var shot: Image = await capture(g)
			var signature: int = hash(shot.get_data())
			if signatures.has(signature): distinct = false
			signatures.append(signature)
			shot.resize(240,288,Image.INTERPOLATE_LANCZOS)
			gallery.blit_rect(shot,Rect2i(0,0,240,288),Vector2i(region*240,(stage-1)*288))
	if not distinct or signatures.size()!=13: failures += 1
	gallery.save_png("res://preview-regions-v12.png")
	# Earth is one-shot; space and cave retain exact 480px phase-compatible loops.
	g._load_stage(4)
	g.player = Vector2(-500,-500)
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.view.vfx.reset()
	g.background_y = 3360
	before = await capture(g)
	g.background_y = 2880
	after = await capture(g)
	if difference(before,after)<0.15: failures += 1
	print("EARTH ONE SHOT: RGB departure difference %.5f"%difference(before,after))
	g.background_y = 1920
	before = await capture(g)
	g.background_y = 1440
	after = await capture(g)
	if difference(before,after)>1.1/255: failures += 1
	print("SPACE LOOP: RGB difference %.5f"%difference(before,after))
	g.background_y = 480
	before = await capture(g)
	g.background_y = 0
	after = await capture(g)
	if difference(before,after)>1.1/255: failures += 1
	print("CAVERN LOOP: RGB difference %.5f"%difference(before,after))
	var comparison := Image.create(800,960,false,Image.FORMAT_RGBA8)
	var original: Image = g.art.sheet("stage4")
	var coordinates: Array = [3360,2880,2400,1920,1440,960,480,0]
	for index in range(8):
		var old: Image = original.get_region(Rect2i(0,coordinates[index],400,480))
		old.resize(200,240,Image.INTERPOLATE_LANCZOS)
		comparison.blit_rect(old,Rect2i(0,0,200,240),Vector2i(index%4*200,int(index/4)*240))
		g.background_y = coordinates[index]
		var current: Image = await capture(g)
		current.resize(200,240,Image.INTERPOLATE_LANCZOS)
		comparison.blit_rect(current,Rect2i(0,0,200,240),Vector2i(index%4*200,480+int(index/4)*240))
	comparison.save_png("res://preview-stage4-original-renewed-v12.png")
	before = await capture(g)
	g.scenery_distance += 10000
	after = await capture(g)
	if before.get_data()!=after.get_data(): failures += 1
	g._return_title()
	g.title.loading_ticks = 0
	g.title.phase = 23
	g.title.slide = 96
	g.title.scroll = 479
	g.title.preview_clock = 12
	var one: Image = await capture(g)
	g.title.preview_clock = 36
	var two: Image = await capture(g)
	if one.get_data()==two.get_data(): failures += 1
	print("RESULT: 8 checks, %d failures"%failures)
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
