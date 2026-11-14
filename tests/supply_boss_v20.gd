extends SceneTree
const Game = preload("res://scripts/game.gd")
const Title = preload("res://scripts/title.gd")
const Fire = preload("res://tests/fixtures/fire_probe.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const FX = preload("res://scripts/combat_vfx.gd")
const Clock = preload("res://scripts/timing.gd")
const Supply = preload("res://scripts/supply_visual.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var title = Title.new()
	title.phase = 11
	title.confirm()
	check(title.phase==22,"settings opens on difficulty with no speed menu row")
	for i in range(20): title.navigate(KEY_UP)
	check(title.phase==22,"up navigation cannot select a hidden speed setting")
	title.navigate(KEY_RIGHT)
	check(title.difficulty==4,"difficulty still changes independently of fixed speed")
	for i in range(3): title.navigate(KEY_DOWN)
	check(title.phase==25 and title.confirm()=="play","all three weapons remain reachable")
	for row in [[3,2],[7,9],[11,7]]:
		var actor = {"kind":row[0],"pos":Vector2(90,101),"velocity":Vector2.ZERO}
		var shots: Array = Fire.burst(actor,Vector2(200,400),row[1],0)
		check(not shots.is_empty() and shots.all(func(s): return s.pos.x==115),"single-port enemy%d emits every bullet from horizontal centre"%row[0])
	var actor = {"kind":22,"pos":Vector2(90,101),"velocity":Vector2.ZERO}
	var prep: Dictionary = Scenery.preparation(actor,{})
	var shots: Array = Fire.burst(actor,Vector2(200,400),2,0)
	check(shots.all(func(s): return s.pos==prep.pos+Vector2(25,25)),"large enemy charge is centred on the actual single projectile port")
	for maximum in [1000,1500,3000]:
		check(not FX.boss_smoking({"hp":maximum*0.4,"max_hp":maximum}),"boss%d at exact40percent has no damage smoke"%maximum)
		check(FX.boss_smoking({"hp":maximum*0.4-0.1,"max_hp":maximum}),"boss%d below40percent emits smoke"%maximum)
	check(not FX.boss_smoking({"hp":0,"max_hp":1000}),"dead boss does not keep lowHP smoke emitter")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(4)
	g.events = []
	g.death_ticks = 1
	g.tick_units = 1
	g.frame = 2
	g.boss = {"stage":4,"pos":Vector2(200,90),"velocity":Vector2.ZERO,"hp":399.0,"max_hp":1000.0}
	g.view.vfx.reset()
	g.view.vfx.observe(g)
	var smoke: Array = g.view.vfx.particles.filter(func(p): return p.smoke)
	check(smoke.size()==6 and smoke.all(func(p): return p.size>=14.4 and p.size<=17.6),"live boss observer uses three large-enemy-size smoke ports")
	check(smoke.any(func(p): return p.p.x<180) and smoke.any(func(p): return p.p.x>220),"boss smoke covers both shoulders rather than a left-biased single port")
	g.boss.clear()
	g.view.vfx.reset()
	var carrier = {"kind":19,"pos":Vector2(150,180),"velocity":Vector2.ZERO,"pattern":1090,"hp":1}
	g.enemies.append(carrier)
	check(Rules.has_cargo(carrier),"unshot open carrier visibly holds its payload")
	var payload: Vector2 = Rules.cargo_position(carrier)
	g._destroy_enemy(carrier)
	check(not Rules.has_cargo(carrier) and carrier.rescued and carrier.kind==201,"shot releases payload and leaves an empty escaping grabber")
	check(g.items.size()==1 and g.items.at(0).pos==payload,"power item starts exactly where it was held")
	check(Supply.released_scale(g.items.at(0))==0.6,"first release frame preserves mounted item size")
	g.frame = 3
	g.view.vfx.observe(g)
	check(g.view.vfx.carrier_releases.size()==1 and g.view.vfx.particles.size()==24,"one visible green release burst is emitted")
	g.frame = 4
	g.view.vfx.observe(g)
	check(g.view.vfx.particles.size()==24,"subsequent frames cannot repeat payload release burst")
	g._update_items()
	check(g.items.at(0).pos.y>payload.y and g.items.at(0).age>0,"released payload falls and grows smoothly from clamp size")
	g._load_stage(1)
	g.events = []
	g.automatic = true
	for i in range(60): g._process(1.0/60.0)
	g.automatic = false
	check(g.frame==60 and is_equal_approx(g.elapsed_units,60*Clock.units_per_tick(1)),"real one-second gameplay stays at native60Hz and fixed level1 speed")
	check(g.view.renewal.enemies.resource_path.ends_with("enemies-v18.png"),"v18 regular enemy atlas is active")
	check(g.view.renewal.bosses.resource_path.ends_with("bosses-v15.png"),"existing mecha boss artwork is retained")
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
