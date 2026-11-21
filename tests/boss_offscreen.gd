extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Rules=preload("res://scripts/enemy_rules.gd")
const Game=preload("res://scripts/game.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in Catalog.ids():
		if Catalog.definition(kind).role not in ["boss","part"]:continue
		for pos in [Vector2(200,-1000),Vector2(200,1000),Vector2(-1000,100),Vector2(1000,100)]:
			check(not Rules.out_of_bounds(Catalog.create(kind,pos)),"boss/part%d is retained beyond the viewport at%s"%[kind,pos])
	for kind in [1,51,52,201]:
		check(Rules.out_of_bounds(Catalog.create(kind,Vector2(200,-101))) and not Rules.out_of_bounds(Catalog.create(kind,Vector2(200,-100))),"ordinary actor%d retains its original offscreen cutoff"%kind)
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(5)
	g.events=[]
	g.supply_director.schedule.clear()
	g.boss=Catalog.create(95,Vector2(200,-250))
	var arm: Dictionary=Catalog.create(141,Vector2.ZERO)
	var turret: Dictionary=Catalog.create(145,Vector2(200,-300))
	g.enemies.append(arm)
	g.enemies.append(turret)
	g.enemies.append(Catalog.create(51,Vector2(200,-300)))
	g._tick(Vector2.ZERO,false,false,false)
	check(g.boss.pos.y==-250 and g.enemies.size()==2 and g.enemies.contains(arm.entity_id) and g.enemies.contains(turret.entity_id),"actual cleanup retains offscreen boss and parts but removes an ordinary turret")
	arm.hp=0
	g._tick(Vector2.ZERO,false,false,false)
	check(not g.enemies.contains(arm.entity_id),"a destroyed offscreen part is still removed byHP")
	g.boss.hp=0
	for i in range(3):g._tick(Vector2.ZERO,false,false,false)
	check(g.boss_defeated and g.enemies.is_empty(),"offscreen boss defeat still automatically destroys its surviving parts")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
