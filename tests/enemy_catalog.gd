extends SceneTree
const HUD = preload("res://scripts/hud.gd")
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Timeline = preload("res://scripts/stage_events.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func document(events: Array) -> Dictionary:
	return {"schema_version":2,"time_unit":"seconds","events":events}
func spawn(at: float, kind: int = 1) -> Dictionary:
	return {"at":at,"action":"spawn","definition_id":kind,"position":[100,100],"pattern":0}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/timeline_v20.json"))
	var expected_hp: Dictionary = {19:1,91:1000,92:1000,93:1500,94:1500,123:400,124:400}
	var total := 0
	for filename in original:
		var stage: int = int(filename.trim_prefix("stage"))
		var events: Array = Timeline.load_stage(stage-10 if stage>10 else stage,stage>10)
		check(events.size()==original[filename].size(),"%s retains every original event"%filename)
		var same: bool = true
		var hp_same: bool = true
		for i in range(events.size()):
			var old: Array = original[filename][i]
			var e: Dictionary = events[i]
			same = same and is_equal_approx(float(e.at),float(old[0])*0.9) and not e.has("hp")
			match int(old[1]):
				61,62: same = same and e.action=="banner" and e.name==("warning" if old[1]==61 else "mission")
				71: same = same and e.action=="scroll" and e.mode==old[2] and e.speed==old[3]
				_:
					var id: int = int(old[1])
					same = same and e.action=="spawn" and e.definition_id==id and e.position==[old[2],old[3]] and e.pattern==(0 if id in [123,124] else old[4])
					if not expected_hp.has(id): expected_hp[id] = int(old[5])
					var actor: Dictionary = Catalog.create(id,Vector2(e.position[0],e.position[1]),int(e.pattern))
					hp_same = hp_same and actor.hp==expected_hp[id] and actor.max_hp==expected_hp[id]
			total += 1
		check(same,"%s named events retain time/order/position/pattern/control semantics"%filename)
		check(hp_same,"%s defaults retain legacy HP with stage3 balance update"%filename)
	check(total==683,"all683 normal and Boss Rush events were migrated")
	check(Catalog.ids().size()==33,"catalog defines all33 entity kinds including supply state")
	for id in expected_hp:
		check(Catalog.definition(id).hp==expected_hp[id],"entity%d matches configured base HP"%id)
	var a: Dictionary = Catalog.create(21,Vector2.ZERO)
	a.hp = 1
	var b: Dictionary = Catalog.create(21,Vector2.ZERO)
	check(b.hp==100 and Catalog.definition(21).hp==100,"runtime damage cannot modify defaults or later spawns")
	var override_actor: Dictionary = Catalog.create(94,Vector2.ZERO,0,{"hp":2000})
	check(override_actor.hp==2000 and override_actor.max_hp==2000 and Catalog.smoke_threshold(override_actor)==800,"explicit boss HP override updates maxHP and relative smoke consistently")
	check(Catalog.definition(94).hp==1500,"per-spawn override cannot change default boss HP")
	check(Catalog.definition(1).is_read_only() and Catalog.definition(1).collision.is_read_only(),"shared definitions and nested metadata are immutable")
	check(Timeline.validate_document(document([spawn(0)])).is_empty(),"valid named timeline is accepted")
	check(not Timeline.validate_document(document([spawn(0,999)])).is_empty(),"unknown entity IDs fail validation")
	check(not Timeline.validate_document(document([spawn(2),spawn(1)])).is_empty(),"unsorted event times fail validation")
	var invalid = spawn(0)
	invalid.hp = 999
	check(not Timeline.validate_document(document([invalid])).is_empty(),"HP cannot silently leak back into timeline spawn fields")
	invalid = spawn(0)
	invalid.overrides = {"hp":-1}
	check(not Timeline.validate_document(document([invalid])).is_empty(),"negative HP override fails validation")
	invalid.overrides = {"hp":60,"hpt":3}
	check(not Timeline.validate_document(document([invalid])).is_empty(),"unknown override fields fail validation")
	invalid.overrides = {"hp":60}
	check(Timeline.validate_document(document([invalid])).is_empty(),"intentional per-spawn HP override is explicit and valid")
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	definitions.entities["1"].hp = 0
	check(not Catalog.validate_document(definitions).is_empty(),"nonpositive catalog HP fails validation")
	definitions.entities["1"].hp = 5
	definitions.entities["201"].open_kind = 999
	check(not Catalog.validate_document(definitions).is_empty(),"invalid supply transition reference fails validation")
	definitions = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	definitions.entities["1"].hpt = 3
	check(not Catalog.validate_document(definitions).is_empty(),"unknown catalog fields fail validation instead of silently doing nothing")
	definitions.entities["1"].erase("hpt")
	definitions.entities["1"].collision.shot_bounds = [35,-25,-15,30]
	check(not Catalog.validate_document(definitions).is_empty(),"reversed collision edges fail validation")
	definitions = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	definitions.entities["92"].stage = 1
	check(not Catalog.validate_document(definitions).is_empty(),"duplicate boss stage definitions fail validation")
	for field in ["collision","damage_smoke","on_defeat"]:
		definitions = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		definitions.entities["1"][field] = "invalid"
		check(not Catalog.validate_document(definitions).is_empty(),"malformed nested %s returns validation errors without a type crash"%field)
	check(HUD.boss_bar_width(2000,2000)==250 and HUD.boss_bar_width(1000,2000)==125,"custom2000HP boss has correctly scaled full and half HUD bars")
	check(HUD.boss_bar_width(1000,1000)==250 and HUD.boss_bar_width(750,1500)==125,"existing1000/1500HP bosses retain the original HUD fill")
	check(HUD.boss_bar_width(0,2000)==0 and HUD.boss_bar_width(9999,2000)==250,"boss HUD clamps empty and overfilled HP")
	check(HUD.boss_bar_width(100,0)==0,"missing maximum HP cannot divide by zero")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(1)
	g.events = []
	for i in range(300):
		var e: Dictionary = spawn(0)
		e.position = [i,-30]
		if i==0: e.overrides = {"hp":77}
		g.events.append(e)
	g.events.append({"at":0,"action":"scroll","mode":2,"speed":7})
	g.events.append(spawn(0,91))
	g.frame = 1
	g.stage_elapsed_seconds = g.frame*0.03
	g._read_events()
	check(g.enemies.size()==300 and g.event_cursor==302,"one timeline update consumes all300 simultaneous spawns without a five-actor quota")
	check(g.enemies.at(0).pos.x==0 and g.enemies.at(299).pos.x==299 and g.enemies.valid(),"large simultaneous wave keeps stable authored order and valid storage")
	check(g.enemies.at(0).hp==77 and g.enemies.at(1).hp==5,"actual spawn path applies only the explicit instance override")
	check(g.boss.hp==1000 and g.boss.kind==91 and g.boss.stage==1 and g.map_mode==2 and g.scroll_target==7,"boss and scroll events after the wave execute on the same scheduled tick")
	g._read_events()
	check(g.enemies.size()==300 and g.event_cursor==302,"consumed events cannot spawn twice")
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
