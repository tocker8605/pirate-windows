extends RefCounted
const Combat = preload("res://scripts/combat.gd")
const POWER_ENERGY_RECOVERY: float = 50.0
const HEALTH_RECOVERY: float = 30.0
static func update_items(g: Node) -> void:
	for item in g.items:
		item.render_pos = item.pos
		item.age = item.get("age",0.0)+g.delta_seconds
		if item.get("born_frame",-1)!=g.frame: item.pos.y += 100.0*g.delta_seconds
		if g.hp>0 and Combat.collects_item(g.player,item.pos):
			if item.kind == 1:
				g.power = mini(7,g.power+1)
				g.energy = minf(100,g.energy+POWER_ENERGY_RECOVERY)
			else: g.hp = minf(100,g.hp+HEALTH_RECOVERY)
			g.score += 200
			item.pos.y = 600
			g._sound("get")
	for item in g.items:
		if item.pos.y>=520: g.items.remove(item.entity_id)
