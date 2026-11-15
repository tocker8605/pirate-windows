extends SceneTree
## Bake only the renewed flight silhouettes; muzzle/hit effects are live particles.
const Style = preload("res://scripts/player_weapon_style.gd")
const SCALE: int = 4
const CELL := Vector2i(24,34)
func _initialize() -> void:
	var source: Image = load("res://assets/renewed/player-weapons-v24.37.png").get_image()
	var atlas := Image.create(CELL.x*SCALE*3,CELL.y*SCALE,false,Image.FORMAT_RGBA8)
	for weapon in range(1,4):
		if weapon==1:
			var lines := Image.new()
			if lines.load_svg_from_string(FileAccess.get_file_as_string("res://assets/renewed/player-single-line-v24.41.svg"))!=OK: quit(1); return
			atlas.blit_rect(lines,Rect2i(Vector2i.ZERO,lines.get_size()),Vector2i.ZERO)
			continue
		var frame: Image = source.get_region(Rect2i((weapon-1)*320+120,180,80,120))
		frame.convert(Image.FORMAT_RGBA8)
		for y in range(frame.get_height()):
			for x in range(frame.get_width()): frame.set_pixel(x,y,Style.grade(frame.get_pixel(x,y),weapon))
		frame.premultiply_alpha()
		var size: Vector2i = Style.SIZES[weapon-1]*SCALE
		frame.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var color: Color = frame.get_pixel(x,y)
				if color.a>0: frame.set_pixel(x,y,Color(minf(1,color.r/color.a),minf(1,color.g/color.a),minf(1,color.b/color.a),color.a))
		var pos: Vector2i = Vector2i((weapon-1)*CELL.x*SCALE,0)+(CELL*SCALE-size)/2
		atlas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),pos)
	if atlas.save_png("res://assets/renewed/player-projectiles-v24.41.png")!=OK: quit(1); return
	print("BAKED FLIGHT ONLY: ",atlas.get_size())
	quit()
