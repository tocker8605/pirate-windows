extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
var failures := 0
func check(ok: bool, text: String) -> void:
	if ok: print("PASS: "+text)
	else:
		failures += 1
		push_error("FAIL: "+text)
func _initialize() -> void: call_deferred("run")
func capture(g: Node) -> Image:
	g._redraw()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func delta(a: Image, b: Image, left: int, right: int) -> float:
	var result: float = 0
	for x in range(left*2,right*2):
		for y in range(459*2,475*2):
			var c: Color = a.get_pixel(x,y)
			var d: Color = b.get_pixel(x,y)
			result = maxf(result,maxf(absf(c.r-d.r),maxf(absf(c.g-d.g),absf(c.b-d.b))))
	return result
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(4)
	g.delta_seconds = 0.03
	g.events = []
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.player = Vector2(-500,-500)
	g.boss = Catalog.create(94,Vector2(200,100),0,{"hp":2000})
	var full: Image = await capture(g)
	g.boss.hp = 1000
	var half: Image = await capture(g)
	half.save_png("res://preview-catalog-hud-v21.png")
	g.boss.hp = 0
	var empty: Image = await capture(g)
	check(delta(full,half,93,215)<0.005,"custom2000HP boss renders the same left-half fill at1000HP")
	check(delta(half,empty,218,341)<0.005,"custom2000HP half-health bar has no fill in the right half")
	check(delta(half,empty,93,215)>0.1,"custom2000HP half-health bar visibly fills its left half")
	check(delta(full,empty,218,341)>0.1,"full-health custom boss visibly fills its right half")
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: 4 checks, %d failures"%failures)
	quit(0 if failures==0 else 1)
