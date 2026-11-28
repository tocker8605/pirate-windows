extends SceneTree
const Game=preload("res://scripts/game.gd")
const Result=preload("res://scripts/run_result.gd")
const Settings=preload("res://scripts/run_settings.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var result=Result.new(99999999,Settings.new(4,2,false),5,true)
	check(result.record.is_read_only() and result.record=={"score":9999999,"weapon":2,"level":4,"mission":5,"cleared":true} and result.cleared and result.ranking_eligible,"run result captures validated immutable score and settings once")
	check(not Result.new(1000,Settings.new(2,1,true),5,true).ranking_eligible,"Boss Rush eligibility is captured independently of clear status")
	var g=Game.new()
	g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.rankings.entries.clear()
	g.run_settings=Settings.new(4,2,false)
	g._load_stage(5)
	g.score=5000
	g._complete_stage()
	var frozen: Dictionary=g.flow.completed_run.record
	check(is_same(frozen,g.clear_screen.record),"clear presentation uses the single completed-run snapshot")
	g.score=123;g.last_score=123;g.stage=1
	g.run_settings=Settings.new(1,3,true)
	g.flow.confirm_clear(g,KEY_ENTER)
	check(g.state==g.GameFlow.RANKING_ENTRY and g.ranking_entry.record=={"score":5000,"weapon":2,"level":4,"mission":5,"cleared":true},"confirmation uses captured result and eligibility despite later mutable game changes")
	var backdrop: Texture2D=g.ranking_entry.background
	g.flow.show_ranking(g,g.GameFlow.MusicPolicy.STOP)
	check(g.ranking_entry.background==backdrop and backdrop!=null and g.music_track.is_empty(),"a ranking backdrop can be shown while music policy explicitly stops playback")
	g._play_music("title",195,true,false)
	g.ranking_entry.background=null
	g.flow.show_ranking(g,g.GameFlow.MusicPolicy.KEEP)
	check(g.ranking_entry.background==null and g.music.playing and g.music_track=="title" and g.music.get_playback_position()>=194.5 and not g.music.stream.loop,"music can continue without a backdrop and retains position and nonlooping policy")
	g.ranking_entry.background=backdrop
	g.rankings.path="res://work/missing-end-flow-policy-directory/rankings.json"
	g.flow.submit_ranking(g,KEY_ENTER)
	check(g.state==g.GameFlow.RANKING_ENTRY and g.ranking_entry.save_failed and g.ranking_entry.background==backdrop and g.music.playing,"save failure preserves ranking input, background and continuous music")
	g.audio.stop_all();g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
