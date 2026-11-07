extends RefCounted
## Shared immutable atlas frames. No image generation/readback/triangulation during play.
const Shape = preload("res://scripts/fireball_shape.gd")
const ATLAS: Texture2D = preload("res://assets/renewed/projectile-effects-v24.7.png")
static var _frames: Array[AtlasTexture] = []
static func warm() -> void:
	if not _frames.is_empty(): return
	var pixels: int = Shape.CELL*Shape.PIXEL_SCALE
	for frame in range(Shape.FRAMES+6):
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = Rect2((frame%Shape.COLUMNS)*pixels,int(frame/Shape.COLUMNS)*pixels,pixels,pixels)
		texture.filter_clip = true
		_frames.append(texture)
static func draw(c: Node2D,p: Vector2,direction: Vector2,phase: float) -> void:
	var frame: int = posmod(roundi(fposmod(phase,Shape.PHASE_PERIOD)*Shape.FRAMES/Shape.PHASE_PERIOD),Shape.FRAMES)
	c.draw_set_transform(p,direction.angle()+PI/2)
	c.draw_texture_rect(_frames[frame],Rect2(-Shape.CELL/2.0,-Shape.CELL/2.0,Shape.CELL,Shape.CELL),false)
	c.draw_set_transform(Vector2.ZERO)

static func draw_plasma(c: Node2D,p: Vector2,kind: int) -> void:
	c.draw_texture_rect(_frames[Shape.FRAMES+kind-4],Rect2(p-Vector2.ONE*Shape.CELL/2,Vector2.ONE*Shape.CELL),false)

static func draw_streak(c: Node2D,p: Vector2,direction: Vector2,kind: int) -> void:
	var index: int = Shape.FRAMES+2
	match kind:
		1: index += 1
		6,7: index += 2
		3: index += 3
	c.draw_set_transform(p,direction.angle()+PI/2)
	c.draw_texture_rect(_frames[index],Rect2(-Shape.CELL/2.0,-Shape.CELL/2.0,Shape.CELL,Shape.CELL),false)
	c.draw_set_transform(Vector2.ZERO)
