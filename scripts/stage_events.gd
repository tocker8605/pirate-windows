extends RefCounted
## Original timeline and reader budget; every actor gets its own dynamic ID.
static func consume(g: Node) -> void:
	# Each event time unit was 30 original ticks (0.75 seconds).
	var actor_events: int = 0
	while actor_events<5 and g.event_cursor < g.events.size() and float(g.events[g.event_cursor][0]) * 30 < g.frame:
		var row: Array = g.events[g.event_cursor]
		g.event_cursor += 1
		var kind: int = int(row[1])
		match kind:
			61:
				g.banner = "WARNING / BOSS APPROACHING"
				g.banner_ticks = 80
			62:
				g.banner = "MISSION %02d / TAKE OFF"%g.stage
				g.banner_ticks = 80
			71:
				g.map_mode = int(row[2])
				g.scroll_target = float(row[3])
			91,92,93,94:
				var maximum: float = 1500.0 if kind==94 else 1000.0
				g.boss = {"stage":kind-90,"pos":Vector2(row[2],row[3]),"velocity":Vector2.ZERO,"hp":maximum,"max_hp":maximum,"age":0}
				g.stats.boss_spawned = true
				g._play_music("boss01")
				g.banner = ""
				g.banner_ticks = 0
			_:
				if kind > 0:
					actor_events += 1
					g.enemies.append({"kind":kind,"pos":Vector2(row[2],row[3]),"velocity":Vector2.ZERO,"pattern":int(row[4]),"hp":float(row[5])})
					g.stats.spawned += 1
