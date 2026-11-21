extends RefCounted
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const CHARACTER_SECONDS: float = 0.12
const HOLD_SECONDS: float = 2.0
static func label(stage: int, boss_rush: bool) -> String:
	return str(Catalog.boss_definition(stage).get("display_name","")) if boss_rush else "MISSION %d"%stage
static func duration(text: String) -> float:
	return text.length()*CHARACTER_SECONDS+HOLD_SECONDS
static func visible_characters(text: String, remaining_seconds: float) -> int:
	var elapsed: float = maxf(0,duration(text)-remaining_seconds)
	return clampi(floori((elapsed+0.000000001)/CHARACTER_SECONDS),0,text.length())
static func draw(canvas: Node2D, text: String, remaining_seconds: float) -> void:
	# Reserve the full line and caret width so the red marker never moves as text appears.
	var pos := Vector2((400-text.length()*10-25)/2.0,205)
	var count: int = visible_characters(text,remaining_seconds)
	SpriteFont.icon(canvas,pos,SpriteFont.MENU_CURSOR)
	SpriteFont.text(canvas,pos+Vector2(15,0),text.left(count))
	SpriteFont.icon(canvas,pos+Vector2(15+count*10,0),SpriteFont.NAME_CURSOR)
