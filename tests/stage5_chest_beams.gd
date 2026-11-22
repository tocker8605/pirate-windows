extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Muzzle=preload("res://scripts/beam_muzzle_effect.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Shapes=preload("res://scripts/collision_geometry.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
const Actions=preload("res://scripts/combat_actions.gd")
const VFX=preload("res://scripts/combat_vfx.gd")
const Rng=preload("res://scripts/random.gd")
const Game=preload("res://scripts/game.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var owner: Dictionary=Catalog.create(95,Vector2(200,70))
	var spec: Dictionary=Catalog.definition(95).beam_profiles[0]
	check_health_paths(spec)
	for tick in range(300):check(Beams.advance(owner,1.0/60,false).is_empty(),"scrolling cannot advance or show the chest attack")
	var warning: Array=Beams.advance(owner,1.0/60,true)
	check(warning.size()==2 and warning.all(func(b):return not b.damaging and b.width==1),"scroll stop starts two thin solid telegraphs immediately")
	for index in range(2):
		var expected: Vector2=Vector2.UP.rotated(deg_to_rad(-10 if index==0 else 10))
		check((warning[index].end-warning[index].origin).normalized().distance_to(expected)<0.00001,"telegraph points10degrees to either side of12oclock")
		check(not Beams.hits(warning[index],warning[index].origin+expected*100,4),"telegraph never has a damage collider")
	for index in range(2):
		for age in [2.0,3.0,4.0,5.0,5.999]:
			var segments: Array=Beams.sample(owner,spec,age)
			var progress: float=(age-2)/4
			var degrees: float=lerpf(-10,170,progress) if index==0 else lerpf(10,-170,progress)
			check(segments.size()==2 and segments[index].damaging and segments[index].width==5,"2to6seconds has a5px active beam")
			check((segments[index].end-segments[index].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(degrees)))<0.00001,"beam sweeps the requested signed180degree path at constant speed")
	check(Beams.sample(owner,spec,1.999).all(func(b):return not b.damaging),"warning persists until2seconds")
	for age in [6.0,7.0,10.0,14.999]:check(Beams.sample(owner,spec,age).is_empty(),"remaining9seconds is cooldown with no line or damage")
	check(Beams.sample(owner,spec,15).size()==2 and not Beams.sample(owner,spec,15)[0].damaging,"15second cycle restarts with warning")
	var before: float=owner.beam_states.chest_sweep.age
	Beams.advance(owner,1,false)
	check(is_equal_approx(owner.beam_states.chest_sweep.age,before+1),"start gate latches; later scrolling does not reset the attack clock")
	var segment: Dictionary=Beams.sample(owner,spec,4)[0]
	var heading: Vector2=(segment.end-segment.origin).normalized()
	var normal:=Vector2(-heading.y,heading.x)
	var point: Vector2=segment.origin+heading*100
	check(Beams.hits(segment,point+normal*6.4,4),"5px beam includes player radius in its collision")
	check(not Beams.hits(segment,point+normal*6.6,4),"outside the combined6.5px collision radius is safe")
	check(not Beams.hits(segment,segment.origin-heading*20,4),"laser is a forward finite segment, not an infinite line")
	var uv:=Vector2((725.0-97)/1254,(505.0-4)/1072)
	var artwork: Vector2=Geometry.image_point(Catalog.definition(95),owner.pos,uv,Vector2(1254,1072))
	check(segment.origin.distance_to(artwork)<0.001,"beam origin is centred on the blue chest core in the artwork")
	var generic: Dictionary={"hp":10,"pos":Vector2(80,200),"pose_angle":PI/2}
	check((Beams.sample(generic,spec,2)[0].end-Beams.sample(generic,spec,2)[0].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(-10)+PI/2))<0.00001,"beam sampling supports another owner pose without entity IDs")
	var fx=VFX.new()
	var combat_rng: int=Rng.state
	fx.emit_enemy_beam_sources(Beams.sample(owner,spec,0.5),1.0/60)
	check(fx.particles.size()==3 and fx.particles.all(func(p):return p.enemy_beam_stage==Muzzle.Stage.CHARGE),"prediction lines have a smaller stage1charge effect")
	fx.reset()
	var live: Array=Beams.sample(owner,spec,4)
	check(Muzzle.emitters(live).size()==1,"two rays sharing one chest muzzle have one particle emitter")
	fx.emit_enemy_beam_sources(live,1.0/60)
	check(fx.particles.size()==6 and fx.particles.all(func(p):return p.get("enemy_beam_source",false)),"one shared muzzle emits one compact core/spark burst")
	check(fx.particles.all(func(p):return p.p.distance_to(live[0].origin)<3.1),"firing particles originate at the actual chest emitter")
	fx.emit_enemy_beam_sources(live,1.0/60)
	check(fx.particles.size()==6,"particle emission has its own50ms cadence instead of emitting every frame")
	check(Rng.state==combat_rng,"laser particles cannot consume gameplay randomness")
	fx.emit_enemy_beam_sources([],1)
	check(fx.beam_muzzle.clocks.is_empty(),"cooldown removes stale visual emitter clocks")
	fx.reset()
	fx.emit_enemy_beam_sources(live,5)
	check(fx.particles.size()==6,"long frame emits a bounded burst with no particle backlog")
	fx.reset()
	owner.hp=0;fx.emit_enemy_beam_sources(live,1)
	check(fx.particles.is_empty(),"dead laser sources emit no new particles")
	owner.hp=owner.max_hp
	var peak: int=0
	for frame in range(240):
		for particle in fx.particles:particle.age+=1.0/60
		fx.particles=fx.particles.filter(func(p):return p.age<p.life)
		fx.emit_enemy_beam_sources(live,1.0/60)
		peak=maxi(peak,fx.particles.size())
	check(peak<40,"sustained chest firing keeps a small bounded live particle count")
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g._load_stage(5);g.events=[];g.supply_director.schedule.clear();g.invulnerability_seconds=999
	g.boss=Catalog.create(95,Vector2(200,-10));g.scroll_speed=30;g.scroll_target=30
	var frames: int=0
	while g.scroll_speed>0 and frames<300:
		g._tick(Vector2.ZERO,false,false,false);frames+=1
		if g.scroll_speed>0:check(g.enemy_beams.is_empty(),"real game keeps lasers hidden throughout deceleration")
	check(g.scroll_speed==0 and g.enemy_beams.size()==2 and not g.enemy_beams[0].damaging,"real game arms the warning exactly after the floor stops")
	var paused_age: float=g.boss.beam_states.chest_sweep.age
	g.flow.pause(g);g._tick(Vector2.ZERO,false,false,false)
	check(g.boss.beam_states.chest_sweep.age==paused_age,"pausing freezes the beam cycle")
	g.flow.resume(g)
	for frame in range(120):g._tick(Vector2.ZERO,false,false,false)
	check(g.enemy_beams.size()==2 and g.enemy_beams[0].damaging,"real game enables collision after the full2second warning")
	var attacking: Array=Beams.sample(g.boss,spec,5.5)
	var aim: Vector2=(attacking[0].end-attacking[0].origin).normalized()
	g.player=attacking[0].origin+aim*80-Pilot.COCKPIT
	for difficulty in range(1,6):
		g.run_settings=g.run_settings.with_difficulty(difficulty)
		g.hp=100;g.invulnerability_seconds=0;g.enemy_beams=attacking
		Actions.resolve_enemy_beams(g)
		check(g.hp==100-(6+difficulty*6),"laser uses the existing difficulty%d incoming damage"%difficulty)
		var hp: float=g.hp
		Actions.resolve_enemy_beams(g)
		check(g.hp==hp and g.invulnerability_seconds==1.5,"continuous/overlapping beams respect existing hit invulnerability")
	g.hp=100;g.invulnerability_seconds=0
	var telegraph: Array=Beams.sample(g.boss,spec,0)
	g.player=telegraph[0].origin+(telegraph[0].end-telegraph[0].origin).normalized()*80-Pilot.COCKPIT
	g.enemy_beams=telegraph;Actions.resolve_enemy_beams(g)
	check(g.hp==100,"real damage resolver ignores prediction lines")
	var stale_segment: Dictionary=attacking[0]
	g.enemy_beams=attacking;g._damage_boss(g.boss.hp)
	check(g.enemy_beams.is_empty() and not Beams.hits(stale_segment,stale_segment.origin+aim*80,4),"boss death immediately removes hazards and invalidates old segments")
	g._load_stage(1)
	check(g.enemy_beams.is_empty(),"stage transitions clear all beam state")
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["1"].beam_attacks=doc.entities["95"].beam_attacks.duplicate(true)
	doc.entities["1"].beam_attacks[0].gate="immediate"
	check(Catalog.validate_document(doc).is_empty(),"another ordinary enemy may configure the same attack without code changes")
	doc.entities["95"].beam_attacks[0].width=0
	check(not Catalog.validate_document(doc).is_empty(),"zero beam width is rejected")
	doc=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH));doc.entities["95"].beam_attacks[0].period_seconds=5
	check(not Catalog.validate_document(doc).is_empty(),"phase durations exceeding the period are rejected")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)

