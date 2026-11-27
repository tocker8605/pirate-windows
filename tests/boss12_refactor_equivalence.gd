extends SceneTree
## Freeze public motion/volleys before cleanup. Do not recapture after refactoring.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Boss=preload("res://scripts/boss.gd")
const Motion=preload("res://scripts/rocket_fist_motion.gd")
const Rng=preload("res://scripts/random.gd")
const PATH="res://tests/fixtures/boss12_before_cleanup.json"
var rows: Array=[]
func volley_rows(scenario: int,tick: int,shots: Array) -> void:
	for s in shots:rows.append(["shot",scenario,tick,s.kind,s.pos.x,s.pos.y,s.velocity.x,s.velocity.y])
func _initialize() -> void:
	for scenario in range(3):
		var body: Dictionary=Catalog.create(91,Vector2(200,80))
		var parts: Array=[Catalog.create(101,Vector2.ZERO),Catalog.create(102,Vector2.ZERO)]
		for tick in range(1000):
			if tick==200:parts.pop_back()
			if tick==400:parts.clear()
			if tick==700:parts=[Catalog.create(101,Vector2.ZERO)]
			body.pos=Vector2(200+20*sin(tick*0.03),80+15*sin(tick*0.02))
			var seconds: float=1.0/60 if scenario==0 else [0.013,0.071,0.4][tick%3] if scenario==1 else 0.03
			volley_rows(scenario,tick,Boss.advance(body,parts,seconds,Vector2(60+tick%280,390)))
	for kind in [101,102]:
		var body: Dictionary=Catalog.create(91,Vector2(200,80))
		var fist: Dictionary=Catalog.create(kind,Vector2(0,-50),2102)
		for tick in range(1600):
			var seconds: float=[1.0/60,0.013,0.071][tick%3]
			var player:=Vector2(-1000 if tick<240 or tick%500<100 else fist.pos.x,400)
			Motion.steer(fist,player,body.pos,seconds)
			body.pos=Vector2(200+30*sin(tick*0.017),80+35*sin(tick*0.02))
			Motion.advance(fist,body,seconds)
			rows.append(["fist",kind,tick,fist.pos.x,fist.pos.y,fist.velocity.x,fist.velocity.y,fist.pattern])
	Rng.state=0x50000
	var second: Dictionary=Catalog.create(92,Vector2(200,80))
	for tick in range(600):volley_rows(92,tick,Boss.advance(second,[],1.0/60,Vector2(100,400)))
	rows.append(["rng",Rng.state])
	if "--capture" in OS.get_cmdline_user_args():
		var output=FileAccess.open(PATH,FileAccess.WRITE);output.store_string(JSON.stringify(rows));output.close()
		print("Captured %d original motion/volley records"%rows.size());quit();return
	var expected: Array=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var failures: int=0 if expected.size()==rows.size() else 1
	for i in range(mini(expected.size(),rows.size())):
		var same: bool=expected[i].size()==rows[i].size()
		for j in range(mini(expected[i].size(),rows[i].size())):
			if expected[i][j] is String:same=same and expected[i][j]==rows[i][j]
			else:same=same and absf(float(expected[i][j])-float(rows[i][j]))<0.0002
		if not same:
			failures+=1
			if failures<=4:push_error("FAIL: record%d changed %s / %s"%[i,expected[i],rows[i]])
	print("RESULT: %d checks, %d failures"%[rows.size()+1,failures]);quit(0 if failures==0 else 1)
