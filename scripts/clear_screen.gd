extends RefCounted
## Presentation only; GameFlow owns the completed run and transition policies.
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const BACKGROUND_PATH: String = "res://assets/images/clear.png"
const MUSIC_TRACK: String = "title"
const MUSIC_START_SECONDS: float = 189.0
const CONFIRM_KEYS: Array = [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]
var background: Texture2D
var record: Dictionary = {}
func begin(result: Dictionary, backdrop: Texture2D) -> void:
	record = result
	background = backdrop
func accepts(event: InputEventKey) -> bool:
	return event.pressed and not event.echo and event.keycode in CONFIRM_KEYS
func render(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(0,0,400,480),Color.BLACK)
	if background!=null: canvas.draw_texture_rect(background,Rect2(0,0,400,480),false)
	var label: String = "YOUR SCORE IS "
	var points: String = str(record.get("score",0))
	var start := Vector2((400-(label.length()+points.length())*10)/2,365)
	SpriteFont.text(canvas,start,label)
	SpriteFont.text(canvas,start+Vector2(label.length()*10,0),points,true)
	SpriteFont.centered(canvas,415,"PRESS SPACE OR ENTER")
