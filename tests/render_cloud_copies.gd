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
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(1)
	g.events = []
	g.clouds = [Vector2(10,100),Vector2(100,230)]
	g._redraw()
	await RenderingServer.frame_post_draw
	var optimized: Image = root.get_texture().get_image()
	check(g.view.cloud_copies.all(func(c): return not c.visible),"renewed alpha clouds do not copy the viewport")
	for copy in g.view.cloud_copies: copy.visible = true
	await RenderingServer.frame_post_draw
	var redundant: Image = root.get_texture().get_image()
	check(optimized.get_data()==redundant.get_data(),"removing redundant screen copies leaves renewed cloud pixels identical")
	g.renewed_art = false
	g._redraw()
	await RenderingServer.frame_post_draw
	check(g.view.cloud_copies.all(func(c): return c.visible),"original GDI cloud shader retains both required screen copies")
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g._redraw()
	check(g.view.cloud_copies.all(func(c): return not c.visible) and g.view.cloud_nodes.all(func(c): return not c.visible),"offscreen clouds skip copying and shader drawing")
	g.state = "menu"
	g._redraw()
	check(g.view.cloud_copies.all(func(c): return not c.visible),"menu/loading do not run game-cloud copies")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
