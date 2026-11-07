extends RefCounted
## Original static energy bullet art, baked beside the animated fireball cells.
const PINK = Color("ff608f")
static func draw(c: Node2D,p: Vector2,kind: int,glow: Texture2D) -> void:
	var radius: float = 4.5 if kind==4 else 3.2
	var extent: float = radius*3
	c.draw_texture_rect(glow,Rect2(p-Vector2.ONE*extent,Vector2.ONE*extent*2),false,Color(PINK,0.85))
	c.draw_circle(p,radius,PINK,true,-1,true)
	c.draw_circle(p,radius*0.5,Color("fff4e6"),true,-1,true)
