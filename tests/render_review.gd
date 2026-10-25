extends SceneTree
const Canvas = preload("res://tests/review_canvas.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var canvas = Canvas.new()
	root.add_child(canvas)
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path)
	quit()
