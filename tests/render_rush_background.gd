extends SceneTree
const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
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
	g.set_process(false)
	g.boss_rush = true
	g._load_stage(4)
	g.delta_seconds = 0.03
	check(g.map_mode==1 and g.scroll_speed==(20/0.03) and g.background_y==3360,"rush4 keeps the same takeoff initialization as other rush stages")
	g.events = []
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.player = Vector2(-500,-500)
	for source in [3360,1920,1200,480]:
		g.background_y = source
		g.presentation.reset(g)
		g.boss_rush = false
		var normal: Image = await capture(g)
		g.boss_rush = true
		var rush: Image = await capture(g)
		var same := true
		for y in range(120,430,13):
			for x in range(20,380,13): same = same and normal.get_pixel(x*2,y*2)==rush.get_pixel(x*2,y*2)
		check(same,"stage4 normal/rush background pixels match at sourceY%d"%source)
	var shader: String = FileAccess.get_file_as_string("res://scripts/renewed_background.gdshader")
	check(not shader.contains("boss_rush"),"obsolete rush-only background shader branch and uniform removed")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
