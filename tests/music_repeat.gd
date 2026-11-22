extends SceneTree
const Game=preload("res://scripts/game.gd")
const Audio=preload("res://scripts/audio.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=Game.new()
	g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for track in ["title","bgm01","bgm02","bgm03","bgm04","boss01"]:
		var stream: AudioStreamOggVorbis=g.audio.music_stream(track)
		g._play_music(track,stream.get_length()-0.08,true)
		await create_timer(0.4).timeout
		check(g.music.playing and g.music.get_playback_position()<1 and stream.loop and stream.loop_offset==0,"track%s actually repeats from the beginning after reaching its end"%track)
	var other=Audio.new()
	root.add_child(other)
	var separate: AudioStreamOggVorbis=other.music_stream("boss01")
	check(not is_same(separate,g.music.stream) and not separate.loop and g.music.stream.loop,"separate audio caches cannot change another player's loop policy")
	other.queue_free()
	for rush in [false,true]:
		g.run_settings=g.run_settings.with_boss_rush(rush)
		g._load_stage(5)
		g.rankings.entries.clear()
		g.score=1234567
		g._complete_stage()
		check(g.music_track=="title" and not g.music.stream.loop and absf(g.music.get_playback_position()-189)<0.5,"ending restarts title at189seconds with repeat explicitly disabled")
		if not rush:
			g.flow.confirm_clear(g,KEY_ENTER)
			check(g.state==g.GameFlow.RANKING_ENTRY and not g.music.stream.loop,"clear ranking keeps the ending's no-repeat policy")
		g.music.seek(g.music.stream.get_length()-0.08)
		await create_timer(0.4).timeout
		check(not g.music.playing,"ending or clear-ranking music actually stops at its end")
	g._play_music("title")
	check(g.music.playing and g.music.stream.loop,"ordinary title playback restores repeat after an ending used the same cached track")
	g.audio.stop_all();g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
