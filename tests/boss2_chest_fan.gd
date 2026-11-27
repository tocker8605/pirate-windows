extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Boss=preload("res://scripts/boss.gd")
const Rng=preload("res://scripts/random.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var centre: Dictionary=Catalog.create(113,Vector2.ZERO)
	var owner: Dictionary=Catalog.create(92,Vector2(200,80))
	var player:=Vector2(50,400)
	var random_before: int=Rng.state
	check(Boss.advance(owner,[centre],0.299,player).is_empty(),"chest waits complete300ms")
	var shots: Array=Boss.advance(owner,[centre],0.001,player)
	check(shots.size()==5,"central part enables five-shot fan")
	for i in range(shots.size()):
		var shot: Dictionary=shots[i]
		var expected: Vector2=(player+Pilot.COCKPIT-Vector2(200,128)).normalized().rotated(deg_to_rad(-10+i*5))*240
		check(shot.pos==Vector2(200,128) and shot.kind==5,"small pink orbs originate at chest")
		check(shot.velocity.distance_to(expected)<0.0001,"fan uses muzzle-to-cockpit aim and exact five-degree spacing")
		check(is_equal_approx(shot.velocity.length(),240),"every ray has240px/s speed")
	check(Rng.state==random_before,"aimed fan consumes no gameplay randomness")
	check(Boss.advance(owner,[centre],1.2,player).size()==20,"active window preserves300ms volley cadence")
	check(Boss.advance(owner,[centre],4.5,player).is_empty(),"fan is silent outside1.8second window")
	check(Boss.advance(owner,[centre],0.3,player).size()==5,"six-second cycle resumes at next full interval")
	centre.hp=0
	shots=Boss.advance(owner,[centre],0.3,player)
	check(not shots.is_empty() and shots.all(func(s):return s.pos.x!=200),"dead central part immediately stops chest fan and enables only existing side enrage")
	shots=Boss.advance(Catalog.create(92,Vector2(200,80)),[],6.5,player)
	check(shots.all(func(s):return s.pos.x!=200),"missing centre never allows fan even during next window")
	centre.hp=400
	var fine: Dictionary=Catalog.create(92,Vector2(200,80))
	var fine_shots: Array=[]
	for tick in range(720):fine_shots.append_array(Boss.advance(fine,[centre],1.0/60,player))
	var coarse: Array=Boss.advance(Catalog.create(92,Vector2(200,80)),[centre],12,player)
	check(fine_shots.size()==coarse.size() and fine_shots.size()>0,"frame subdivision preserves firing windows and volley count")
	for i in range(mini(fine_shots.size(),coarse.size())):check(fine_shots[i]==coarse[i],"fine and coarse simulation produce identical trajectories")
	var second: Dictionary=Catalog.create(92,Vector2(200,80))
	check(Boss.advance(second,[centre],0.299,player).is_empty(),"each boss owns an independent timer")
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["92"].fire_channels[1].part_id=999
	check(not Catalog.validate_document(doc).is_empty(),"part_alive rejects unknown reference")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
