extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const VFX=preload("res://scripts/combat_vfx.gd")
const Timeline=preload("res://scripts/beam_timeline.gd")
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
		var selected: Dictionary=Timeline.phase_for(owner,spec)
		check(is_same(selected,spec.default_phase if hp>2400 else spec.health_phases[1] if hp>1200 else spec.health_phases[0]),"HP%d selects correct inclusive health phase"%hp)
	owner.hp=1200
	for age in [0,0.5,1.999]:
		var warning: Array=Beams.sample(owner,spec,age)
		check(warning.size()==2 and warning.all(func(b):return not b.damaging and b.width==1),"continuous phase has full two-second harmless warning")
		for i in range(2):check((warning[i].end-warning[i].origin).normalized().distance_to(Vector2.UP.rotated(deg_to_rad(165+30*i)))<0.00001,"V prediction remains at minus/plus15degrees from six oclock")
	for frame in range(1801):
		var age: float=2+frame/60.0
		var live: Array=Beams.sample(owner,spec,age)
		var offset: float=30*sin(TAU*(age-2)/8)
		check(live.size()==2 and live.all(func(b):return b.damaging and b.width==5),"continuous phase has no old four-second cutoff or15second reset")
		var a: Vector2=(live[0].end-live[0].origin).normalized()
		var b: Vector2=(live[1].end-live[1].origin).normalized()
		check(absf(angle_difference(a.angle(),b.angle())-deg_to_rad(30))<0.00001,"V opening remains30degrees")
		check(a.distance_to(Vector2.UP.rotated(deg_to_rad(165+offset)))<0.00001,"V smoothly follows eight-second plus/minus30degree swing")
		if age>=2.2:check(is_equal_approx(live[0].visual_width,5),"sustained beam never shrinks at old cooldown boundaries")
		check(Beams.hits(live[0],live[0].origin+a*100,4),"collision follows the moving beam")
	var clock_owner: Dictionary=Catalog.create(95,Vector2(200,70))
	clock_owner.hp=1200
	check(Beams.advance(clock_owner,0,false).is_empty(),"continuous phase still waits for scenery to stop")
	Beams.advance(clock_owner,0,true)
	check(not Beams.advance(clock_owner,1.999,true)[0].damaging,"runtime warning lasts two seconds")
	check(Beams.advance(clock_owner,0.001,true)[0].damaging,"runtime starts damage exactly after warning")
	var after: Array=Beams.advance(clock_owner,30,true)
	check(after[0].damaging and clock_owner.beam_states.chest_sweep.phase_start==0,"continuous runtime never restarts telegraph at15or30seconds")
	var transition: Dictionary=Catalog.create(95,Vector2(200,70))
	Beams.advance(transition,0,true);Beams.advance(transition,3,true);transition.hp=1200
	check(Beams.advance(transition,1,true)[0].damaging,"HP crossing does not replace an active predicted path")
	var entry: Array=Beams.advance(transition,11,true)
	check(not entry[0].damaging and transition.beam_states.chest_sweep.phase_start==15,"next cycle enters continuous pattern with fresh warning")
	check(Beams.advance(transition,2,true)[0].damaging,"transition warning finishes before sustained damage")
	var fx=VFX.new();var peak: int=0
	for frame in range(1800):
		for particle in fx.particles:particle.age+=1.0/60
		fx.particles=fx.particles.filter(func(p):return p.age<p.life)
		fx.emit_enemy_beam_sources(Beams.sample(owner,spec,2+frame/60.0),1.0/60)
		peak=maxi(peak,fx.particles.size())
	check(peak<40,"continuous muzzle particles remain bounded during extended firing")
	for bad in [0,-1,"8"]:
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["95"].beam_attacks[0].health_phases[0].swing.period_seconds=bad
		check(not Catalog.validate_document(doc).is_empty(),"invalid swing period rejected")
	owner.hp=0
	check(Beams.sample(owner,spec,20).is_empty(),"destroyed body ends continuous beam immediately")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
