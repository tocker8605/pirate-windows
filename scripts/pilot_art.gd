extends RefCounted
## One common crop/pivot for all banks prevents per-frame sprite alignment jitter.
const Geometry = preload("res://scripts/pilot_geometry.gd")
var atlas: Texture2D = preload("res://assets/renewed/pilot-v14.png")
var frames: Array = []
func _init() -> void:
	var image: Image = atlas.get_image()
	var size := Vector2i(atlas.get_width()/3,atlas.get_height())
	var common := Rect2i()
	for index in range(3):
		var used: Rect2i = image.get_region(Rect2i(index*size.x,0,size.x,size.y)).get_used_rect()
		common = used if index==0 else common.merge(used)
	for index in range(3):
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2i(index*size.x,0)+common.position,common.size)
		texture.filter_clip = true
		frames.append(texture)
func texture(bank: int) -> Texture2D:
	# Use one bank pose and its mirror for consistent left/right silhouettes.
	return frames[0 if bank==0 else 1]
func draw(c: Node2D, pos: Vector2, bank: int = 0) -> void:
	c.draw_set_transform(pos+Vector2(25,25),0,Vector2(-1 if bank==2 else 1,1))
	c.draw_texture_rect(texture(bank),Rect2(-Geometry.DRAW_SIZE/2,Geometry.DRAW_SIZE),false)
	c.draw_set_transform(Vector2.ZERO)
