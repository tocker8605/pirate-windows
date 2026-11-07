class_name PirateEnemyRules
extends RefCounted
const CARGO_LOCAL = Vector2(25,40)
static func cargo_position(e: Dictionary) -> Vector2:
	return e.pos+CARGO_LOCAL
static func has_cargo(e: Dictionary) -> bool:
	return int(e.kind) in [19,201] and not e.get("rescued",false)

const SCORE: Dictionary = {1:15,2:25,3:40,4:55,5:50,6:65,7:35,8:70,9:60,10:45,11:30,21:115,22:145,41:185,42:205}
const SMOKE: Dictionary = {1:3,2:4,3:7,4:9,5:9,6:13,7:5,8:15,9:12,10:5,11:5,21:40,22:50,41:90,42:100,101:80,102:80,111:80,112:80,113:120,121:160,122:160,123:80,124:80,131:240,132:240,133:200}
static func carrier(e: Dictionary, previous_y: float = NAN) -> void:
	if e.kind!=201 or e.get("rescued",false): return
	var y: float = e.pos.y
	var crossed: bool = not is_nan(previous_y) and (previous_y-291)*(y-291)<=0
	if is_equal_approx(y,291) or crossed: e.kind = 19
static func score(kind: int, difficulty: int) -> int:
	if kind>=100 and kind<200: return 350*difficulty
	if kind==19: return 500
	return int(SCORE.get(kind,0))*difficulty
static func explosion_ticks(kind: int) -> int:
	if kind>=100 and kind<200: return 30
	return 35 if kind>20 and kind<51 else 20
static func drop(e: Dictionary, boss_rush: bool) -> Dictionary:
	var kind: int = int(e.kind)
	if kind==19: return {"pos":cargo_position(e),"kind":1,"age":0.0,"cargo_release":true}
	if boss_rush and kind>=100 and kind<200: return {"pos":e.pos+Vector2(25,40),"kind":1}
	if kind==21: return {"pos":e.pos+Vector2(25,25),"kind":2}
	if kind in [41,42]: return {"pos":e.pos+Vector2(25,40),"kind":2}
	return {}
static func out_of_bounds(e: Dictionary) -> bool:
	return e.pos.x< -100 or e.pos.x>480 or e.pos.y< -100 or e.pos.y>580
