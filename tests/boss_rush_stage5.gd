extends SceneTree
const Game=preload("res://scripts/game.gd")
const Events=preload("res://scripts/stage_events.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Regions=preload("res://scripts/background_regions.gd")
const Ground=preload("res://scripts/ground_turret.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/stage15.json"))
	check(Events.validate_document(doc).is_empty(),"Boss Rush stage15 timeline validates")
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.run_settings=g.run_settings.with_boss_rush(true)
	g._load_stage(4)
	g.score=12345
	g.hp=71
	g.power=5
	g._complete_stage()
	check(g.state=="loading" and g.flow.loading_target==5 and g.flow.loading_preserve,"fourth boss clear loads the fifth boss with preserved run state")
	g._tick(Vector2.ZERO,false,false,false)
	check(g.stage==5 and g.state=="playing" and g.score==12345 and g.hp==71 and g.power==5,"fifth Boss Rush stage preserves HP, power and score")
	check(g.background_y==480 and g.map_mode==3 and Regions.sample(g.background_y,5).near==3,"Boss Rush stage5 starts directly in the third chamber region")
	check(g.view.background_textures[2].resource_path=="res://assets/backgrounds/stage05/region03-supercomputer-chamber.png","third region uses the same normal-stage5 chamber art")
	check(g.scroll_speed==60 and g.scroll_target==60,"chamber begins scrolling at60px/s")
	check(g.supply_director.schedule.is_empty(),"Boss Rush schedules no regular carriers")
	g.invulnerability_seconds=999
	var last_spawn: float=0
	for event in doc.events:
		if event.get("action")=="spawn":last_spawn=maxf(last_spawn,float(event.at))
	while g.stage_elapsed_seconds<last_spawn+0.1:g._tick(Vector2.ZERO,false,false,false)
	check(g.boss.get("kind",0)==95 and g.boss.hp==3600,"supercomputer appears after5.4seconds with3600HP")
	check(g.enemies.size()==8 and g.enemies.all(func(e):return Catalog.is_part(int(e.kind))),"only the eight boss parts appear; no ordinary ground turrets")
	var expected_speed: float=60
	for event in Events.sorted_events(doc.events):
		if event.action=="scroll" and float(event.at)<g.stage_elapsed_seconds:expected_speed=float(event.speed)
	check(is_equal_approx(g.scroll_target,expected_speed) and Regions.sample(g.background_y,5).near==3,"boss appearance preserves the current timeline scroll speed")
	var origin_y: float=g.boss.pos.y
	var origin_distance: float=g.scenery_distance
	var stop_y: float=Catalog.boss_definition(5).boss_scroll.stop_after_y
	while g.boss.pos.y<=stop_y and g.stage_elapsed_seconds<60:g._tick(Vector2.ZERO,false,false,false)
	check(g.boss.pos.y>stop_y and g.scroll_target==0 and g.scroll_speed>0,"crossing the configured stopY requests a smooth stop without zeroing current speed")
	check(absf(g.boss.pos.y-origin_y-(g.scenery_distance-origin_distance))<0.001,"mainframe follows exact floor displacement during entry")
	for frame in range(60):g._tick(Vector2.ZERO,false,false,false)
	check(g.scroll_speed==0 and g.scroll_target==0,"background and ground boss finish decelerating to rest")
	check(g.enemies.all(func(e):return not Ground.active(e) or not Ground.ready(e)),"support turrets retain their bossHP hatch gates")
	for e in g.enemies:
		if e.kind not in [145,146]:continue
		var event: Dictionary={}
		for row in doc.events:
			if row.get("definition_id")==e.kind and is_equal_approx(float(row.position[0]),e.pos.x):event=row;break
		check(not event.is_empty() and is_equal_approx(e.pos.x,float(event.position[0])) and is_equal_approx(e.pos.y,g.boss.pos.y+float(Catalog.definition(e.kind).attachment.offset[1])),"support part%d preserves JSON X and follows its boss-relative Y"%e.kind)
	var rankings: Array=g.rankings.entries.duplicate(true)
	g._complete_stage()
	check(g.state=="clear" and g.rankings.entries==rankings and g.last_score==12345 and not g.flow.completed_run.ranking_eligible,"final Boss Rush clear shows ending without ranking registration")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
