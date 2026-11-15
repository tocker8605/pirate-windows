extends SceneTree
const Timeline=preload("res://scripts/stage_events.gd")
const Game=preload("res://scripts/game.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if ok: print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func _initialize()->void: call_deferred("run")
func run()->void:
	var document={"schema_version":2,"time_unit":"seconds","comment":"Stage notes\n설명 / https://example.com", "events":[
		{"at":2,"action":"spawn","definition_id":1,"position":[100,-50],"pattern":1011,"comment":"First ship"},
		{"at":1,"action":"scroll","mode":2,"speed":100,"comment":"Background change"},
		{"at":1,"action":"banner","name":"mission","comment":"Message"},
		{"at":2,"action":"spawn","definition_id":1,"position":[200,-50],"pattern":1011,"comment":"Second ship"}]}
	check(Timeline.validate_document(document).is_empty(),"root and all three event types accept comment strings")
	var round_trip=JSON.parse_string(JSON.stringify(document))
	check(round_trip.comment==document.comment and Timeline.validate_document(round_trip).is_empty(),"comments retain Korean, newlines and URL text through standard JSON")
	var ordered=Timeline.sorted_events(document.events)
	check(ordered.map(func(e):return e.comment)==["Background change","Message","First ship","Second ship"],"comments stay with events through stable time sorting")
	for invalid in [null,7,[],{}]:
		var altered=document.duplicate(true)
		altered.comment=invalid
		check(not Timeline.validate_document(altered).is_empty(),"non-string root comment rejected: %s"%[invalid])
		altered=document.duplicate(true)
		altered.events[0].comment=invalid
		check(not Timeline.validate_document(altered).is_empty(),"non-string event comment rejected: %s"%[invalid])
	var blank=document.duplicate(true)
	blank.comment=""
	blank.events[0].comment=""
	check(Timeline.validate_document(blank).is_empty(),"empty comment strings are allowed")
	var without=document.duplicate(true)
	without.erase("comment")
	for event in without.events: event.erase("comment")
	check(Timeline.validate_document(without).is_empty(),"existing documents without comments remain valid")
	var standalone=document.duplicate(true)
	standalone.events.insert(0,{"comment":"Group A"})
	standalone.events.insert(2,{"action":"memo","comment":"Group B"})
	standalone.events.append({"arbitrary":[1,2],"comment":123})
	check(Timeline.validate_document(standalone).is_empty(),"untimed objects are ignored regardless of action or fields")
	ordered=Timeline.sorted_events(standalone.events)
	check(ordered.size()==4 and ordered.map(func(e):return e.comment)==["Background change","Message","First ship","Second ship"],"untimed notes are excluded before stable sorting")
	var malformed=standalone.duplicate(true)
	malformed.events[0].at=null
	check(not Timeline.validate_document(malformed).is_empty(),"present null at is rejected rather than ignored")
	malformed=standalone.duplicate(true)
	malformed.events.append("not an object")
	check(not Timeline.validate_document(malformed).is_empty(),"non-object entries are still rejected")
	for rush in [false,true]:
		for stage in range(1,5):
			var events=Timeline.load_stage(stage,rush)
			var sorted_ok=not events.is_empty()
			for i in range(1,events.size()): sorted_ok=sorted_ok and events[i-1].at<=events[i].at
			check(sorted_ok,"current stage%d rush%s loads in time order"%[stage,rush])
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(1)
	g.events=[{"action":"memo","comment":"Runtime note"}]+ordered
	g.stage_elapsed_seconds=2.1
	g._read_events()
	check(g.event_cursor==5 and g.map_mode==2 and g.scroll_target==100 and g.banner=="MISSION 01 / TAKE OFF","comments never change scheduling or control-event effects")
	check(g.enemies.size()==2 and g.enemies.at(0).pos.x==100 and g.enemies.at(1).pos.x==200,"comments never spawn actors or change same-time actor order")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
