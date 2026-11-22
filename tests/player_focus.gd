extends SceneTree
const Game = preload("res://scripts/game.gd")
const Geometry = preload("res://scripts/pilot_geometry.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func key(code: Key, pressed: bool, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.location = location
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(1)
	g.events = []
	g.invulnerability_seconds = 300
	for slow in [false,true]:
		g.player=Vector2(150,469.9)
		g._tick(Vector2.DOWN,false,false,false,1.0/60,slow)
		check(g.player.y==470,"normal and slow movement clamp atY470")
		g.player=Vector2(150,0.1)
		g._tick(Vector2.UP,false,false,false,1.0/60,slow)
		check(g.player.y==0,"normal and slow movement preserve top limitY0")
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(1,1)]:
		g.player = Vector2(150,200)
		g._tick(direction,false,false,false,1.0/60,true)
		check(g.player.distance_to(Vector2(150,200)+direction*(100.0/60))<0.0001 and g.slow_movement_active,"slow movement travels1.667px per axis and exposes cockpit marker")
	for rate in [30,60,120]:
		g.player = Vector2(100,200)
		for i in range(rate): g._tick(Vector2.RIGHT,false,false,false,1.0/rate,true)
		check(absf(g.player.x-200.0)<0.002,"slow movement retains100px/s at%sHz"%rate)
	key(KEY_SHIFT,true,KEY_LOCATION_RIGHT)
	check(not Input.is_action_pressed("slow_movement"),"right Shift does not enable slow movement")
	key(KEY_SHIFT,false,KEY_LOCATION_RIGHT)
	key(KEY_SHIFT,true,KEY_LOCATION_LEFT)
	check(Input.is_action_pressed("slow_movement"),"left Shift enables slow movement")
	key(KEY_RIGHT,true)
	g.player = Vector2(100,200)
	g.automatic = true
	g._process(1.0/60)
	g.automatic = false
	check(absf(g.player.x-100.0-100.0/60)<0.0001 and g.slow_movement_active,"real input path applies left Shift precision speed")
	key(KEY_SHIFT,false,KEY_LOCATION_LEFT)
	var before: float = g.player.x
	g.automatic = true
	g._process(1.0/60)
	g.automatic = false
	check(absf(g.player.x-before-200.0/60)<0.0001 and not g.slow_movement_active,"releasing Shift immediately restores normal speed and hides marker")
	key(KEY_RIGHT,false)
	check(Geometry.COCKPIT==Vector2(25,18) and Geometry.HIT_RADIUS==4,"precision marker does not change the cockpit collision geometry")
	g._tick(Vector2.ZERO,true,false,false,1.0/60,true)
	check(g.stats.shots>0 and g.slow_movement_active,"slow mode permits ordinary firing")
	g._load_stage(2)
	check(not g.slow_movement_active,"stage reset clears precision presentation state")
	for rush in [false,true]:
		g.run_settings = g.run_settings.with_boss_rush(rush)
		for stage in range(1,5):
			g._load_stage(stage)
			check(g.player.x+Geometry.COCKPIT.x==200 and g.player.y==300,"stage%d rush%s starts cockpit at screen centreX200"%[stage,rush])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
