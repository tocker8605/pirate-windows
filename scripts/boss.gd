class_name PirateBoss
extends RefCounted
const PoseMotion=preload("res://scripts/entity_pose_motion.gd")
const Volleys=preload("res://scripts/projectile_volley.gd")
const Attachment=preload("res://scripts/entity_attachment.gd")
const SceneryMotion=preload("res://scripts/scenery_motion.gd")
const Movement = preload("res://scripts/movement.gd")
const AttackTimer = preload("res://scripts/attack_timer.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const CoreMotion = preload("res://scripts/boss_core_motion.gd")
## Boss bodies, attached weapons and independent authored attack channels.
static func parts_alive(enemies: Variant) -> bool:
	for e in enemies:
		if Catalog.is_part(int(e.kind)) and e.hp>0: return true
	return false

static func has_part(enemies: Variant, kind: int) -> bool:
	for e in enemies:
		if e.kind==kind and e.hp>0: return true
	return false

static func steer(b: Dictionary, player: Vector2, enemies: Variant, seconds: float = 1.0/60.0) -> void:
	if Catalog.for_actor(b).get("movement_mode","pattern") in ["stationary","scenery"]:
		b.velocity = Vector2.ZERO
		return
	if seconds<=0: return
	var acceleration: float = Movement.BASE_ACCELERATION*seconds
	var p: Vector2 = b.pos
	var v: Vector2 = b.velocity
	match int(b.stage):
		1:
			if p.y>120:
				v.x += acceleration if p.x<player.x+25 else -acceleration
				v.y -= acceleration
			if p.y<80:
				v.x += acceleration if p.x<player.x+25 else -acceleration
				v.y += acceleration
			if p.x<100: v.x += acceleration*2
			if p.x>300: v.x -= acceleration*2
			v = v.clamp(Vector2(-166.66666666666669,-166.66666666666669),Vector2(166.66666666666669,100))
		2:
			v.x += acceleration if p.x<player.x+25 else -acceleration
			if p.y<0: v.y += acceleration*3
			elif p.y>player.y-80: v.y -= acceleration*2
			if p.x<150: v.x += acceleration*2
			if p.x>250: v.x -= acceleration*2
			v = v.clamp(Vector2(-100,-233.33333333333334),Vector2(100,100))
		3:
			v.x += acceleration if p.x<player.x+25 else -acceleration
			if p.y< -10: v.y += acceleration
			elif p.y>100: v.y -= acceleration
			if p.x<150: v.x += acceleration*2
			if p.x>250: v.x -= acceleration*2
			v = v.clamp(Vector2(-100,-100),Vector2(100,100))
		4:
			v.x += acceleration if p.x<player.x+25 else -acceleration
			if parts_alive(enemies):
				if p.y<51: v.y = 33.333333333333336
				elif p.y>149: v.y = -33.333333333333336
			else: v.y = -33.333333333333336 if p.y>30 else 0
			if p.x<100: v.x += acceleration*2
			if p.x>300: v.x -= acceleration*2
			v.x = clampf(v.x,-100,100)
	b.velocity = v

static func attach(e: Dictionary, b: Dictionary) -> void:
	if b.is_empty(): return
	var attachment: Dictionary = Catalog.definition(int(e.kind)).get("attachment",{})
	if attachment.is_empty(): return
	if int(e.kind)==CoreMotion.KIND and e.pattern!=0: return
	Attachment.apply(e,b)
	if int(e.kind)==CoreMotion.KIND and e.hp<CoreMotion.settings().detach_hp:
		CoreMotion.detach(e)

static func enabled(enemies: Variant, channel: Dictionary) -> bool:
	match str(channel.gate):
		"no_parts": return not parts_alive(enemies)
		"any_parts": return parts_alive(enemies)
		"part_missing": return not has_part(enemies,int(channel.part_id))
		"part_alive": return has_part(enemies,int(channel.part_id))
		"parts_missing":
			for part_id in channel.part_ids:
				if has_part(enemies,int(part_id)): return false
			return true
	return channel.gate=="always"

static func emit(b: Dictionary, attack: String, player: Vector2 = Vector2.ZERO, fired_at: float = -1) -> Array:
	var definition: Dictionary=Catalog.for_actor(b)
	return Volleys.emit(b,player,Catalog.fire_channel(int(definition.id),attack),{},fired_at,definition.get("attack",{}))

# Common channels can coexist with legacy spiral channels during incremental migration.
static func advance(b: Dictionary,enemies: Variant,seconds: float,player: Vector2 = Vector2.ZERO) -> Array:
	var result: Array = []
	if b.is_empty() or b.hp<=0: return result
	PoseMotion.advance(b,seconds)
	var definition: Dictionary=Catalog.for_actor(b)
	var channels: Array = Catalog.boss_definition(int(b.stage)).get("fire_channels",[])
	var events: Array = AttackTimer.advance(b,channels,seconds,func(channel): return enabled(enemies,channel))
	for event in events: result.append_array(emit(b,event.name,player,float(event.at)))
	var attack: Dictionary = definition.get("attack",{})
	if attack.get("type")!="spiral":return result
	if attack.is_empty() or not attack.has("ports"): return result
	var sweep_enabled: bool=parts_alive(enemies) and b.pos.y>float(attack.get("min_y",-INF))
	var sweep_events: Array=AttackTimer.periodic(b,"body_spiral",seconds,attack.interval_seconds,sweep_enabled)
	var sweep: float = float(b.get("body_sweep",0.0))
	for _event in sweep_events:
		for i in range(attack.ports.size()):
			var port: Array = attack.ports[i]
			var angle: float = deg_to_rad(attack.initial_degrees)+sweep*float(attack.rotation_directions[i])
			_add(result,b.pos+Vector2(port[0],port[1]),Vector2.from_angle(angle)*float(attack.speed),int(attack.projectile_kind))
		sweep = fposmod(sweep+deg_to_rad(attack.step_degrees),TAU)
	b.body_sweep = sweep
	return result

static func _add(result: Array, pos: Vector2, velocity: Vector2, kind: int) -> void:
	result.append({"pos":pos,"velocity":velocity,"kind":kind})

static func part_side(kind: int) -> int:
	return int(Catalog.definition(kind).get("part_side",0))
static func claw_muzzle(e: Dictionary) -> Vector2:
	var volley: Dictionary=Catalog.fire_channel(int(e.kind),"plasma").get("volley",{})
	var ports: Array=volley.get("ports",[[25,25]])
	return e.pos+Vector2(ports[0][0],ports[0][1])

static func bind_scenery(b: Dictionary,distance: float) -> void:
	b.scenery_anchor_y=b.pos.y
	b.scenery_anchor_distance=distance
	b.scenery_stop_triggered=false
static func advance_position(b: Dictionary,seconds: float,distance: float) -> bool:
	b.age+=seconds
	var definition: Dictionary=Catalog.for_actor(b)
	if definition.get("movement_mode","pattern")!="scenery":
		b.pos+=Movement.displacement(b.velocity,seconds)
		return false
	if not b.has("scenery_anchor_distance"):bind_scenery(b,distance)
	var previous_y: float=b.pos.y
	b.pos.y=SceneryMotion.y(b.scenery_anchor_y,b.scenery_anchor_distance,distance)
	b.velocity=Vector2(0,(b.pos.y-previous_y)/seconds if seconds>0 else 0)
	var policy: Dictionary=definition.get("boss_scroll",{})
	if policy.has("stop_after_y") and b.pos.y>float(policy.stop_after_y) and not b.get("scenery_stop_triggered",false):
		b.scenery_stop_triggered=true
		return true
	return false
