class_name PirateBoss
extends RefCounted
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rng = preload("res://scripts/random.gd")
## Four original boss bodies, attached weapons and body attack phases.
static func parts_alive(enemies: Variant) -> bool:
	for e in enemies:
		if Catalog.is_part(int(e.kind)) and e.hp>0: return true
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
		1: pass # Independent300/150ms body clock is advanced every native tick.
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
			if section in [0,3] and not parts:
				var x: int = 10-Rng.between(0,20)
				var vx: int = 3-Rng.between(0,6)
				_add(result,p+Vector2(x,35),Vector2(vx,-5+absi(vx)),8)
	return result

# The paired sweep has an independent100ms clock, not the legacy60ms phase clock.
# Both ports start downward and share sweep progress with opposite rotation signs.
static func advance(b: Dictionary,enemies: Variant,seconds: float,timer: int = 0) -> Array:
	var result: Array = []
	if b.is_empty() or b.hp<=0: return result
	if int(b.stage)==1: return _advance_first(b,enemies,seconds,timer)
	if int(b.stage)!=4: return result
	var attack: Dictionary = Catalog.boss_definition(4).get("attack",{})
	if attack.is_empty() or not attack.has("ports"): return result
	if not parts_alive(enemies) or b.pos.y<=float(attack.get("min_y",-INF)):
		b.body_attack_elapsed = 0.0
		return result
	var elapsed: float = float(b.get("body_attack_elapsed",0.0))+seconds
	var sweep: float = float(b.get("body_sweep",0.0))
	while elapsed>=float(attack.interval_seconds)-0.0000001:
		elapsed = maxf(0,elapsed-float(attack.interval_seconds))
		for i in range(attack.ports.size()):
			var port: Array = attack.ports[i]
			var angle: float = deg_to_rad(attack.initial_degrees)+sweep*float(attack.rotation_directions[i])
			_add(result,b.pos+Vector2(port[0],port[1]),Vector2.from_angle(angle)*float(attack.speed),int(attack.projectile_kind))
		sweep = fposmod(sweep+deg_to_rad(attack.step_degrees),TAU)
	b.body_attack_elapsed = elapsed
	b.body_sweep = sweep
	return result

static func _advance_first(b: Dictionary,enemies: Variant,seconds: float,timer: int) -> Array:
	var attack: Dictionary = Catalog.boss_definition(1).get("attack",{})
	var result: Array = []
	if attack.is_empty(): return result
	var interval: float = attack.interval_seconds if parts_alive(enemies) else attack.enraged_interval_seconds
	# Start a fresh half-length interval when the final fist goes away; no backlog burst.
	if not is_equal_approx(float(b.get("body_attack_period",interval)),interval): b.body_attack_elapsed = 0.0
	b.body_attack_period = interval
	var elapsed: float = float(b.get("body_attack_elapsed",0.0))+seconds
	while elapsed>=interval-0.0000001:
		elapsed = maxf(0,elapsed-interval)
		var side: float = 1 if timer%4>1 else -1
		var port: Array = attack.ports[1 if side>0 else 0]
		_add(result,b.pos+Vector2(port[0],port[1]),Vector2(side*(float(attack.horizontal_base)+b.velocity.y),float(attack.speed_y)),int(attack.projectile_kind))
	b.body_attack_elapsed = elapsed
	return result

static func _add(result: Array, pos: Vector2, velocity: Vector2, kind: int) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})

static func part_side(kind: int) -> int:
	return int(Catalog.definition(kind).get("part_side",0))
static func claw_muzzle(e: Dictionary) -> Vector2:
	# Inner empty region of the existing50x100 claw sprite, mirrored about the torso.
	match int(e.kind):
		131: return e.pos+Vector2(14,36)
		132: return e.pos+Vector2(36,36)
	return e.pos+Vector2(25,25)
