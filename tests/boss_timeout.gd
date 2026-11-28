extends SceneTree
const Game=preload("res://scripts/game.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const Actions=preload("res://scripts/combat_actions.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
const Rng=preload("res://scripts/random.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=Game.new()
	g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.run_settings=g.run_settings.with_boss_rush(true)
	g._load_stage(1);g.events=[];g.supply_director.schedule.clear()
	var timer=g.boss_timeout
	check(timer.remaining()==-1,"deadline is hidden before actual boss spawn")
	for stage in range(1,6):
		timer.start(Catalog.create(90+stage,Vector2(200,80)),stage)
		var limit: int=180 if stage==5 else 90
		check(timer.remaining()==limit,"stage%d has correct boss deadline"%stage)
		check(timer.advance(g.player,limit-0.001).is_empty() and timer.actors.is_empty() and timer.remaining()==1,"deadline cannot activate early")
		timer.advance(g.player,0.001)
		check(timer.remaining()==0 and timer.actors.size()==2,"expiry creates exactly two reapers")
	timer.reset()
	g.events=[{"at":0,"action":"spawn","definition_id":91,"position":[200,-100]}]
	g.event_cursor=0;g.stage_elapsed_seconds=0.01;g._read_events()
	check(is_same(timer.owner,g.boss) and timer.remaining()==90,"actual spawn event arms boss-owned timer")
	var before_rng: int=Rng.state
	check(timer.advance(g.player,90).is_empty(),"appearance phase has no beams")
	for i in range(2):
		check(timer.actors[i].pos==[Vector2(25,125),Vector2(325,125)][i],"reapers use requested top-left positions")
		check(is_equal_approx(timer.actors[i].scale,0.1) and is_equal_approx(timer.actors[i].opacity,0.1),"reapers begin5x5 at10percent opacity")
	timer.advance(g.player,0.75)
	check(timer.actors.all(func(a):return is_equal_approx(a.scale,0.55) and is_equal_approx(a.opacity,0.55)),"appearance size and alpha interpolate together")
	var beams: Array=timer.advance(g.player,0.75)
	check(beams.size()==2 and beams.all(func(b):return not b.damaging and b.visual_width==1),"full-size arrival starts two-second nondamaging telegraph")
	check(timer.actors.all(func(a):return a.scale==1 and a.opacity==1),"appearance completes at50x50 and100percent")
	beams=timer.advance(g.player,1.999)
	check(beams.all(func(b):return not b.damaging),"telegraph lasts entire two seconds")
	beams=timer.advance(g.player,0.001)
	check(beams.all(func(b):return b.damaging and absf(b.visual_width-1)<0.001 and b.width==5),"beam starts firing at2seconds with original5px collision width")
	beams=timer.advance(g.player,0.1)
	check(beams.all(func(b):return absf(b.visual_width-3)<0.001),"beam expands using stage5's200ms envelope")
	beams=timer.advance(g.player,0.1)
	check(beams.all(func(b):return absf(b.visual_width-5)<0.001 and b.color.r>b.color.b),"beam reaches5px with red palette")
	var boss_profile: Dictionary=Catalog.definition(95).beam_profiles[0]
	check(timer.beam_profile.telegraph_seconds==boss_profile.telegraph_seconds and timer.beam_profile.width==boss_profile.width and timer.beam_profile.width_transition_seconds==boss_profile.width_transition_seconds,"reapers inherit stage5 beam timing and width")
	g.player=Vector2(20,30)
	beams=timer.advance(g.player,1000)
	check(beams.size()==2 and beams.all(func(b):return b.damaging and absf(b.visual_width-5)<0.001),"tracking lasers have no expiry or repeated telegraph")
	for i in range(2):
		var target: Vector2=g.player+Pilot.COCKPIT
		var direction: Vector2=(beams[i].end-beams[i].origin).normalized()
		check(direction.dot((target-beams[i].origin).normalized())>0.9999,"each beam tracks current cockpit")
		check(Vector2.UP.rotated(timer.actors[i].pose_angle).dot(direction)>0.9999,"reaper sprite faces its laser target")
	check(Rng.state==before_rng,"deadline, facing and tracking use no gameplay randomness")
	g.shots.append({"pos":Vector2(35,135),"kind":1,"alive":true,"impact_remaining_seconds":-1})
	Actions.resolve_shots(g)
	g.player=Vector2(175,400);g.beam_remaining_seconds=1
	Actions.apply_beam(g)
	check(timer.actors.all(func(a):return a.hp==1) and g.enemies.is_empty(),"reapers are outside all normal attack targets and boss part gates")
	g.enemy_beams=timer.advance(g.player,0.1)
	g.hp=100;g.invulnerability_seconds=0;g.shield_remaining_seconds=6
	Actions.resolve_enemy_beams(g)
	var first_hp: float=g.hp
	check(first_hp<100,"tracking lasers inflict damage even while player shield is active")
	Actions.resolve_enemy_beams(g)
	check(g.hp==first_hp,"overlapping beams preserve normal post-hit invulnerability")
	for i in range(10):
		g.invulnerability_seconds=0
		Actions.resolve_enemy_beams(g)
	check(g.hp<=0,"sustained beam contact can kill the player")
	g.hp=100;g.invulnerability_seconds=0
	var held: Dictionary=g.enemy_beams[0]
	var old_score: int=g.score
	g._damage_boss(10000)
	check(g.boss_defeated and timer.actors.is_empty() and g.enemy_beams.is_empty() and timer.remaining()==-1,"boss death instantly removes reapers, beams and timer")
	check(not Beams.alive(held) and g.explosions.size()==2,"all reapers die with explosions and stale beam references cannot hurt")
	check(g.score-old_score==3000*g.run_settings.difficulty,"reapers add no kill score")
	check(timer.advance(g.player,1000).is_empty(),"defeated boss can never respawn reapers")
	g._load_stage(2);g.events=[];g.supply_director.schedule.clear()
	check(timer.actors.is_empty() and timer.owner.is_empty() and timer.remaining()==-1,"stage transition resets all deadline state")
	g.boss=Catalog.create(92,Vector2(200,80));timer.start(g.boss,2)
	g.flow.state="paused"
	g._tick(Vector2.ZERO,false,false,false,10)
	check(timer.remaining()==90,"pause freezes boss deadline")
	g._load_stage(1);g.events=[];g.supply_director.schedule.clear()
	g.boss=Catalog.create(91,Vector2(200,80));timer.start(g.boss,1)
	timer.elapsed=89.99
	g._tick(Vector2.ZERO,false,false,false)
	check(timer.actors.size()==2 and timer.remaining()==0 and g.enemy_beams.is_empty(),"real game tick crosses deadline into harmless appearance")
	timer.elapsed=93.7
	g.invulnerability_seconds=0
	g._tick(Vector2.ZERO,false,false,false)
	check(g.enemy_beams.size()==2 and g.enemy_beams.all(func(b):return b.damaging) and g.hp<100,"real game tick connects persistent tracking beams to damage")
	g._load_stage(1);g.events=[];g.supply_director.schedule.clear()
	g.boss=Catalog.create(91,Vector2(200,80));timer.start(g.boss,1)
	g._damage_boss(10000)
	check(timer.actors.is_empty() and g.explosions.is_empty(),"early boss defeat never creates reaper explosions")
	g.audio.stop_all()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
