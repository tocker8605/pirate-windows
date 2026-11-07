extends SceneTree
## Run with graphical Godot: --path <project> --script tools/bake_projectiles.gd
## Native code-generated effect, not AI art. Preserve shape, glow and full phase cycle.
const Streak = preload("res://scripts/streak_shape.gd")
const Plasma = preload("res://scripts/plasma_shape.gd")
const Shape = preload("res://scripts/fireball_shape.gd")
class Sheet extends Node2D:
	var glow: Texture2D = Shape.glow_texture()
	func _draw() -> void:
		for frame in range(Shape.FRAMES+6):
			var centre := Vector2((frame%Shape.COLUMNS)*Shape.CELL+Shape.CELL/2,(frame/Shape.COLUMNS as int)*Shape.CELL+Shape.CELL/2)
			if frame<Shape.FRAMES: Shape.draw(self,centre,Vector2.UP,frame*Shape.PHASE_PERIOD/Shape.FRAMES,glow)
			elif frame<Shape.FRAMES+2: Plasma.draw(self,centre,4+frame-Shape.FRAMES,glow)
			else: Streak.draw(self,centre,Vector2.UP,[2,1,6,3][frame-Shape.FRAMES-2],glow)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(Shape.COLUMNS*Shape.CELL,ceili(float(Shape.FRAMES+6)/Shape.COLUMNS)*Shape.CELL)*Shape.PIXEL_SCALE
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var sheet = Sheet.new()
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sheet.scale = Vector2.ONE*Shape.PIXEL_SCALE
	view.add_child(sheet)
	await RenderingServer.frame_post_draw
	var image: Image = view.get_texture().get_image()
	var path: String = "res://assets/renewed/projectile-effects-v24.7.png"
	var error: Error = image.save_png(path)
	if error!=OK: push_error("Atlas save failed: %s"%error)
	print("PROJECTILE_ATLAS: %dx%d /%dframes /%s"%[image.get_width(),image.get_height(),Shape.FRAMES,path])
	view.queue_free()
	await process_frame
	quit(0 if error==OK else 1)
