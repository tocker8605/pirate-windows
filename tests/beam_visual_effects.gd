extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Muzzle=preload("res://scripts/beam_muzzle_effect.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const Style=preload("res://scripts/beam_style.gd")
const FX=preload("res://scripts/combat_vfx.gd")
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
	for pair in [[2.0,1.0],[2.1,3.0],[2.2,5.0],[4.0,5.0],[5.8,5.0],[5.9,3.0],[5.999,1.0003]]:
		var beam: Dictionary=Beams.sample(owner,spec,pair[0])[0]
		check(absf(beam.visual_width-float(pair[1]))<0.002,"visual beam width expands/shrinks within200ms")
		check(beam.width==5 and beam.damaging,"collision remains5px throughout the active phase")
		var direction: Vector2=(beam.end-beam.origin).normalized()
		check(Beams.hits(beam,beam.origin+direction*80+direction.orthogonal()*6.4,4),"visual thinning cannot alter the existing hit width")
	check(Beams.sample(owner,spec,6).is_empty(),"beam disappears after completing the shrink")
	var fx=FX.new()
	var warning: Array=Beams.sample(owner,spec,0.5)
	fx.emit_enemy_beam_sources(warning,1.0/60)
	check(fx.particles.size()==3 and fx.particles.all(func(p):return p.enemy_beam_stage==Muzzle.Stage.CHARGE),"stage1uses charge core and two inward particles")
	var charge_core: Dictionary=fx.particles.filter(func(p):return p.get("enemy_beam_core",false))[0]
	var live: Array=Beams.sample(owner,spec,5.8)
	fx.emit_enemy_beam_sources(live,1.0/60)
	var firing_core: Dictionary=fx.particles.filter(func(p):return p.get("enemy_beam_core",false) and p.enemy_beam_stage==Muzzle.Stage.FIRING)[0]
	check(firing_core.size>charge_core.size*2 and firing_core.size*0.8>=9,"stage2has an opaque core large enough to cover the beam junction")
	check(firing_core.enemy_beam_effect and firing_core.life>=0.1,"muzzle cover is a particle drawn in the beam foreground layer")
	check(firing_core.color==Style.core_color(live[0].color,true),"beam outer edge and stage2 particle edge use the identical shared color")
	check(firing_core.color.r>live[0].color.r and firing_core.color.g>live[0].color.g,"active beam outer edge is brighter than the previous dark blue")
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g._load_stage(5);g.events=[];g.supply_director.schedule.clear();g.boss=owner
	var performance_fx=FX.new()
	var peak: int=0
	for frame in range(240):
		g.frame+=1
		g.enemy_beams=Beams.sample(owner,spec,3.5+float(frame%60)/60)
		performance_fx.observe(g)
		peak=maxi(peak,performance_fx.particles.filter(func(p):return p.get("enemy_beam_effect",false)).size())
	check(peak<40,"sustained muzzle effects retain a bounded live particle count")
	check(performance_fx.particles.all(func(p):return not p.get("enemy_beam_effect",false) or p.get("enemy_beam_source",false)),"beam visuals emit only muzzle particles, with no particles along the ray")
	g.enemy_beams=[]
	for frame in range(20):g.frame+=1;performance_fx.observe(g)
	check(performance_fx.particles.all(func(p):return not p.get("enemy_beam_effect",false)),"cooldown clears both stages promptly")
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
