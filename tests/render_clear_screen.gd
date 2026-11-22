extends SceneTree
const Game=preload("res://scripts/game.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func capture(g: Node) -> Image:
	g._redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=Game.new()
	g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.rankings.entries.clear()
	g._load_stage(5)
	g.score=1234567
	g._complete_stage()
	var clear: Image=await capture(g)
	clear.save_png("res://work/clear-screen-review.png")
	var ratio:=Vector2(clear.get_size())/Vector2(400,480)
	var green:=0
	var white:=0
	for y in range(365,385):
		for x in range(95,305):
			var color: Color=clear.get_pixelv(Vector2i(Vector2(x,y)*ratio))
			if x>=235 and color.g>color.r+0.06 and color.g>0.4:green+=1
			if x<235 and color.r>0.7 and color.g>0.7 and color.b>0.7:white+=1
	check(green>20 and white>20,"clear score uses green numeric glyphs and white English glyphs from font.png")
	var event:=InputEventKey.new()
	event.keycode=KEY_SPACE;event.pressed=true
	g._unhandled_key_input(event)
	var entry: Image=await capture(g)
	entry.save_png("res://work/clear-ranking-review.png")
	var max_error:=0.0
	for point in [Vector2(20,30),Vector2(80,60),Vector2(200,80),Vector2(370,450)]:
		var a: Color=clear.get_pixelv(Vector2i(point*ratio))
		var b: Color=entry.get_pixelv(Vector2i(point*ratio))
		max_error=maxf(max_error,maxf(absf(b.r-a.r*0.5),maxf(absf(b.g-a.g*0.5),absf(b.b-a.b*0.5))))
	check(max_error<0.02,"ranking input renders the same ending artwork at50percent opacity over black")
	g._load_stage(2)
	g.score=7654321
	g._finish_run()
	var ordinary: Image=await capture(g)
	check(ordinary.get_pixelv(Vector2i(Vector2(80,60)*ratio))==Color.BLACK,"ordinary game-over ranking entry retains the original black background")
	g.audio.stop_all();g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
