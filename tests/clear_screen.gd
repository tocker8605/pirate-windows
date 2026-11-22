extends SceneTree
const Game=preload("res://scripts/game.gd")
const Ranking=preload("res://scripts/score_ranking.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const PATH="res://work/clear-screen-test-rankings.json"
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func key(g: Node,code: int,pressed: bool=true,echo: bool=false) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.pressed=pressed;event.echo=echo
	g._unhandled_key_input(event)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for path in [PATH,PATH+".tmp"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var g=Game.new()
	g.automatic=false;g.mute=true
	g.rankings=Ranking.new(PATH)
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for rush in [false,true]:
		for confirm in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
			g.run_settings=g.run_settings.with_boss_rush(rush).with_weapon(2).with_difficulty(3)
			g._load_stage(5)
			g.score=1234567
			var saved: Array=g.rankings.entries.duplicate(true)
			g._complete_stage()
			check(g.state==g.GameFlow.CLEAR and g.score==0 and g.last_score==1234567,"rush%s clear waits for confirmation and remembers the score"%rush)
			check(g.clear_screen.record=={"score":1234567,"weapon":2,"level":3,"mission":5} and g.flow.completed_run.ranking_eligible==not rush,"clear screen snapshots run result and eligibility")
			check(g.clear_screen.background!=null and g.music_track=="title" and g.music.playing and g.accumulator==0,"clear screen has prepared artwork and starts title music while gameplay time is stopped")
			check(not g.music.stream.loop and g.music.stream.get_length()>189 and absf(g.music.get_playback_position()-189)<0.5,"normal and Boss Rush clear music starts at189seconds")
			var frame: int=g.frame
			var player: Vector2=g.player
			g._tick(Vector2.DOWN,true,true,true,1.0)
			check(g.frame==frame and g.player==player and g.score==0,"clear screen freezes gameplay updates")
			g._redraw()
			check(not g.view.background.visible and g.view.cloud_nodes.all(func(cloud):return not cloud.visible),"clear screen hides gameplay background and clouds")
			key(g,KEY_Z)
			key(g,confirm,true,true)
			check(g.state==g.GameFlow.CLEAR,"fire keys and repeat events cannot dismiss clear screen")
			g.music.seek(195)
			key(g,confirm)
			if rush:
				check(g.state==g.GameFlow.MENU and g.rankings.entries==saved,"Boss Rush confirmation returns to initial ranking list without changing records")
			else:
				check(g.music_track=="title" and g.music.playing and g.music.get_playback_position()>=194.5,"clear ranking entry keeps the current playback position instead of restarting the title track")
				check(g.state==g.GameFlow.RANKING_ENTRY and g.ranking_entry.background==g.clear_screen.background and g.ranking_entry.record==g.clear_screen.record,"qualifying clear enters name registration with ending backdrop and frozen result")
				key(g,confirm)
				check(g.state==g.GameFlow.RANKING_ENTRY and g.rankings.entries==saved,"clear confirmation cannot immediately submit the blank name")
				key(g,confirm,false)
				g.ranking_entry.player_name="CLEAR "
				key(g,confirm)
				check(g.state==g.GameFlow.MENU and g.rankings.entries.any(func(entry):return entry.name=="CLEAR "),"finished name entry saves result and returns to the initial ranking list")
			check(g.title.screen==g.title.RANKING and g.title.blocked_confirmation_key==confirm and g.music_track.is_empty(),"returning to initial title stops ending music and blocks the same confirmation")
			key(g,confirm,false)
	g.run_settings=g.run_settings.with_boss_rush(false)
	for points in [999,1000]:
		g._load_stage(5)
		g.score=points
		g._complete_stage()
		check(g.state==g.GameFlow.CLEAR,"nonqualifying clear still shows score and ending artwork")
		key(g,KEY_ENTER)
		check(g.state==g.GameFlow.MENU and g.title.screen==g.title.RANKING,"below cutoff and trailing tie return to title after confirmation")
		key(g,KEY_ENTER,false)
	g._load_stage(3)
	g.score=7654321
	g._finish_run()
	check(g.state==g.GameFlow.RANKING_ENTRY and g.ranking_entry.background==null,"ordinary game-over name entry retains its black background after a clear run")
	g._load_stage(5)
	g.events=[]
	g.boss=Catalog.create(95,Vector2(200,50))
	g._damage_boss(g.boss.hp)
	check(g.state==g.GameFlow.BOSS_DYING and g.boss_death_remaining_seconds==7.2,"final boss death still plays its existing destruction sequence first")
	g.delta_seconds=7.2
	g._update_lifecycle()
	check(g.state==g.GameFlow.CLEAR,"destruction sequence completion enters the clear screen")
	g.audio.stop_all();g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	for path in [PATH,PATH+".tmp"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
