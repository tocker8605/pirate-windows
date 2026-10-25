class_name PiratePlayerWeapons
extends RefCounted
const Rng = preload("res://scripts/random.gd")
## Position is the original cwx/cwy anchor, NOT the visible sprite centre.
static func volley(player: Vector2, weapon: int, power: int) -> Array:
	var plan: Array = []
	var kind: int = 4 if weapon == 3 else 1
	if power <= 2:
		_add(plan,player,11,0,kind)
	elif power <= 4:
		if weapon == 1:
			_add(plan,player,7,3,2)
			_add(plan,player,13,3,3)
		elif weapon == 2:
			_add(plan,player,17,3,1)
			_add(plan,player,5,3,1)
		else:
			for i in range(2): _add(plan,player,7+Rng.between(0,8),0,4)
	elif power <= 6:
		if weapon == 1:
			_add(plan,player,-5,5,2)
			_add(plan,player,25,5,3)
		elif weapon == 2:
			_add(plan,player,0,2,1)
			_add(plan,player,20,2,1)
		else:
			for i in range(3): _add(plan,player,5+Rng.between(0,12),-Rng.between(0,1),4)
		if weapon < 3: _add(plan,player,10,0,1)
	else:
		if weapon == 1:
			_add(plan,player,-5,2,1)
			_add(plan,player,25,2,1)
			_add(plan,player,-10,5,2)
			_add(plan,player,30,5,3)
		elif weapon == 2:
			_add(plan,player,5,2,1)
			_add(plan,player,-5,5,1)
			_add(plan,player,15,2,1)
			_add(plan,player,25,5,1)
		else:
			for i in range(4): _add(plan,player,3+Rng.between(0,16),-Rng.between(0,2),4)
	return plan

static func _add(plan: Array, player: Vector2, x: float, y: float, kind: int) -> void:
	plan.append({"pos":player+Vector2(x,y),"kind":kind,"alive":true,"impact_ticks":-1})

static func cost(power: int) -> float:
	return [0.0,0.8,0.6,1.0,0.8,1.2,1.0,1.3][power]

static func advance(shot: Dictionary, player: Vector2) -> void:
	var p: Vector2 = shot.pos
	match int(shot.get("kind",1)):
		1: p.y -= 19
		2: p += Vector2(-1,-17)
		3: p += Vector2(1,-17)
		4:
			p.x -= (player.x+11-p.x)/14.0
			var dy: float = absf(player.y+20-p.y)
			p.y = vb_integer(p.y-(dy/8.0+5 if dy<120 else 20))
	shot.pos = p

static func vb_integer(value: float) -> int:
	# Assignment to VB6 Integer uses ties-to-even, unlike Godot's round().
	var low: float = floorf(value)
	if value-low==0.5: return int(low) if int(low)%2==0 else int(low)+1
	return int(floorf(value+0.5))

static func visual(shot: Dictionary, player: Vector2) -> Dictionary:
	var ticks: int = int(shot.get("impact_ticks",-1))
	if ticks >= 0:
		var row: int = 60 if ticks>6 else (120 if ticks>3 else 180)
		return {"phase":"impact","rect":Rect2i(0,row,80,30),"mask":Vector2i(0,row+30),"offset":Vector2(-25,0)}
	if shot.pos.y < player.y-19:
		return {"phase":"flight","rect":Rect2i(10,0,20,30),"mask":Vector2i(10,30),"offset":Vector2(5,0)}
	return {"phase":"launch","rect":Rect2i(40,0,40,30),"mask":Vector2i(40,30),"offset":Vector2(-5,0)}
