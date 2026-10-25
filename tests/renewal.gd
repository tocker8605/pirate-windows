extends SceneTree
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
const Preview = preload("res://scripts/weapon_preview.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const Rng = preload("res://scripts/random.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for speed in range(1,6):
		check(is_equal_approx(Clock.interval(speed),[0.0,0.030,0.024,0.018,0.012,0.006][speed]),"speed %d uses centrally tuned gameplay interval"%speed)
		check(is_equal_approx(Clock.interval(speed,false),(30.0-speed*5)/1000),"speed %d keeps original menu-animation interval"%speed)
	var preview = Preview.new()
	for weapon in range(1,4):
		Rng.state = 0x50000
		var shots: Array = preview.samples(weapon,Vector2(100,300),3)
		check(shots.size()==4 and shots.all(func(s): return s.visual.phase=="flight"),"weapon %d preview uses real max-power volley and flight phase"%weapon)
		check(Rng.state==0x50000,"weapon %d preview never consumes gameplay random values"%weapon)
		var reference: Array = Weapons.volley(Vector2(100,300),weapon,7,Preview.DemoRandom.new())
		for shot in reference:
			for i in range(3): Weapons.advance(shot,Vector2(100,300))
		check(shots[0].pos==reference[0].pos and shots[3].pos==reference[3].pos,"weapon %d preview follows the actual trajectory algorithm"%weapon)
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for render_rate in [30,60,144]:
		game._load_stage(1)
		game.events = []
		game.automatic = true
		for i in range(render_rate): game._process(1.0/render_rate)
		game.automatic = false
		check(game.frame==33,"one second produces 33 gameplay ticks at %d render frames/sec"%render_rate)
	game.state = "paused"
	var distance: float = game.scenery_distance
	game.automatic = true
	game._process(1.0)
	game.automatic = false
	check(game.frame==33 and game.scenery_distance==distance,"pause freezes gameplay and renewed scenery")
	game._load_stage(4)
	game.events = []
	for i in range(600): game._tick(Vector2.ZERO,false,false,false)
	check(game.background_y==2160 and game.scenery_distance==1200 and game.scroll_speed==2,"slow stage4 intro keeps the original two-pixel movement for all 600 ticks")
	for kind in game.view.renewal.SMALL:
		var texture: Texture2D = game.view.renewal.enemy_texture(kind)
		check(texture.get_width()>0 and texture.get_height()>0,"renewed enemy kind %d resolves a nonempty atlas cell"%kind)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	game.audio.stop_all()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
