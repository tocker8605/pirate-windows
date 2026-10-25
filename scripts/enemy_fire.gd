class_name PirateEnemyFire
extends RefCounted
const Rng = preload("res://scripts/random.gd")
## Original pixel-coordinate rules, expressed independently of game/render state.
## Player/enemy positions are TOP LEFT, not muzzle centres. Do not normalize aim.
static func aim(enemy: Vector2, player: Vector2, speed: float) -> Vector2:
	var delta: Vector2 = player - enemy
	var denominator: float = floorf(Vector2(delta.x, delta.y + 20).length())
	# The original skipped one coincidence case but could still divide by zero.
	return delta * speed / denominator if denominator > 0 else Vector2.ZERO

static func burst(e: Dictionary, player: Vector2, phase: int, timer: int, boss: Dictionary = {}) -> Array:
	var result: Array = []
	var p: Vector2 = e.pos
	var v: Vector2 = e.velocity
	var kind: int = int(e.kind)
	var target: Vector2 = aim(p,player,1)
	if player.x == p.x and player.y == p.y - 20: return result
	match kind:
		1:
			if v.y < 4 and v.y > -5 and phase % 6 == 0: _add(result,p+Vector2(25,20),target*7)
		2:
			if phase % 3 == 0 and v.x != 0: _add(result,p+Vector2(25,20),Vector2(-v.x,11-absf(v.x)))
			if v.x == 0 and phase % 6 == 0 and v.y > -1: _add(result,p+Vector2(25,20),Vector2(0,9),3)
		3:
			if phase % 2 == 0 and p.y < 199 and p.y > 20: _add(result,p+Vector2(20,30),Vector2((10-absf(20-int(p.y)%41))/3.0,8),5)
		4:
			if phase % 5 == 0: _add(result,p+Vector2(25,25),target*9,4)
		5:
			if v.x == 0 and phase % 2 == 0:
				var vx: float = (25-absf(25-int(p.y)%51))/3.0
				if p.x > 175: vx = -vx
				_add(result,p+Vector2(25,25),Vector2(vx,(25-int(p.y)%51)/2.0),6)
		6:
			if phase % 4 == 0:
				if v.y > 0:
					_add(result,p+Vector2(5,30),Vector2(-v.x,7),7)
					_add(result,p+Vector2(35,30),Vector2(-v.x,7),7)
				elif v.x == 0:
					_add(result,p+Vector2(5,30),target*9,7)
					_add(result,p+Vector2(35,30),target*9,7)
		7:
			if phase % 9 == 0:
				_add(result,p+Vector2(20,25),target*9,5)
				_add(result,p+Vector2(20,25),target*7+Vector2(-2,0),5)
				_add(result,p+Vector2(20,25),target*7+Vector2(2,0),5)
		8:
			if phase % 10 == 0: _add(result,p+Vector2(25,30),Vector2(0,-1),2)
			if v.y > 0 and phase % 3 == 0:
				_add(result,p+Vector2(30,25),Vector2(1+v.y,11-v.y))
				_add(result,p+Vector2(10,25),Vector2(-1-v.y,11-v.y))
		9:
			if p.y < 220 and phase % 3 == 0: _add(result,p+Vector2(25,25),Vector2(3-Rng.between(0,6),-1-Rng.between(0,2)),8)
		10:
			if v.y > 1 and phase % 6 == 0:
				_add(result,p+Vector2(10,40),Vector2(0,8))
				_add(result,p+Vector2(40,40),Vector2(0,8))
			if v.y < 4 and v.y > -5 and phase % 5 == 0: _add(result,p+Vector2(25,20),target*7)
		11:
			if phase % 7 == 0:
				_add(result,p+Vector2(20,25),Vector2(-v.x/2,9),7)
				_add(result,p+Vector2(20,25),Vector2(-v.x/3,6),5)
		21:
			if phase % 12 == 0:
				_add(result,p+Vector2(0,40),Vector2(-1,-1),2)
				_add(result,p+Vector2(50,40),Vector2(1,-1),2)
			if phase % 4 == 0: _add(result,p+Vector2(25,40),target*10)
		22:
			if p.y < 150 and p.y > 100:
				_add(result,p+Vector2(25,25),target*9+Vector2(3-int(p.y)%7,0),5)
				if phase % 2 == 0: _add(result,p+Vector2(25,25),target*10,7)
		41:
			if phase % 3 == 0: _add(result,p+Vector2(-20 if timer%4>1 else 70,40),target*10,6)
			if phase % 12 == 0: _add(result,p+Vector2(25,40),Vector2(0,-1),2)
		42:
			if phase % 8 == 0:
				_add(result,p+Vector2(-10,40),Vector2(2-Rng.between(0,4),-1-Rng.between(0,2)),2)
				_add(result,p+Vector2(60,40),Vector2(2-Rng.between(0,4),-1-Rng.between(0,2)),2)
		101,102:
			if p.y > 390:
				var vx: int = 3-Rng.between(0,6)
				_add(result,p+Vector2(25,20),Vector2(vx,-10+absi(vx)),5)
		111:
			if phase % 2 == 0 and timer%3<2: _add(result,p+Vector2(30,55),Vector2(-boss.get("velocity",Vector2.ZERO).x,8))
		112:
			if phase % 6 == 0 and timer%4>1:
				var vx: float = -boss.get("velocity",Vector2.ZERO).x
				_add(result,p+Vector2(20,55),Vector2(vx,8),7)
				_add(result,p+Vector2(20,55),Vector2(vx-2,7),7)
				_add(result,p+Vector2(20,55),Vector2(vx+2,7),7)
		113:
			if phase % 2 == 0 and p.y > 300:
				var vx: float = 2-floorf((p.y-280)/20)
				var vy: float = -floorf((500-p.y)/12)
				_add(result,p+Vector2(25,25),Vector2(vx,vy),8)
				_add(result,p+Vector2(25,25),Vector2(-vx,vy),8)
		121:
			if phase % 8 == 0 and timer%4>1:
				_add(result,p+Vector2(5,50),target*8+Vector2(-1,0),5)
				_add(result,p+Vector2(5,50),target*9,5)
				_add(result,p+Vector2(5,50),target*8+Vector2(1,0),5)
		122:
			if phase % 8 == 0 and timer%4<2:
				_add(result,p+Vector2(45,50),target*8+Vector2(-1,0),5)
				_add(result,p+Vector2(45,50),target*9,5)
				_add(result,p+Vector2(45,50),target*8+Vector2(1,0),5)
		123,124:
			if phase % 5 == 0 and p.y > boss.get("pos",Vector2.ZERO).y+30: _add(result,p+Vector2(25,25),Vector2(0,9),7 if kind==123 else 6)
		131,132:
			var by: float = boss.get("pos",Vector2.ZERO).y
			if (kind==131 and by<80 and by>40) or (kind==132 and by>120):
				_add(result,p+Vector2(25,25),target*9+Vector2(3-int(p.y)%7,0),5)
				if phase%2==0: _add(result,p+Vector2(25,25),target*10,7)
		133:
			if e.pattern == 2401:
				var vx: int = 3-Rng.between(0,6)
				_add(result,p+Vector2(25,20),Vector2(vx,-5+absi(vx)),8)
	return result

static func _add(result: Array, pos: Vector2, velocity: Vector2, kind: int = 1) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})
