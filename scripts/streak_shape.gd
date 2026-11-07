extends RefCounted
## Canonical directed enemy projectiles; kept for offline baking and pixel tests.
const HOT = Color("ff8945")
const PINK = Color("ff608f")
static func streak(c: Node2D,p: Vector2,d: Vector2,length: float,width: float,color: Color,glow: Texture2D) -> void:
	c.draw_texture_rect(glow,Rect2(p-Vector2.ONE*width*3,Vector2.ONE*width*6),false,Color(color,0.65))
	c.draw_line(p-d*length,p,color,width,true)
	c.draw_line(p-d*length*0.7,p,Color("fff6ec"),maxf(0.7,width*0.36),true)
static func draw(c: Node2D,p: Vector2,d: Vector2,kind: int,glow: Texture2D) -> void:
	if kind==2:
		streak(c,p-d*5,-d,12,3,HOT,glow)
		c.draw_line(p-d*5,p+d*5,Color("e1e5ee"),3,true)
		c.draw_line(p-d.rotated(PI/2)*3,p+d.rotated(PI/2)*3,HOT,1,true)
	elif kind==3: streak(c,p,d,19,3,HOT,glow)
	else: streak(c,p,d,6 if kind==1 else 10,2.2,HOT if kind==1 else PINK,glow)
