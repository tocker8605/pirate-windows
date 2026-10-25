extends Node2D
## Orchestrates original-tick gameplay rules; rendering, audio and combat are separate modules.
const Art = preload("res://scripts/art.gd")
const Movement = preload("res://scripts/movement.gd")
const EnemyFire = preload("res://scripts/enemy_fire.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const HUD = preload("res://scripts/hud.gd")
const Effects = preload("res://scripts/special_effects.gd")
const Boss = preload("res://scripts/boss.gd")
const Title = preload("res://scripts/title.gd")
const Combat = preload("res://scripts/combat.gd")
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
var art = Art.new()
var title = Title.new()
var clock = Clock.new()
var audio: Node
var shot_visuals: Array = []
var invulnerable_render_ticks: int = 0
var render_hp: float = 100
var view: Node2D
var hit_flash_render_ticks: int = 0
var last_score: int = 0
var death_ticks: int = 0
var boss_death_ticks: int = 0
var hit_flash_ticks: int = 0
var shot_cursor: int = 0
var loading_image: String = "loading2"
var loading_target: int = 1
var loading_preserve: bool = false
var loading_ticks: int = 0
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
var transition_ticks: int = 0
var preview_stage: int = 1
var weapon: int = 1
var player: Vector2 = Vector2(170, 380)
var player_bank: int = 0
var hp: float = 100
var energy: float = 100
var power: int = 1
var score: int = 0
var frame: int = 0
var accumulator: float = 0
var animation: int = 0
var invulnerable: int = 0
var fire_cooldown: int = 0
var laser: int = 0
var shield: int = 0
var shield_center: Vector2 = Vector2.ZERO
var laser_render_ticks: int = 0
var shield_render_ticks: int = 0
var laser_contacts: Array = []
var shield_contacts: Array = []
var renewed_art: bool = true
var scenery_distance: float = 0.0
var background_y: float = 3360
var scroll_speed: float = 20
var scroll_target: float = 2
var map_mode: int = 1
var banner: String = ""
var banner_ticks: int = 0
var enemies = Entities.new()
var shots: Array = []
var bullets = Entities.new()
var items = Entities.new()
var explosions: Array = []
var boss: Dictionary = {}
var mute: bool = false
var automatic: bool = true
var preview_path: String = ""
var preview_mode: String = "stage"
var font: Font = ThemeDB.fallback_font
var stats: Dictionary = {"spawned":0,"killed":0,"shots":0,"hits":0,"boss_spawned":false}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_tree().auto_accept_quit = false
	view = Renderer.new()
	view.g = self
	add_child(view)
	audio = Audio.new()
	add_child(audio)
	music = audio.music
	events = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage01.json"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="): preview_path = arg.trim_prefix("--preview=")
		if arg.begins_with("--preview-mode="): preview_mode = arg.trim_prefix("--preview-mode=")
		if arg.begins_with("--preview-stage="): preview_stage = clampi(int(arg.trim_prefix("--preview-stage=")),1,4)
	if not preview_path.is_empty(): await Capture.run(self)

func start_game() -> void:
	_load_stage(selected_stage)

func _load_stage(number: int, preserve_run: bool = false) -> void:
	var saved_hp: float = hp
	var saved_power: int = power
	var saved_score: int = score
	stage = clampi(number,1,4)
	events = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage%02d.json"%(stage+10 if boss_rush else stage)))
	checkpoint_stage = stage
	checkpoint_rush = boss_rush
	transition_ticks = 0
	death_ticks = 0
	boss_death_ticks = 0
	boss_defeated = false
	hit_flash_ticks = 0
	hit_flash_render_ticks = 0
	state = "playing"
	player = Vector2(170, 300)
	hp = 100
	energy = 100
	power = 1
	score = 0
	frame = 0
	event_cursor = 0
	invulnerable = 0
	invulnerable_render_ticks = 0
	render_hp = hp
	shot_visuals.clear()
	laser = 0
	shield = 0
	laser_render_ticks = 0
	shield_render_ticks = 0
	laser_contacts.clear()
	shield_contacts.clear()
	scenery_distance = 0.0
	background_y = 3360
	scroll_speed = 20
	scroll_target = 2
	map_mode = 1
	# frmtmrs.fload Case 4 overrides the normal takeoff; Case 14 does not.
	if stage==4 and not boss_rush:
		map_mode = 2
		scroll_speed = 2
	banner = ""
	banner_ticks = 0
	enemies.clear()
	shots.clear()
	bullets.clear()
	items.clear()
	explosions.clear()
	boss.clear()
	accumulator = 0
	stats = {"spawned":0,"killed":0,"shots":0,"hits":0,"boss_spawned":false}
	if boss_rush: _stop_music()
	else: _play_music("bgm%02d"%stage)
	if preserve_run:
		hp = saved_hp
		power = saved_power
		score = saved_score
	view.vfx.reset()
	view.renewal.reset_motion()
	_redraw()

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
	var step: float = Clock.interval(title.speed,state!="menu")
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
		while accumulator >= step:
			accumulator -= step
			var direction := Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
			_tick(direction, Input.is_physical_key_pressed(KEY_Z), Input.is_physical_key_pressed(KEY_X), Input.is_physical_key_pressed(KEY_C))
			if state=="loading" or state not in ["playing","dying","boss_dying"]: break
	_redraw()

