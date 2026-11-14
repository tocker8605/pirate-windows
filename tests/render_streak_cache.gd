extends SceneTree
const FX = preload("res://scripts/combat_vfx.gd")
const Shape = preload("res://scripts/streak_shape.gd")
const Flame = preload("res://scripts/fireball_shape.gd")
const Frames = preload("res://scripts/projectile_frames.gd")
var checks := 0
var failures := 0
class Board extends Node2D:
	var glow = Flame.glow_texture()
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),Color("182633"))
		for row in range(4):
			var kind: int = [1,2,3,6][row]
			for i in range(2):
				var d: Vector2 = Vector2.UP if i==0 else Vector2(1,2).normalized()
				Shape.draw(self,Vector2(50+i*200,60+row*120),d,kind,glow)
				Frames.draw_streak(self,Vector2(150+i*200,60+row*120),d,kind)
class AimedBoard extends Node2D:
	var fx = FX.new()
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),Color("182633"))
		for i in range(3):
			fx.draw_bullet(self,{"kind":3,"pos":Vector2(70+i*130,300),"velocity":[Vector2.UP,Vector2.RIGHT,Vector2.DOWN][i]})
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size = Vector2i(400,480)
	root.size = Vector2i(800,960)
	Frames.warm()
	var board = Board.new()
	root.add_child(board)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	for row in range(4):
		for i in range(2):
			var error := 0.0
			for y in range(128):
				for x in range(128):
					var a: Color = image.get_pixel((18+i*200)*2+x,(28+row*120)*2+y)
					var b: Color = image.get_pixel((118+i*200)*2+x,(28+row*120)*2+y)
					error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
			checks += 1
			if error/(128*128*3)<0.015: print("PASS: cached projectile%d orientation%d preserves body/glow"%[[1,2,3,6][row],i])
			else:
				failures += 1
				push_error("Projectile pixel equivalence failed")
	image.save_png("res://preview-streak-cache-v24.7.png")
	board.queue_free()
	await process_frame
	root.add_child(AimedBoard.new())
	await RenderingServer.frame_post_draw
	var aimed: Image = root.get_texture().get_image()
	for i in range(3):
		checks += 1
		if aimed.get_pixel((70+i*130)*2,600).get_luminance()>0.3: print("PASS: aimed kind3 projectile is visible in direction%d"%i)
		else:
			failures += 1
			push_error("Aimed kind3 projectile must remain visible in every direction")
	aimed.save_png("res://preview-type2-aim-v24.10.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
