extends RefCounted
## A single payload visual is used while mounted and after release.
const Rules = preload("res://scripts/enemy_rules.gd")
const GREEN = Color("b6ff66")
static func released_scale(item: Dictionary) -> float:
	return lerpf(0.6,1.0,clampf(item.get("age",0.0)/0.36,0,1)) if item.get("cargo_release",false) else 1.0
static func draw_item(c: Node2D, art: RefCounted, center: Vector2, cycle: int, phase: float, scale: float = 1.0) -> void:
	var size := Vector2(20,30)*scale
	var pulse: float = 0.5+0.5*sin(phase*0.2)
	c.draw_circle(center,9*scale,Color(GREEN,0.08+pulse*0.06),true,-1,true)
	c.draw_arc(center,11*scale,phase*0.05,phase*0.05+PI*1.5,24,Color(GREEN,0.35),0.8,true)
	var texture: Texture2D = art.sprite("eweapons",Rect2i(cycle*20,260,20,30),Vector2i(cycle*20,290))
	c.draw_texture_rect(texture,Rect2(center-size/2,size),false)
static func draw_mount(c: Node2D, art: RefCounted, e: Dictionary, pos: Vector2, cycle: int, phase: float) -> void:
	var center: Vector2 = pos+Rules.cargo_offset()
	var loaded: bool = Rules.has_cargo(e)
	var color: Color = GREEN if loaded else Color("64c9d9")
	# Status lights belong to the grabber, not a second sprite painted over the hull.
	for side in [-1,1]:
		c.draw_circle(center+Vector2(side*9,-8),1.0,Color(color,0.8),true,-1,true)
	if loaded:
		draw_item(c,art,center,cycle,phase,0.6)
		if e.kind==19:
			c.draw_arc(center,9,-PI*0.9,-PI*0.1,18,Color(GREEN,0.65),1.0,true)
