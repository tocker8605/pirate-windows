extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Muzzle=preload("res://scripts/beam_muzzle_effect.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const FX=preload("res://scripts/combat_vfx.gd")
const Rng=preload("res://scripts/random.gd")
const PATH="res://tests/fixtures/beam_before_visual_refactor.json"
var rows: Array=[]
func _initialize() -> void:
	var owner: Dictionary=Catalog.create(95,Vector2(200,70))
	var spec: Dictionary=Catalog.definition(95).beam_profiles[0]
	var fx=FX.new()
	for tick in range(1200):
		var age: float=tick/60.0
		var beams: Array=Beams.sample(owner,spec,age)
		for beam in beams:rows.append(["beam",tick,beam.origin.x,beam.origin.y,beam.end.x,beam.end.y,beam.width,beam.visual_width,beam.damaging,beam.color.to_html()])
		for particle in fx.particles:
			particle.previous_pos=particle.p
			particle.age+=1.0/60
			particle.p+=particle.v/60
			particle.v*=pow(0.96,33.333333333333336/60)
		fx.particles=fx.particles.filter(func(p):return p.age<p.life)
		fx.emit_enemy_beam_sources(beams,1.0/60)
		for p in fx.particles:rows.append(["particle",tick,p.p.x,p.p.y,p.v.x,p.v.y,p.age,p.life,p.size,p.color.to_html(),p.enemy_beam_stage,p.get("enemy_beam_core",false)])
		rows.append(["rng",tick,str(fx.rng.state),str(Rng.state)])
	if "--capture" in OS.get_cmdline_user_args():
		var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(rows))
		print("Captured %d beam/particle records before refactoring"%rows.size());quit();return
	var reference: Array=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var failed: int=0 if reference.size()==rows.size() else 1
	for i in range(mini(reference.size(),rows.size())):
		var same: bool=reference[i].size()==rows[i].size()
		for j in range(mini(reference[i].size(),rows[i].size())):
			if rows[i][j] is float or rows[i][j] is int:same=same and absf(float(rows[i][j])-float(reference[i][j]))<0.0002
			else:same=same and rows[i][j]==reference[i][j]
		if not same:
			failed+=1
			if failed<6:push_error("FAIL: visual checkpoint%d differs: %s / %s"%[i,reference[i],rows[i]])
	print("RESULT: %d checks, %d failures"%[rows.size()+1,failed]);quit(0 if failed==0 else 1)