func check_health_paths(spec: Dictionary) -> void:
	var owner: Dictionary=Catalog.create(95,Vector2(200,70))
	for hp in [2401,2400,2399]:
		owner.hp=hp
		for age in [0.0,1.999,2.0,3.0,4.0,5.999]:
			var progress: float=0 if age<2 else (age-2)/4
			var shots: Array=Beams.sample(owner,spec,age)
			for i in range(2):
				var start: float=([165,195] if hp<=2400 else [-10,10])[i]
				var finish: float=([15,345] if hp<=2400 else [170,-170])[i]
				var expected: Vector2=Vector2.UP.rotated(deg_to_rad(lerpf(start,finish,progress)))
				check((shots[i].end-shots[i].origin).normalized().distance_to(expected)<0.00001,"HP%d uses correct signed sweep at age%.3f"%[hp,age])
				check(shots[i].damaging==(age>=2) and shots[i].width==(5 if age>=2 else 1),"HP change preserves telegraph and collision widths")
	owner.hp=owner.max_hp
	Beams.advance(owner,0,true)
	owner.hp=2400
	var during: Array=Beams.advance(owner,1,true)
	check((during[0].end-during[0].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(-10)))<0.00001,"HP crossing during telegraph does not change the predicted path")
	during=Beams.advance(owner,1,true)
	check((during[0].end-during[0].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(-10)))<0.00001,"active beam follows its original telegraph despite HP change")
	during=Beams.advance(owner,13,true)
	check(not during[0].damaging and (during[0].end-during[0].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(165)))<0.00001,"next15second cycle adopts low-health prediction")
	during=Beams.advance(owner,2,true)
	check(during[0].damaging and (during[0].end-during[0].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(165)))<0.00001,"low-health live beam starts at its predicted six-oclock offset")
	owner.hp=2401
	during=Beams.advance(owner,2,true)
	check((during[0].end-during[0].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(90)))<0.00001,"healing during active sweep cannot jump its path")
	check(spec.health_phases[1].is_read_only() and spec.health_phases[1].beams.is_read_only() and spec.health_phases[1].beams[0].is_read_only(),"low-health paths share immutable prepared settings")
	for ratio in [0,-0.1,1.1,"0.5",null]:
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["95"].beam_attacks[0].health_phases[1].at_or_below_ratio=ratio
		check(not Catalog.validate_document(doc).is_empty(),"invalid low-health threshold is rejected")
	for sweeps in [[],null,[{"from_degrees":0,"to_degrees":"bad"}]]:
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["95"].beam_attacks[0].health_phases[1].beams=sweeps
		check(not Catalog.validate_document(doc).is_empty(),"invalid alternate beam geometry is rejected")
