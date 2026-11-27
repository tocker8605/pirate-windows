extends SceneTree
const Geometry=preload("res://scripts/entity_geometry.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Motion=preload("res://scripts/rocket_fist_motion.gd")
const Movement=preload("res://scripts/movement.gd")
const Boss=preload("res://scripts/boss.gd")
const Game=preload("res://scripts/game.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var body: Dictionary=Catalog.create(91,Vector2(200,80))
	var parts: Array=[Catalog.create(101,Vector2.ZERO),Catalog.create(102,Vector2.ZERO)]
	for id in [101,102]:
		var fist: Dictionary=Catalog.create(id,Vector2(0,-50),2102)
		for tick in range(300):
			Movement.steer(fist,Vector2(-1000,400),body.pos,1.0/60)
			Motion.advance(fist,body,1.0/60)
		check(fist.fist_phase==Motion.Phase.DOCKED and fist.pos==Motion.dock(fist,body.pos) and fist.velocity==Vector2.ZERO,"both spawn patterns enter their correct arm socket before launching")
		body.pos+=Vector2(13,-7)
		Movement.steer(fist,Vector2(-1000,400),body.pos,1.0/60);Motion.advance(fist,body,1.0/60)
		check(fist.pos==Motion.dock(fist,body.pos),"docked fist follows exact moving socket without oscillation")
		Movement.steer(fist,Vector2(fist.pos.x+40,400),body.pos,1.0/60)
		check(fist.fist_phase==Motion.Phase.DOCKED,"40px launch boundary remains strict")
		Movement.steer(fist,Vector2(fist.pos.x+39.9,400),body.pos,1.0/60)
		check(fist.fist_phase==Motion.Phase.LAUNCHING and fist.velocity.y>0,"matching playerX launches only a docked fist")
		fist.pos.y=440;Movement.steer(fist,Vector2(-1000,400),body.pos,1.0/60)
		check(fist.fist_phase==Motion.Phase.LAUNCHING,"Y440 does not begin return until exceeded")
		fist.pos.y=440.1;Movement.steer(fist,Vector2(fist.pos.x,400),body.pos,1.0/60)
		check(fist.fist_phase==Motion.Phase.RETURNING and fist.velocity.y<0,"Y greater than440 begins return even if player remains aligned")
		var docked: bool=false
		for tick in range(300):
			body.pos.y=80+10*sin(tick/60.0)
			Movement.steer(fist,Vector2(fist.pos.x,400),body.pos,1.0/60)
			Motion.advance(fist,body,1.0/60)
			if fist.fist_phase==Motion.Phase.DOCKED:docked=true;break
		check(docked and fist.pos==Motion.dock(fist,body.pos) and fist.velocity==Vector2.ZERO,"return clamps exactly into moving socket before any relaunch")
		fist.pos.y+=1;fist.velocity=Vector2(0,-333);fist.fist_phase=Motion.Phase.RETURNING
		Motion.advance(fist,body,0.5)
		check(fist.fist_phase==Motion.Phase.DOCKED and fist.pos==Motion.dock(fist,body.pos),"long return step cannot overshoot the socket")
		var definition: Dictionary=Catalog.definition(id)
		var coupling: Vector2=Geometry.image_point(definition,fist.pos,Vector2(0.62,0.06))
		check(coupling.distance_to(body.pos+Vector2(-44 if id==101 else 44,46))<0.0001,"painted rear coupling, rather than fist image centre, aligns with socket")
		fist.pos=Motion.dock(fist,body.pos)+Vector2(0,0.5);fist.velocity=Vector2(0,-100);fist.fist_phase=Motion.Phase.RETURNING
		Movement.steer(fist,Vector2(-1000,400),body.pos,1.0/60)
		body.pos.y+=2
		Motion.advance(fist,body,1.0/60)
		check(fist.fist_phase==Motion.Phase.DOCKED and fist.pos==Motion.dock(fist,body.pos),"socket crossing caused by parent motion cannot be missed")
		fist.pos.y-=5;fist.velocity=Vector2(0,-300);fist.fist_phase=Motion.Phase.RETURNING
		Motion.advance(fist,body,1.0/60)
		check(fist.pos==Motion.dock(fist,body.pos),"returning fist above socket is clamped immediately instead of keeping upward inertia")
		fist.fist_phase=Motion.Phase.LAUNCHING;fist.velocity=Vector2(0,8)
		body.pos.y+=2;Motion.advance(fist,body,1.0/60)
		check(fist.pos.y>=Motion.dock(fist,body.pos).y,"descending body cannot overtake a newly launched fist")
	var base: Dictionary=Catalog.create(91,Vector2(200,80))
	# Twenty-four seconds cover three complete normal sweep periods.
	var batches: Array=Boss.advance(base,parts,24)
	for i in range(0,batches.size(),2):
		var left: Dictionary=batches[i];var right: Dictionary=batches[i+1]
		check(left.pos.distance_to(Vector2(193,99.3))<0.0001 and right.pos.distance_to(Vector2(207,99.3))<0.0001,"both eye ends fire on each interval")
		check(is_equal_approx(left.velocity.length(),250) and is_equal_approx(right.velocity.length(),250),"both projectiles keep constant250px/s speed")
		check(absf(left.velocity.x+right.velocity.x)<0.0001 and absf(left.velocity.y-right.velocity.y)<0.0001,"paired trajectories stay mirror symmetric through eight-second swing")
		var degrees: float=rad_to_deg(Vector2.DOWN.angle_to(left.velocity))
		check(degrees>=-30.001 and degrees<=60.001,"left sweep stays in requested-30to60degree range")
	# Normal0.3second cadence reaches a half-cycle endpoint at t12.
	var at12: Dictionary=batches[78]
	check(absf(rad_to_deg(Vector2.DOWN.angle_to(at12.velocity))-60)<0.0001,"half-cycle reaches requested60degree endpoint")
	for target in [Vector2(20,400),Vector2(340,300),Vector2(175,440)]:
		var revolving_body: Dictionary=Catalog.create(91,Vector2(200,80))
		check(Boss.advance(revolving_body,[],0.119,target).is_empty(),"enrage waits full120ms interval")
		var volley: Array=Boss.advance(revolving_body,[],0.001,target)
		check(volley.size()==2 and volley.all(func(s):return s.velocity==Vector2(0,250)),"enrage begins downwards independent of target position")
		volley=Boss.advance(revolving_body,[],0.12,target)
		for i in range(2):
			var expected: Vector2=Vector2.DOWN.rotated(TAU*0.12/4*(-1 if i==0 else 1))*250
			check(volley[i].velocity.distance_to(expected)<0.0001,"left rotates counterclockwise and right clockwise with four-second period")

	var entered: Dictionary=Catalog.create(91,Vector2(200,80))
	Boss.advance(entered,parts,2.7)
	var initial: Array=Boss.advance(entered,[],0.12,Vector2(0,400))
	check(initial.size()==2 and initial.all(func(shot):return shot.velocity==Vector2(0,250)),"normal-phase elapsed time cannot shift initial enrage direction")
	var start: float=entered.fire_age
	for elapsed in [1.0,2.0,3.0,4.0]:
		var rotated: Array=Boss.emit(entered,"eye_revolving",Vector2(350,400),start+elapsed)
		for i in range(2):
			var expected: Vector2=Vector2.DOWN.rotated(TAU*elapsed/4*(-1 if i==0 else 1))*250
			check(rotated[i].velocity.distance_to(expected)<0.0001,"quarter-turn samples and full four-second revolution keep exact directions")
	var fine_body: Dictionary=Catalog.create(91,Vector2(200,80))
	var stepped: Array=[]
	for tick in range(600):stepped.append_array(Boss.advance(fine_body,[],1.0/60))
	var caught_up: Array=Boss.advance(Catalog.create(91,Vector2(200,80)),[],10)
	check(stepped.size()==caught_up.size(),"continuous rotation preserves volley count across frame subdivision")
	for i in range(mini(stepped.size(),caught_up.size())):check(stepped[i].velocity.distance_to(caught_up[i].velocity)<0.0001,"continuous rotation uses event time independently of frame size")
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["91"].fire_channels[0].volley.period_seconds=0
	check(not Catalog.validate_document(doc).is_empty(),"invalid sweep period rejected")
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g);await process_frame;g.set_process(false)
	g._load_stage(1);g.events=[];g.supply_director.schedule.clear();g.invulnerability_seconds=999
	g.boss=Catalog.create(91,Vector2(200,80));g.enemies.replace_all(parts);g.player=Vector2(-10,440)
	for tick in range(240):g._tick(Vector2.ZERO,false,false,false)
	for fist in g.enemies:
		check(fist.fist_phase==Motion.Phase.DOCKED and fist.pos==Motion.dock(fist,g.boss.pos),"actual game integration leaves untriggered fists docked on moving body")
	var returns: int=0
	for tick in range(1200):
		var left_fist: Dictionary=g.enemies.at(0)
		g.player.x=left_fist.pos.x
		var before: int=left_fist.fist_phase
		g._tick(Vector2.ZERO,false,false,false)
		if before==Motion.Phase.RETURNING and left_fist.fist_phase==Motion.Phase.DOCKED:returns+=1
		for fist in g.enemies:
			check(fist.pos.y>=Motion.dock(fist,g.boss.pos).y-0.0001,"repeated launches never put a fist above the moving coupling")
	check(returns>=2,"moving-body integration completes repeated launch and docking cycles")
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
