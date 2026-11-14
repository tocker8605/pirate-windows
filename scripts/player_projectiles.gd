extends RefCounted
const Weapons = preload("res://scripts/player_weapons.gd")
const Clock = preload("res://scripts/timing.gd")
static func fire(g: Node) -> void:
	if g.shots.size()+Weapons.volley_count(g.power)>Weapons.active_limit(): return
	var volley: Array = Weapons.volley(g.player,g.weapon,g.power)
	for shot in volley:
		g.shots.append(shot)
		g.stats.shots += 1
	g.fire_cooldown_seconds += Weapons.cadence_seconds(g.power)

static func advance_shots(g: Node) -> void:
	g.shot_visuals.clear()
	for shot in g.shots:
		if float(shot.get("impact_remaining_seconds",-1))>=0:
			if shot.impact_remaining_seconds<=0.000001:
				shot.alive = false
				continue
			shot.pos.y -= 66.66666666666667*g.delta_seconds
			shot.visual = Weapons.visual(shot,g.player)
			shot.impact_remaining_seconds = Clock.countdown(shot.impact_remaining_seconds,g.delta_seconds)
			g.shot_visuals.append(shot.duplicate(true))
		else:
			Weapons.advance(shot,g.player,g.delta_seconds)
			shot.visual = Weapons.visual(shot,g.player)
			g.shot_visuals.append(shot.duplicate(true))
	for shot in g.shots:
		if not shot.alive or shot.pos.y<0 or shot.pos.x<0 or shot.pos.x>400: g.shots.remove(shot.entity_id)
