extends RefCounted
## A single payload visual is used while mounted and after release.
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const GREEN = Color("b6ff66")
const HEALTH = Color("ff7d8a")
static func cargo_color(item_kind: int) -> Color: return HEALTH if item_kind==2 else GREEN
static func released_scale(item: Dictionary) -> float:
	return lerpf(0.6,1.0,clampf(item.get("age",0.0)/0.36,0,1)) if item.get("cargo_release",false) else 1.0
static func draw_item(c: Node2D, art: RefCounted, center: Vector2, cycle: int, phase: float, scale: float = 1.0, item_kind: int = 1) -> void:
	var size := Vector2(20,30)*scale
	var color: Color = cargo_color(item_kind)
	var pulse: float = 0.5+0.5*sin(phase*0.2)
	c.draw_circle(center,9*scale,Color(color,0.08+pulse*0.06),true,-1,true)
	c.draw_arc(center,11*scale,phase*0.05,phase*0.05+PI*1.5,24,Color(color,0.35),0.8,true)
	var row: int = 320 if item_kind==2 else 260
	var texture: Texture2D = art.sprite("eweapons",Rect2i(cycle*20,row,20,30),Vector2i(cycle*20,row+30))
	c.draw_texture_rect(texture,Rect2(center-size/2,size),false)
static func draw_mount(c: Node2D, art: RefCounted, e: Dictionary, pos: Vector2, cycle: int, phase: float) -> void:
	var center: Vector2 = pos+Rules.cargo_offset(e)
	var loaded: bool = Rules.has_cargo(e)
	var item_kind: int = Rules.cargo_item(e)
	var color: Color = cargo_color(item_kind) if loaded else Color("64c9d9")
	# Status lights belong to the grabber, not a second sprite painted over the hull.
	for side in [-1,1]:
		c.draw_circle(center+Vector2(side*9,-8),1.0,Color(color,0.8),true,-1,true)
	if loaded:
		draw_item(c,art,center,cycle,phase,0.6,item_kind)
		if Catalog.definition(int(e.kind)).damageable:
			c.draw_arc(center,9,-PI*0.9,-PI*0.1,18,Color(color,0.65),1.0,true)
	if item_kind==2:
		var badge := center+Vector2(0,-18)
		c.draw_line(badge-Vector2(3,0),badge+Vector2(3,0),HEALTH,2.0,true)
		c.draw_line(badge-Vector2(0,3),badge+Vector2(0,3),HEALTH,2.0,true)
