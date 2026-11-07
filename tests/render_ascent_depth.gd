extends SceneTree
const Art = preload("res://scripts/renewed_art.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0
class SpriteSample extends Node2D:
	var art = Art.new()
	var y: float = 350
	func _draw() -> void:
		art.draw_enemy(self,Catalog.create(9,Vector2(100,y),1071),Vector2.ZERO,0)
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func metrics(image: Image) -> Vector2:
	var count := 0.0
	var light := 0.0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color: Color = image.get_pixel(x,y)
			if color.a>0.9:
				count += 1
				light += color.get_luminance()
	return Vector2(count,light/maxf(1,count))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size = Vector2i(400,480)
	root.size = Vector2i(800,960)
	var views: Array = []
	for y in [350,250]:
		var view := SubViewport.new()
		view.size = Vector2i(100,100)
		view.transparent_bg = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var sprite = SpriteSample.new()
		sprite.y = y
		sprite.scale = Vector2.ONE*2
		view.add_child(sprite)
		views.append(view)
	await RenderingServer.frame_post_draw
	var lower: Vector2 = metrics(views[0].get_texture().get_image())
	var normal: Vector2 = metrics(views[1].get_texture().get_image())
	check(lower.x/normal.x>0.55 and lower.x/normal.x<0.73,"lower enemy occupies about64percent area from80percent linear size")
	check(lower.y/normal.y>0.5 and lower.y/normal.y<0.8,"lower sprite is visibly darker in actual rendered pixels")
	for view in views: view.queue_free()
	await process_frame
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.events = []
	g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
	g.player = Vector2(175,350)
	g._redraw()
	await RenderingServer.frame_post_draw
	var alone: Image = root.get_texture().get_image()
	var e: Dictionary = Catalog.create(9,g.player,1071)
	g.enemies.append(e)
	g._redraw()
	await RenderingServer.frame_post_draw
	var below: Image = root.get_texture().get_image()
	var pixel := Vector2i(400,736)
	check(alone.get_pixelv(pixel).is_equal_approx(below.get_pixelv(pixel)),"lower-plane arrival renders behind the overlapping player cockpit")
	e.pattern = 0
	g._redraw()
	await RenderingServer.frame_post_draw
	var same_plane: Image = root.get_texture().get_image()
	check(not alone.get_pixelv(pixel).is_equal_approx(same_plane.get_pixelv(pixel)),"ordinary enemy at the same position retains its existing foreground layer")
	g.enemies.clear()
	for y in [350,280,250]:
		var sample: Dictionary = Catalog.create(9,Vector2(65+(350-y)*2,y),1071)
		g.enemies.append(sample)
	g._redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-ascent-depth-v24.6.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
