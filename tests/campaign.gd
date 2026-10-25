extends SceneTree
const Game = preload("res://scripts/game.gd")
const Boss = preload("res://scripts/boss.gd")
const Movement = preload("res://scripts/movement.gd")
var checks: int = 0
var failed: int = 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: "+text)
	else:
		failed += 1
		push_error("FAIL: "+text)
func part(kind: int, pos: Vector2 = Vector2.ZERO, pattern: int = 0) -> Dictionary:
	return {"kind":kind,"pos":pos,"pattern":pattern,"velocity":Vector2.ZERO,"hp":200.0}
func body(stage: int) -> Dictionary:
	return {"stage":stage,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0 if stage==4 else 1000.0,"max_hp":1500.0 if stage==4 else 1000.0,"age":0}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	var totals: Array = [0,133,155,178,189]
	var spawn_totals: Array = [0,125,145,169,184]
	var times: Array = [0,116,113,125,121]
	for stage in range(1,5):
		for weapon in range(1,4):
			game._load_stage(stage)
			game.weapon = weapon
			check(game.events.size()==totals[stage],"stage %d weapon %d loads complete event data"%[stage,weapon])
			for i in range(times[stage]*30+500):
				game.invulnerable = 100
				game.hp = 100
				game._tick(Vector2(sin(i*0.012),0),true,i%300==0,i%500==0)
			check(game.event_cursor==totals[stage] and game.stats.spawned==spawn_totals[stage],"stage %d weapon %d consumes all enemy and control events"%[stage,weapon])
			check(game.stats.boss_spawned and game.boss.get("stage",0)==stage,"stage %d weapon %d creates matching boss body"%[stage,weapon])
			check(game.stats.killed>0 and game.stats.hits>0,"stage %d weapon %d combat remains active"%[stage,weapon])
			check(game.bullets.valid() and game.shots.size()<=50 and game.enemies.valid(),"stage %d weapon %d dynamic entity lifecycle remains consistent"%[stage,weapon])
		game._load_stage(stage)
		game.events = game.events.filter(func(row): return int(row[0])==times[stage])
		game.frame = times[stage]*30+1
		game._read_events()
		check(game.boss.max_hp==(1500 if stage==4 else 1000),"stage %d original boss HP"%stage)
		var found: Array = []
		for e in game.enemies:
			if e.kind>=100 and e.kind<200:
				found.append(e.kind)
				Boss.attach(e,game.boss)
				var texture: Texture2D = game.art.enemy(e.kind,e.velocity,0,stage)
				check(texture.get_width()==50,"stage %d part %d extracts original artwork"%[stage,e.kind])
		check(found==[[101,102],[111,112,113],[121,122,123,124],[131,132,133]][stage-1],"stage %d all original boss attachments present"%stage)
	var b: Dictionary = body(2)
	var e: Dictionary = part(113,Vector2(175,401),2201)
	Movement.steer(e,Vector2(170,380),b.pos)
	check(e.pattern==2202 and e.velocity.y== -2,"stage 2 diving unit turns upward below Y=400")
	e.pos.y = 149
	Movement.steer(e,Vector2(170,380),b.pos)
	check(e.pattern==2201 and e.velocity.y==8,"stage 2 diving unit returns at boss-relative Y")
	e = part(123,Vector2(200,150),2203)
	Movement.steer(e,Vector2.ZERO,Vector2(200,100))
	check(e.velocity==Vector2(-2,3),"stage 3 orbit A original acceleration")
	e = part(124,Vector2(200,150),2204)
	Movement.steer(e,Vector2.ZERO,Vector2(200,100))
	check(e.velocity==Vector2(-3,2),"stage 3 orbit B original acceleration")
	e = part(111)
	b.velocity.y = 3
	Boss.attach(e,b)
	check(e.pos==Vector2(226,160),"stage 2 side weapon follows body and vertical speed")
	e = part(133)
	e.hp = 99
	b = body(4)
	Boss.attach(e,b)
	check(e.pos==Vector2(174,150) and e.pattern==2401 and e.velocity.y== -5,"final boss centre weapon detaches below 100 HP")
	Movement.steer(e,Vector2.ZERO,b.pos)
	check(e.velocity.y== -4,"detached centre weapon uses original acceleration")
	b.pos.y = 31
	Boss.steer(b,Vector2(170,380),[])
	check(b.velocity.y== -1,"final body rises after all attachments are gone")
	b.pos.y = 30
	Boss.steer(b,Vector2(170,380),[])
	check(b.velocity.y==0,"final body stops at original Y=30")
	b = body(2)
	check(Boss.fire(b,[part(111)],2,0).is_empty(),"stage 2 body attack waits for attachment destruction")
	var shots: Array = Boss.fire(b,[],2,0)
	check(shots.size()==2 and shots[0].kind==6 and shots[1].kind==7,"stage 2 exposed body launches both energy shot types")
	b = body(3)
	shots = Boss.fire(b,[part(121)],8,0)
	check(shots.size()==2 and shots[0].kind==2 and shots[1].kind==2,"stage 3 body launches dual missiles with wings alive")
	shots = Boss.fire(b,[],5,2)
	check(shots.size()==2 and shots[0].velocity==Vector2(3,7) and shots[1].velocity==Vector2(-3,7),"stage 3 exposed body preserves timer-driven mirrored spread")
	b = body(4)
	shots = Boss.fire(b,[part(131),part(132)],3,0)
	check(shots.size()==2 and shots[0].kind==6 and shots[0].velocity==Vector2(5,0),"stage 4 body uses pixel-modulo side attacks")
	check(Boss.fire(b,[part(131),part(132)],2,0).is_empty(),"stage 4 intact side weapons suppress replacement cannons")
	shots = Boss.fire(b,[part(132)],2,0)
	check(shots.size()==1 and shots[0].pos==Vector2(165,155),"stage 4 destroyed left weapon activates left replacement cannon")
	shots = Boss.fire(b,[],2,0)
	check(shots.size()==3 and shots[2].kind==8,"stage 4 final phase adds accelerating centre missile")
	# Complete the campaign through the same projectile hit and clear/transition paths used in play.
	game._load_stage(1)
	game.weapon = 2
	game.hp = 61
	game.power = 4
	var cumulative: int = 0
	for stage in range(1,5):
		game.boss = body(stage)
		game.boss.hp = 3
		game.enemies.clear()
		game.frame = 0
		game.events = []
		game.shots = [{"pos":Vector2(200,145),"kind":1,"alive":true,"impact_ticks":-1}]
		game._tick(Vector2.ZERO,false,false,false)
		game._tick(Vector2.ZERO,false,false,false)
		check(game.state=="boss_dying" and game.boss_death_ticks==239,"campaign stage %d starts original boss destruction"%stage)
		for i in range(239): game._tick(Vector2.ZERO,false,false,false)
		cumulative += [0,5000,10000,20000,30000][stage]
		if stage<4:
			check(game.state=="loading" and game.score==cumulative,"stage %d clear bonus is awarded after full explosion sequence"%stage)
			game._tick(Vector2.ZERO,false,false,false)
			check(game.stage==stage+1 and game.state=="playing","campaign advances %d -> %d after original loading artwork"%[stage,stage+1])
			check(game.hp==61 and game.power==4 and game.weapon==2 and game.score==cumulative and game.energy==100,"campaign retains original carried state")
			check(game.enemies.is_empty() and game.shots.is_empty() and game.bullets.is_empty() and game.laser_render_ticks==0,"stage load removes stale entities and effects")
		else:
			check(game.stage==4 and game.state=="menu" and game.last_score==65000 and game.score==0,"final boss returns to original Space title with completed score")
	# Stage selection starts a fresh practice run, rather than keeping campaign state.
	game.selected_stage = 3
	game.start_game()
	check(game.stage==3 and game.hp==100 and game.power==1 and game.score==0,"menu stage select starts fresh chosen stage")
	print("RESULT: %d checks, %d failures"%[checks,failed])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failed==0 else 1)
