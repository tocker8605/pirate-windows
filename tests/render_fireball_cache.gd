extends SceneTree
const Plasma = preload("res://scripts/plasma_shape.gd")
const Shape = preload("res://scripts/fireball_shape.gd")
const Frames = preload("res://scripts/projectile_frames.gd")
var checks := 0
var failures := 0
class Board extends Node2D:
	var glow = Shape.glow_texture()
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),Color("182633"))
		var font = ThemeDB.fallback_font
		draw_string(font,Vector2(20,45),"PROCEDURAL FLAMES",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
		draw_string(font,Vector2(20,240),"CACHED FLAMES / SAME SHAPE",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
		for i in range(3):
			var phase: float = [0,32,75][i]*Shape.PHASE_PERIOD/Shape.FRAMES
			Shape.draw(self,Vector2(70+i*130,120),Vector2.UP,phase,glow)
			Frames.draw(self,Vector2(70+i*130,315),Vector2.UP,phase)
		for i in range(2):
			Plasma.draw(self,Vector2(70+i*130,190),4+i,glow)
			Frames.draw_plasma(self,Vector2(70+i*130,385),4+i)
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
	Frames.warm()
	check(Frames.ATLAS.get_size()==Vector2(2048,1152),"shared atlas contains128 flame frames and6 static projectile cells at2x resolution")
	root.add_child(Board.new())
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	for i in range(3):
		var error := 0.0
		for y in range(128):
			for x in range(128):
				var a: Color = image.get_pixel((38+i*130)*2+x,88*2+y)
				var b: Color = image.get_pixel((38+i*130)*2+x,283*2+y)
				error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
		error /= 128*128*3
		print("FLAME_IMAGE_DELTA: frame%d meanRGB%.6f"%[i,error])
		check(error<0.015,"cached flame retains procedural shape/color/glow at phase%d"%i)
	for i in range(2):
		var error := 0.0
		for y in range(128):
			for x in range(128):
				var a: Color = image.get_pixel((38+i*130)*2+x,158*2+y)
				var b: Color = image.get_pixel((38+i*130)*2+x,353*2+y)
				error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
		error /= 128*128*3
		check(error<0.015,"cached energy bullet%d retains its original circles/glow"%(4+i))
	image.save_png("res://preview-fireball-cache-v24.7.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
