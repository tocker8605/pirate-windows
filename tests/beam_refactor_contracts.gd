extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Profile=preload("res://scripts/beam_profile.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const Muzzle=preload("res://scripts/beam_muzzle_effect.gd")
const Layers=preload("res://scripts/particle_layers.gd")
const FX=preload("res://scripts/combat_vfx.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH)).entities["95"].beam_attacks[0]
	var prepared: Dictionary=Profile.prepare(raw)
	check(prepared.origin is Vector2 and prepared.color is Color,"beam origin and color are prepared as native values")
	check(prepared.is_read_only() and prepared.beams.is_read_only() and prepared.beams[0].is_read_only(),"prepared beam settings are immutable through nested sweeps")
	check(is_equal_approx(prepared.beams[0].from_radians,deg_to_rad(-10)) and is_equal_approx(prepared.beams[1].to_radians,deg_to_rad(-170)),"signed sweep radians are prepared once")
	var original_origin: Vector2=prepared.origin
	raw.origin[0]+=100;raw.color="#ff0000";raw.beams[0].from_degrees=50
	check(prepared.origin==original_origin and prepared.color!=Color.RED and is_equal_approx(prepared.beams[0].from_radians,deg_to_rad(-10)),"prepared settings do not alias mutable authoring arrays")
	var shared: Dictionary=Catalog.definition(95).beam_profiles[0]
	var actor: Dictionary=Catalog.create(95,Vector2(200,70))
	for tick in range(60):Beams.advance(actor,1.0/60,true)
	check(is_same(shared,Catalog.definition(95).beam_profiles[0]),"beam simulation reuses the catalog-prepared profile")
	var smoke: Dictionary={"smoke":true}
	var general: Dictionary={"smoke":false}
	var beam: Dictionary={"smoke":false,"enemy_beam_effect":true}
	var particles: Array=[smoke,general,beam]
	check(Layers.select_non_smoke(particles,Layers.Layer.ALL)==[general,beam],"all-effects batch keeps particle order")
	check(Layers.select_non_smoke(particles,Layers.Layer.GENERAL)==[general],"general batch excludes beam foreground")
	check(Layers.select_non_smoke(particles,Layers.Layer.BEAM_FOREGROUND)==[beam],"beam foreground contains only beam particles")
	check(Layers.select_non_smoke(particles,Layers.Layer.SMOKE).is_empty(),"smoke does not enter glow/streak batches")
	check(particles==[smoke,general,beam],"layer selection cannot mutate shared particle storage")
	var fx=FX.new()
	var other=FX.new()
	var warning: Array=Beams.sample(actor,shared,0)
	var live: Array=Beams.sample(actor,shared,4)
	var emitters: Array=Muzzle.emitters(live)
	check(emitters.size()==1 and emitters[0].stage==Muzzle.Stage.FIRING,"visual grouping emits one named firing source for both rays")
	check(Muzzle.emitters(warning)[0].stage==Muzzle.Stage.CHARGE,"telegraph maps to the named charge stage")
	fx.emit_enemy_beam_sources(live,1.0/60)
	check(not fx.beam_muzzle.clocks.is_empty() and other.beam_muzzle.clocks.is_empty(),"visual timing belongs to each VFX instance")
	fx.reset();check(fx.beam_muzzle.clocks.is_empty() and fx.particles.is_empty(),"reset clears the dedicated effect clocks and shared pool together")
	for i in range(FX.LIMIT):fx.emit(Vector2.ZERO,Vector2.ZERO,10,1,Color.WHITE)
	fx.emit_enemy_beam_sources(live,1)
	check(fx.particles.size()==FX.LIMIT and fx.particles.all(func(p):return not p.has("enemy_beam_effect")),"dedicated effects respect shared admission limits without relabeling existing particles")
	var authoring: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	check(not authoring.entities["95"].has("beam_profiles"),"prepared runtime fields do not leak into authoring JSON")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
