extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Boss=preload("res://scripts/boss.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
const Rng=preload("res://scripts/random.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func body() -> Dictionary:return Catalog.create(95,Vector2(200,70))
func parts(ids: Array) -> Array:return ids.map(func(id):return Catalog.create(id,Vector2.ZERO))
func _initialize() -> void:
	var player:=Vector2(125,390)
	var b: Dictionary=body()
	check(b.hp==3600 and b.max_hp==3600,"stage5 body has3600HP")
	b.hp=1440
	check(not Catalog.smoking(b),"damage smoke stays off at exactly40percentHP")
	b.hp=1439
	check(Catalog.smoking(b),"damage smoke starts below40percent of3600HP")
	b.hp=b.max_hp
	var origin: Vector2=b.pos+Vector2(0.079745,46.735075)
	for target in [player,Vector2(200,50),origin-Pilot.COCKPIT+Vector2(0.01,-0.01)]:
		var fan: Array=Boss.emit(b,"chest_fan",target)
		check(fan.size()==5,"chest fan contains five shots")
		for i in range(5):
			check(fan[i].pos.is_equal_approx(origin) and fan[i].kind==3 and is_equal_approx(fan[i].velocity.length(),250.0),"existing long streak originates in chest at250px/s")
			check(absf(angle_difference((target+Pilot.COCKPIT-origin).angle(),fan[i].velocity.angle())-deg_to_rad(-6+i*3))<0.0001,"fan aims from muzzle to cockpit with three-degree spacing")
	var intact: Array=parts([141,142,143,144,145,146])
	check(Boss.advance(body(),intact,0.399,player).is_empty(),"chest waits first400ms interval")
	b=body()
	var fine: Array=[]
	for frame in range(600):fine.append_array(Boss.advance(b,intact,1.0/60,player))
	var coarse: Array=Boss.advance(body(),intact,10,player)
	check(fine==coarse and fine.size()==40,"native and catchup preserve two five-second burst/rest cycles")
	b=body()
	Boss.advance(b,intact,2,player)
	check(Boss.advance(b,intact,3,player).is_empty(),"chest remains silent during cooldown")
	for side in range(2):
		var name: String="left_hinge_ring" if side==0 else "right_hinge_ring"
		var sign: int=-1 if side==0 else 1
		var required: Array=[141,143] if side==0 else [142,144]
		for survivor in required:
			var shots: Array=Boss.advance(body(),parts([survivor]),0.8,player)
			check(shots.filter(func(s):return s.kind==6 and s.pos.x==200+32*sign).is_empty(),"either surviving arm or wing suppresses its hinge")
		b=body()
		var first: Array=Boss.emit(b,name,player)
		var second: Array=Boss.emit(b,name,player)
		check(first.size()==30 and second.size()==30,"hinge emits thirty bullets covering360degrees")
		for i in range(30):
			check(first[i].kind==6 and first[i].pos==b.pos+Vector2(sign*32,37) and is_equal_approx(first[i].velocity.length(),200.0),"pink straight bullet at correct hinge and200px/s")
			check(absf(angle_difference(first[i].velocity.angle(),second[i].velocity.angle())-deg_to_rad(sign))<0.0001,"each volley rotates one degree in requested direction")
			check(absf(angle_difference(first[i].velocity.angle(),first[(i+1)%30].velocity.angle())-deg_to_rad(12))<0.0001,"ring spacing is twelve degrees")
	b=body()
	Boss.emit(b,"left_hinge_ring",player)
	Boss.emit(b,"left_hinge_ring",player)
	var fresh_right: Array=Boss.emit(b,"right_hinge_ring",player)
	check(fresh_right[0].velocity.is_equal_approx(Vector2(0,200)),"left shots never advance right rotation")
	b=body()
	Boss.advance(b,intact,3,player)
	check(Boss.advance(b,parts([142,144]),0.799,player).filter(func(s):return s.kind==6).is_empty(),"destroyed pair starts fresh800ms timer without banking")
	check(Boss.advance(b,parts([142,144]),0.001,player).filter(func(s):return s.kind==6).size()==30,"one destroyed pair enables only its own ring")
	var fine_rings: Array=[]
	b=body()
	for frame in range(480):fine_rings.append_array(Boss.advance(b,[],1.0/60,player).filter(func(s):return s.kind==6))
	var coarse_rings: Array=Boss.advance(body(),[],8,player).filter(func(s):return s.kind==6)
	check(fine_rings==coarse_rings and fine_rings.size()==600,"both independent rings maintain800ms timing across catchup")
	Rng.state=0x50000
	Boss.advance(body(),[],10,player)
	check(Rng.state==0x50000,"new body patterns do not consume gameplay randomness")
	b=body();b.hp=0
	check(Boss.advance(b,[],10,player).is_empty(),"destroyed body cannot fire")
	check(Catalog.validate_document(JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))).is_empty(),"authored new patterns pass schema validation")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
