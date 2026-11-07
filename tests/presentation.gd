extends SceneTree
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
const Boss = preload("res://scripts/boss.gd")
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
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(1)
	var p = g.presentation
	g.player = Vector2(100,300)
	g.background_y = 2881
	g.clouds = [Vector2(30,40),Vector2(10,470)]
	p.capture(g)
	g.frame += 1
	g.player += Vector2(10,-6)
	g.background_y = 3359
	g.clouds = [Vector2(32,44),Vector2(160,-400)]
	p.alpha = 0.5
	check(p.player(g)==Vector2(105,297) and g.player==Vector2(110,294),"player interpolation does not mutate simulation")
	check(p.background(g)==2880,"background wrap follows forward travel across loop boundary")
	g.map_mode = 2
	g.background_y = 2879
	check(p.background(g)==2880,"released loop crosses boundary without rewrapping")
	check(p.cloud(g,0)==Vector2(31,42),"cloud speed changes interpolate")
	check(p.cloud(g,1)==g.clouds[1],"recycled clouds snap rather than crossing the screen")
	check(p.position({"previous_pos":Vector2(4,8),"pos":Vector2(8,12)})==Vector2(6,10),"entity motion interpolates")
	check(p.position({"pos":Vector2(20,40)})==Vector2(20,40),"new entity has no stale interpolation")
	g.shield_center = Vector2(150,350)
	check(p.shield(g)==g.shield_center,"new shield starts at the current anchor")
	g.state = "paused"
	p.refresh(g)
	check(p.alpha==0.5,"pause freezes presentation")
	p.reset(g)
	check(p.alpha==1 and p.sample_frame==-1 and p.player(g)==g.player,"stage reset clears stale presentation")
	check(is_equal_approx(Clock.interval(1),1.0/60.0),"default simulation runs one tick per16.667ms")
	check(Engine.max_fps==60,"render frame cap is60")
	var pilot = g.view.pilot
	check(pilot.frames.size()==3 and pilot.texture(0)==pilot.frames[0] and pilot.texture(1)==pilot.frames[1] and pilot.texture(2)==pilot.frames[1],"hero neutral/left/right frames use observed bank direction")
	check(pilot.frames[0].region.size==pilot.frames[1].region.size and pilot.frames[1].region.size==pilot.frames[2].region.size,"hero frames share crop size and pivot")
	for pair in [[112,111],[121,122],[131,132]]:
		for vy in [-7,0,3]:
			var b = {"pos":Vector2(200,50),"velocity":Vector2(0,vy)}
			var left = {"kind":pair[0],"pos":Vector2.ZERO}
			var right = {"kind":pair[1],"pos":Vector2.ZERO}
			Boss.attach(left,b)
			Boss.attach(right,b)
			check(left.pos.x+25-200==-(right.pos.x+25-200) and left.pos.y==right.pos.y,"boss %d/%d attachment symmetry at vy%d"%[pair[0],pair[1],vy])
		check(g.view.renewal.enemy_texture(pair[0])==g.view.renewal.enemy_texture(pair[1]) and Boss.part_side(pair[0])==-1 and Boss.part_side(pair[1])==1,"paired parts share canonical artwork and opposite handedness")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
