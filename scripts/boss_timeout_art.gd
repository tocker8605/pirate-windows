extends RefCounted
const SpriteFont=preload("res://scripts/menu_sprite_font.gd")
const SPRITE: Texture2D=preload("res://assets/enemies/boss-timeout-reaper.png")
static func draw(canvas: Node2D,actors: Array) -> void:
	for actor in actors:
		if actor.hp<=0:continue
		canvas.draw_set_transform(actor.pos+Vector2(25,25),actor.pose_angle,Vector2.ONE*float(actor.scale))
		canvas.draw_texture_rect(SPRITE,Rect2(-25,-25,50,50),false,Color(1,1,1,actor.opacity))
	canvas.draw_set_transform(Vector2.ZERO)
static func draw_timer(canvas: Node2D,timeout: RefCounted) -> void:
	var seconds: int=timeout.remaining()
	if seconds>=0:SpriteFont.centered(canvas,7,str(seconds),true)
