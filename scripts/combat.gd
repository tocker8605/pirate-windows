class_name PirateCombat
extends RefCounted
## Exact point tests in weaponhit/pil. Visible artwork is not a collision rectangle.
const DAMAGE: Array = [0,3,10,4,6,5,6,7,4]
static func between(value: float, low: float, high: float) -> bool: return value>low and value<high
static func shot_hits(pos: Vector2, e: Dictionary) -> bool:
	var kind: int = int(e.kind)
	if kind<=0 or kind>=200 or not between(pos.y,e.pos.y-25,e.pos.y+30): return false
	var half: Vector2 = Vector2(15,35)
	if kind>20 and kind<41: half = Vector2(40,60)
	elif kind>40 and kind<101: half = Vector2(65,85)
	return between(pos.x,e.pos.x-half.x,e.pos.x+half.y)
static func shot_hits_boss(pos: Vector2, boss: Dictionary) -> bool:
	return not boss.is_empty() and between(pos.x,boss.pos.x-90,boss.pos.x+60) and between(pos.y,boss.pos.y-25,boss.pos.y+60)
static func beam_hits(player: Vector2, e: Dictionary) -> bool:
	var kind: int = int(e.kind)
	if e.pos.y>=player.y or kind<=0 or kind>=200: return false
	var width: float = 15
	if kind>20 and kind<41: width = 35
	elif kind>40 and kind<101: width = 55
	return between(e.pos.x,player.x-width,player.x+width)
static func beam_hits_boss(player: Vector2, boss: Dictionary) -> bool:
	return not boss.is_empty() and boss.pos.y<player.y and between(boss.pos.x,player.x-25,player.x+75)
static func hurts_player(player: Vector2, point: Vector2) -> bool:
	return between(point.x,player.x+13,player.x+36) and between(point.y,player.y+12,player.y+37)
static func collects_item(player: Vector2, point: Vector2) -> bool:
	return between(point.x,player.x-5,player.x+55) and between(point.y,player.y-5,player.y+55)
