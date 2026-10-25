extends SceneTree
const Game = preload("res://scripts/game.gd")
const Title = preload("res://scripts/title.gd")
const Scenery = preload("res://scripts/scenery.gd")
var count: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func key(game: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	game._unhandled_key_input(event)
func enemy(kind: int, y: int) -> Dictionary: return {"kind":kind,"pos":Vector2(100,y)}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var title = Title.new()
	check(title.phase==0 and title.loading_ticks==1,"original publisher loading image precedes Space screen")
	title.tick()
	check(title.phase==0 and title.loading_ticks==0,"title waits for Space without auto-start")
	check(title.confirm()=="opening" and title.slide==1,"Space triggers original opening")
	for i in range(45): title.tick()
	check(title.phase==1 and title.slide==46 and title.scroll==45,"opening midpoint preserves 2.6x slide and 1px scroll counters")
	for i in range(49): title.tick()
	check(title.phase==11 and title.slide==96 and title.scroll==94,"opening enters menu at original slide=95 threshold")
	for i in range(500): title.tick()
	check(title.scroll==479,"title background stops at original 479px limit")
	title.navigate(KEY_DOWN)
	check(title.phase==12,"original Boss Rush menu entry")
	title.confirm()
	check(title.phase==21 and title.boss_rush,"Boss Rush opens original settings screen")
	title.navigate(KEY_RIGHT)
	check(title.speed==2,"original game-speed setting")
	title.navigate(KEY_DOWN)
	title.navigate(KEY_LEFT)
	check(title.difficulty==2,"original difficulty setting")
	for i in range(3): title.navigate(KEY_DOWN)
	check(title.phase==25 and title.confirm()=="play","third original weapon entry starts selected mode")
	title.reset()
	check(title.phase==0 and title.slide==0 and title.scroll==0 and title.speed==2,"return to title resets animation but retains settings")
	var clouds: Array = Scenery.initial_clouds()
	check(clouds==[Vector2(120,400),Vector2(320,20)],"original two cloud starting positions")
	Scenery.advance_clouds(clouds,2)
	check(clouds==[Vector2(120,403),Vector2(320,23)],"clouds advance floor(2x1.5)=3px")
	Scenery.advance_clouds(clouds,19.8)
	check(clouds[0].y==432 and clouds[1].y==52,"clouds accelerate to floor(19.8x1.5)=29px")
	clouds = [Vector2(240,480),Vector2(320,480)]
	Scenery.advance_clouds(clouds,0)
	check(clouds[0].y==480,"cloud reset threshold is strict Y>480")
	Scenery.advance_clouds(clouds,2)
	check(clouds==[Vector2(340,-300),Vector2(-50,-300)],"cloud recycle offsets are +100/+50 and X wrap is >340")
	clouds = [Vector2(340,480),Vector2(290,480)]
	Scenery.advance_clouds(clouds,2)
	check(clouds==[Vector2(-50,-300),Vector2(340,-300)],"clouds wrap independently at exact X boundary")
	check(Scenery.preparation(enemy(22,50),{}).is_empty(),"100x100 enemy preparation hidden at Y=50")
	var visual: Dictionary = Scenery.preparation(enemy(22,51),{})
	check(visual.pos==Vector2(100,61) and visual.rect==Rect2i(200,100,50,50),"enemy Y=51 shows original preparation frame 1 and XY offset")
	visual = Scenery.preparation(enemy(22,52),{})
	check(visual.rect==Rect2i(200,0,50,50),"enemy Y=52 switches to original preparation frame 0")
	check(not Scenery.preparation(enemy(131,174),{"pos":Vector2(200,109)}).is_empty(),"boss left preparation visible below Y=110")
	check(Scenery.preparation(enemy(131,175),{"pos":Vector2(200,110)}).is_empty(),"boss left preparation hidden at Y=110")
	check(Scenery.preparation(enemy(132,155),{"pos":Vector2(200,90)}).is_empty(),"boss right preparation hidden at Y=90")
	check(not Scenery.preparation(enemy(132,156),{"pos":Vector2(200,91)}).is_empty(),"boss right preparation visible above Y=90")
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	key(game,KEY_SPACE)
	check(game.music_track=="title" and game.music.playing,"title music begins with original Space opening")
	for i in range(94): game.title.tick()
	key(game,KEY_SPACE)
	for i in range(2): key(game,KEY_DOWN)
	key(game,KEY_SPACE)
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="playing" and game.weapon==1 and game.music_track=="bgm01","original New Game -> weapon menu starts stage 1 music")
	game._tick(Vector2.ZERO,false,false,false)
	check(game.background_y==3340 and is_equal_approx(game.scroll_speed,19.8) and game.clouds[0].y==429,"scroll, easing, then cloud movement follow original order")
	var before: Array = game.clouds.duplicate()
	game._load_stage(2,true)
	check(game.clouds==before and game.music_track=="bgm02","stage transition retains cloud state and switches BGM")
	# Original fload Case 4: slow entry across the long background, not the takeoff loop.
	game.boss_rush = false
	game._load_stage(4)
	check(game.background_y==3360 and game.map_mode==2 and game.scroll_speed==2 and game.scroll_target==2,"normal stage 4 uses original slow-entry initialization")
	var slow_entry_ok: bool = true
	for tick in range(1,601):
		game.invulnerable = 100
		game._tick(Vector2.ZERO,false,false,false)
		slow_entry_ok = slow_entry_ok and game.background_y==3360-tick*2 and game.scroll_speed==2 and game.map_mode==2
	check(slow_entry_ok and game.background_y==2160,"all first 600 stage-4 ticks move 2px without premature background repetition")
	game._tick(Vector2.ZERO,false,false,false)
	check(game.background_y==2158 and game.scroll_target==25 and is_equal_approx(game.scroll_speed,2.2),"stage-4 t20 event begins acceleration only on tick 601")
	game.background_y = 1442
	game.scroll_speed = 2
	game.scroll_target = 2
	game._update_scenery()
	check(game.background_y==1440,"stage-4 mode2 does not wrap at exact Y1440")
	game._update_scenery()
	check(game.background_y==1918,"stage-4 mode2 wraps below Y1440 by exactly 480px")
	for earlier in range(1,4):
		game._load_stage(earlier)
		check(game.map_mode==1 and game.scroll_speed==20,"normal stage %d retains original takeoff speed and mode"%earlier)
	game.boss_rush = true
	game._load_stage(4)
	check(game.map_mode==1 and game.scroll_speed==20,"Boss Rush Case14 retains takeoff initialization separately from Case4")
	game.boss_rush = false
	for stage in range(1,5):
		game._load_stage(stage)
		check(game.music_track=="bgm%02d"%stage and game.music.playing,"stage %d starts its original MIDI arrangement"%stage)
		check(game.music.stream.get_length()>120 and not game.music.stream.loop,"stage %d has original once-through Ogg music"%stage)
		for row in game.events:
			if int(row[1]) in [91,92,93,94]: game.frame = int(row[0])*30+1
		while game.event_cursor<game.events.size() and int(game.events[game.event_cursor][0])*30<game.frame:
			game.enemies.clear()
			game._read_events()
		check(game.music_track=="boss01" and game.music.playing,"stage %d replaces BGM with original boss track"%stage)
	key(game,KEY_P)
	check(game.music.stream_paused,"pause suspends music transport")
	key(game,KEY_P)
	check(not game.music.stream_paused,"resume continues music transport")
	game.mute = false
	key(game,KEY_M)
	check(game.mute and game.music.volume_db== -80,"M mutes music and effects together")
	game.boss_rush = false
	game._load_stage(3)
	key(game,KEY_ESCAPE)
	check(game.state=="menu" and game.title.phase==0 and not game.music.playing,"return to title restores original waiting screen and stops BGM")
	key(game,KEY_SPACE)
	for i in range(94): game.title.tick()
	key(game,KEY_DOWN)
	key(game,KEY_DOWN)
	key(game,KEY_SPACE)
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="playing" and game.stage==3 and game.music_track=="bgm03","original Continue entry resumes latest stage")
	game._return_title()
	key(game,KEY_SPACE)
	for i in range(94): game.title.tick()
	key(game,KEY_DOWN)
	key(game,KEY_SPACE)
	for i in range(2): key(game,KEY_DOWN)
	key(game,KEY_SPACE)
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.boss_rush and game.events.size()==6 and game.music_track=="","original Boss Rush entry loads stage11 and waits for boss music")
	game.frame = 181
	game._read_events()
	check(game.music_track=="boss01" and game.stats.boss_spawned,"Boss Rush starts boss music at original event")
	game._finish_stage()
	check(game.music_track=="boss01" and game.music.playing,"original boss music continues during destruction sequence")
	for i in range(241): game._tick(Vector2.ZERO,false,false,false)
	check(game.stage==2 and game.events.size()==7 and game.boss_rush,"Boss Rush campaign uses next original alternate event data")
	for number in range(1,5):
		game._load_stage(number)
		game.frame = 300
		while game.event_cursor<game.events.size() and int(game.events[game.event_cursor][0])*30<game.frame:
			game.enemies.clear()
			game._read_events()
		check(game.boss_rush and game.event_cursor==[0,6,7,8,7][number] and game.boss.get("stage",0)==number and game.music_track=="boss01","Boss Rush stage %d reads complete original alternate events and music"%number)
	print("RESULT: %d checks, %d failures"%[count,failures])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
