extends RefCounted
## One level pose plus one banked painting; the banked painting is mirrored for left input.
const Geometry = preload("res://scripts/pilot_geometry.gd")
const CELL_SIZE := Vector2i(724,724)
# Retain the original registration rectangle, so recoloring cannot move the cockpit or hull.
const FRAME_CROP := Rect2i(0,19,720,705)
const COCKPIT_ANCHORS: Array[Vector2] = [Vector2(375.5,250.5),Vector2(384.5,247.5)]
const POSES: Array = [
	{"frame":0,"mirror_x":false}, # neutral / level
	{"frame":1,"mirror_x":true},  # left roll
	{"frame":1,"mirror_x":false}] # right roll
var atlas: Texture2D = preload("res://assets/renewed/pilot-white-wings.png")
var frames: Array = []
var frame_crop: Rect2i = FRAME_CROP
func _init() -> void:
	# The third cell of the source painting is a duplicate level pose, not a right roll.
	# Only the two distinct poses are registered; input direction selects mirroring below.
	for index in range(2):
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2i(index*CELL_SIZE.x,0)+frame_crop.position,frame_crop.size)
		texture.filter_clip = true
		frames.append(texture)
func pose(bank: int) -> Dictionary:return POSES[clampi(bank,0,POSES.size()-1)]
func texture(bank: int) -> Texture2D:return frames[int(pose(bank).frame)]
func sprite_rect(bank: int) -> Rect2:
	var cockpit: Vector2 = COCKPIT_ANCHORS[int(pose(bank).frame)]
	var pivot: Vector2 = (cockpit-Vector2(frame_crop.position))/Vector2(frame_crop.size)*Geometry.DRAW_SIZE
	return Rect2(-pivot,Geometry.DRAW_SIZE)
func draw(c: Node2D, pos: Vector2, bank: int = 0) -> void:
	c.draw_set_transform(pos+Geometry.COCKPIT,0,Vector2(-1 if pose(bank).mirror_x else 1,1))
	c.draw_texture_rect(texture(bank),sprite_rect(bank),false)
	c.draw_set_transform(Vector2.ZERO)