func _tick(direction: Vector2, firing: bool, use_laser: bool, use_shield: bool) -> void:
	if state=="loading":
		if loading_ticks>0:
			loading_ticks -= 1
			return
		_load_stage(loading_target,loading_preserve)
		return
	if state not in ["playing","dying","boss_dying"]: return
	frame += 1
	var due: Dictionary = clock.begin()
	animation = clock.animation-1
	var alive: bool = death_ticks==0
	if automatic and alive:
		var held: Array = []
		for code in [KEY_C,KEY_R,KEY_U,KEY_F6,KEY_F7,KEY_F8]:
			if Input.is_physical_key_pressed(code): held.append(code)
		if _debug_controls(held): return
	if alive:
		player += direction*6
		player_bank = 1 if direction.x<0 else (2 if direction.x>0 else 0)
		if automatic and Input.is_physical_key_pressed(KEY_RIGHT): player_bank = 2
	player.x = clampf(player.x,10,340)
	player.y = clampf(player.y,0,430)
	hp = minf(100,hp)
	energy = clampf(energy,0,100)
	power = mini(7,power)
	invulnerable_render_ticks = invulnerable
	invulnerable = maxi(0,invulnerable-1)
	banner_ticks = maxi(0,banner_ticks-1)
	hit_flash_render_ticks = hit_flash_ticks
	hit_flash_ticks = maxi(0,hit_flash_ticks-1)
	if firing and alive and fire_cooldown==0 and energy>1: _fire()
	fire_cooldown = maxi(0,fire_cooldown-1)
	if use_laser and alive and laser==0 and energy>7:
		energy -= 8
		laser = 15
		_sound("pil")
	if use_shield and alive and shield==0 and energy>39:
		energy -= 40
		shield = 200
		shield_center = player+Vector2(25,25)
		_sound("shi")
	render_hp = hp
	_read_events()
	if due.move:
		for e in enemies: Movement.steer(e,player,boss.get("pos",Vector2(200,-100)))
		_boss_steer()
	if due.fire and boss_death_ticks==0:
		BulletPool.body(self)
		for e in enemies: _enemy_fire(e)
	_update_scenery()
	for blast in explosions:
		if blast.get("pending_sound",false):
			_sound("bang-e")
			blast.pending_sound = false
	WorldEffects.advance(explosions,scroll_speed)
	explosions = explosions.filter(func(blast): return blast.ticks>=0)
	_update_boss()
	for e in enemies:
		e.pos += e.velocity
		Boss.attach(e,boss)
		e.render_kind = e.kind
		e.render_hp = e.hp
		EnemyRules.carrier(e)
		if e.hp<=0: _destroy_enemy(e)
	# Removal unlinks the current entry in O(1); iteration preserves spawn order.
	for e in enemies:
		if e.hp<=0 or EnemyRules.out_of_bounds(e):
			view.renewal.forget(e.entity_id)
			enemies.remove(e.entity_id)
	_advance_shots()
	laser_render_ticks = laser
	shield_render_ticks = shield
	laser_contacts.clear()
	shield_contacts.clear()
	if shield>0:
		shield_center.y -= 1
		shield -= 1
	_apply_beam()
	_update_lifecycle()
	if state in ["menu","loading"]:
		if clock.recover(death_ticks==0): energy = minf(100,energy+1)
		return
	_resolve_shots()
	_update_items()
	_update_bullets()
	if clock.finish(death_ticks==0): energy = minf(100,energy+1)
	if view!=null:
		view.vfx.observe(self)
		view.renewal.observe(self)

func _update_scenery() -> void:
	scenery_distance += scroll_speed
	background_y = Weapons.vb_integer(background_y-scroll_speed)
	background_y = Regions.wrap(background_y,map_mode)
	if scroll_speed>scroll_target: scroll_speed -= 0.2
	if scroll_speed<scroll_target: scroll_speed += 0.2
	Scenery.advance_clouds(clouds,scroll_speed)

func _apply_beam() -> void:
	if laser<=0: return
	for e in enemies:
		if Combat.beam_hits(player,e):
			e.hp -= 4
			laser_contacts.append(Vector2(player.x+10,e.pos.y+25))
	if Combat.beam_hits_boss(player,boss):
		boss.hp -= 2
		laser_contacts.append(Vector2(player.x+10,boss.pos.y+45))
	laser -= 1

func _update_lifecycle() -> void:
	Lifecycle.update(self)

func _complete_stage() -> void:
	Lifecycle.complete_stage(self)

func _read_events() -> void:
	StageEvents.consume(self)

func _fire() -> void:
	if shot_cursor>46: shot_cursor = 0
	for active in shots:
		if active.get("slot",-1)==shot_cursor and active.alive: return
	for shot in Weapons.volley(player,weapon,power):
		var slot: int = shot_cursor
		shots = shots.filter(func(active): return active.get("slot",-1)!=slot)
		shot.slot = slot
		shot_cursor += 1
		shots.append(shot)
		stats.shots += 1
	energy -= Weapons.cost(power)
	fire_cooldown = 2 if power%2==0 else 3

