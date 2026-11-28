extends SceneTree
const Boss = preload("res://scripts/boss.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Rng = preload("res://scripts/random.gd")
const Game = preload("res://scripts/game.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Pool = preload("res://scripts/bullet_pool.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func parts(ids: Array) -> Array: return ids.map(func(id): return Catalog.create(id,Vector2.ZERO))
func body() -> Dictionary: return Catalog.create(93,Vector2(200,60))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var b: Dictionary = body()
	var player := Vector2(90,350)
	check(b.hp==1500 and b.max_hp==1500,"stage3 bodyHP is1500")
	var left: Array=Boss.emit(b,"left_enrage",player,0.18)
	var right: Array=Boss.emit(b,"right_enrage",player,0.18)
	check(left.size()==2 and right.size()==2,"each shoulder emits two sweeping rays")
	for at in [0.0,0.18,1.5,3.0,4.5,6.0]:
		var progress: float=(1+cos(TAU*at/6.0))/2
		var aim: float=(player-b.pos).angle()
		for side in range(2):
			var rays: Array=Boss.emit(b,"left_enrage" if side==0 else "right_enrage",player,at)
			var sign: float=1 if side==0 else -1
			for i in range(2):
				var degrees: float=lerpf(-10.0 if i==0 else -7.0,10.0 if i==0 else 13.0,progress)*sign
				check(rays[i].pos==b.pos+Vector2(-43 if side==0 else 43,46),"original shoulder muzzle retained")
				check(rays[i].kind==6 and is_equal_approx(rays[i].velocity.length(),320),"sweeping rays use320px/s optical bullets")
				check(absf(angle_difference(aim,rays[i].velocity.angle())-deg_to_rad(degrees))<0.0001,"both angle ranges follow mirrored six-second cosine sweep")
	check(Boss.advance(body(),parts([121,122,123,124]),0.18,player).is_empty(),"intact arms suppress shoulder attacks")
	check(Boss.advance(body(),parts([122,123,124]),0.18,player).is_empty(),"left arm loss alone cannot enable enrage")
	check(Boss.advance(body(),parts([121,123,124]),0.18,player).is_empty(),"right arm loss alone cannot enable enrage")
	check(Boss.advance(body(),parts([123,124]),0.18,player)==left+right,"both lost arms enable simultaneous mirrored shoulders")
	b=body()
	Boss.advance(b,parts([122,123,124]),1.0,player)
	check(Boss.advance(b,parts([123,124]),0.179,player).filter(func(s):return s.kind==6).is_empty(),"second arm loss starts fresh180ms timer without precharge")
	var activation: Array=Boss.advance(b,parts([123,124]),0.001,player).filter(func(s):return s.kind==6)
	check(activation==Boss.emit(b,"left_enrage",player,1.18)+Boss.emit(b,"right_enrage",player,1.18),"both shoulders activate together and retain shared sweep phase")
	var dead_arms: Array=parts([121,122,123,124])
	dead_arms[0].hp=0
	dead_arms[1].hp=0
	check(Boss.advance(body(),dead_arms,0.18,player)==left+right,"both zero-HP arms activate enrage before removal even with orbs alive")
	var fine: Array=[]
	b=body()
	for tick in range(960):fine.append_array(Boss.advance(b,parts([123,124]),1.0/60,player).filter(func(s):return s.kind==6))
	var coarse: Array=Boss.advance(body(),parts([123,124]),16.0,player).filter(func(s):return s.kind==6)
	check(fine.size()==352 and coarse.size()==fine.size(),"both shoulders emit88 paired volleys over16seconds")
	for i in range(mini(fine.size(),coarse.size())):
		check(fine[i].pos==coarse[i].pos and fine[i].velocity.distance_to(coarse[i].velocity)<0.001,"fine and coarse steps preserve sweeping trajectory")
	for kind in [121,122]:
		var arm: Dictionary = Catalog.create(kind,Vector2(120,100))
		for target in [Vector2(200,350),Vector2(120,80),Vector2(119.99,100.01)]:
			var volley: Array = Fire.emit(arm,target,"triple")
			var aim: float = (target-arm.pos).angle()
			check(volley.size()==3,"arm%d emits three aimed shots"%kind)
			for i in range(3):
				check(volley[i].kind==5 and is_equal_approx(volley[i].velocity.length(),260.0) and absf(angle_difference(aim,volley[i].velocity.angle())-deg_to_rad(-8+8*i))<0.0001,"arm%d uses constant-speed minus8/zero/plus8degree spread at every range"%kind)
		check(Catalog.fire_channel(kind,"triple").interval_seconds==0.36,"arm cadence is360ms")
	check(not Boss.emit(body(),"left_enrage",Vector2(310,350),0.18)[0].velocity.distance_to(left[0].velocity)<0.001,"fan retargets current cockpit for each volley")
	Rng.state = 0x50000
	var before: int = Rng.state
	Boss.emit(body(),"left_enrage",player)
	Boss.emit(body(),"right_enrage",player)
	check(Rng.state==before,"shoulder fans consume no gameplay RNG")
	var missiles: Array = Boss.emit(body(),"missiles",player)
	check(missiles.size()==2 and missiles.all(func(s): return s.kind==2),"existing dual metallic missiles retained")
	var shots: Array = Boss.emit(body(),"left_enrage",left[0].pos-Pilot.COCKPIT)
	check(shots.all(func(s): return is_finite(s.velocity.x) and is_finite(s.velocity.y)),"coincident cockpit and shoulder have finite fallback")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	check(Catalog.validate_document(doc).is_empty(),"both-arms-missing gates and sweeping ranges validate")
	doc.entities["93"].fire_channels[1].part_ids = [121,999]
	check(not Catalog.validate_document(doc).is_empty(),"missing-part gate rejects nonexistent part ID")
	for invalid_ids in [[], "121", null, 121.5, 93]:
		doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["93"].fire_channels[1].part_ids = invalid_ids
		check(not Catalog.validate_document(doc).is_empty(),"invalid required-part list rejected: %s"%str(invalid_ids))
	doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["121"] = "invalid"
	check(not Catalog.validate_document(doc).is_empty(),"malformed referenced part returns validation errors without crashing")
	for invalid_value in [1,"true",null]:
		doc=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["93"].fire_channels[1].volley.aim_relative=invalid_value
		check(not Catalog.validate_document(doc).is_empty(),"aim-relative mode rejects nonboolean values")
	var heavy: Dictionary=Catalog.create(41,b.pos)
	for at in [0.0,2.0,4.0,8.0]:
		var pair: Array=Fire.emit(heavy,player,"aim",{},at)
		var angle: float=deg_to_rad(lerpf(-10.0,20.0,(1+cos(TAU*at/8))/2))
		var direction: Vector2=(player-heavy.pos).normalized()
		check(pair.size()==2 and pair[0].velocity.distance_to(direction.rotated(angle)*280)<0.001 and pair[1].velocity.distance_to(direction.rotated(-angle)*280)<0.001,"enemy41 sweeping pair remains unchanged")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.boss = body()
	g.player = player
	g.enemies.replace_all(parts([122,123,124]))
	g.bullets.clear()
	Pool.body(g,0.18)
	check(g.bullets.is_empty(),"actual bullet emitter suppresses enrage while one arm survives")
	g.enemies.replace_all(parts([123,124]))
	Pool.body(g,0.18)
	var emitted: Array = []
	for shot in g.bullets:
		if shot.kind==6: emitted.append(shot)
	check(emitted.size()==4 and emitted.filter(func(s):return s.pos==Vector2(157,106)).size()==2 and emitted.filter(func(s):return s.pos==Vector2(243,106)).size()==2,"actual bullet emitter enables both shoulders after both arms are lost")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
