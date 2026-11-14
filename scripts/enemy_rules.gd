class_name PirateEnemyRules
extends RefCounted
const Catalog = preload("res://scripts/enemy_catalog.gd")
# One cargo anchor comes from the same definition as the spawned reward.
static func cargo_position(e: Dictionary) -> Vector2:
	return e.pos+Catalog.definition(int(e.kind)).get("drop",Catalog.cargo_drop()).offset
static func cargo_offset() -> Vector2: return Catalog.cargo_drop().offset
static func has_cargo(e: Dictionary) -> bool:
	return Catalog.definition(int(e.kind)).get("role","")=="supply" and not e.get("rescued",false)
static func carrier(e: Dictionary, previous_y: float = NAN) -> void:
	var d: Dictionary = Catalog.definition(int(e.kind))
	if not d.has("open_at_y") or e.get("rescued",false): return
	var boundary: float = float(d.open_at_y)
	var y: float = e.pos.y
	var crossed: bool = not is_nan(previous_y) and (previous_y-boundary)*(y-boundary)<=0
	if is_equal_approx(y,boundary) or crossed:
		e.kind = int(d.open_kind)
static func score(kind: int, difficulty: int) -> int:
	var d: Dictionary = Catalog.definition(kind)
	return int(d.get("score",0))*(difficulty if d.get("score_scales_with_difficulty",true) else 1)
static func explosion_seconds(kind: int) -> float: return float(Catalog.definition(kind).get("explosion_seconds",0.6))
static func death_sound(kind: int) -> String: return Catalog.definition(kind).get("death_sound","bang-e")
static func drop(e: Dictionary, boss_rush: bool) -> Dictionary:
	var d: Dictionary = Catalog.definition(int(e.kind))
	var reward: Dictionary = d.get("drop",{})
	if boss_rush and d.has("boss_rush_drop"): reward = d.boss_rush_drop
	if reward.is_empty(): return {}
	var item := {"pos":e.pos+reward.offset,"kind":int(reward.item)}
	if reward.get("cargo_release",false):
		item.age = 0.0
		item.cargo_release = true
	return item
static func release_and_escape(e: Dictionary) -> bool:
	var action: Dictionary = Catalog.definition(int(e.kind)).get("on_defeat",{})
	if action.get("action","")!="release_and_escape": return false
	e.rescued = true
	e.kind = int(action.definition_id)
	e.hp = float(Catalog.definition(e.kind).hp)
	e.max_hp = e.hp
	e.pattern = int(action.pattern)
	return true
static func out_of_bounds(e: Dictionary) -> bool:
	return e.pos.x< -100 or e.pos.x>480 or e.pos.y< -100 or e.pos.y>580
