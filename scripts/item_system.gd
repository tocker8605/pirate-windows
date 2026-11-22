extends RefCounted
const Combat = preload("res://scripts/combat.gd")
enum Kind { POWER = 1, HEALTH = 2 }
const DEFINITIONS: Dictionary = {
	Kind.POWER: {"power":1,"energy":50.0,"score":200},
	Kind.HEALTH: {"health":30.0,"score":200},
}
const FALL_SPEED: float = 100.0
const REMOVE_Y: float = 520.0
static func apply_pickup(g: Node, kind: int) -> bool:
	var effect: Dictionary = DEFINITIONS.get(kind,{})
	if effect.is_empty(): return false
	if effect.has("power"): g.power = mini(7,g.power+int(effect.power))
	if effect.has("energy"): g.energy = minf(100,g.energy+float(effect.energy))
	if effect.has("health"): g.hp = minf(100,g.hp+float(effect.health))
	g.score += int(effect.score)
	return true
static func update_items(g: Node) -> void:
	for item in g.items:
		item.render_pos = item.pos
		item.age = item.get("age",0.0)+g.delta_seconds
		if item.get("born_frame",-1)!=g.frame: item.pos.y += FALL_SPEED*g.delta_seconds
		if g.hp>0 and Combat.collects_item(g.player,item.pos) and apply_pickup(g,int(item.kind)):
			g.items.remove(item.entity_id)
			g._sound("get")
		elif item.pos.y>=REMOVE_Y: g.items.remove(item.entity_id)
