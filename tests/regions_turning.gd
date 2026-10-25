extends SceneTree
const Game = preload("res://scripts/game.gd")
const Regions = preload("res://scripts/background_regions.gd")
const Pose = preload("res://scripts/enemy_pose.gd")
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
	for pair in [[3360,1],[2880,1],[2400,2],[1920,2],[1440,2],[960,3],[480,3],[0,3]]:
		var sample: Dictionary = Regions.sample(pair[0])
		check(sample.near==pair[1] and (sample.near==sample.far or sample.blend==0),"original background boundary %d selects region %d"%pair)
	check(Regions.sample(2640).blend==0.5 and Regions.sample(1200).blend==0.5,"both original 480px connectors blend the two neighboring regions")
	check(is_equal_approx(Regions.source_phase(3102),Regions.source_phase(3582)),"480px loop wrap preserves reusable texture phase")
	for kind in [1,10]:
		var expected: Array = [0,50,100,150] if kind==1 else [2050,2100,2150,2200]
		var velocities: Array = [5,0,-2,-5]
		var frames: Array = []
		for vy in velocities: frames.append(Pose.sprite_x(kind,Vector2(0,vy),0))
		check(frames==expected,"type %d shares the original down/level/pull-up/up frame selector"%kind)
		var pose: Dictionary = Pose.target(kind,Vector2(0,5),0)
		var maximum_step: float = 0
		var compressed: bool = false
		for i in range(10):
			var before: float = pose.pitch
			Pose.advance(pose,kind,Vector2(0,-5),0)
			maximum_step = maxf(maximum_step,absf(pose.pitch-before))
			compressed = compressed or absf(Pose.projection(pose).y)<0.4
		check(is_equal_approx(pose.pitch,PI) and maximum_step<=Pose.TURN_STEP+0.00001 and compressed,"type %d pitches continuously through a visible wing-edge attitude without instant 180deg yaw"%kind)
	check(Pose.sprite_x(7,Vector2(0,1),0)==1550 and Pose.sprite_x(7,Vector2(0,-1),0)==1400,"type7 retains its reversed source-sheet orientation layout")
	for kind in [2,6,7]:
		check(Pose.target(kind,Vector2(0,1),0).pitch==0 and Pose.target(kind,Vector2(0,0),0).pitch==PI,"kind %d preserves original vY>0 versus vY<=0 facing threshold"%kind)
	check(Pose.target(8,Vector2(1,0),0).bank==0 and Pose.target(8,Vector2(2,0),0).bank==1 and Pose.target(8,Vector2(-2,0),0).bank== -1,"type8 uses original strict left/right bank thresholds")
	check(Pose.project(0,0,8).x<Pose.project(0,1,8).x and Pose.project(0,1,8).x==Pose.project(0,-1,8).x,"type8 opens its wing span when banking, matching the original folded-center frames")
	var down_right: Vector2 = Vector2.DOWN.rotated(Pose.bank_yaw(1,1))
	var up_right: Vector2 = Vector2.UP.rotated(Pose.bank_yaw(1,-1))
	check(down_right.x>0 and up_right.x>0 and Pose.bank_yaw(1,0)==0,"right bank leans the nose right in both down/up attitudes and stays level at the wing edge")
	for kind in [3,4,5,9]:
		var values: Array = []
		for cycle in range(4): values.append(Pose.target(kind,Vector2.ZERO,cycle).pulse)
		check(values==[0.0,0.5,1.0,0.5],"type %d retains a four-phase pulse cycle without spinning its whole hull"%kind)
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	for stage in range(1,5):
		game._load_stage(stage)
		game.events = game.events.filter(func(row): return int(row[1])==71)
		var path: Array = []
		for tick in range(1,4200):
			game.frame = tick
			game._read_events()
			game._update_scenery()
			var region: Dictionary = Regions.sample(game.background_y+240,stage)
			var main: int = region.far if region.blend>=0.5 else region.near
			if path.is_empty() or path[-1]!=main: path.append(main)
		check(path==([1,2,3,4] if stage==4 else [1,2,3]),"stage %d follows its original stage-specific region route"%stage)
	game._load_stage(1)
	game.background_y = 3000
	game.scroll_speed = 2
	game.scroll_target = 2
	game.events = [[0,71,2,2,0,0]]
	game.frame = 1
	game._read_events()
	check(Regions.sample(game.background_y).near==1,"region2 command releases the old loop without immediately replacing the viewport")
	for i in range(61): game._update_scenery()
	check(game.background_y==2878 and Regions.sample(game.background_y).near==2 and Regions.sample(game.background_y+480).near==1,"the first connector enters at the top while the bottom still shows region1")
	for i in range(480): game._update_scenery()
	check(Regions.sample(game.background_y).near==2 and Regions.sample(game.background_y+480).near==2,"the complete viewport reaches region2 after crossing its connector")
	game._load_stage(4)
	game.boss_rush = true
	game._load_stage(4)
	check(game.map_mode==1 and game.background_y==3360,"Boss Rush14 retains its original region1 looping start")
	game.boss_rush = false
	game._load_stage(1)
	game.events = []
	var actor := {"kind":1,"pos":Vector2(100,100),"velocity":Vector2(0,5),"pattern":0,"hp":10}
	game.enemies.append(actor)
	game.frame = 1
	game.view.renewal.observe(game)
	var id: int = actor.entity_id
	actor.velocity.y = -5
	for frame in range(2,12):
		game.frame = frame
		game.view.renewal.observe(game)
	check(is_equal_approx(game.view.renewal.poses[id].pitch,PI) and actor.velocity==Vector2(0,-5),"per-entity visual attitude follows velocity without changing its movement")
	game.view.renewal.forget(id)
	check(not game.view.renewal.poses.has(id),"despawn releases the visual pose by stable ID")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	game.audio.stop_all()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
