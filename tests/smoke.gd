extends SceneTree
const Game = preload("res://scripts/game.gd")
var checks: int = 0
var failed: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error("FAIL: " + message)
	else: print("PASS: " + message)

func key(game: Node, code: int, ctrl: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.ctrl_pressed = ctrl
	event.pressed = true
	game._unhandled_key_input(event)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	check(game.state == "menu", "title screen loads")
	check(game.events.size() == 133, "all 133 stage-one events imported")
	key(game,KEY_SPACE)
	for i in range(94): game.title.tick()
	key(game,KEY_SPACE)
	for i in range(3): key(game,KEY_DOWN)
	check(game.title.phase==24,"original title weapon selection handles input")
	key(game,KEY_SPACE)
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state == "playing", "space starts gameplay")
	game._tick(Vector2(-1,-1),false,false,false)
	check(game.player == Vector2(164,294), "movement follows original six-pixel tick")
	for i in range(100): game._tick(Vector2(-1,-1),false,false,false)
	check(game.player == Vector2(10,0), "player remains inside playfield")
	game.start_game()
	game._tick(Vector2.ZERO,true,false,false)
	check(game.stats.shots == 1 and game.energy < 100, "firing consumes energy")
	game._tick(Vector2.ZERO,false,true,false)
	check(game.laser > 0, "beam activates")
	game.energy = 100
	game._tick(Vector2.ZERO,false,false,true)
	check(game.shield > 0, "shield activates")
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	game.bullets.clear()
	game._bullet(game.shield_center,Vector2(0,0.1))
	game._update_bullets()
	check(game.bullets.is_empty(), "shield intercepts incoming projectiles")
	game.shield = 0
	game.invulnerable = 0
	game._bullet(game.player+Vector2(25,25),Vector2(0,0.1))
	game._update_bullets()
	check(game.hp == 91 and game.invulnerable == 50, "bullet damage grants temporary invulnerability")
	game._bullet(game.player+Vector2(25,25),Vector2(0,0.1))
	game._update_bullets()
	check(game.hp == 91, "invulnerability prevents repeated damage")
	game.items = [{"pos":game.player+Vector2(25,20),"kind":1}]
	game._update_items()
	check(game.power == 2 and game.energy == 100, "power-up collection")
	key(game,KEY_P)
	var before: int = game.frame
	game._tick(Vector2.ONE,true,false,false)
	check(game.state == "paused" and game.frame == before, "pause freezes simulation")
	key(game,KEY_P)
	check(game.state == "playing", "resume works")
	key(game,KEY_R,true)
	check(game.score == 0 and game.frame == 0 and game.power == 1, "restart clears run state")
	for w in range(1,4):
		game.start_game()
		game.weapon = w
		for i in range(3550):
			game.hp = 100
			game.invulnerable = 100
			game._tick(Vector2(sin(i*0.017),0),true,i%300==0,i%500==0)
		check(game.stats.spawned == 125, "weapon %d: every enemy event consumed" % w)
		check(game.stats.boss_spawned and not game.boss.is_empty(), "weapon %d: boss appears" % w)
		check(game.stats.killed > 0 and game.stats.hits > 0, "weapon %d: shots destroy enemies" % w)
		check(game.event_cursor == 133, "weapon %d: event stream completes" % w)
		check(game.bullets.size() <= 200 and game.enemies.size() < 40, "weapon %d: entity collections remain bounded" % w)
	# Exercise the real hit path against the boss body and wing protection.
	game.start_game()
	game.events = game.events.filter(func(row): return int(row[0])==116)
	game.frame = 3481
	game._read_events()
	check(game.Boss.parts_alive(game.enemies) and not game.boss.is_empty(), "boss body remains hittable while weapon attachments fire")
	for e in game.enemies: e.hp = 0
	game.enemies.clear()
	check(not game.Boss.parts_alive(game.enemies) and not game.boss.is_empty(), "destroying wing units leaves boss body hittable")
	game.boss.pos = Vector2(200,100)
	game.boss.hp = 3
	game.shots = [{"pos":Vector2(200,145),"velocity":Vector2(0,-19),"alive":true}]
	game._update_shots()
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="boss_dying" and game.boss_death_ticks==239, "boss destruction starts original 240-tick sequence")
	game.start_game()
	game.hp = 1
	game.invulnerable = 0
	game._bullet(game.player+Vector2(25,25),Vector2(0,0.1))
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="dying" and game.death_ticks==239, "fatal damage starts original game-over explosion sequence")
	for i in range(239): game._tick(Vector2.ZERO,false,false,false)
	key(game,KEY_SPACE)
	for i in range(94): game.title.tick()
	key(game,KEY_DOWN)
	key(game,KEY_DOWN)
	key(game,KEY_SPACE)
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="playing" and game.hp==100,"original Continue restarts after game-over returns to title")
	# Check alpha extraction against an original white background and opaque centre.
	var sprite: Image = game.art.sprite("picair",Rect2i(0,0,50,50),Vector2i(0,50)).get_image()
	check(sprite.get_pixel(0,0).a == 0, "original white mask becomes transparent")
	check(sprite.get_pixel(25,25).a > 0.9, "aircraft centre remains opaque")
	print("RESULT: %d checks, %d failures" % [checks,failed])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
