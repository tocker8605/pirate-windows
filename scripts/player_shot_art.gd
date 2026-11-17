extends RefCounted
## Flight bodies only. Launch and impact events are handled by the particle system.
const ATLAS = preload("res://assets/renewed/player-projectiles-v24.41.png")
const Style = preload("res://scripts/player_weapon_style.gd")
const CELL := Vector2(24,34)
const SCALE: int = 4
static var _frames: Dictionary = {}
static var _atlas: CanvasTexture = _filtered_atlas()
static func _filtered_atlas() -> CanvasTexture:
	var result := CanvasTexture.new()
	result.diffuse_texture = ATLAS
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return result
func frame_texture(weapon: int, _visual: Dictionary = {}) -> Texture2D:
	var index: int = clampi(weapon,1,3)-1
	if not _frames.has(index):
		var frame := AtlasTexture.new()
		frame.atlas = _atlas
		frame.region = Rect2(Vector2(index*CELL.x,0)*SCALE,CELL*SCALE)
		frame.filter_clip = true
		_frames[index] = frame
	return _frames[index]
func draw(c: Node2D, shot: Dictionary, _player: Vector2, weapon: int, position: Variant = null) -> void:
	if float(shot.get("impact_remaining_seconds",-1))>=0: return
	var pos: Vector2 = position if position!=null else shot.pos
	c.draw_texture_rect(frame_texture(weapon),Rect2(pos+Style.CENTRE-CELL/2,CELL),false)
