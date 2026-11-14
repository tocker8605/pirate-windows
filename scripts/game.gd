extends Node2D
## Fixed60Hz orchestration. Gameplay time is seconds and velocity is pixels/second.
const Art = preload("res://scripts/art.gd")
const Movement = preload("res://scripts/movement.gd")
const EnemyFire = preload("res://scripts/enemy_fire.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const HUD = preload("res://scripts/hud.gd")
const Effects = preload("res://scripts/special_effects.gd")
const OrbMotion = preload("res://scripts/boss_orb_motion.gd")
const CoreMotion = preload("res://scripts/boss_core_motion.gd")
const Boss = preload("res://scripts/boss.gd")
const Title = preload("res://scripts/title.gd")
const Combat = preload("res://scripts/combat.gd")
const PilotGeometry = preload("res://scripts/pilot_geometry.gd")
const Clock = preload("res://scripts/timing.gd")
const EnemyRules = preload("res://scripts/enemy_rules.gd")
const WorldEffects = preload("res://scripts/world_effects.gd")
const Audio = preload("res://scripts/audio.gd")
const Renderer = preload("res://scripts/renderer.gd")
const Capture = preload("res://scripts/preview.gd")
const Lifecycle = preload("res://scripts/lifecycle.gd")
const StageEvents = preload("res://scripts/stage_events.gd")
const BulletPool = preload("res://scripts/bullet_pool.gd")
const Entities = preload("res://scripts/entity_store.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Regions = preload("res://scripts/background_regions.gd")
const Presentation = preload("res://scripts/presentation.gd")
const StageSession = preload("res://scripts/stage_session.gd")
const PlayerProjectiles = preload("res://scripts/player_projectiles.gd")
const CombatActions = preload("res://scripts/combat_actions.gd")
const ItemSystem = preload("res://scripts/item_system.gd")
const SupplyDirector = preload("res://scripts/supply_director.gd")
var supply_director = SupplyDirector.new()
var presentation = Presentation.new()
var art = Art.new()
var title = Title.new()
var clock = Clock.new()
var audio: Node
var shot_visuals: Array = []
var invulnerability_render_seconds: float = 0
var render_hp: float = 100
var view: Node2D
var hit_flash_render_seconds: float = 0
var last_score: int = 0
var death_remaining_seconds: float = 0
var boss_death_remaining_seconds: float = 0
var hit_flash_remaining_seconds: float = 0
var loading_image: String = "loading2"
var loading_target: int = 1
var loading_preserve: bool = false
var loading_remaining_seconds: float = 0
var debug_enabled: bool = false
var boss_defeated: bool = false
var title_repeat: float = 0
var clouds: Array = Scenery.initial_clouds()
var boss_rush: bool = false
var checkpoint_stage: int = 0
var checkpoint_rush: bool = false
var music: AudioStreamPlayer
var music_track: String = ""
var events: Array = []
var event_cursor: int = 0
var paused_state: String = "playing"
var state: String = "menu"
var stage: int = 1
var selected_stage: int = 1
var preview_stage: int = 1
var weapon: int = 1
var player: Vector2 = Vector2(170, 380)
var player_bank: int = 0
var hp: float = 100
var energy: float = 100
var power: int = 1
var score: int = 0
var frame: int = 0
var stage_elapsed_seconds: float = 0
var delta_seconds: float = Clock.FIXED_STEP_SECONDS
var accumulator: float = 0
var animation: int = 0
var invulnerability_seconds: float = 0
var fire_cooldown_seconds: float = 0
var beam_remaining_seconds: float = 0
var shield_remaining_seconds: float = 0
var shield_center: Vector2 = Vector2.ZERO
var beam_render_seconds: float = 0
var shield_render_seconds: float = 0
var laser_contacts: Array = []
var shield_contacts: Array = []
var renewed_art: bool = true
var scenery_distance: float = 0.0
var background_y: float = 3360
var scroll_speed: float = 20
var scroll_target: float = 2
var map_mode: int = 1
var banner: String = ""
var banner_remaining_seconds: float = 0
var enemies = Entities.new()
var shots = Entities.new()
var bullets = Entities.new()
var items = Entities.new()
var explosions: Array = []
var boss: Dictionary = {}
var mute: bool = false
var automatic: bool = true
var preview_path: String = ""
var preview_mode: String = "stage"
var font: Font = ThemeDB.fallback_font
var stats: Dictionary = {"spawned":0,"killed":0,"shots":0,"hits":0,"boss_spawned":false,"supply_spawned":0}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_tree().auto_accept_quit = false
	Engine.max_fps = 60
	view = Renderer.new()
	view.g = self
	add_child(view)
	audio = Audio.new()
	add_child(audio)
	music = audio.music
	events = StageEvents.load_stage(1)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="): preview_path = arg.trim_prefix("--preview=")
		if arg.begins_with("--preview-mode="): preview_mode = arg.trim_prefix("--preview-mode=")
		if arg.begins_with("--preview-stage="): preview_stage = clampi(int(arg.trim_prefix("--preview-stage=")),1,4)
	if not preview_path.is_empty(): await Capture.run(self)

func start_game() -> void:
	_load_stage(selected_stage)

func _load_stage(number: int, preserve_run: bool = false) -> void:
	StageSession.load_stage(self, number, preserve_run)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.keycode
	if key==KEY_F11:
		var full: bool = DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif key==KEY_M:
		mute = not mute
	elif state=="menu":
		if key==KEY_ESCAPE: _quit()
		elif key in [KEY_SPACE,KEY_ENTER]:
			_title_accept()
		else: title.navigate(key)
	elif key==KEY_ESCAPE:
		_return_title()
	elif key==KEY_R and event.ctrl_pressed:
		start_game()
	elif key==KEY_P and state in ["playing","dying","boss_dying","paused"]:
		if state=="paused": state = paused_state
		else:
			paused_state = state
			state = "paused"
	elif state in ["dead","clear"] and key in [KEY_SPACE,KEY_ENTER]:
		if state=="clear" and stage<4: _load_stage(stage+1,true)
		else: start_game()
	_sync_audio()
	_redraw()

func _return_title() -> void:
	last_score = score
	state = "menu"
	title.reset()
	_stop_music()
	_save_score()

func _sync_audio() -> void:
	if audio!=null: audio.sync(mute,state=="paused")

func _play_music(track: String) -> void:
	if audio==null: return
	music_track = track
	audio.play(track)
	_sync_audio()

func _stop_music() -> void:
	music_track = ""
	if audio!=null: audio.stop()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: _quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state in ["playing","dying","boss_dying"] and automatic:
		paused_state = state
		state = "paused"
		_sync_audio()
		_redraw()

func _process(delta: float) -> void:
	if not automatic: return
	_sync_audio()
	var step: float = Clock.MENU_STEP_SECONDS if state=="menu" else Clock.FIXED_STEP_SECONDS
	if state=="menu":
		title_repeat += delta
		if title_repeat>=0.12:
			title_repeat = 0
			for code in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
				if Input.is_physical_key_pressed(code): title.navigate(code)
		accumulator += minf(delta,0.15)
		while accumulator>=step:
			accumulator -= step
			if Input.is_physical_key_pressed(KEY_SPACE): _title_accept()
			title.tick()
			if state!="menu":
				_redraw()
				return
	if state=="menu":
		_redraw()
		return
	# A menu-to-game transition already consumed this frame's elapsed time.
	if state in ["playing","dying","boss_dying","loading"]:
		accumulator += minf(delta, 0.15)
		while accumulator+0.000000001 >= step:
			accumulator = maxf(0,accumulator-step)
			var direction := Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
			_tick(direction, Input.is_physical_key_pressed(KEY_Z), Input.is_physical_key_pressed(KEY_X), Input.is_physical_key_pressed(KEY_C),Clock.FIXED_STEP_SECONDS)
			if state=="loading" or state not in ["playing","dying","boss_dying"]: break
	_redraw()

func _tick(direction: Vector2, firing: bool, use_laser: bool, use_shield: bool, seconds: float = Clock.FIXED_STEP_SECONDS) -> void:
	delta_seconds = seconds
	if state=="loading":
		if loading_remaining_seconds>0:
			loading_remaining_seconds = Clock.countdown(loading_remaining_seconds,seconds)
			return
		_load_stage(loading_target,loading_preserve)
		return
	if state not in ["playing","dying","boss_dying"]: return
	presentation.capture(self)
	frame += 1
	stage_elapsed_seconds += delta_seconds
	var due: Dictionary = clock.begin()
	animation = clock.animation-1
	var alive: bool = death_remaining_seconds==0
	if automatic and alive:
		var held: Array = []
		for code in [KEY_C,KEY_R,KEY_U,KEY_F6,KEY_F7,KEY_F8]:
			if Input.is_physical_key_pressed(code): held.append(code)
		if _debug_controls(held): return
	if alive:
		player += direction*200.0*seconds
		player_bank = 1 if direction.x<0 else (2 if direction.x>0 else 0)
		if automatic and Input.is_physical_key_pressed(KEY_RIGHT): player_bank = 2
	player.x = PilotGeometry.clamp_horizontal(player.x)
	player.y = clampf(player.y,0,430)
	hp = minf(100,hp)
	energy = clampf(energy,0,100)
	power = mini(7,power)
	invulnerability_render_seconds = invulnerability_seconds
	invulnerability_seconds = Clock.countdown(invulnerability_seconds,seconds)
	banner_remaining_seconds = Clock.countdown(banner_remaining_seconds,seconds)
	hit_flash_render_seconds = hit_flash_remaining_seconds
	hit_flash_remaining_seconds = Clock.countdown(hit_flash_remaining_seconds,seconds)
	while firing and alive and fire_cooldown_seconds<=0.000001:
		var before: float = fire_cooldown_seconds
		_fire()
		if fire_cooldown_seconds<=before: break
	if fire_cooldown_seconds>0: fire_cooldown_seconds -= seconds
	if use_laser and alive and beam_remaining_seconds<=0.000001 and energy>7:
		energy -= 8
		beam_remaining_seconds += 0.45
		_sound("pil")
	if use_shield and alive and shield_remaining_seconds<=0.000001 and energy>39:
		energy -= 40
		shield_remaining_seconds += 6.0
		shield_center = player+Vector2(25,25)
		_sound("shi")
	render_hp = hp
	_read_events()
	supply_director.advance(self)
	if due.move:
		for e in enemies: Movement.steer(e,player,boss.get("pos",Vector2(200,-100)))
		_boss_steer()
	for e in enemies:
		if OrbMotion.active(e): OrbMotion.prepare(e,boss)
	if boss_death_remaining_seconds==0:
		BulletPool.body(self,delta_seconds)
		for e in enemies: _enemy_fire(e,delta_seconds)
	_update_scenery()
	for blast in explosions:
		if blast.get("pending_sound",false):
			_sound("bang-e")
			blast.pending_sound = false
	WorldEffects.advance(explosions,scroll_speed,seconds)
	explosions = explosions.filter(func(blast): return blast.remaining_seconds>=0)
	_update_boss()
	for e in enemies:
		var previous_y: float = e.pos.y
		if CoreMotion.active(e): CoreMotion.advance(e,seconds)
		elif OrbMotion.active(e): OrbMotion.advance(e,seconds)
		else: e.pos += Movement.displacement(e.velocity,seconds)
		Boss.attach(e,boss)
		e.render_kind = e.kind
		e.render_hp = e.hp
		EnemyRules.carrier(e,previous_y)
		if e.hp<=0: _destroy_enemy(e)
	# Removal unlinks the current entry in O(1); iteration preserves spawn order.
	for e in enemies:
		if e.hp<=0 or EnemyRules.out_of_bounds(e):
			view.renewal.forget(e.entity_id)
			enemies.remove(e.entity_id)
	_advance_shots()
	beam_render_seconds = beam_remaining_seconds
	shield_render_seconds = shield_remaining_seconds
	laser_contacts.clear()
	shield_contacts.clear()
	if shield_remaining_seconds>0:
		shield_center.y -= 33.333333333333336*seconds
		shield_remaining_seconds = Clock.countdown(shield_remaining_seconds,seconds)
	_apply_beam()
	_update_lifecycle()
	if state in ["menu","loading"]:
		if clock.recover(death_remaining_seconds==0,seconds) and not firing: energy = minf(100,energy+1)
		return
	_resolve_shots()
	_update_items()
	_update_bullets()
	_resolve_body_contacts()
	if clock.finish(death_remaining_seconds==0,seconds) and not firing: energy = minf(100,energy+1)
	if view!=null:
		view.vfx.observe(self)
		view.renewal.observe(self)

func _update_scenery() -> void:
	scenery_distance += scroll_speed*delta_seconds
	background_y -= scroll_speed*delta_seconds
	background_y = Regions.wrap(background_y,map_mode)
	if scroll_speed>scroll_target: scroll_speed = move_toward(scroll_speed,scroll_target,222.222222222222*delta_seconds)
	if scroll_speed<scroll_target: scroll_speed = move_toward(scroll_speed,scroll_target,222.222222222222*delta_seconds)
	Scenery.advance_clouds(clouds,scroll_speed,delta_seconds)

func _apply_beam() -> void:
	CombatActions.apply_beam(self)

func _update_lifecycle() -> void:
	Lifecycle.update(self)

func _complete_stage() -> void:
	Lifecycle.complete_stage(self)

func timeline() -> float:
	return stage_elapsed_seconds

func _read_events() -> void:
	StageEvents.consume(self)

func _fire() -> void:
	PlayerProjectiles.fire(self)

func _update_shots() -> void:
	_advance_shots()
	_resolve_shots()

func _advance_shots() -> void:
	PlayerProjectiles.advance_shots(self)

func _resolve_shots() -> void:
	CombatActions.resolve_shots(self)

func _bullet(pos: Vector2, velocity: Vector2, kind: int = 1) -> void:
	BulletPool.single(self,pos,velocity,kind)

func _enemy_fire(e: Dictionary, seconds: float) -> void:
	BulletPool.enemy(self,e,seconds)

func _boss_steer() -> void:
	if not boss.is_empty(): Boss.steer(boss,player,enemies)

func _update_boss() -> void:
	if boss.is_empty(): return
	boss.age += delta_seconds
	boss.pos += Movement.displacement(boss.velocity,delta_seconds)

func _damage_boss(amount: float) -> void:
	CombatActions.damage_boss(self, amount)

func _finish_stage() -> void:
	Lifecycle.begin_boss_death(self)

func _update_bullets() -> void:
	CombatActions.update_bullets(self)

func _hurt_player(damage: float) -> void:
	CombatActions.hurt_player(self, damage)

func _resolve_body_contacts() -> void:
	CombatActions.resolve_body_contacts(self)

func _destroy_enemy(e: Dictionary) -> void:
	var kind: int = int(e.kind)
	_sound(EnemyRules.death_sound(kind))
	score += EnemyRules.score(kind,title.difficulty)
	var item: Dictionary = EnemyRules.drop(e,boss_rush)
	if not item.is_empty(): _drop_item(item)
	if EnemyRules.release_and_escape(e): return
	_explosion(e.pos,EnemyRules.explosion_seconds(kind))
	explosions[-1].owner_id = e.get("entity_id",-1)
	stats.killed += 1

func _drop_item(item: Dictionary) -> void:
	item.born_frame = frame
	items.append(item)

func _update_items() -> void:
	ItemSystem.update_items(self)

func _explosion(pos: Vector2, duration_seconds: float = 0.6, pending_sound: bool = false) -> void:
	explosions.append({"pos":pos,"remaining_seconds":duration_seconds,"render_remaining_seconds":0,"render_pos":pos,"pending_sound":pending_sound,"delay_seconds":0.03 if pending_sound else 0})

func _sound(id: String) -> void:
	if audio!=null: audio.sound(id,mute)

func _save_score() -> void:
	last_score = score

func _exit_tree() -> void:
	_stop_music()

func _redraw() -> void:
	if view!=null: view.refresh()

func _title_accept() -> void:
	var action: String = title.confirm()
	if action=="opening": _play_music("title")
	elif action=="play":
		boss_rush = title.boss_rush
		weapon = title.phase-22
		selected_stage = 1
		_begin_run()
	elif action=="continue" and checkpoint_stage>0:
		boss_rush = checkpoint_rush
		selected_stage = checkpoint_stage
		_begin_run()

func _debug_controls(held: Array) -> bool:
	if KEY_C in held and KEY_R in held and KEY_U in held: debug_enabled = true
	if not debug_enabled or death_remaining_seconds>0: return false
	if KEY_F6 in held: hp = 100
	if KEY_F8 in held: power = mini(7,power+1)
	if KEY_F7 in held:
		_complete_stage()
		return true
	return false

func _quit() -> void:
	if audio!=null: audio.stop_all()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _begin_run() -> void:
	_stop_music()
	loading_target = selected_stage
	loading_preserve = false
	loading_remaining_seconds = 0.03
	loading_image = "loading1"
	state = "loading"
