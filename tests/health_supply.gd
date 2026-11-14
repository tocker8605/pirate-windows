extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const Combat = preload("res://scripts/combat.gd")
const Clock = preload("res://scripts/timing.gd")
const Director = preload("res://scripts/supply_director.gd")
const Timeline = preload("res://scripts/stage_events.gd")
const Rng = preload("res://scripts/random.gd")
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
	for id in [21,41,42]:
		for rush in [false,true]: check(Rules.drop(Catalog.create(id,Vector2.ZERO),rush).is_empty(),"enemy%d no HP drop in rush%s"%[id,rush])
	for id in [20,202]:
		var e: Dictionary = Catalog.create(id,Vector2(100,300))
		check(Rules.cargo_item(e)==2 and Rules.cargo_position(e)==Vector2(125,340),"health supply%d shares mounted/released HP payload anchor"%id)
		check(not Combat.touches_player(Vector2(100,300),e),"health supply%d remains exempt from contact damage"%id)
	var protected: Dictionary = Catalog.create(202,Vector2(100,300))
	check(not Combat.shot_hits(protected.pos,protected) and not Combat.beam_hits(Vector2(100,400),protected),"approaching HP carrier is protected from bullets and beam")
	Rules.carrier(protected,292)
	check(protected.kind==202,"HP carrier stays protected before291crossing")
	protected.pos.y = 290
	Rules.carrier(protected,292)
	check(protected.kind==20 and Combat.shot_hits(protected.pos,protected),"crossing291opens HP carrier to normal fire")
	for stage in range(1,5):
		var events: Array = Timeline.load_stage(stage)
		check(events.all(func(e): return int(e.get("definition_id",0)) not in [19,20,201,202]),"stage%d timeline contains no supply carrier"%stage)
		var boss_time := 0.0
		for event in events:
			if event.action=="spawn" and Catalog.definition(int(event.definition_id)).role=="boss": boss_time = event.at; break
		for power in [1,2,7]:
			var director = Director.new()
			director.rng.seed = 32000+stage*10+power
			var before: int = Rng.state
			director.plan(stage,power,events)
			var expected_power: int = 6 if stage>=2 and power==1 else 3
			check(director.schedule.filter(func(e): return e.kind==201).size()==expected_power and director.schedule.filter(func(e): return e.kind==202).size()==3,"stage%d startingPower%d gives%d power and3HP deliveries"%[stage,power,expected_power])
			check(director.schedule.all(func(e): return ((e.at>10 and e.at<boss_time-10) or (stage>=2 and e.kind==201 and e.at==1.0)) and e.pos.x>=100 and e.pos.x<=300 and e.pos.y==480 and e.pattern==1074),"stage%d supplies obey requested time/X bounds and existing approach motion"%stage)
			var early: Array = director.schedule.filter(func(e): return e.at<10)
			check(early.size()==(1 if stage>=2 else 0) and (stage==1 or (early[0].kind==201 and early[0].at==1.0)),"stage%d startingPower%d has exactly the requested1second power allocation within total budget"%[stage,power])
			var ordered := true
			for i in range(1,director.schedule.size()): ordered = ordered and director.schedule[i-1].at<director.schedule[i].at
			check(ordered and Rng.state==before,"schedule is ordered and never consumes enemy-pattern RNG")
		var first = Director.new()
		var second = Director.new()
		first.rng.seed = 100
		second.rng.seed = 101
		first.plan(stage,1,events)
		second.plan(stage,1,events)
		check(first.schedule!=second.schedule,"stage%d seed changes actual random times and X positions"%stage)
		first.plan(stage,1,events,true)
		check(first.schedule.is_empty(),"rush stage%d never schedules a carrier even with an otherwise valid time window"%stage)
	for id in [101,102,111,112,113,121,122,123,124,131,132,133]:
		var actor: Dictionary = Catalog.create(id,Vector2(100,100))
		check(Rules.drop(actor,false).is_empty() and Rules.drop(actor,true).kind==1,"boss part%d retains its intentional BossRush-only power drop"%id)
	for id in [19,20,201,202]:
		var timeline: Dictionary = {"schema_version":2,"time_unit":"seconds","events":[{"at":10,"action":"spawn","definition_id":id,"position":[150,480],"pattern":1074}]}
		check(not Timeline.validate_document(timeline).is_empty(),"timeline schema rejects supply carrier%d"%id)
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.events = []
	for i in range(59): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.stats.supply_spawned==0,"early carrier cannot appear before1second")
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.stats.supply_spawned==1 and g.enemies.size()==1 and g.enemies.at(0).kind==201,"60th native tick creates the guaranteed power carrier at1second")
	for i in range(120): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.stats.supply_spawned==1,"guaranteed carrier is not duplicated on following ticks")
	g._load_stage(1)
	g.events = []
	g.supply_director.schedule = [{"at":10.1,"kind":202,"pos":Vector2(150,480),"pattern":1074}]
	g.stage_elapsed_seconds = 10.1
	g.hp = 40
	g.player = Vector2(300,400)
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.stats.supply_spawned==1 and g.enemies.size()==1 and g.enemies.at(0).kind==202,"actual native update admits due HP supply independently of timeline")
	for i in range(240):
		g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
		if g.enemies.at(0).kind==20: break
	var carrier: Dictionary = g.enemies.at(0)
	check(carrier.kind==20,"actual HP supply opens during native ascent")
	g.shots.replace_all([{"pos":carrier.pos,"kind":1,"alive":true,"impact_remaining_seconds":-1}])
	g._resolve_shots()
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(carrier.kind==202 and carrier.get("rescued",false) and g.items.size()==1 and g.items.at(0).kind==2 and g.explosions.is_empty(),"shooting releases exactly one HP item and carrier escapes without fake explosion")
	for i in range(20): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.items.size()==1 and g.stats.supply_spawned==1,"release and scheduled delivery cannot repeat")
	g.player = g.items.at(0).pos-Vector2(25,25)
	g.hp = 40
	g.energy = 42
	g.power = 3
	g._update_items()
	check(g.hp==65 and g.energy==42 and g.power==3 and g.items.is_empty(),"HP payload heals25 without changing power or energy")
	g.hp = 95
	g._drop_item({"pos":g.player+Vector2(25,25),"kind":2})
	g._update_items()
	check(g.hp==100,"HP payload clamps recovery at100")
	g._load_stage(2,true)
	check(g.supply_director.schedule.size()==6,"carried power3plans three power and three HP supplies")
	g.power = 1
	g._load_stage(3,true)
	check(g.supply_director.schedule.size()==9,"carried power1at stage3plans six power and three HP supplies")
	g.power = 7
	check(g.supply_director.schedule.size()==9,"midstage power gain cannot change the starting-power delivery budget")
	g.boss_rush = true
	g._load_stage(4)
	check(g.supply_director.schedule.is_empty(),"actual BossRush stage load contains no scheduled supply carriers")
	g.supply_director.schedule = [{"at":0,"kind":202,"pos":Vector2(150,480),"pattern":1074}]
	g.stage_elapsed_seconds = 20
	g.supply_director.advance(g)
	check(g.enemies.is_empty(),"BossRush blocks even an accidentally injected supply schedule")
	g.events = [{"at":0,"action":"spawn","definition_id":201,"position":[150,480],"pattern":1074}]
	g.event_cursor = 0
	g._read_events()
	check(g.enemies.is_empty(),"BossRush cannot restore carriers through stale unvalidated legacy timeline events")
	for id in [101,113,123,133]:
		g.enemies.clear()
		g.items.clear()
		var part: Dictionary = Catalog.create(id,Vector2(100,100))
		g._destroy_enemy(part)
		check(g.items.size()==1 and g.items.at(0).kind==1,"actual BossRush part%d destruction still releases one power item"%id)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
