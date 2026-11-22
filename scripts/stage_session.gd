extends RefCounted
const Campaign = preload("res://scripts/campaign_rules.gd")
const StageEvents = preload("res://scripts/stage_events.gd")
const Stages=preload("res://scripts/stage_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Resources=preload("res://scripts/stage_resources.gd")
static func load_stage(g: Node, number: int, preserve_run: bool = false) -> void:
	var saved_hp: float = g.hp
	var saved_power: int = g.power
	var saved_score: int = g.score
	g.stage = clampi(number,1,Campaign.stage_count(g.run_settings.boss_rush))
	g.events = StageEvents.load_stage(g.stage,g.run_settings.boss_rush)
	g.checkpoint_stage = g.stage
	g.checkpoint_settings = g.run_settings
	g.death_remaining_seconds = 0
	g.boss_death_remaining_seconds = 0
	g.boss_defeated = false
	g.hit_flash_remaining_seconds = 0
	g.hit_flash_render_seconds = 0
	g.player = Vector2(Pilot.centred_x(),300)
	g.slow_movement_active = false
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
	var initial: Dictionary=Stages.initial(g.stage,g.run_settings.boss_rush)
	g.background_y = initial.background_y
	g.scroll_speed = initial.scroll_speed
	g.scroll_target = initial.scroll_target
	g.map_mode = int(initial.map_mode)
	g.banner = ""
	g.banner_remaining_seconds = 0
	g.enemies.clear()
	g.shots.clear()
	g.bullets.clear()
	g.items.clear()
	g.explosions.clear()
	g.ground_wrecks.clear()
	g.enemy_beams.clear()
	g.boss.clear()
	g.accumulator = 0
	g.stats = {"spawned":0,"killed":0,"shots":0,"hits":0,"boss_spawned":false,"supply_spawned":0}
	if preserve_run:
		g.hp = saved_hp
		g.power = saved_power
		g.score = saved_score
	g.supply_director.plan(g.stage,g.power,g.events,g.run_settings.boss_rush)
	Resources.prepare(g)
	g.flow.play_stage(g)
	g.presentation.reset(g)
	g.view.vfx.reset()
	g.view.renewal.reset_motion()
	g._redraw()
