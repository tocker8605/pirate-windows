extends RefCounted
const Combat = preload("res://scripts/combat.gd")
static func update_items(g: Node) -> void:
	for item in g.items:
		item.render_pos = item.pos
		item.age = item.get("age",0.0)+g.delta_seconds
		if item.get("born_frame",-1)!=g.frame: item.pos.y += 100.0*g.delta_seconds
		if g.hp>0 and Combat.collects_item(g.player,item.pos):
			if item.kind == 1:
				g.power = mini(7,g.power+1)
				g.energy = 100
			else: g.hp = minf(100,g.hp+25)
			g.score += 1000
			item.pos.y = 600
			g._sound("get")
	for item in g.items:
		if item.pos.y>=520: g.items.remove(item.entity_id)
