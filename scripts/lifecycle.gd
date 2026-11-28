extends RefCounted
const Campaign = preload("res://scripts/campaign_rules.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const VisualRandom = preload("res://scripts/visual_random.gd")
## Boss/player destruction lasts7.2seconds; stage transitions preserve run state.
static func update(g: Node) -> void:
	if not g.boss.is_empty() and g.boss.hp<=0 and not g.boss_defeated: g._finish_stage()
	if g.hp<=0 and g.death_remaining_seconds==0:
		g.hp = 0
		g.death_remaining_seconds = 7.2
		g.flow.player_died(g)
	if g.boss_death_remaining_seconds>0:
		var previous: float = g.boss_death_remaining_seconds
		g.boss_death_remaining_seconds = maxf(0,g.boss_death_remaining_seconds-g.delta_seconds)
		if g.boss_death_remaining_seconds<0.000001: g.boss_death_remaining_seconds = 0
		for e in g.enemies:
			# A part already killed by a shot/beam still earns its normal reward.
			if e.hp>0 and Catalog.is_part(int(e.kind)): e.auto_destroyed = true
			e.hp = 0
		g.bullets.clear()
		g.items.clear()
		if int(ceil(previous/0.3))!=int(ceil(g.boss_death_remaining_seconds/0.3)):
			var center: Vector2=Rules.destruction_center(g.boss)
			var scatter:=Vector2(29.5-VisualRandom.legacy_event().between(0,59),0)
			g._explosion(center+scatter-Vector2(25,25),0.6,true)
		if g.boss_death_remaining_seconds==0 and g.death_remaining_seconds==0:
			g._complete_stage()
			return
	if g.death_remaining_seconds>0:
		var previous: float = g.death_remaining_seconds
		g.death_remaining_seconds = maxf(0,g.death_remaining_seconds-g.delta_seconds)
		if g.death_remaining_seconds<0.000001: g.death_remaining_seconds = 0
		if g.death_remaining_seconds>0 and int(ceil(previous/0.3))!=int(ceil(g.death_remaining_seconds/0.3)):
			g._explosion(g.player+Vector2(20-VisualRandom.legacy_event().between(0,39),-10),0.6,true)
		if g.death_remaining_seconds==0:
			g._finish_run()

static func begin_boss_death(g: Node) -> void:
	if g.boss_defeated: return
	g.boss_defeated = true
	for pos in g.boss_timeout.defeat():g._explosion(pos,0.6,true)
	g.enemy_beams.clear()
	g.score += Rules.score(int(Catalog.for_actor(g.boss).id),g.run_settings.difficulty)
	g._remember_score()
	g.boss_death_remaining_seconds = 7.2
	g.scroll_target = float(Catalog.for_actor(g.boss).get("boss_scroll",{}).get("defeat_speed",g.scroll_target))
	g.flow.boss_died(g)

static func complete_stage(g: Node) -> void:
	VisualRandom.reserve_transition_history()
	if g.stage<Campaign.stage_count(g.run_settings.boss_rush):
		g._remember_score()
		g.flow.load_stage(g,g.stage+1,true,"loading")
	else:
		g._finish_run(true)
