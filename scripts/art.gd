class_name PirateArt
extends RefCounted
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pose = preload("res://scripts/enemy_pose.gd")
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

## Classic colour/mask sheets are baked into one transparent strip per entity.
func classic_frame(kind: int, index: int) -> Texture2D:
	var settings: Dictionary = Catalog.definition(kind).get("classic_sprite",{})
	if settings.is_empty():
		push_error("No classic sprite configured for entity %d"%kind)
		return null
	var path: String = settings.path
	var key: String = "%s:%d"%[path,index]
	if not textures.has(key):
		if not textures.has(path): textures[path] = load(path)
		var atlas: Texture2D = textures[path]
		var size := Vector2(settings.frame_size[0],settings.frame_size[1])
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(clampi(index,0,int(atlas.get_width()/size.x)-1)*size.x,0),size)
		frame.filter_clip = true
		textures[key] = frame
	return textures[key]
func enemy(kind: int, velocity: Vector2, frame: int, _stage: int = 1, y: float = 0) -> Texture2D:
	return classic_frame(kind,Pose.frame_index(kind,velocity,frame,y))
func boss_body(stage: int) -> Texture2D:
	return classic_frame(int(Catalog.boss_definition(stage).id),0)
