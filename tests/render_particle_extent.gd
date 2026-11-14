extends SceneTree
const FX = preload("res://scripts/combat_vfx.gd")
class Board extends Node2D:
	var fx = FX.new()
	func _init() -> void:
		fx.emit(Vector2(100,65),Vector2(4,0),20,1.5,FX.HOT)
		fx.emit(Vector2(300,65),Vector2(4,-4),20,1.5,FX.CYAN)
		fx.burst(Vector2(100,205),40,FX.HOT,4)
		fx.burst(Vector2(300,205),70,FX.HOT,6)
		fx.burst(Vector2(100,355),12,FX.CYAN,3.4)
		fx.burst(Vector2(300,355),9,FX.CYAN,2.8)
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),Color.BLACK)
		fx.draw_particles(self,1)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.add_child(Board.new())
	await RenderingServer.frame_post_draw
	var pixels: Image = root.get_texture().get_image()
	pixels.save_png(OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://particles-fixed-v24.30.png")
	var expected: Image = Image.load_from_file(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size()>1 else load("res://tests/fixtures/particles-v24.28.png").get_image()
	var changed := 0
	var escaped := 0
	var scale: float = float(pixels.get_width())/400
	var centers: Array = [Vector2(100,65),Vector2(300,65),Vector2(100,205),Vector2(300,205),Vector2(100,355),Vector2(300,355)]
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var color: Color = pixels.get_pixel(x,y)
			var golden: Color = expected.get_pixel(x,y)
			if maxf(absf(color.r-golden.r),maxf(absf(color.g-golden.g),absf(color.b-golden.b)))>0.025: changed += 1
			if maxf(color.r,maxf(color.g,color.b))<0.04: continue
			var local := Vector2(x,y)/scale
			if centers.all(func(center): return local.distance_to(center)>30): escaped += 1
	var failures := 0
	if changed>100:
		failures += 1
		push_error("FAIL: particle extent differs from v24.28: %d pixels"%changed)
	if escaped>0:
		failures += 1
		push_error("FAIL: particle lines escaped30px sample bounds: %d pixels"%escaped)
	print("PARTICLE_PIXELS: changed%d escaped%d"%[changed,escaped])
	print("RESULT: 2 checks, %d failures"%failures)
	quit(0 if failures==0 else 1)
