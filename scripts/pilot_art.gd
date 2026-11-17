extends RefCounted
## Shared crop/scale; each painted cockpit is anchored to the fixed gameplay hit centre.
const Geometry = preload("res://scripts/pilot_geometry.gd")
# Measured canopy centres in each724px atlas cell, before cropping or mirroring.
const COCKPIT_ANCHORS: Array[Vector2] = [Vector2(375.5,250.5),Vector2(384.5,247.5)]
var atlas: Texture2D = preload("res://assets/renewed/pilot-v14.png")
var frames: Array = []
var frame_crop: Rect2i
func _init() -> void:
	var image: Image = atlas.get_image()
	var size := Vector2i(atlas.get_width()/3,atlas.get_height())
	var common := Rect2i()
	for index in range(3):
		var used: Rect2i = image.get_region(Rect2i(index*size.x,0,size.x,size.y)).get_used_rect()
		common = used if index==0 else common.merge(used)
	frame_crop = common
	for index in range(3):
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2i(index*size.x,0)+common.position,common.size)
		texture.filter_clip = true
		frames.append(texture)
func texture(bank: int) -> Texture2D:
	# Frame 1 banks right; mirror it for the left-input pose (bank 1).
	return frames[0 if bank==0 else 1]
func sprite_rect(bank: int) -> Rect2:
	var cockpit: Vector2 = COCKPIT_ANCHORS[0 if bank==0 else 1]
	var pivot: Vector2 = (cockpit-Vector2(frame_crop.position))/Vector2(frame_crop.size)*Geometry.DRAW_SIZE
	return Rect2(-pivot,Geometry.DRAW_SIZE)
func draw(c: Node2D, pos: Vector2, bank: int = 0) -> void:
	c.draw_set_transform(pos+Geometry.COCKPIT,0,Vector2(-1 if bank==1 else 1,1))
	c.draw_texture_rect(texture(bank),sprite_rect(bank),false)
	c.draw_set_transform(Vector2.ZERO)
