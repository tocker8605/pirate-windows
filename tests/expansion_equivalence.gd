extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Boss=preload("res://scripts/boss.gd")
const Ground=preload("res://scripts/ground_turret.gd")
const Combat=preload("res://scripts/combat.gd")
const Game=preload("res://scripts/game.gd")
const Rng=preload("res://scripts/random.gd")
const PATH="res://tests/fixtures/expansion_before_refactor.json"
var rows: Array=[]
func volley(label: String,tick: int,shots: Array) -> void:
	for s in shots:rows.append([label,tick,s.kind,s.pos.x,s.pos.y,s.velocity.x,s.velocity.y])
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in Catalog.ids():
		if Catalog.definition(kind).role not in ["enemy","part"]:continue
		for scenario in range(2):
			Rng.state=0x50000
			var e: Dictionary=Catalog.create(kind,Vector2(110+scenario*140,100))
			var boss: Dictionary=Catalog.create(95,Vector2(200,70))
			if Ground.active(e):Ground.initialize(e,0,true,boss)
			for tick in range(600):
				var phase: int=(tick/60)%6
				e.pos.y=[50,100,200,395,80,150][phase]
				e.velocity=Vector2(0 if phase%2==0 else 80,-100+phase*60)
				e.orb_y_stationary=phase%2==0
				e.orb_stationary=phase%2==0
				boss.hp=[3000,2000,1000,2001,800,0][phase]
				if Ground.active(e):e.deployment_progress=1.0
				volley("e%d/%d"%[kind,scenario],tick,Fire.advance(e,[1.0/60,0.013,0.071][tick%3],Vector2(175,380),boss))
	for stage in range(1,6):
		var b: Dictionary=Catalog.create(90+stage,Vector2(200,100))
		var parts: Array=[]
		for id in Catalog.ids():
			if Catalog.is_part(id):parts.append(Catalog.create(id,Vector2.ZERO))
		for tick in range(600):
			if tick==180:parts=[]
			if tick==360:parts=[Catalog.create(111,Vector2.ZERO)]
			b.velocity=Vector2(40,-100+tick%60*4)
			volley("b%d"%stage,tick,Boss.advance(b,parts,[1.0/60,0.013,0.071][tick%3],Vector2(175,380)))
	# Absolute collision samples preserve every existing strict edge convention.
	for kind in Catalog.ids():
		var actor: Dictionary=Catalog.create(kind,Vector2(200,100))
		actor.deployment_progress=1.0
		actor.hatch_enabled=true
		var bits: String=""
		for y in [-40,-25,-24,0,25,59,60,90]:
			for x in range(-140,141,2):bits+="1" if Combat.shot_hits(actor.pos+Vector2(x,y),actor) else "0"
		for x in range(50,351,2):bits+="1" if Combat.beam_hits(Vector2(x,400),actor) else "0"
		rows.append(["collision",kind,bits])
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.run_settings.boss_rush=true
	g._load_stage(5)
	g.supply_director.schedule.clear()
	g.invulnerability_seconds=999
	for tick in range(1200):
		if not g.boss.is_empty():g.boss.hp=3000 if tick<650 else (2000 if tick<800 else 1000)
		g._tick(Vector2.ZERO,false,false,false)
		var row: Array=["world",tick,g.scroll_speed,g.scenery_distance]
		if not g.boss.is_empty():row.append_array([g.boss.pos.x,g.boss.pos.y])
		for e in g.enemies:row.append_array([e.kind,e.pos.x,e.pos.y,e.get("deployment_progress",0),e.get("ground_angle",0)])
		rows.append(row)
		for bullet in g.bullets:rows.append(["bullet",tick,bullet.kind,bullet.pos.x,bullet.pos.y,bullet.velocity.x,bullet.velocity.y])
	g.free()
	if "--capture" in OS.get_cmdline_user_args():
		var f=FileAccess.open(PATH,FileAccess.WRITE)
		f.store_string(JSON.stringify(rows))
		print("Captured %d reference records before refactoring"%rows.size())
		quit()
		return
	var expected: Array=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	# Only the deliberately changed plasma volley rows are replaced by dedicated behavior tests.
	var unchanged_plasma: Callable=func(row):return not (row.size()==7 and str(row[0]).get_slice("/",0) in ["e22","e131","e132"] and row[2]==5)
	expected=expected.filter(unchanged_plasma)
	rows=rows.filter(unchanged_plasma)
	var failures: int=0 if expected.size()==rows.size() else 1
	for i in range(mini(expected.size(),rows.size())):
		var same: bool=expected[i].size()==rows[i].size()
		for j in range(mini(expected[i].size(),rows[i].size())):
			if rows[i][j] is float or rows[i][j] is int:same=same and absf(float(rows[i][j])-float(expected[i][j]))<0.0001
			else:same=same and rows[i][j]==expected[i][j]
		if not same:
			failures+=1
			if failures<=5:push_error("FAIL: expansion reference record%d differs: %s / %s"%[i,expected[i],rows[i]])
	print("RESULT: %d checks, %d failures"%[rows.size()+1,failures])
	quit(0 if failures==0 else 1)
