extends SceneTree
const Timeline = preload("res://scripts/stage_events.gd")
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/timeline_v20.json"))
	for name in original:
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json"))
		var number: int = int(name.trim_prefix("stage"))
		var events: Array = Timeline.load_stage(number-10 if number>10 else number,number>10)
		var same: bool = source.schema_version==2 and source.time_unit=="seconds" and Timeline.validate_document(source).is_empty()
		if same: same=events==Timeline.sorted_events(source.events)
		check(same,"%s preserves current authored seconds and stable event order"%name)
	var fractional: Dictionary = {"schema_version":2,"time_unit":"seconds","events":[{"at":0.025,"action":"banner","name":"mission"}]}
	check(Timeline.validate_document(fractional).is_empty(),"millisecond-precision decimal seconds are accepted")
	var legacy: Dictionary = fractional.duplicate(true)
	legacy.schema_version = 1
	legacy.time_unit = "authored_30_ticks"
	check(not Timeline.validate_document(legacy).is_empty(),"legacy time metadata is explicitly rejected instead of misinterpreted")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	var mixed: Array = [
		{"at":2,"action":"scroll","mode":1,"speed":10},
		{"at":0.1,"action":"scroll","mode":2,"speed":20},
		{"at":0.1,"action":"scroll","mode":3,"speed":30},
		{"at":1,"action":"banner","name":"mission"}]
	check(Timeline.validate_document({"schema_version":2,"time_unit":"seconds","events":mixed}).is_empty(),"unordered events pass validation")
	var ordered: Array = Timeline.sorted_events(mixed)
	check(ordered.map(func(event): return event.at)==[0.1,0.1,1,2],"load-time sorting orders events by exact time")
	check(ordered[0].mode==2 and ordered[1].mode==3 and mixed[0].at==2,"equal-time events keep file order without rearranging source data")
	for invalid_time in [-1,"1",INF,NAN]:
		var malformed: Dictionary = fractional.duplicate(true)
		malformed.events[0].at = invalid_time
		check(not Timeline.validate_document(malformed).is_empty(),"sorting never bypasses invalid time validation: %s"%invalid_time)
	g._load_stage(1)
	g.events = ordered
	g.stage_elapsed_seconds = 0.11
	g._read_events()
	check(g.event_cursor==2 and g.map_mode==3 and g.scroll_target==30,"simultaneous ordered control events execute in original file order")
	g._load_stage(1)
	g.delta_seconds = 0.03
	g.events = fractional.events.duplicate(true)
	g.invulnerability_seconds = 300.0
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.event_cursor==0 and is_equal_approx(g.stage_elapsed_seconds,1.0/60),"25ms event is not early on first native tick")
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.event_cursor==1 and is_equal_approx(g.stage_elapsed_seconds,2.0/60),"25ms event runs on first native tick after its scheduled time")
	var elapsed: float = g.stage_elapsed_seconds
	g.state = "paused"
	for i in range(60): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.stage_elapsed_seconds==elapsed,"pause does not advance stage seconds")
	g._load_stage(2)
	g.delta_seconds = 0.03
	check(g.stage_elapsed_seconds==0 and g.event_cursor==0,"new stage resets its independent seconds clock and event cursor")
	g.events = [{"at":0.025,"action":"banner","name":"warning"}]
	g.frame = 1000000
	g._read_events()
	check(g.event_cursor==0,"timeline no longer derives scheduling from frame number")
	g.events = []
	for i in range(1000): g.events.append({"at":0.025,"action":"spawn","definition_id":1,"position":[100,-30],"pattern":0})
	g.events.append({"at":0.026,"action":"scroll","mode":2,"speed":(7/0.03)})
	check(Timeline.validate_document({"schema_version":2,"time_unit":"seconds","events":g.events}).is_empty(),"1001fractional events validate without200event cap")
	g.stage_elapsed_seconds = 0.024
	g._read_events()
	check(g.enemies.is_empty() and g.event_cursor==0,"dense fractional wave does not spawn early")
	g.stage_elapsed_seconds = 0.0251
	g._read_events()
	check(g.enemies.size()==1000 and g.event_cursor==1000 and g.enemies.valid(),"all1000simultaneous fractional spawns consume in one update")
	g.stage_elapsed_seconds = 0.0261
	g._read_events()
	check(g.event_cursor==1001 and g.map_mode==2 and g.scroll_target==(7/0.03),"following subsecond control event remains ordered and executes once")
	g._read_events()
	check(g.enemies.size()==1000 and g.event_cursor==1001,"consumed seconds events cannot repeat")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
