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
	check(Combat.beam_hits(e.pos+Vector2(0,60),e),"lower-plane enemy remains vulnerable to beam_remaining_seconds")
	check(is_equal_approx(Depth.scale_for(e),0.8) and is_equal_approx(Depth.tint_for(e).r,0.65),"distant ascent uses80percent size and65percent brightness")
	e.pos.y = 280
	check(is_equal_approx(Depth.scale_for(e),0.9) and is_equal_approx(Depth.tint_for(e).r,0.825),"last60pixels blend scale and brightness smoothly")
	e.pos.y = 250
	check(Depth.scale_for(e)==1 and Depth.tint_for(e)==Color.WHITE,"surface boundary restores full size and brightness")
	e.velocity.y = (-10/0.03)
	Movement.steer(e,Vector2.ZERO,Vector2.ZERO)
	check(absf(e.velocity.y-(-10/0.03+Movement.BASE_ACCELERATION*3/60))<0.001,"movement starts decelerating at the same sharedY250 boundary")
	e = actor(250.001)
	Movement.steer(e,Vector2.ZERO,Vector2.ZERO)
	check(is_equal_approx(e.velocity.y,-10/0.03),"movement retains rapid ascent below the surface boundary")
	e = actor(350,0)
	check(Combat.touches_player(e.pos+Vector2(0,7),e) and Depth.scale_for(e)==1,"same enemy with another pattern keeps ordinary contact and appearance")
	for kind in [201,202]:
		var supply: Dictionary = Catalog.create(kind,Vector2(100,480),1074)
		check(Depth.is_below(supply) and is_equal_approx(Depth.scale_for(supply),0.8) and is_equal_approx(Depth.tint_for(supply).r,0.65),"protected supply%d shares lower-plane scale and brightness"%kind)
		check(not Combat.shot_hits(supply.pos,supply) and not Combat.touches_player(supply.pos+Vector2(0,7),supply),"protected supply%d retains damage and contact exemptions"%kind)
		supply.pos.y = 321
		check(is_equal_approx(Depth.scale_for(supply),0.9),"supply%d rises smoothly over its last60pixels"%kind)
		supply.pos.y = 291
		check(Depth.scale_for(supply)==1 and Depth.tint_for(supply)==Color.WHITE,"supply%d reaches normal size at opening threshold"%kind)
		supply.kind = 19 if kind==201 else 20
		check(not Depth.is_below(supply),"open supply%d returns to normal rendering layer"%kind)
		supply.kind = kind
		supply.rescued = true
		check(Depth.is_below(supply) and is_equal_approx(Depth.scale_for(supply),0.8),"rescued supply%d escapes below the combat plane"%kind)
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.delta_seconds = 0.03
	g.events = []
	g.clock = Clock.new()
	g.title.difficulty = 5
	g.player = Vector2(100,267)
	e = actor(260)
	e.velocity = (Vector2(0,-10))/0.03
	g.enemies.append(e)
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(e.pos.y>250 and g.hp==100 and g.invulnerability_seconds==0,"actual60Hz overlap below boundary causes no damage or invulnerability")
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(e.pos.y<250 and g.hp==64 and is_equal_approx(g.invulnerability_seconds,1.5),"actual60Hz crossing enables normal max-difficulty36contact damage immediately")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