func _update_shots() -> void:
	_advance_shots()
	_resolve_shots()

func _advance_shots() -> void:
	shot_visuals.clear()
	shots.sort_custom(func(a,b): return a.get("slot",-1)<b.get("slot",-1))
	for shot in shots:
		if int(shot.get("impact_ticks",-1))>=0:
			if shot.impact_ticks==0:
				shot.alive = false
				continue
			shot.pos.y -= 2
			shot.visual = Weapons.visual(shot,player)
			shot.impact_ticks -= 1
			shot_visuals.append(shot.duplicate(true))
		else:
			Weapons.advance(shot,player)
			shot.visual = Weapons.visual(shot,player)
			shot_visuals.append(shot.duplicate(true))
	shots = shots.filter(func(s): return s.alive and s.pos.y>=0 and s.pos.x>=0 and s.pos.x<=400)

func _resolve_shots() -> void:
	for shot in shots:
		if int(shot.get("impact_ticks",-1))>=0: continue
		var hit: bool = false
		for e in enemies:
			if Combat.shot_hits(shot.pos,e):
				e.hp -= 3
				hit = true
				stats.hits += 1
		# Original outer cw>0 guard is evaluated once: overlapping units AND body can be hit.
		if Combat.shot_hits_boss(shot.pos,boss):
			boss.hp -= 3
			hit = true
			stats.hits += 1
		if hit: shot.impact_ticks = 9

func _bullet(pos: Vector2, velocity: Vector2, kind: int = 1) -> void:
	BulletPool.single(self,pos,velocity,kind)

func _enemy_fire(e: Dictionary) -> void:
	BulletPool.enemy(self,e)

func _boss_steer() -> void:
	if not boss.is_empty(): Boss.steer(boss,player,enemies)

func _update_boss() -> void:
	if boss.is_empty(): return
	boss.age += 1
	boss.pos += boss.velocity

func _finish_stage() -> void:
	Lifecycle.begin_boss_death(self)

func _update_bullets() -> void:
	for bullet in bullets:
		bullet.render_pos = bullet.pos
		bullet.render_velocity = bullet.velocity
		if int(bullet.kind)==2: bullet.velocity.y = minf(15,bullet.velocity.y+0.3)
		if int(bullet.kind)==8: bullet.velocity.y = minf(10,bullet.velocity.y+0.2)
		bullet.pos.x += bullet.velocity.x
		bullet.pos.y = Weapons.vb_integer(bullet.pos.y+bullet.velocity.y)
		if bullet.velocity==Vector2.ZERO or bullet.pos.x<0 or bullet.pos.x>400 or bullet.pos.y<0 or bullet.pos.y>480:
			bullet.alive = false
			continue
		if Effects.shield_contains(shield_center,bullet.pos,shield):
			bullet.alive = false
			shield_contacts.append(bullet.pos)
			shield = maxi(0,shield-4)
			score += 25*title.difficulty
		elif hp>0 and invulnerable==0 and Combat.hurts_player(player,bullet.pos):
			hp -= Combat.DAMAGE[int(bullet.kind)]*title.difficulty
			invulnerable = 50
			hit_flash_ticks = 19
			bullet.alive = false
			_sound("damage")
	for bullet in bullets:
		if not bullet.alive: bullets.remove(bullet.entity_id)

func _destroy_enemy(e: Dictionary) -> void:
	var kind: int = int(e.kind)
	_sound("bang-be" if kind>20 and kind<51 else "bang-e")
	score += EnemyRules.score(kind,title.difficulty)
	var item: Dictionary = EnemyRules.drop(e,boss_rush)
	if not item.is_empty(): _drop_item(item)
	if kind==19:
		e.kind = 201
		e.hp = 1
		e.pattern = 1091
		return
	_explosion(e.pos,EnemyRules.explosion_ticks(kind))
	explosions[-1].owner_id = e.get("entity_id",-1)
	stats.killed += 1

func _drop_item(item: Dictionary) -> void:
	item.born_frame = frame
	items.append(item)

func _update_items() -> void:
	for item in items:
		item.render_pos = item.pos
		if item.get("born_frame",-1)!=frame: item.pos.y += 3
		if hp>0 and Combat.collects_item(player,item.pos):
			if item.kind == 1:
				power = mini(7,power+1)
				energy = 100
			else: hp = minf(100,hp+25)
			score += 1000
			item.pos.y = 600
			_sound("get")
	for item in items:
		if item.pos.y>=520: items.remove(item.entity_id)

func _explosion(pos: Vector2, ticks: int = 20, pending_sound: bool = false) -> void:
	explosions.append({"pos":pos,"ticks":ticks,"render_ticks":0,"render_pos":pos,"pending_sound":pending_sound,"delay":1 if pending_sound else 0})

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
	if not debug_enabled or death_ticks>0: return false
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
	loading_ticks = 1
	loading_image = "loading1"
	state = "loading"
