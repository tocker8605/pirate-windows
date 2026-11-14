extends SceneTree
const Game = preload("res://scripts/game.gd")
const Combat = preload("res://scripts/combat.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Clock = preload("res://scripts/timing.gd")
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
	var pos := Vector2(100,300)
	check(Combat.hurts_player(pos,pos+Pilot.COCKPIT),"cockpit centre is vulnerable")
	for point in [Vector2(7,25),Vector2(43,25),Vector2(25,42),Vector2(25,5)]:
		check(not Combat.hurts_player(pos,pos+point),"wing/tail/nose point%s is outside the cockpit hit region"%point)
	check(not Combat.hurts_player(pos,pos+Pilot.COCKPIT+Vector2(4,0)) and Combat.hurts_player(pos,pos+Pilot.COCKPIT+Vector2(3.9,0)),"cockpit radius has strict4px boundary")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(1)
	g.delta_seconds = 0.03
	g.events = []
	g.player = pos
	g.delta_seconds = Clock.FIXED_STEP_SECONDS
	g._bullet(pos+Pilot.COCKPIT-Vector2(0,g.delta_seconds),(Vector2.DOWN)/0.03)
	g._update_bullets()
	check(g.hp==75 and is_equal_approx(g.invulnerability_seconds,1.5),"actual enemy bullet at cockpit causes damage and invulnerability")
	g.hp = 100
	g.invulnerability_seconds = 0
	g._bullet(pos+Vector2(7,25),(Vector2.DOWN)/0.03)
	g._update_bullets()
	check(g.hp==100,"actual enemy bullet at wing does not damage the pilot")
	g.bullets.clear()
	g.player = Vector2(340,430)
	g._bullet(Vector2(100,200),(Vector2(2,-3))/0.03,8)
	for i in range(27): g._update_bullets()
	var apex: float = g.bullets.at(0).pos.y
	for i in range(27): g._update_bullets()
	check(apex<200 and g.bullets.at(0).pos.y>apex and is_equal_approx(g.bullets.at(0).velocity.y,(3/0.03)),"fireball retains upward launch/apex/downward gravitational parabola")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
