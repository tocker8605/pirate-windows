extends SceneTree
const Game = preload("res://scripts/game.gd")
const Boss = preload("res://scripts/boss.gd")
const OrbMotion = preload("res://scripts/boss_orb_motion.gd")
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
	return {"stage":stage,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0 if stage==4 else (1500.0 if stage==3 else (1250.0 if stage==2 else 1000.0)),"max_hp":1500.0 if stage==4 else (1500.0 if stage==3 else (1250.0 if stage==2 else 1000.0)),"age":0}
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
			game.delta_seconds = 0.03
			game.weapon = weapon
			check(game.events.size()==totals[stage],"stage %d weapon %d loads complete event data"%[stage,weapon])
			for i in range(times[stage]*30+500):
				game.invulnerability_seconds = 3.0
				game.hp = 100
				game._tick(Vector2(sin(i*0.012),0),true,i%300==0,i%500==0,0.03)
			check(game.event_cursor==totals[stage] and game.stats.spawned==spawn_totals[stage],"stage %d weapon %d consumes all enemy and control events"%[stage,weapon])
			check(game.stats.boss_spawned and game.boss.get("stage",0)==stage,"stage %d weapon %d creates matching boss body"%[stage,weapon])
			check(game.stats.killed>0 and game.stats.hits>0,"stage %d weapon %d combat remains active"%[stage,weapon])
			check(game.bullets.valid() and game.shots.size()<=50 and game.enemies.valid(),"stage %d weapon %d dynamic entity lifecycle remains consistent"%[stage,weapon])
		game._load_stage(stage)
		game.delta_seconds = 0.03
		game.events = game.events.filter(func(row): return is_equal_approx(float(row.at),times[stage]*0.9))
		game.frame = times[stage]*30+1
		game.stage_elapsed_seconds = game.frame*0.03
		game._read_events()
		check(game.boss.max_hp==([0,1000,1250,1500,1500][stage]),"stage %d configured boss HP"%stage)
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
	check(e.pattern==2202 and is_equal_approx(e.velocity.y,-2/0.03),"stage 2 diving unit turns upward below Y=400")
	e.pos.y = 149
	Movement.steer(e,Vector2(170,380),b.pos)
	check(e.pattern==2201 and is_equal_approx(e.velocity.y,8/0.03),"stage 2 diving unit returns at boss-relative Y")
	for id in [123,124]:
		e = part(id,Vector2(100,50))
		OrbMotion.prepare(e,body(3))
		OrbMotion.advance(e,(1000)*0.03)
		check(e.pos==Vector2(75 if id==123 else 275,75) and e.velocity==(Vector2.ZERO)/0.03,"stage3 orb%d reaches fixed upper station"%id)
	e = part(111)
	b.velocity.y = (3/0.03)
	Boss.attach(e,b)
	check(e.pos==Vector2(226,160),"stage 2 side weapon follows body and vertical speed")
	e = part(133)
	e.hp = 199
	b = body(4)
	Boss.attach(e,b)
	check(e.pos==Vector2(174,150) and e.pattern==2401 and is_equal_approx(e.velocity.x,0/0.03) and e.velocity.y<(0/0.03) and e.velocity.length()<=5.0/0.03+0.0001,"final boss centre weapon launches upward below200HP")
	Movement.steer(e,Vector2.ZERO,b.pos)
	check(is_equal_approx(e.velocity.x,0/0.03) and e.velocity.y<(0/0.03) and e.velocity.length()<=5.0/0.03+0.0001,"legacy steering leaves bounded core launch to native integration")
	b.pos.y = 31
	Boss.steer(b,Vector2(170,380),[])
	check(is_equal_approx(b.velocity.y,-1/0.03),"final body rises after all attachments are gone")
	b.pos.y = 30
	Boss.steer(b,Vector2(170,380),[])
	check(is_equal_approx(b.velocity.y,0/0.03),"final body stops at original Y=30")
	b = body(2)
	check(Boss.advance(b,[part(113)],0.09).is_empty(),"stage 2 body waits while centre module survives even without arms")
	var shots: Array = Boss.emit(b,"enrage")
	check(shots.size()==2 and shots[0].kind==5 and shots[1].kind==5,"stage 2 exposed body launches paired pink orbs")
	b = body(3)
	shots = Boss.emit(b,"missiles")
	check(shots.size()==2 and shots[0].kind==2 and shots[1].kind==2,"stage 3 body launches dual missiles with wings alive")
	shots = Boss.emit(b,"left_enrage")+Boss.emit(b,"right_enrage")
	check(shots.size()==8 and shots.all(func(s): return s.kind==6 and is_equal_approx(s.velocity.length(),(9/0.03))),"stage 3 exposed body emits two aimed four-way fans")
	b = body(4)
	shots = Boss.advance(b,[part(131),part(132)],0.01)
	check(shots.is_empty(),"stage4 pixel-modulo body attack is replaced by the independent100ms sweep")
	check(Boss.advance(b,[part(131),part(132)],0.01).is_empty(),"stage 4 intact side weapons suppress replacement cannons")
	shots = Boss.emit(b,"left_replacement")
	check(shots.size()==1 and shots[0].pos==Vector2(165,155),"stage 4 destroyed left weapon activates left replacement cannon")
	shots = Boss.emit(b,"left_replacement")+Boss.emit(b,"right_replacement")+Boss.emit(b,"enrage")
	check(shots.size()==3 and shots[2].kind==8,"stage 4 final phase adds accelerating centre missile")
	# Complete the campaign through the same projectile hit and clear/transition paths used in play.
	game._load_stage(1)
	game.delta_seconds = 0.03
	game.weapon = 2
	game.hp = 61
	game.power = 4
	var cumulative: int = 0
	for stage in range(1,5):
		game.boss = body(stage)
		game.boss.hp = 3
		game.enemies.clear()
		game.frame = 0
		game.stage_elapsed_seconds = game.frame*0.03
		game.events = []
		game.shots.replace_all([{"pos":Vector2(200,145),"kind":1,"alive":true,"impact_remaining_seconds":-1}])
		game._tick(Vector2.ZERO,false,false,false,0.03)
		cumulative += [0,5000,10000,20000,30000][stage]
		check(game.score==cumulative,"stage %d lethal hit immediately grants boss score"%stage)
		game._tick(Vector2.ZERO,false,false,false,0.03)
		check(game.state=="boss_dying" and is_equal_approx(game.boss_death_remaining_seconds,7.17),"campaign stage %d starts original boss destruction"%stage)
		for i in range(239): game._tick(Vector2.ZERO,false,false,false,0.03)
		if stage<4:
			check(game.state=="loading" and game.score==cumulative,"stage %d stage transition preserves already-awarded boss score"%stage)
			game._tick(Vector2.ZERO,false,false,false,0.03)
			check(game.stage==stage+1 and game.state=="playing","campaign advances %d -> %d after original loading artwork"%[stage,stage+1])
			check(game.hp==61 and game.power==4 and game.weapon==2 and game.score==cumulative and game.energy==100,"campaign retains original carried state")
			check(game.enemies.is_empty() and game.shots.is_empty() and game.bullets.is_empty() and game.beam_render_seconds==0,"stage load removes stale entities and effects")
		else:
			check(game.stage==4 and game.state=="menu" and game.last_score==65000 and game.score==0,"final boss returns to original Space title with completed score")
	# Stage selection starts a fresh practice run, rather than keeping campaign state.
	game.selected_stage = 3
	game.start_game()
	game.delta_seconds = 0.03
	check(game.stage==3 and game.hp==100 and game.power==1 and game.score==0,"menu stage select starts fresh chosen stage")
	print("RESULT: %d checks, %d failures"%[checks,failed])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failed==0 else 1)
