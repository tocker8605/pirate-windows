extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Volleys=preload("res://scripts/projectile_volley.gd")
const Rng=preload("res://scripts/random.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	for spec in [[1,"aim",230],[10,"aim",230],[10,"twin",250],[21,"aim",320],[22,"streak",320],[41,"aim",280]]:
		var actor: Dictionary=Catalog.create(spec[0],Vector2(100,125))
		for target in [Vector2(175,380),Vector2(100.01,125.01),Vector2(0,0)]:
			var shots: Array=Fire.emit(actor,target,spec[1])
			check(not shots.is_empty() and shots.all(func(s):return absf(s.velocity.length()-float(spec[2]))<0.001),"requested speed is independent of target range")
	for id in [1,10]:
		var crescent: Dictionary=Catalog.create(id,Vector2(100,100))
		check(Fire.advance(crescent,0.399).is_empty(),"crescent aim waits full400ms")
		check(Fire.advance(crescent,0.001).size()==1,"crescent aim emits at400ms")
	var descending: Dictionary=Catalog.create(10,Vector2(100,100));descending.velocity.y=200
	check(Fire.advance(descending,0.449).is_empty() and Fire.advance(descending,0.001).size()==2,"crescent downward twins wait450ms")
	for vx in [-200.0,0.1,200.0]:
		var moving: Dictionary=Catalog.create(2,Vector2(100,100));moving.velocity=Vector2(vx,100)
		check(Fire.advance(moving,0.359).is_empty(),"variable wing moving shot waits full360ms")
		check(Fire.advance(moving,0.001)[0].velocity.distance_to(Vector2(-vx,300-absf(vx)))<0.001,"variable wing uses exact300minusabsX vertical formula")
	var pod: Dictionary=Catalog.create(11,Vector2(100,100));pod.velocity=Vector2(120,0)
	var pod_shots: Array=Fire.advance(pod,0.42)
	check(pod_shots.size()==2 and pod_shots[0].velocity.is_equal_approx(Vector2(-48,288)) and pod_shots[1].velocity==Vector2(-40,240),"twin pod beam scales the entire orb velocity by1.2")
	for vx in [-120.0,0.0,120.0]:
		var pair_actor: Dictionary=Catalog.create(11,Vector2(100,100));pair_actor.velocity.x=vx
		var pair: Array=Fire.advance(pair_actor,0.42)
		check(pair[0].velocity.distance_to(pair[1].velocity*1.2)<0.001,"pod twin rays share a direction and beam speed is1.2times orb at any Xspeed")
	var swept: Dictionary=Catalog.create(6,Vector2(100,100));swept.velocity=Vector2(120,100)
	check(Fire.advance(swept,0.24).all(func(shot):return shot.velocity==Vector2(-120,230)),"descending swept-wing keeps X coupling and Y230")
	var cross: Dictionary=Catalog.create(5,Vector2(100,100))
	check(Fire.advance(cross,0.1).all(func(s):return absf(s.velocity.length()-230)<0.001),"opposed spiral uses230px/s")
	var heavy: Dictionary=Catalog.create(41,Vector2(100,100))
	check(Fire.advance(heavy,0.219).is_empty(),"heavyA waits full220ms")
	var pair: Array=Fire.advance(heavy,0.001)
	check(pair.size()==2 and pair.all(func(s):return s.kind==6 and absf(s.velocity.length()-280)<0.001),"heavyA emits both280px/s cannon shots at220ms")
	var ring: Dictionary=Catalog.create(3,Vector2(100,20))
	var before: int=Rng.state
	check(Fire.advance(ring,2).is_empty(),"ring retains strict lowerY gate")
	ring.pos.y=21
	check(Fire.advance(ring,0.119).is_empty(),"ring waits full120ms after gate activation")
	var first: Array=Fire.advance(ring,0.001)
	check(first.size()==1 and first[0].kind==5 and first[0].velocity.distance_to(Vector2(0,240))<0.001,"first ring shot starts at six oclock after any entry duration")
	var start: float=ring.fire_age
	var channel: Dictionary=Catalog.fire_channel(3,"sweep")
	for sample in [[0,0],[0.375,-20],[0.75,0],[1.125,20],[1.5,0]]:
		var shot: Dictionary=Volleys.emit(ring,Vector2.ZERO,channel,{},start+sample[0])[0]
		check(shot.velocity.distance_to(Vector2.DOWN.rotated(deg_to_rad(sample[1]))*240)<0.001,"ring reaches centre and both20degree limits over1.5seconds")
	check(Rng.state==before,"ring trajectory consumes no gameplay random draws")
	var fine: Dictionary=Catalog.create(3,Vector2(100,80))
	var rows: Array=[]
	for tick in range(540):rows.append_array(Fire.advance(fine,1.0/60))
	var coarse: Array=Fire.advance(Catalog.create(3,Vector2(100,80)),9)
	check(rows.size()==75 and coarse.size()==75,"ring keeps120ms cadence across frame sizes")
	for i in range(75):
		check(rows[i].velocity.distance_to(coarse[i].velocity)<0.001,"ring phase follows event time rather than position or frame count")
		check(absf(rows[i].velocity.length()-240)<0.001 and absf(rad_to_deg(Vector2.DOWN.angle_to(rows[i].velocity)))<=20.001,"ring bullets keep fixed speed and bounded angles")
	var upper: Dictionary=Catalog.create(3,Vector2(100,199))
	check(Fire.advance(upper,1).is_empty(),"ring retains strict upperY gate")
	for origin in ["unknown",null,1]:
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["3"].fire_channels[0].volley.clock_origin=origin
		check(not Catalog.validate_document(doc).is_empty(),"invalid oscillation clock basis is rejected")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
