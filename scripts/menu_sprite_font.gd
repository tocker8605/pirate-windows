extends RefCounted
## Original10x20 green/white alphabet, with two cursors and three weapons on row3.
const ATLAS: Texture2D = preload("res://assets/images/font.png")
const GLYPHS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const CELL := Vector2(10,20)
const NAME_CURSOR: int = 0
const MENU_CURSOR: int = 1
static var _frames: Dictionary = {}
static func frame(column: int, row: int) -> Texture2D:
	var key: int = row*36+column
	if not _frames.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = Rect2(Vector2(column*10,row*20),CELL)
		texture.filter_clip = true
		_frames[key] = texture
	return _frames[key]
static func text(canvas: Node2D, pos: Vector2, value: String, green: bool = false) -> void:
	var upper: String = value.to_upper()
	for i in range(upper.length()):
		var column: int = GLYPHS.find(upper[i])
		if column>=0: canvas.draw_texture(frame(column,0 if green else 1),pos+Vector2(i*10,0))
static func centered(canvas: Node2D, y: float, value: String, green: bool = false) -> void:
	text(canvas,Vector2((400-value.length()*10)/2,y),value,green)
static func icon(canvas: Node2D, pos: Vector2, index: int) -> void:
	canvas.draw_texture(frame(clampi(index,0,4),2),pos)
static func weapon_icon(canvas: Node2D, pos: Vector2, weapon: int) -> void:
	icon(canvas,pos,clampi(weapon,1,3)+1)
