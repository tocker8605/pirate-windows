extends SceneTree
## Recorded before clock/profile extraction; do not recapture after refactoring.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Beams=preload("res://scripts/beam_attack.gd")
const FX=preload("res://scripts/combat_vfx.gd")
const Ground=preload("res://scripts/ground_turret.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Rng=preload("res://scripts/random.gd")
const PATH="res://tests/fixtures/beam_timing_before_refactor.json"
var rows: Array=[]
func _initialize() -> void:
	for scenario in range(6):
		var owner: Dictionary=Catalog.create(95,Vector2(200,70))
		var fx=FX.new()
		Rng.state=0x50000
		for tick in range(2100):
			match scenario:
				1:owner.hp=2400
				2:owner.hp=1200
				3:owner.hp=3600 if tick<90 else 2400 if tick<960 else 1200
				4:owner.hp=1200 if tick<300 else 2400 if tick<700 else 3600 if tick<1000 else 1200
				5:owner.hp=[2401,2400,1201,1200,1199,3600][(tick/120)%6]
			var dt: float=[1.0/60,0.013,0.071,0.4,1.8][tick%5] if scenario==5 else 1.0/60
			var beams: Array=Beams.advance(owner,dt,tick>=3)
			var clock: Dictionary=owner.get("beam_states",{}).get("chest_sweep",{})
			if not clock.is_empty():rows.append([scenario,tick,"clock",clock.age,clock.cycle,clock.phase_start,bool(clock.phase.get("continuous",false))])
			for beam in beams:rows.append([scenario,tick,"beam",beam.origin.x,beam.origin.y,beam.end.x,beam.end.y,beam.width,beam.visual_width,beam.damaging,beam.age,beam.color.to_html()])
			for p in fx.particles:
				p.age+=dt;p.p+=p.v*dt;p.v*=pow(0.96,33.333333333333336*dt)
			fx.particles=fx.particles.filter(func(p):return p.age<p.life)
			fx.emit_enemy_beam_sources(beams,dt)
			if tick%30==0:
				rows.append([scenario,tick,"rng",str(fx.rng.state),str(Rng.state)])
				for p in fx.particles:rows.append([scenario,tick,"particle",p.p.x,p.p.y,p.v.x,p.v.y,p.age,p.life,p.size,p.color.to_html(),p.enemy_beam_stage,p.get("enemy_beam_core",false)])
	for kind in [145,146]:
		for side in [-1,1]:
			var boss: Dictionary=Catalog.create(95,Vector2(200,70));boss.hp=1000
			var turret: Dictionary=Catalog.create(kind,Vector2(175+side*60,215))
			Ground.initialize(turret,0,true,boss)
			# Compare in the fixture's original downward frame; current12oclock starts have dedicated tests.
			var initial: float=turret.ground_angle
			var center: Vector2=turret.pos+Vector2(25,25)
			for tick in range(900):
				var shots: Array=Fire.advance(turret,[1.0/60,0.013,0.071][tick%3],Vector2(10+tick%300,400),boss)
				rows.append([kind,side,tick,turret.ground_angle-initial,turret.ground_rotation_age])
				for shot in shots:
					var pos: Vector2=center+(shot.pos-center).rotated(-initial)
					var velocity: Vector2=shot.velocity.rotated(-initial)
					rows.append([kind,side,tick,shot.kind,pos.x,pos.y,velocity.x,velocity.y])
	if "--capture" in OS.get_cmdline_user_args():
		var file=FileAccess.open(PATH,FileAccess.WRITE);file.store_string(JSON.stringify(rows))
		print("Captured %d records before clock/profile refactoring"%rows.size());quit();return
	var expected: Array=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var failures: int=0 if expected.size()==rows.size() else 1
	for i in range(mini(rows.size(),expected.size())):
		var same: bool=rows[i].size()==expected[i].size()
		for j in range(mini(rows[i].size(),expected[i].size())):
			# Undoing the intentional180degree start uses float32 Vector2 rotations.
			var tolerance: float=0.001 if rows[i].size()==8 and rows[i][0] in [145,146] and j>=6 else 0.0002
			if rows[i][j] is float or rows[i][j] is int:same=same and absf(float(rows[i][j])-float(expected[i][j]))<tolerance
			else:same=same and rows[i][j]==expected[i][j]
		if not same:
			failures+=1
			if failures<=5:push_error("FAIL: timing record%d changed: %s / %s"%[i,expected[i],rows[i]])
	print("RESULT: %d checks, %d failures"%[rows.size()+1,failures]);quit(0 if failures==0 else 1)
