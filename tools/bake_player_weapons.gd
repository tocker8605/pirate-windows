extends SceneTree
## Pack generated source frames into compact4x runtime sprites; no runtime readback.
const CELL := Vector2i(320,160)
const SIZES = [Vector2i(160,120),Vector2i(80,120),Vector2i(320,120),Vector2i(320,120),Vector2i(320,120)]
func _initialize() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/renewed/player-weapons-source-v24.37.json"))
	var atlas := Image.create(CELL.x*3,CELL.y*5,false,Image.FORMAT_RGBA8)
	for weapon in range(1,4):
		var source := Image.load_from_file("res://assets/renewed/player-weapon%d-source-v24.37.png"%weapon)
		for i in range(5):
			var r: Array = metadata.weapons[str(weapon)][i]
			var frame: Image = source.get_region(Rect2i(r[0],r[1],r[2],r[3]))
			# Remove subvisible generation matte noise before alpha-correct resizing.
			frame.convert(Image.FORMAT_RGBA8)
			for y in range(frame.get_height()):
				for x in range(frame.get_width()):
					if frame.get_pixel(x,y).a<0.03: frame.set_pixel(x,y,Color.TRANSPARENT)
			frame.premultiply_alpha()
			frame.resize(SIZES[i].x,SIZES[i].y,Image.INTERPOLATE_LANCZOS)
			for y in range(frame.get_height()):
				for x in range(frame.get_width()):
					var color: Color = frame.get_pixel(x,y)
					if color.a>0: frame.set_pixel(x,y,Color(minf(1,color.r/color.a),minf(1,color.g/color.a),minf(1,color.b/color.a),color.a))
			var dest: Vector2i = Vector2i((weapon-1)*CELL.x,i*CELL.y)+(CELL-SIZES[i])/2
			atlas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),dest)
	if atlas.save_png("res://assets/renewed/player-weapons-v24.37.png")!=OK:
		quit(1)
		return
	print("BAKED: ",atlas.get_size()," /3weapons x5phases /4x")
	quit()
