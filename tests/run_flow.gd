extends SceneTree
const Game = preload("res://scripts/game.gd")
const Settings = preload("res://scripts/run_settings.gd")
const Flow = preload("res://scripts/game_flow.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const Preview = preload("res://scripts/weapon_preview.gd")
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
	var original = Settings.new(5,2,false)
	var changed = original.with_weapon(3).with_boss_rush(true).with_difficulty(1)
	check(original.difficulty==5 and original.weapon==2 and not original.boss_rush,"changing settings produces a new snapshot without changing the previous run")
	check(changed.difficulty==1 and changed.weapon==3 and changed.boss_rush,"new snapshot applies the requested choices")
	check(Settings.new(99,-1).difficulty==5 and Settings.new(99,-1).weapon==1,"run settings constrain choices to playable values")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.rankings.entries.clear()
	g.title.screen = g.title.SETTINGS
	g.title.settings_selection = 2
	g.title.difficulty = 5
	g.title.boss_rush = false
	g._title_accept(g.title.confirm())
	check(g.state==Flow.LOADING and g.flow.loading_image=="loading1" and g.flow.loading_remaining_seconds==0.03,"new run enters loading through the shared transition")
	g.title.difficulty = 1
	g.title.settings_selection = 3
	g.title.boss_rush = true
	check(g.run_settings.difficulty==5 and g.run_settings.weapon==2 and not g.run_settings.boss_rush,"later menu changes cannot alter combat settings")
	g._tick(Vector2.ZERO,false,false,false,0.03)
	check(g.state==Flow.LOADING,"loading artwork retains its presented frame")
	g._tick(Vector2.ZERO,false,false,false,0.03)
	g.events = []
	check(g.state==Flow.PLAYING and g.music_track=="bgm01","stage entry starts the correct music and playing state")
	g.score = 0
	g._destroy_enemy(Catalog.create(1,Vector2(100,100)))
	check(g.score==Rules.score(1,5),"enemy rewards use captured run difficulty despite changed menu difficulty")
	g.accumulator = 0.007
	g.title.navigation_key = KEY_DOWN
	g.flow.pause(g)
	check(g.state==Flow.PAUSED and g.music.stream_paused and g.accumulator==0.007 and g.title.navigation_key==0,"pause freezes time and music and clears held menu input")
	g.flow.resume(g)
	check(g.state==Flow.PLAYING and not g.music.stream_paused and g.music_track=="bgm01" and g.accumulator==0.007,"resume keeps the active track and partial simulation time")
	g.death_remaining_seconds = 0
	g.flow.boss_died(g)
	g.flow.pause(g)
	g.flow.resume(g)
	check(g.state==Flow.BOSS_DYING,"pause resumes the boss destruction state rather than forcing normal play")
	g._return_title()
	check(g.state==Flow.MENU and g.last_score==Rules.score(1,5) and g.accumulator==0 and g.music_track.is_empty(),"manual return remembers score and resets menu time and music")
	g.run_settings = changed
	g._title_accept("continue")
	check(g.state==Flow.LOADING and g.run_settings.difficulty==5 and g.run_settings.weapon==2 and not g.run_settings.boss_rush,"Continue restores checkpoint settings instead of current menu or run edits")
	g._load_stage(1)
	g.events = []
	g.score = 1234
	g._finish_run()
	check(g.state==Flow.RANKING_ENTRY and g.last_score==1234 and g.score==0 and g.ranking_entry.record.level==5 and g.ranking_entry.record.weapon==2,"normal run captures the final score and run settings for registration")
	g.flow.show_menu(g)
	check(g.last_score==1234,"returning from ranking cannot overwrite the final score with the cleared live score")
	g.run_settings = Settings.new(2,3,true)
	g._load_stage(2)
	g.events = []
	g.score = 7654321
	g.hp = 0
	g.death_remaining_seconds = 0.03
	g.flow.player_died(g)
	g._tick(Vector2.ZERO,false,false,false,0.03)
	check(g.state==Flow.MENU and g.last_score==7654321 and g.score==0 and g.rankings.entries.is_empty(),"Boss Rush game-over bypasses name entry and leaves rankings unchanged")
	g._load_stage(4)
	g.events = []
	g.score = 8765432
	g._complete_stage()
	check(g.state==Flow.LOADING and g.flow.loading_target==5,"Boss Rush stage4 continues to the new fifth boss")
	g._load_stage(5,true)
	g.events=[]
	g._complete_stage()
	check(g.state==Flow.MENU and g.last_score==8765432 and g.score==0 and g.rankings.entries.is_empty(),"Boss Rush final clear also bypasses rankings")
	g.run_settings = Settings.new(2,3,false)
	for stage in range(1,5):
		g._load_stage(stage)
		g._complete_stage()
		check(g.state==Flow.LOADING and g.flow.loading_image=="loading" and g.flow.loading_target==stage+1 and g.flow.loading_preserve,"stage%d transition uses loading.png and preserves run state"%stage)
	g._load_stage(5)
	g.score = 8765432
	g._complete_stage()
	check(g.state==Flow.RANKING_ENTRY and g.last_score==8765432,"normal final clear remains eligible for ranking")
	check(Preview.displayed_age(0)==0 and Preview.displayed_age(0.3)==18 and Preview.displayed_age(0.6)==36,"legend animation follows the native60Hz trajectory using seconds")
	check(Preview.displayed_age(0.7)==36 and Preview.displayed_age(0.8)==0,"legend pauses at the end and repeats on its established0.8-second cycle")
	check(Preview.displayed_power(2.49)==4 and Preview.displayed_power(2.5)==7 and Preview.displayed_power(5)==4,"legend power changes every2.5 seconds")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
