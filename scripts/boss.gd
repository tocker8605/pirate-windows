class_name PirateBoss
extends RefCounted
const Rng = preload("res://scripts/random.gd")
## Four original boss bodies, attached weapons and body attack phases.
static func parts_alive(enemies: Variant) -> bool:
	for e in enemies:
		if e.kind>=100 and e.kind<200 and e.hp>0: return true
	return false

static func has_part(enemies: Variant, kind: int) -> bool:
	for e in enemies:
		if e.kind==kind and e.hp>0: return true
	return false

static func steer(b: Dictionary, player: Vector2, enemies: Variant) -> void:
	var p: Vector2 = b.pos
	var v: Vector2 = b.velocity
	match int(b.stage):
		1:
			if p.y>120:
				v.x += 1 if p.x<player.x+25 else -1
				v.y -= 1
			if p.y<80:
				v.x += 1 if p.x<player.x+25 else -1
				v.y += 1
			if p.x<100: v.x += 2
			if p.x>300: v.x -= 2
			v = v.clamp(Vector2(-5,-5),Vector2(5,3))
		2:
			v.x += 1 if p.x<player.x+25 else -1
			if p.y<0: v.y += 3
			elif p.y>player.y-80: v.y -= 2
			if p.x<150: v.x += 2
			if p.x>250: v.x -= 2
			v = v.clamp(Vector2(-3,-7),Vector2(3,3))
		3:
			v.x += 1 if p.x<player.x+25 else -1
			if p.y< -10: v.y += 1
			elif p.y>100: v.y -= 1
			if p.x<150: v.x += 2
			if p.x>250: v.x -= 2
			v = v.clamp(Vector2(-3,-3),Vector2(3,3))
		4:
			v.x += 1 if p.x<player.x+25 else -1
			if parts_alive(enemies):
				if p.y<51: v.y = 1
				elif p.y>149: v.y = -1
			else: v.y = -1 if p.y>30 else 0
			if p.x<100: v.x += 2
			if p.x>300: v.x -= 2
			v.x = clampf(v.x,-3,3)
	b.velocity = v

static func attach(e: Dictionary, b: Dictionary) -> void:
	if b.is_empty(): return
	var p: Vector2 = b.pos
	match int(e.kind):
		101: e.pos.x = p.x-65
		102: e.pos.x = p.x+15
		111: e.pos = p+Vector2(20+b.velocity.y*2,60)
		112: e.pos = p+Vector2(-70-b.velocity.y*2,60)
		113: e.pos.x = p.x-25
		121: e.pos = p+Vector2(-75,65)
		122: e.pos = p+Vector2(25,65)
		131: e.pos = p+Vector2(-80,65)
		132: e.pos = p+Vector2(30,65)
		133:
			if e.pattern==0: e.pos = p+Vector2(-26,50)
			if e.hp<100 and e.pattern==0:
				e.pattern = 2401
				e.velocity.y = -5

static func fire(b: Dictionary, enemies: Variant, phase: int, timer: int, section: int = 0) -> Array:
	var result: Array = []
	var p: Vector2 = b.pos
	var v: Vector2 = b.velocity
	var parts: bool = parts_alive(enemies)
	match int(b.stage):
		1:
			if not parts and phase%5==0:
				var side: float = 1 if timer%4>1 else -1
				_add(result,p+Vector2(40*side,50),Vector2(side*(1+v.y),9),1)
		2:
			if not parts and phase%2==0:
				_add(result,p+Vector2(15,60),Vector2(3-Rng.between(0,6),3-Rng.between(0,6)),6)
				_add(result,p+Vector2(-15,60),Vector2(3-Rng.between(0,6),3-Rng.between(0,6)),7)
		3:
			if phase%8==0:
				_add(result,p+Vector2(40,40),Vector2(2-Rng.between(0,4),-1-Rng.between(0,2)),2)
				_add(result,p+Vector2(-40,40),Vector2(2-Rng.between(0,4),-1-Rng.between(0,2)),2)
			if not parts and phase%5==0:
				var dx: float = timer%6+1
				var dy: float = 9-timer%6
				_add(result,p+Vector2(30,70),Vector2(dx,dy),6)
				_add(result,p+Vector2(-30,70),Vector2(-dx,dy),6)
		4:
			if section in [0,1] and phase%2==0:
				if not has_part(enemies,131):
					var vx: int = 5-Rng.between(0,8)
					_add(result,p+Vector2(-35,55),Vector2(vx,11-absi(vx)),5)
				if not has_part(enemies,132):
					var vx: int = 3-Rng.between(0,8)
					_add(result,p+Vector2(35,55),Vector2(vx,11-absi(vx)),5)
			if section in [0,2] and phase%3==0 and p.y>49 and parts:
				var mod_y: int = int(p.y)%50
				_add(result,p+Vector2(-25,50),Vector2(5-mod_y/5.0,(100-p.y)/5.0),6)
				_add(result,p+Vector2(25,50),Vector2(mod_y/5.0-5,(100-p.y)/5.0),6)
			if section in [0,3] and not parts:
				var x: int = 10-Rng.between(0,20)
				var vx: int = 3-Rng.between(0,6)
				_add(result,p+Vector2(x,35),Vector2(vx,-5+absi(vx)),8)
	return result

static func _add(result: Array, pos: Vector2, velocity: Vector2, kind: int) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})
