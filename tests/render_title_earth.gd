extends SceneTree
const Game = preload("res://scripts/game.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func capture(g: Node) -> Image:
	g._redraw()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.title.loading_ticks = 0
	var title: Image = await capture(g)
	title.save_png("res://preview-title-black-v17.png")
	check(not g.view.background.visible and title.get_pixel(400,400)==Color.BLACK,"initial title stays black before Space")
	var original: Image = g.art.sheet("piclog")
	var text_ok: bool = true
	for y in range(448,480):
		for x in range(400):
			if original.get_pixel(x,y).r<0.99: continue
			if title.get_pixel(x*2+1,y*2+1).r<0.99: text_ok = false
	check(text_ok,"original initial start lettering remains intact")
	g.title.confirm()
	for i in range(47): g.title.tick()
	var opening: Image = await capture(g)
	opening.save_png("res://preview-opening-earth-v17.png")
	check(g.view.background.visible and g.view.background.material.get_shader_parameter("earth_texture")==g.view.renewal.earth,"Space reveals the exact shared stage4 Earth texture")
	check(g.view.background.material.get_shader_parameter("stage")==4 and not g.view.background.material.get_shader_parameter("boss_rush"),"opening uses normal-stage4 Earth shader mode")
	var source_top: float = 3360.0-g.title.scroll
	var dx: int = int(round(g.title.scroll/3.5))
	check(g.view.background.material.get_shader_parameter("source_top")==source_top and g.view.background.position.x==-dx,"opening retains original vertical scroll and horizontal camera drift")
	check(opening.get_pixel(400,600)==Color.BLACK and opening.get_pixel(60,600)!=Color.BLACK,"black pane reveals Earth from left to right")
	g._load_stage(4)
	g.background_y = source_top
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.player = Vector2(-500,-500)
	g.view.vfx.reset()
	var stage: Image = await capture(g)
	var delta: float = 0
	for y in range(170,430,11):
		for x in range(10,120,13):
			var a: Color = stage.get_pixel((x+dx)*2,y*2)
			var b: Color = opening.get_pixel(x*2,y*2)
			delta = maxf(delta,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	check(delta<=1.1/255,"revealed Earth matches stage4 sampled GPU pixels(delta%.5f)"%delta)
	g._return_title()
	g.title.loading_ticks = 0
	g.title.confirm()
	for i in range(94): g.title.tick()
	await capture(g)
	check(g.title.phase==11 and g.view.background.visible,"completed slide enters the original menu over Earth")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
