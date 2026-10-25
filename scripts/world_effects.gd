class_name PirateWorldEffects
extends RefCounted
const EnemyRules = preload("res://scripts/enemy_rules.gd")
static func sprite(sheet: String, rect: Rect2i, mask: Vector2i, pos: Vector2) -> Dictionary:
	return {"sheet":sheet,"rect":rect,"mask":mask,"pos":pos}
static func smoke(commands: Array, pos: Vector2, frame: int) -> void:
	commands.append(sprite("picsmo",Rect2i(frame*50,0,50,50),Vector2i(frame*50,50),pos))
static func enemy_smoke(e: Dictionary, frame: int, speed: float) -> Array:
	var commands: Array = []
	if e.hp>=EnemyRules.SMOKE.get(int(e.kind),0): return commands
	var offsets: Array = [Vector2.ZERO]
	if e.kind>20 and e.kind<100: offsets.append(Vector2(35,10))
	if e.kind>40 and e.kind<100: offsets.append(Vector2(-50,10))
	for offset in offsets:
		smoke(commands,e.pos+offset-Vector2(e.velocity.x*8,e.velocity.y*6)+Vector2(0,speed*2),frame)
		smoke(commands,e.pos+offset-Vector2(e.velocity.x*5,e.velocity.y*4)+Vector2(0,speed),frame+1)
		smoke(commands,e.pos+offset-e.velocity*2,frame+2)
	return commands
static func player_smoke(player: Vector2, frame: int, speed: float) -> Array:
	var commands: Array = []
	smoke(commands,player+Vector2(0,10),frame+2)
	smoke(commands,player+Vector2(0,25+speed*2),frame+1)
	smoke(commands,player+Vector2(0,40+speed*4),frame)
	return commands
static func advance(blasts: Array, speed: float) -> void:
	for blast in blasts:
		if blast.get("delay",0)>0:
			blast.delay -= 1
			continue
		blast.render_pos = blast.pos
		blast.render_ticks = blast.ticks
		blast.pos.y += speed
		blast.ticks -= 1
static func explosion(blast: Dictionary, speed: float) -> Array:
	var n: int = int(blast.get("render_ticks",0))
	var p: Vector2 = blast.get("render_pos",blast.pos)
	var result: Array = []
	if n>20 and n<35:
		var frame: int = int((n-20)/3)
		for offset in [Vector2(-80+n*2,-speed*3),Vector2(80-n*2,-speed*3),Vector2(0,15-speed*3)]:
			result.append(sprite("bang",Rect2i(frame*50,0,50,50),Vector2i(frame*50,50),p+offset))
	if n>0 and n<15:
		var frame: int = int(n/3)
		result.append(sprite("bang",Rect2i(frame*50,0,50,50),Vector2i(frame*50,50),p-Vector2(0,speed*2)))
	if n>8 and n<20:
		var frame: int = int((n-8)/3)
		result.append(sprite("bang",Rect2i(frame*100,100,100,50),Vector2i(frame*100,150),p+Vector2(-25,15-speed)))
	return result
static func hit_flash(player: Vector2, ticks: int) -> Array:
	if ticks<=0: return []
	return [sprite("bang",Rect2i(int(ticks/4)*50,0,50,50),Vector2i(int(ticks/4)*50,50),player+Vector2(0,45-ticks*2))]
