class_name PirateArt
extends RefCounted
## Converts the original colour/mask pairs to ordinary alpha textures once.
var sheets: Dictionary = {}
var textures: Dictionary = {}

func sheet(id: String) -> Image:
	if not sheets.has(id):
		var tex: Texture2D = load("res://assets/images/%s.png" % id)
		var image: Image = tex.get_image()
		image.convert(Image.FORMAT_RGBA8)
		sheets[id] = image
	return sheets[id]

func texture(id: String) -> Texture2D:
	if not textures.has(id):
		textures[id] = ImageTexture.create_from_image(sheet(id))
	return textures[id]

func sprite(id: String, colour: Rect2i, mask: Vector2i) -> Texture2D:
	var key: String = "%s:%s:%s" % [id, colour, mask]
	if not textures.has(key):
		var source: Image = sheet(id)
		var image: Image = Image.create(colour.size.x,colour.size.y,false,Image.FORMAT_RGBA8)
		for y in range(colour.size.y):
			for x in range(colour.size.x):
				var point: Vector2i = colour.position+Vector2i(x,y)
				var matte_point: Vector2i = mask+Vector2i(x,y)
				if not Rect2i(Vector2i.ZERO,source.get_size()).has_point(point) or not Rect2i(Vector2i.ZERO,source.get_size()).has_point(matte_point): continue
				var pixel: Color = source.get_pixelv(point)
				var matte: Color = source.get_pixel(mask.x + x, mask.y + y)
				pixel.a = 1.0 - matte.r
				image.set_pixel(x, y, pixel)
		textures[key] = ImageTexture.create_from_image(image)
	return textures[key]

func enemy(kind: int, velocity: Vector2, frame: int, stage: int = 1, y: float = 0) -> Texture2D:
	var x: int = 0
	match kind:
		1:
			x = 0 if velocity.y > 2 else (50 if velocity.y >= 0 else (100 if velocity.y > -4 else 150))
		2, 6, 7:
			var base: int = 200 if kind == 2 else (1100 if kind == 6 else 1400)
			x = base + (150 if (velocity.y>0)==(kind==7) else 0) + (100 if velocity.x > 2 else (50 if velocity.x < -2 else 0))
		3: x = 500 + frame * 50
		4: x = 700 + frame * 50
		5: x = 900 + frame * 50
		8: x = 1700 + (100 if velocity.x > 1 else (50 if velocity.x < -1 else 0))
		9: x = 1850 + frame * 50
		10: x = 2050 + (0 if velocity.y > 2 else (50 if velocity.y >= 0 else (100 if velocity.y > -4 else 150)))
		11: x = 2250 + (100 if velocity.x > 2 else (50 if velocity.x < -2 else 0))
		19: x = 2400
		201: x = 2500 if y>290 else 2450
		21, 22:
			return sprite("enemy_mid", Rect2i(0 if kind == 21 else 100, 0, 100, 100), Vector2i(0 if kind == 21 else 100, 100))
		41, 42:
			return sprite("enemy_big", Rect2i(0 if kind == 41 else 150, 0, 150, 100), Vector2i(0 if kind == 41 else 150, 100))
		101, 102:
			return sprite("boss%02d"%stage, Rect2i(150, 0 if kind == 101 else 100, 50, 50), Vector2i(150, 50 if kind == 101 else 150))
		111,112,121,122,131,132:
			x = 150 if kind%10==1 else 200
			return sprite("boss%02d"%stage,Rect2i(x,0,50,100),Vector2i(x,100))
		113: return sprite("boss02",Rect2i(250,0,50,50),Vector2i(250,150))
		123,124:
			var row: int = 0 if kind==123 else 100
			return sprite("boss03",Rect2i(250,row,50,50),Vector2i(250,row+50))
		133: return sprite("boss04",Rect2i(250,10,50,80),Vector2i(250,110))
	return sprite("enemy_sm", Rect2i(x, 0, 50, 50), Vector2i(x, 50))
