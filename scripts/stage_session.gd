extends RefCounted
const StageEvents = preload("res://scripts/stage_events.gd")
static func load_stage(g: Node, number: int, preserve_run: bool = false) -> void:
	var saved_hp: float = g.hp
	var saved_power: int = g.power
	var saved_score: int = g.score
	g.stage = clampi(number,1,4)
	g.events = StageEvents.load_stage(g.stage,g.boss_rush)
	g.checkpoint_stage = g.stage
	g.checkpoint_rush = g.boss_rush
	g.death_remaining_seconds = 0
	g.boss_death_remaining_seconds = 0
	g.boss_defeated = false
	g.hit_flash_remaining_seconds = 0
	g.hit_flash_render_seconds = 0
	g.state = "playing"
	g.player = Vector2(170, 300)
	g.hp = 100
	g.energy = 100
	g.power = 1
	g.score = 0
	g.frame = 0
	g.stage_elapsed_seconds = 0
	g.delta_seconds = 1.0/60.0
	g.event_cursor = 0
	g.invulnerability_seconds = 0
	g.invulnerability_render_seconds = 0
	g.render_hp = g.hp
	g.shot_visuals.clear()
	g.beam_remaining_seconds = 0
	g.shield_remaining_seconds = 0
	g.beam_render_seconds = 0
	g.shield_render_seconds = 0
	g.laser_contacts.clear()
	g.shield_contacts.clear()
	g.scenery_distance = 0.0
	g.background_y = 3360
	g.scroll_speed = 666.6666666666667
	g.scroll_target = 66.66666666666667
	g.map_mode = 1
	# frmtmrs.fload Case 4 overrides the normal takeoff; Case 14 does not.
	if g.stage==4 and not g.boss_rush:
		g.map_mode = 2
		g.scroll_speed = 66.66666666666667
	g.banner = ""
	g.banner_remaining_seconds = 0
	g.enemies.clear()
	g.shots.clear()
	g.bullets.clear()
	g.items.clear()
	g.explosions.clear()
	g.boss.clear()
	g.accumulator = 0
	g.stats = {"spawned":0,"killed":0,"shots":0,"hits":0,"boss_spawned":false}
	if g.boss_rush: g._stop_music()
	else: g._play_music("bgm%02d"%g.stage)
	if preserve_run:
		g.hp = saved_hp
		g.power = saved_power
		g.score = saved_score
	g.presentation.reset(g)
	g.view.vfx.reset()
	g.view.renewal.reset_motion()
	g._redraw()
