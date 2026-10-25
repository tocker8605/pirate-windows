class_name PirateScenery
extends RefCounted
static func initial_clouds() -> Array:
	return [Vector2(120,400),Vector2(320,20)]
static func advance_clouds(clouds: Array, speed: float) -> void:
	var dy: int = int(floorf(speed*1.5))
	for i in range(2):
		var p: Vector2 = clouds[i]
		p.y += dy
		if p.y>480:
			p.x += 100 if i==0 else 50
			p.y = -300
		if p.x>340: p.x = -50
		clouds[i] = p

static func preparation(e: Dictionary, boss: Dictionary) -> Dictionary:
	var visible: bool = false
	match int(e.kind):
		22: visible = e.pos.y>50
		131: visible = not boss.is_empty() and boss.pos.y<110
		132: visible = not boss.is_empty() and boss.pos.y>90
	if not visible: return {}
	var parity: int = int(e.pos.y)%2
	if parity<0: return {}
	return {"rect":Rect2i(200,parity*100,50,50),"mask":Vector2i(200,50+parity*100),"pos":e.pos+Vector2(0,10)}
