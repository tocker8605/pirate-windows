extends SceneTree
const Depth = preload("res://scripts/enemy_depth.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Combat = preload("res://scripts/combat.gd")
const Movement = preload("res://scripts/movement.gd")
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func actor(y: float, pattern: int = 1071) -> Dictionary:
	return Catalog.create(9,Vector2(100,y),pattern)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for y in [480.0,310.0,260.0,250.001]:
		var e: Dictionary = actor(y)
		check(Depth.is_below(e) and not Combat.touches_player(e.pos+Vector2(0,7),e),"1071 overlap before Y250 is safe atY%s"%y)
	for y in [250.0,249.999,200.0]:
		var e: Dictionary = actor(y)
		check(not Depth.is_below(e) and Combat.touches_player(e.pos+Vector2(0,7),e),"contact activates at and above Y250: Y%s"%y)
	var e: Dictionary = actor(350)
	check(Combat.shot_hits(e.pos+Vector2(25,25),e),"lower-plane enemy remains vulnerable to player bullets")
	check(Combat.beam_hits(e.pos+Vector2(0,60),e),"lower-plane enemy remains vulnerable to laser")
	check(is_equal_approx(Depth.scale_for(e),0.8) and is_equal_approx(Depth.tint_for(e).r,0.65),"distant ascent uses80percent size and65percent brightness")
	e.pos.y = 280
	check(is_equal_approx(Depth.scale_for(e),0.9) and is_equal_approx(Depth.tint_for(e).r,0.825),"last60pixels blend scale and brightness smoothly")
	e.pos.y = 250
	check(Depth.scale_for(e)==1 and Depth.tint_for(e)==Color.WHITE,"surface boundary restores full size and brightness")
	e.velocity.y = -10
	Movement.steer(e,Vector2.ZERO,Vector2.ZERO)
	check(e.velocity.y== -7,"movement starts decelerating at the same sharedY250 boundary")
	e = actor(250.001)
	Movement.steer(e,Vector2.ZERO,Vector2.ZERO)
	check(e.velocity.y== -10,"movement retains rapid ascent below the surface boundary")
	e = actor(350,0)
	check(Combat.touches_player(e.pos+Vector2(0,7),e) and Depth.scale_for(e)==1,"same enemy with another pattern keeps ordinary contact and appearance")
	var supply: Dictionary = Catalog.create(201,Vector2(100,350),1074)
	check(not Depth.is_below(supply) and Depth.scale_for(supply)==1 and not Combat.touches_player(supply.pos+Vector2(0,7),supply),"1074 supply retains normal appearance and its separate contact exemption")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.events = []
	g.clock = Clock.new()
	g.title.difficulty = 5
	g.player = Vector2(100,267)
	e = actor(260)
	e.velocity = Vector2(0,-10)
	g.enemies.append(e)
	g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(e.pos.y>250 and g.hp==100 and g.invulnerable==0,"actual60Hz overlap below boundary causes no damage or invulnerability")
	g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
	check(e.pos.y<250 and g.hp==50 and g.invulnerable==50,"actual60Hz crossing enables normal max-difficulty50contact damage immediately")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
