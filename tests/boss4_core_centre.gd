extends SceneTree
const Core = preload("res://scripts/boss_core_motion.gd")
const Boss = preload("res://scripts/boss.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Movement = preload("res://scripts/movement.gd")
const Fire = preload("res://tests/fixtures/fire_probe.gd")
const Clock = preload("res://scripts/timing.gd")
const Game = preload("res://scripts/game.gd")
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
	var boss: Dictionary = Catalog.create(94,Vector2(120,70))
	var core: Dictionary = Catalog.create(133,Vector2.ZERO)
	core.hp = 200
	Boss.attach(core,boss)
	check(core.pattern==0 and core.pos==boss.pos+Vector2(-26,50),"HP200 remains attached at original chest offset")
	core.hp = 199
	Boss.attach(core,boss)
	check(Core.active(core) and is_equal_approx(core.velocity.x,0/0.03) and core.velocity.y<(0/0.03) and core.velocity.length()<=5.0/0.03+0.0001,"HP199 launches vertically upward before moving to centre")
	var definition: Dictionary = Catalog.definition(133)
	check((Core.target()+definition.draw_offset+definition.draw_size/2)==Vector2(200,240),"target centres actual sprite including drawing offset")
	var before: Vector2 = core.pos
	Movement.steer(core,Vector2.ZERO,boss.pos)
	Core.advance(core,Clock.FIXED_STEP_SECONDS)
	check(core.pos.x==before.x and core.pos.y<before.y and core.velocity.y<(0/0.03),"native60Hz launch rises vertically with deceleration")
	check(core.core_phase=="launch","upward launch remains a separate phase before centre transfer")
	var detached: Vector2 = core.pos
	boss.pos += Vector2(80,40)
	Boss.attach(core,boss)
	check(core.pos==detached,"detached core no longer follows moving boss")
	for i in range(600):
		Movement.steer(core,Vector2.ZERO,boss.pos)
		Core.advance(core,Clock.FIXED_STEP_SECONDS)
		Boss.attach(core,boss)
	check(core.pos==Core.target() and core.velocity==(Vector2.ZERO)/0.03,"core reaches exact centre and remains stationary for ten seconds")
	Core.advance(core,(1000)*0.03)
	check(core.pos==Core.target() and core.velocity==(Vector2.ZERO)/0.03,"large time step cannot overshoot or restart stationary core")
	for start in [Vector2(-20,-20),Vector2(410,490),Vector2(200,400),Core.target()+Vector2(0.001,0.001)]:
		core.pos = start
		Core.detach(core)
		Core.advance(core,(1000)*0.03)
		check(core.pos==Core.target() and core.velocity==(Vector2.ZERO)/0.03,"approach from%s clamps to target without overshoot"%start)
	check(Fire.burst(core,Vector2(175,380),1,0,boss).is_empty(),"settled core stops the travel-phase fireball attack")
	check(Boss.parts_alive([core]),"stationary live core still counts as surviving boss part")
	var other: Dictionary = Catalog.create(132,Vector2.ZERO)
	other.pattern = 2401
	check(not Core.active(other),"native core integration only applies to centre part133")
	for start_y in [8.0,16.0,16.01,30.0,80.0,180.0,400.0,490.0]:
		var probe: Dictionary = Catalog.create(133,Vector2(125,start_y))
		Core.detach(probe)
		var inside := true
		var upward_only := true
		for i in range(360):
			var was_launch: bool = probe.get("core_phase","")=="launch"
			var old_x: float = probe.pos.x
			Core.advance(probe,Clock.FIXED_STEP_SECONDS)
			var top: float = probe.pos.y+definition.draw_offset.y
			var bottom: float = top+definition.draw_size.y
			inside = inside and top>=Core.settings().vertical_margin-0.0001 and bottom<=480-Core.settings().vertical_margin+0.0001
			if was_launch and probe.core_phase=="launch": upward_only = upward_only and probe.pos.x==old_x
		check(inside and upward_only and probe.pos==Core.target(),"launch fromY%s stays wholly onscreen then reaches centre"%start_y)
	var coarse: Dictionary = Catalog.create(133,Vector2(125,180))
	var fine: Dictionary = Catalog.create(133,Vector2(125,180))
	Core.detach(coarse)
	Core.detach(fine)
	Core.advance(coarse,(2.0/0.03)*0.03)
	for i in range(120): Core.advance(fine,Clock.FIXED_STEP_SECONDS)
	check(coarse.pos.distance_to(fine.pos)<0.001 and coarse.core_phase==fine.core_phase,"large step crossing the apex matches120native ticks")
	var apex: Dictionary = Catalog.create(133,Vector2(125,180))
	Core.detach(apex)
	var apex_y: float = 180-pow(float(apex.core_launch_speed),2)/(2*Core.settings().launch_deceleration)
	Core.advance(apex,(float(apex.core_launch_duration)/0.03)*0.03)
	check(is_equal_approx(apex.pos.y,apex_y) and apex.core_phase=="transfer","launch completes at analytic apex before centre transfer")
	Core.advance(apex,(1000)*0.03)
	Core.advance(apex,(1000)*0.03)
	check(apex.core_phase=="settled" and apex.pos==Core.target() and apex.velocity==(Vector2.ZERO)/0.03,"settled core never relaunches")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(4)
	g.delta_seconds = 0.03
	g.events = []
	g.clock = Clock.new()
	g.boss = Catalog.create(94,Vector2(80,80))
	core = Catalog.create(133,Vector2.ZERO)
	core.hp = 199
	g.enemies.append(core)
	g.invulnerability_seconds = 300.0
	for i in range(360): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(core.pos==Core.target() and core.velocity==(Vector2.ZERO)/0.03 and g.enemies.size()==1,"actual game ticks deliver and retain detached core at centre")
	for i in range(60): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(core.pos==Core.target() and core.hp==199 and g.bullets.size()>0,"stationary live core retains health and continues emitting attacks")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
