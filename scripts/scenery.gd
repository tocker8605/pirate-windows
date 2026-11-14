class_name PirateScenery
extends RefCounted
const Boss = preload("res://scripts/boss.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
static func initial_clouds() -> Array:
	return [Vector2(120,400),Vector2(320,20)]
static func advance_clouds(clouds: Array, speed: float, seconds: float = 1.0/60.0) -> void:
	var dy: float = floorf(speed*0.045)*33.333333333333336
	for i in range(2):
		var p: Vector2 = clouds[i]
		p.y += dy*seconds
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
	var pos: Vector2 = Boss.claw_muzzle(e)-Vector2(25,25) if e.kind in [131,132] else Fire.single_muzzle(e)-Vector2(25,25)
	return {"rect":Rect2i(200,parity*100,50,50),"mask":Vector2i(200,50+parity*100),"pos":pos}
