extends SceneTree
const Game = preload("res://scripts/game.gd")
const Banner = preload("res://scripts/mission_banner.gd")
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
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	for rush in [false,true]:
		g.run_settings=g.run_settings.with_boss_rush(rush)
		for stage in range(1,5):
			g._load_stage(stage)
			g.events=[{"at":0,"action":"banner","name":"mission"}]
			g.stage_elapsed_seconds=0.001
			g._read_events()
			var text: String=Banner.label(stage,rush)
			var duration: float=Banner.duration(text)
			check(g.banner==text and is_equal_approx(g.banner_remaining_seconds,duration),"stage%d rush%s timeline starts the correct typing message and lifetime"%[stage,rush])
			check(Banner.visible_characters(text,duration)==0 and Banner.visible_characters(text,duration-0.119)==0,"message starts with an empty typing position")
			check(Banner.visible_characters(text,duration-0.12)==1,"first letter appears after120ms")
			check(Banner.visible_characters(text,duration-0.24)==2,"second letter appears after240ms")
			check(Banner.visible_characters(text,2.001)==text.length()-1,"last letter is not revealed before its120ms interval")
			check(Banner.visible_characters(text,2.0)==text.length(),"all letters finish exactly two seconds before expiry")
			g.events=[]
			g.banner_remaining_seconds=2.0
			g._tick(Vector2.ZERO,false,false,false,1.999)
			check(g.banner_remaining_seconds>0 and Banner.visible_characters(text,g.banner_remaining_seconds)==text.length(),"completed message remains visible for the full hold period")
			g._tick(Vector2.ZERO,false,false,false,0.001)
			check(g.banner_remaining_seconds==0,"message expires after two seconds of hold")
	g._load_stage(1)
	g.events=[{"at":0,"action":"banner","name":"warning"}]
	g.stage_elapsed_seconds=0.001
	g._read_events()
	check(g.banner.begins_with("WARNING") and g.banner_remaining_seconds==2.4,"warning retains its own sprite and lifetime")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
