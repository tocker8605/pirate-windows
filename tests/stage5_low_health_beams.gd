extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const Timeline=preload("res://scripts/beam_timeline.gd")
const Rng=preload("res://scripts/random.gd")
const VFX=preload("res://scripts/combat_vfx.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var owner: Dictionary=Catalog.create(95,Vector2(200,70))
	var spec: Dictionary=Catalog.definition(95).beam_profiles[0]
	for hp in [2401,2400,1201,1200,1199]:
		owner.hp=hp
		check(is_same(Timeline.phase_for(owner,spec),spec.default_phase if hp>2400 else spec.health_phases[1] if hp>1200 else spec.health_phases[0]),"inclusive HP phase threshold")
	owner.hp=1200
	var starts: Array=[[150,170],[210,190]]
	var ends: Array=[[0,320],[360,40]]
	for choice in range(2):
		for age in [0.0,1.999,2.0,3.0,4.0,5.0,5.999]:
			var beams: Array=Beams.sample(owner,spec,age,{},choice)
			check(beams.size()==2,"both selected beams present")
			for i in range(2):
				var progress: float=maxf(0,age-2)/4
				var heading: Vector2=Vector2.UP.rotated(deg_to_rad(lerpf(starts[choice][i],ends[choice][i],progress)))
				check((beams[i].end-beams[i].origin).normalized().distance_to(heading)<0.00001,"selected signed sweep follows its telegraph")
				check(beams[i].damaging==(age>=2) and beams[i].width==(5 if age>=2 else 1),"warning harmless and collision width unchanged")
				if age>=2:check(Beams.hits(beams[i],beams[i].origin+heading*100,4),"collision follows either selected geometry")
	for age in [6.0,12.0,18.0]:check(not Beams.sample(owner,spec,age)[0].damaging,"next prediction begins immediately at attack end")
	check(not Beams.sample(owner,spec,6)[0].damaging,"six-second period restarts prediction")
	check(Beams.advance(owner,0,false).is_empty(),"scroll stop gate remains required")
	Rng.state=0x50000
	var seen: Array=[]
	var repeated: bool=false
	var previous: int=-1
	Beams.advance(owner,0,true)
	for cycle in range(100):
		var choice: int=owner.beam_states.chest_sweep.choice
		seen.append(choice);repeated=repeated or choice==previous;previous=choice
		var rng_state: int=Rng.state
		var warning: Array=Beams.advance(owner,1,true)
		var live: Array=Beams.advance(owner,1,true)
		check(not warning[0].damaging and live[0].damaging,"two-second prediction then attack")
		check((warning[0].end-warning[0].origin).normalized().distance_to((live[0].end-live[0].origin).normalized())<0.00001,"prediction matches attack start")
		check(owner.beam_states.chest_sweep.choice==choice and Rng.state==rng_state,"no reroll between warning and attack")
		var next_warning: Array=Beams.advance(owner,4,true)
		check(next_warning.size()==2 and not next_warning[0].damaging and Rng.state!=rng_state,"four-second attack immediately starts next random prediction")
	check(0 in seen and 1 in seen and repeated,"random choices include both patterns and allow consecutive repeats")
	var transition: Dictionary=Catalog.create(95,Vector2(200,70))
	Beams.advance(transition,0,true);Beams.advance(transition,3,true);transition.hp=1200
	check(Beams.advance(transition,1,true)[0].damaging,"HP crossing preserves current active path")
	var entry: Array=Beams.advance(transition,11,true)
	check(not entry[0].damaging and transition.beam_states.chest_sweep.phase_start==15,"new phase starts at existing cycle boundary")
	check(not Beams.advance(transition,6,true)[0].damaging,"next prediction starts without cooldown")
	check(not Beams.advance(transition,6,true)[0].damaging and transition.beam_states.chest_sweep.phase_start==27,"subsequent cycles use six seconds")
	var other: Dictionary=Catalog.create(95,Vector2(200,70));other.hp=1200
	Beams.advance(other,0,true)
	check(other.beam_states.chest_sweep.age==0 and transition.beam_states.chest_sweep.age==27,"clocks are owner local")
	var skip: Array=Beams.advance(other,26,true)
	check(skip[0].damaging and other.beam_states.chest_sweep.phase_start==24,"long update consumes all crossed cycle boundaries")
	var fx=VFX.new();var peak: int=0
	for frame in range(1200):
		for particle in fx.particles:particle.age+=1.0/60
		fx.particles=fx.particles.filter(func(p):return p.age<p.life)
		fx.emit_enemy_beam_sources(Beams.sample(owner,spec,frame/60.0),1.0/60)
		peak=maxi(peak,fx.particles.size())
	check(peak<40,"particle budget remains bounded")
	for bad in [0,-1,"9",5.99]:
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["95"].beam_attacks[0].health_phases[0].period_seconds=bad
		check(not Catalog.validate_document(doc).is_empty(),"invalid phase duration rejected")
	for bad in [[],null,[[]],[[{"from_degrees":0,"to_degrees":"bad"}]]]:
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["95"].beam_attacks[0].health_phases[0].beam_choices=bad
		check(not Catalog.validate_document(doc).is_empty(),"invalid random choices rejected")
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["95"].beam_attacks[0].health_phases[0].beams=[{"from_degrees":0,"to_degrees":1}]
	check(not Catalog.validate_document(doc).is_empty(),"ambiguous geometry fields rejected")
	check(spec.health_phases[0].beam_choices.is_read_only() and spec.health_phases[0].beam_choices[0].is_read_only() and spec.health_phases[0].beam_choices[0][0].is_read_only(),"random geometry remains immutable")
	owner.hp=0
	check(Beams.sample(owner,spec,2).is_empty(),"destroyed source removes beams immediately")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
