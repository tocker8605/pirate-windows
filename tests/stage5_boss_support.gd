extends SceneTree
const Game=preload("res://scripts/game.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Ground=preload("res://scripts/ground_turret.gd")
const GroundArt=preload("res://scripts/ground_art.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Combat=preload("res://scripts/combat.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var body: Dictionary=Catalog.boss_definition(5)
	var rect: Rect2=GroundArt.decoration_rect(body,Vector2(200,80))
	check(rect.size==Vector2(240,240) and rect.get_center()==Vector2(200,130),"240x240 cable network is centred on the visible boss body")
	check(not body.floor_decoration.asset.path.is_empty() and Geometry.layer(body)=="floor","cables are a boss floor decoration, not a collidable part")
	for pair in [[145,51],[146,52]]:
		var special: Dictionary=Catalog.definition(pair[0])
		var original: Dictionary=Catalog.definition(pair[1])
		check(special.role=="part" and special.hp==800 and special.score==2000,"special turret%d has800HP and awards2000base points but is a boss part"%pair[0])
		check(special.ground_turret.hatch==original.ground_turret.hatch and special.ground_turret.wreck==original.ground_turret.wreck,"special turret%d reuses the same hatch and wreck assets"%pair[0])
		check(special.sprite_path!=original.sprite_path and Geometry.layer(special)=="floor","special turret%d has independent boss-colour artwork on the floor layer"%pair[0])
		var e: Dictionary=Catalog.create(pair[0],Vector2(100,200))
		Ground.initialize(e,0,false)
		check(not Ground.ready(e) and not Combat.shot_hits(e.pos+Vector2(25,25),e) and Fire.advance(e,2,Vector2(175,380)).is_empty(),"special turret%d stays invulnerable and silent under its hatch"%pair[0])
		var gate_boss: Dictionary=Catalog.create(95,Vector2(200,80))
		gate_boss.hp=1200
		Ground.initialize(e,0,true,gate_boss)
		check(Combat.shot_hits(e.pos+Vector2(25,25),e) and Combat.beam_hits(Vector2(100,380),e),"special turret%d can be hit by shots and laser when exposed"%pair[0])
		check(not Combat.touches_player(e.pos+Vector2(25,25)-Combat.Pilot.COCKPIT,e),"special turret%d never collides with the player hull"%pair[0])
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(5)
	g.events=g.events.filter(func(e):return e.has("at") and is_equal_approx(float(e.at),82))
	g.supply_director.schedule.clear()
	g.stage_elapsed_seconds=82.001
	g._read_events()
	check(g.boss.kind==95 and g.enemies.size()==8,"boss timeline spawns the torso and eight parts simultaneously")
	var support: Array=[]
	var kinds: Dictionary={145:0,146:0}
	for e in g.enemies:
		if e.kind in [145,146]:
			kinds[e.kind]+=1
			support.append(e)
	check(kinds[145]==2 and kinds[146]==2,"boss front row contains two autocannon and two energy turrets")
	for e in support:
		check(is_equal_approx(e.pos.y,g.boss.pos.y+float(Catalog.definition(e.kind).attachment.offset[1])) and not Ground.ready(e),"part%d starts concealed at its boss-relative Y offset"%e.kind)
	g.events=[]
	g.invulnerability_seconds=999
	for frame in range(60):g._tick(Vector2.ZERO,false,false,false)
	check(support.all(func(e):return not Ground.ready(e)) and g.bullets.is_empty(),"allfour turrets remain closed while the boss is healthy")
	g.boss.hp=2400
	for frame in range(90):g._tick(Vector2.ZERO,false,false,false)
	check(support.all(func(e):return Ground.ready(e)==(e.kind==146)),"only energy turrets open at two-thirds bossHP")
	g.boss.hp=1200
	for frame in range(90):g._tick(Vector2.ZERO,false,false,false)
	check(support.all(func(e):return Ground.ready(e)) and not g.bullets.is_empty(),"allfour turrets are exposed and attack at one-third bossHP")
	var score: int=g.score
	g.boss.hp=0
	for frame in range(3):g._tick(Vector2.ZERO,false,false,false)
	check(g.enemies.is_empty() and g.ground_wrecks.size()==4,"boss death automatically destroys the four support turrets and leaves four floor wrecks")
	check(g.score==score+int(body.score)*g.run_settings.difficulty,"automatic support-part destruction awards no extra part points beyond the body reward")
	g._load_stage(1)
	check(g.boss.is_empty() and g.ground_wrecks.is_empty(),"stage change clears the cable owner and all turret remains")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
