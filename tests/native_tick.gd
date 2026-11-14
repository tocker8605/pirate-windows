extends SceneTree
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
var checks: int = 0
var failures: int = 0
var g: Node
var units: float = Clock.FIXED_STEP_SECONDS
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func reset(stage: int = 1) -> void:
	g._load_stage(stage)
	g.delta_seconds = 0.03
	g.events = []
	g.clock = Clock.new()
	g.fire_cooldown_seconds = 0
	g.invulnerability_seconds = 300.0
func ticks(count: int, firing: bool = false) -> void:
	for i in range(count): g._tick(Vector2.ZERO,firing,false,false,units)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	check(is_equal_approx(units,1.0/60),"60Hz converts each authored30ms metadata unit by5/9")
	for rate in [30,60,144]:
		reset()
		g.automatic = true
		for i in range(rate): g._process(1.0/rate)
		g.automatic = false
		check(g.frame==60 and absf(g.stage_elapsed_seconds-1.0)<0.0001,"one second integrates60 simulation ticks at render rate%d"%rate)
	reset()
	var first: Vector2 = g.player
	for i in range(180): g._tick(Vector2(0.05,0),false,false,false,units)
	check(g.frame==180 and absf(g.player.x-first.x-30)<0.002,"three seconds preserve authored player distance while updating180 times")
	reset(4)
	ticks(1080)
	check(absf(g.background_y-2160)<0.1 and absf(g.scenery_distance-1200)<0.1,"18-second stage4 departure preserves1200px travel with1080 real ticks")
	reset()
	g.delta_seconds = units
	g.bullets.append({"kind":1,"pos":Vector2(50,50),"velocity":(Vector2(3,9))/0.03,"alive":true})
	for i in range(36): g._update_bullets()
	check(g.bullets.size()==1 and g.bullets.at(0).pos.distance_to(Vector2(110,230))<0.001,"enemy bullets preserve travel without integer-rounding drift")
	reset()
	g.delta_seconds = units
	g.shots.replace_all([{"kind":1,"pos":Vector2(100,450),"alive":true,"impact_remaining_seconds":-1}])
	for i in range(18): g._advance_shots()
	check(absf(g.shots.at(0).pos.y-260)<0.001,"player shots preserve190px travel over0.3seconds")
	reset()
	g.delta_seconds = units
	g.boss = {"pos":Vector2(200,50),"velocity":(Vector2(1,2))/0.03,"age":0.0}
	for i in range(18): g._update_boss()
	check(g.boss.pos.distance_to(Vector2(210,70))<0.001,"boss velocity converts proportionally")
	reset()
	g.beam_remaining_seconds = 0.45
	ticks(26)
	check(g.beam_remaining_seconds>0,"beam_remaining_seconds remains active before original450ms duration")
	ticks(1)
	check(g.beam_remaining_seconds<3e-08,"beam_remaining_seconds completes at27 native ticks450ms")
	reset()
	g.shield_remaining_seconds = 6.0
	g.shield_center = Vector2(100,400)
	ticks(360)
	check(g.shield_remaining_seconds==0 and absf(g.shield_center.y-200)<0.01,"shield_remaining_seconds duration6seconds and200px movement both preserved")
	reset()
	g.energy = 0
	ticks(180)
	check(g.energy==25,"energy recovery retains25 points over3seconds without fractional duplicate recoveries")
	reset()
	g.events = [{"at":0.9,"action":"banner","name":"mission"}]
	ticks(54)
	check(g.event_cursor==0,"event at0.9seconds does not trigger early")
	ticks(1)
	check(g.event_cursor==1,"event triggers at the first60Hz tick after900ms")
	reset()
	ticks(180,true)
	check(g.stats.shots==34,"default player firing preserves34 volleys over3seconds")
	reset()
	g.hp = 0
	ticks(432)
	check(g.state=="menu","240-unit death sequence completes after432 native ticks7.2seconds")
	for speed in range(1,6):
		var clock = Clock.new()
		var fires: int = 0
		var actor: Dictionary = {"kind":4,"hp":20,"pos":Vector2(100,100),"velocity":Vector2.ZERO,"pattern":0}
		var scale: float = Clock.FIXED_STEP_SECONDS
		for i in range(600):
			fires += g.EnemyFire.advance(actor,scale,Vector2(175,380)).size()
			clock.finish(true,scale)
		check(fires==int(floor(600*scale/0.3+0.000001)),"speed%d preserves independent300ms enemy cadence without phase wrap"%speed)

	for stage in range(1,5):
		g._load_stage(stage)
		g.delta_seconds = 0.03
		g.clock = Clock.new()
		g.fire_cooldown_seconds = 0
		g.weapon = stage%3+1
		var duration: int = [0,116,113,125,121][stage]*54+900
		for i in range(duration):
			g.invulnerability_seconds = 3.0
			g.hp = 100
			g._tick(Vector2(sin(i*0.012*units/0.03),0),true,i%540==0,i%900==0,units)
		check(g.event_cursor==[0,133,155,178,189][stage] and g.stats.spawned==[0,125,145,169,184][stage],"native60Hz stage%d consumes all authored events"%stage)
		check(g.stats.boss_spawned and g.boss.get("stage",0)==stage and g.stats.killed>0 and g.stats.hits>0,"native60Hz stage%d enemies, boss and combat stay active"%stage)
		check(g.bullets.valid() and g.enemies.valid() and g.shots.size()<=50,"native60Hz stage%d entity lifecycle remains valid"%stage)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
