extends SceneTree
const Game = preload("res://scripts/game.gd")
const Rng = preload("res://scripts/random.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: "+description)
	else:
		failures += 1
		push_error("FAIL: "+description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Rng.state = 0x50000
	var values: Array = []
	for i in range(10):
		Rng.next_value()
		values.append(Rng.state)
	check(values==[11837123,8949370,9722709,4858052,5065847,12997982,235177,12762824,13664875,11895682],"24-bit generator matches ten independent Microsoft VBMath states")
	Rng.state = 0x50000
	check(Rng.next_value()==11837123.0/16777216.0,"Rnd returns exact normalized Single fraction")
	Rng.state = 0x50000
	var volley: Array = Weapons.volley(Vector2(100,100),3,3)
	check(volley[0].pos==Vector2(113,100) and volley[1].pos==Vector2(111,100),"scatter weapon consumes original default-seed X sequence")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.start_game()
	g.clock.phase = 3
	g.bullets.replace_all([{"slot":3,"kind":1,"pos":Vector2(100,100),"velocity":Vector2.DOWN,"alive":true}])
	Rng.state = 0x50000
	g._enemy_fire({"kind":9,"pos":Vector2(100,100),"velocity":Vector2.ZERO,"hp":10,"pattern":0})
	check(g.bullets.size()==2 and Rng.state==8949370,"crowded storage does not suppress an authored random missile")
	g.bullets.clear()
	g.items.clear()
	g.enemies.clear()
	g.boss = {"stage":4,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0,"age":0}
	g.clock.phase = 1
	Rng.state = 0x50000
	g.BulletPool.body(g)
	check(g.bullets.size()==1 and g.bullets.at(0).pos==Vector2(196,135) and g.bullets.at(0).velocity==Vector2(0,-5),"final missile consumes random muzzle X before horizontal velocity")
	check(Rng.state==8949370,"one final missile consumes exactly two random values")
	g.bullets.replace_all([{"slot":5,"kind":1,"pos":Vector2(100,100),"velocity":Vector2.DOWN,"alive":true}])
	g.clock.phase = 2
	Rng.state = 0x50000
	g.BulletPool.body(g)
	check(g.bullets.size()==4 and Rng.state==4858052,"complete boss volley consumes all four authored random values without slot gating")
	var before: int = Rng.state
	g._load_stage(2)
	check(Rng.state==before,"stage loading does not reseed or consume original Rnd state")
	g.stage = 4
	Rng.state = 0x50000
	g._complete_stage()
	check(g.state=="menu" and Rng.state==11837123,"final clear still consumes original unused loading-picture choice")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	# Audio playback release is asynchronous; let the freed player leave the mixer.
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
