extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Ground = preload("res://scripts/ground_turret.gd")
const Combat = preload("res://scripts/combat.gd")
const Boss = preload("res://scripts/boss.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Events = preload("res://scripts/stage_events.gd")
const Campaign = preload("res://scripts/campaign_rules.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Textures=preload("res://scripts/entity_textures.gd")
const GroundArt = preload("res://scripts/ground_art.gd")
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
	check(Campaign.stage_count(false)==5 and Campaign.stage_count(true)==5,"normal campaign and Boss Rush both include stage5")
	check(Catalog.boss_definition(5).hp==3000 and Catalog.boss_definition(5).fire_channels.size()==3,"supercomputer has3000HP and three projectile channels independent from beam hazards")
	for stage in range(1,6):
		var body: Dictionary=Catalog.create(90+stage,Vector2(200,100))
		for local_y in [-26.0,-24.0,59.0,61.0]:
			check(Combat.shot_hits_boss(body.pos+Vector2(0,local_y),body)==(local_y>-25 and local_y<60),"stage%d body shares the same shot Y edges at%.1f"%[stage,local_y])
	var document: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/stage05.json"))
	check(Events.validate_document(document).is_empty(),"stage5 timeline validates with both deployment modes")
	check(Catalog.definition(53).is_empty() and document.events.all(func(e):return int(e.get("definition_id",0))!=53),"missile floor turret is removed from catalog and timeline")
	var clipped: bool=true
	for phase in range(21):
		for side in [-1,1]:
			for polygon in GroundArt.door_polygons(phase/20.0,side):
				for p in polygon:
					clipped=clipped and absf(p.x)<=25.001 and absf(p.y)<=25.001 and absf(p.x)+absf(p.y)<=38.001
	check(clipped,"sliding door vertices stay inside the octagonal aperture throughout deployment")
	var invalid: Dictionary=document.duplicate(true)
	invalid.events=[{"at":0,"action":"spawn","definition_id":51,"position":[100,0],"start_exposed":"unknown"}]
	check(not Events.validate_document(invalid).is_empty(),"invalid deployment option is rejected")
	for start_exposed in [false,true]:
		invalid.events=[{"at":0,"action":"spawn","definition_id":51,"position":[100,0],"start_exposed":start_exposed}]
		check(Events.validate_document(invalid).is_empty(),"start_exposed accepts boolean%s"%start_exposed)
	for value in [0,1,"true","exposed"]:
		invalid.events=[{"at":0,"action":"spawn","definition_id":51,"position":[100,0],"start_exposed":value}]
		check(not Events.validate_document(invalid).is_empty(),"start_exposed rejects non-boolean%s"%value)
	invalid.events=[{"at":0,"action":"spawn","definition_id":51,"position":[100,0],"deployment":"exposed"}]
	check(not Events.validate_document(invalid).is_empty(),"retired deployment string field is rejected")
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g._load_stage(5)
	g.events=[]
	g.supply_director.schedule.clear()
	g.invulnerability_seconds=999
	for option in [false,true,null]:
		var event: Dictionary={"at":0,"action":"spawn","definition_id":51,"position":[100,0]}
		if option!=null:event.start_exposed=option
		g.events=[event]
		g.event_cursor=0
		g.stage_elapsed_seconds=0.001
		g._read_events()
		check(Ground.ready(g.enemies.at(0))==(option==true),"timeline loader applies boolean/default initial hatch state%s"%option)
		g.enemies.clear()
	g.events=[]
	g.stage_elapsed_seconds=0
	check(g.stage==5 and g.view.background_textures.size()==3 and g.scroll_speed==60,"stage5 enters with three local backgrounds and a steady floor scroll")
	for kind in [51,52]:
		var hidden: Dictionary=Catalog.create(kind,Vector2(175,80))
		Ground.initialize(hidden,g.scenery_distance,false)
		check(not Combat.shot_hits(hidden.pos+Vector2(25,25),hidden),"hidden turret%d ignores normal shots"%kind)
		check(not Combat.beam_hits(Vector2(175,300),hidden),"hidden turret%d ignores the laser"%kind)
		check(not Combat.touches_player(Vector2(175,87),hidden),"hidden turret%d has no body collision"%kind)
		check(Fire.advance(hidden,10,g.player).is_empty(),"hidden turret%d cannot bank or emit shots"%kind)
		Ground.advance(hidden,g,0.1)
		check(hidden.deployment_progress==0,"turret%d stays concealed at exactlyY80"%kind)
		hidden.pos.y=80.01
		hidden.ground_anchor_y=80.01
		Ground.advance(hidden,g,0.1)
		check(hidden.deployment_progress>0 and not Ground.ready(hidden),"turret%d starts rising only afterY80"%kind)
		check(not Combat.shot_hits(hidden.pos+Vector2(25,25),hidden),"rising turret%d stays invulnerable until fully exposed"%kind)
		Ground.advance(hidden,g,0.8)
		check(Ground.ready(hidden) and Combat.shot_hits(hidden.pos+Vector2(25,25),hidden),"fully exposed turret%d becomes damageable"%kind)
		check(not Fire.advance(hidden,2,g.player).is_empty(),"exposed turret%d fires through its independent timer"%kind)
		var exposed: Dictionary=Catalog.create(kind,Vector2(175,120))
		Ground.initialize(exposed,g.scenery_distance,true)
		check(Ground.ready(exposed) and Combat.beam_hits(Vector2(175,300),exposed),"turret%d can spawn already exposed"%kind)
		check(not Combat.touches_player(exposed.pos+Vector2(25,25)-Combat.Pilot.COCKPIT,exposed),"fully exposed turret%d cannot collide with the player's overlapping cockpit"%kind)
	var actor: Dictionary=Catalog.create(51,Vector2(175,100))
	Ground.initialize(actor,g.scenery_distance,true)
	g.enemies.append(actor)
	var start_y: float=actor.pos.y
	var start_distance: float=g.scenery_distance
	var follows: bool=true
	for speed in [0.0,25.0,150.0,10.0,0.0]:
		g.scroll_target=speed
		for frame in range(20):
			g._tick(Vector2.ZERO,false,false,false)
			follows=follows and absf(actor.pos.y-start_y-(g.scenery_distance-start_distance))<0.001 and actor.pos.x==175
	check(follows,"turret follows exact background displacement through easing and stops with fixedX")
	actor.hp=0
	g._tick(Vector2.ZERO,false,false,false)
	check(g.enemies.is_empty() and g.ground_wrecks.size()==1,"destroying a turret removes the actor and leaves exactly one ground wreck")
	var remains: Dictionary=g.ground_wrecks[0]
	var wreck_y: float=remains.pos.y
	var wreck_distance: float=g.scenery_distance
	g.scroll_speed=0
	g.scroll_target=0
	for frame in range(120):g._tick(Vector2.ZERO,false,false,false)
	check(g.ground_wrecks.size()==1 and remains.pos.y==wreck_y,"wreck has no lifetime expiry and remains on a stopped floor")
	g.scroll_speed=80
	g.scroll_target=80
	for frame in range(60):g._tick(Vector2.ZERO,false,false,false)
	check(absf(remains.pos.y-wreck_y-(g.scenery_distance-wreck_distance))<0.001,"wreck also follows exact floor scroll")
	g.scenery_distance+=1000
	Ground.advance_wrecks(g)
	check(g.ground_wrecks.is_empty(),"wreck is removed after scrolling outside the screen")
	g._load_stage(5)
	g.events=[{"at":0,"action":"spawn","definition_id":95,"position":[200,100]}]
	g.stage_elapsed_seconds=0.001
	g._read_events()
	check(g.boss.hp==3000 and g.scroll_speed>0,"mainframe spawn preserves floor scrolling")
	g._tick(Vector2.ZERO,false,false,false)
	check(g.boss.pos.y>100 and g.scroll_speed>0 and g.scroll_target==0,"crossingY100 starts gentle floor deceleration")
	for frame in range(60):g._tick(Vector2.ZERO,false,false,false)
	var pos: Vector2=g.boss.pos
	for frame in range(120):g._tick(Vector2.ZERO,false,false,false)
	check(g.boss.pos==pos and g.boss.get("fire_age",0)>0,"floor-mounted mainframe remains stopped while its projectile clocks advance")
	g._load_stage(5)
	g.invulnerability_seconds=999
	var visited: Dictionary={}
	for frame in range(5100):
		g._tick(Vector2.ZERO,false,false,false)
		visited[g.map_mode]=true
	check(g.stats.spawned-g.stats.supply_spawned==27 and g.boss.get("kind",0)==95,"complete stage5 timeline deploys19 ordinary turrets, eight boss parts and the mainframe alongside automatic supplies")
	# Authored entry Y/speed may change; allow the scenery-mounted boss to reach its stop.
	while not g.boss.is_empty() and g.scroll_speed>0 and g.stage_elapsed_seconds<150:
		g._tick(Vector2.ZERO,false,false,false)
	check(visited.has(1) and visited.has(2) and visited.has(3) and g.scroll_speed==0,"stage5 traverses allthree regions and stops on the chamber floor")
	var parts_correct: bool=true
	for kind in [141,142,143,144]:
		var found: bool=false
		for e in g.enemies:
			if int(e.kind)==kind:
				found=true
				var offset: Array=Catalog.definition(kind).attachment.offset
				parts_correct=parts_correct and e.pos.is_equal_approx(g.boss.pos+Vector2(offset[0],offset[1])) and not Catalog.definition(e.kind).fire_channels.is_empty()
		parts_correct=parts_correct and found
	check(parts_correct,"allfour stationary boss parts attach correctly; wings have missile attacks and arms have gatling attacks")
	var hinges_aligned: bool=true
	for kind in [141,142,143,144]:
		var definition: Dictionary=Catalog.definition(kind)
		var alignment_error: float=(Geometry.hinge_offset(definition,Textures.native_size(definition))+definition.draw_offset).length()
		hinges_aligned=hinges_aligned and alignment_error<0.00001
		var offset: Array=definition.attachment.offset
		hinges_aligned=hinges_aligned and Vector2(offset[0],offset[1]).is_equal_approx(Vector2(-32 if kind in [141,143] else 32,37))
	check(hinges_aligned,"mirrored arm and wing hinge centers coincide with both body sockets after aspect fitting")
	g._load_stage(4)
	g.score=123
	g._complete_stage()
	check(g.state=="loading" and g.flow.loading_target==5,"normal stage4 now continues to stage5")
	g._load_stage(5)
	g.rankings.entries.clear()
	g.score=456
	g._complete_stage()
	check(g.state=="ranking_entry" and g.ranking_entry.record.mission==5 and g.last_score==456,"stage5 completion records mission5 in the normal ranking")
	g.run_settings=g.run_settings.with_boss_rush(true)
	g._load_stage(4)
	g._complete_stage()
	check(g.state=="loading" and g.flow.loading_target==5,"Boss Rush advances from stage4 to stage5")
	g._load_stage(5,true)
	g._complete_stage()
	check(g.state=="menu","Boss Rush completes after stage5 without name entry")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
