extends RefCounted
## Stage3 orbs enter fixed upper stations, then slowly track body X in the lower phase.
const Catalog = preload("res://scripts/enemy_catalog.gd")
static func active(e: Dictionary) -> bool:
 return Catalog.definition(int(e.kind)).get("motion",{}).get("type","")=="boss_health_stations"
static func prepare(e: Dictionary, boss: Dictionary) -> void:
 var definition: Dictionary = Catalog.definition(int(e.kind))
 var settings: Dictionary = definition.motion
 var maximum: float = float(boss.get("max_hp",0))
 if maximum>0 and float(boss.get("hp",maximum))<=maximum*float(settings.lower_below_ratio): e.orb_lowered = true
 var lowered: bool = e.get("orb_lowered",false)
 var point: Array = settings.lower_center if lowered else settings.upper_center
 var centre := Vector2(point[0],point[1])
 var follow: Dictionary = settings.get("lower_follow",{})
 e.orb_following = lowered and not follow.is_empty()
 if e.orb_following and boss.has("pos"): centre.x = boss.pos.x+float(follow.x_offset)
 e.orb_target = centre-definition.draw_offset-definition.draw_size/2
 _update_state(e,settings)
static func advance(e: Dictionary, units: float) -> void:
 var settings: Dictionary = Catalog.definition(int(e.kind)).motion
 var step: float = maxf(0,units)
 if e.get("orb_following",false):
  # Separate axes: slow X chase never changes the lower row's Y travel/arrival.
  e.pos.x = move_toward(e.pos.x,e.orb_target.x,float(settings.lower_follow.speed)*step)
  e.pos.y = move_toward(e.pos.y,e.orb_target.y,float(settings.speed)*step)
 else: e.pos = e.pos.move_toward(e.orb_target,float(settings.speed)*step)
 _update_state(e,settings)
static func _update_state(e: Dictionary,settings: Dictionary) -> void:
 e.orb_stationary = e.pos==e.orb_target
 e.orb_y_stationary = e.pos.y==e.orb_target.y
 if e.get("orb_following",false):
  e.velocity = Vector2(signf(e.orb_target.x-e.pos.x)*float(settings.lower_follow.speed),signf(e.orb_target.y-e.pos.y)*float(settings.speed))
 else: e.velocity = Vector2.ZERO if e.orb_stationary else e.pos.direction_to(e.orb_target)*float(settings.speed)
