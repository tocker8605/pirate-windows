extends SceneTree
const Boss = preload("res://scripts/boss.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const Rng = preload("res://scripts/random.gd")
const Game = preload("res://scripts/game.gd")
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
	var left: Array = Boss.emit(b,"left_enrage",player)
	var right: Array = Boss.emit(b,"right_enrage",player)
	check(left.size()==4 and right.size()==4,"each shoulder emits its own complete four-way fan")
	check((left+right).all(func(s): return s.kind==6 and is_equal_approx(s.velocity.length(),(9/0.03))),"fan projectile type and speed retained")
	for side in range(2):
		var shots: Array = left if side==0 else right
		var muzzle: Vector2 = b.pos+Vector2(-43 if side==0 else 43,46)
		var aim: float = (player+Pilot.COCKPIT-muzzle).angle()
		var correct := true
		for i in range(4): correct = correct and shots[i].pos==muzzle and is_equal_approx(angle_difference(aim,shots[i].velocity.angle()),deg_to_rad(-22.5+15*i))
		check(correct,"shoulder%d fan originates in arm coupling hole and spans45degrees at15degree spacing"%side)
	check(Boss.advance(body(),parts([121,122,123,124]),0.3,player).is_empty(),"both intact arms suppress both shoulder attacks")
	var shots: Array = Boss.advance(body(),parts([122,123,124]),0.3,player)
	check(shots.is_empty(),"one surviving right arm suppresses both shoulder attacks")
	shots = Boss.advance(body(),parts([121,123,124]),0.3,player)
	check(shots.is_empty(),"one surviving left arm suppresses both shoulder attacks")
	shots = Boss.advance(body(),parts([123,124]),0.3,player)
	check(shots==left+right,"both shoulders attack even when both floating orbs remain alive")
	var dead_arm: Dictionary = Catalog.create(121,Vector2.ZERO)
	dead_arm.hp = 0
	check(Boss.advance(body(),[dead_arm]+parts([122,123,124]),0.3,player).is_empty(),"one dead arm pending removal cannot activate enrage while other arm survives")
	var dead_right: Dictionary = Catalog.create(122,Vector2.ZERO)
	dead_right.hp = 0
	check(Boss.advance(body(),[dead_arm,dead_right]+parts([123,124]),0.3,player)==left+right,"both dead arms pending removal enable both fans")
	b = body()
	Boss.advance(b,parts([122,123,124]),10.0,player)
	check(Boss.advance(b,parts([123,124]),0.299,player).filter(func(s): return s.kind==6).is_empty(),"both arms lost starts fresh300ms timer without precharging")
	check(Boss.advance(b,parts([123,124]),0.001,player)==left+right,"both shoulder fans start together at300ms")
	var total_shots := 0
	b = body()
	for i in range(600): total_shots += Boss.advance(b,parts([123,124]),1.0/60,player).filter(func(s): return s.kind==6).size()
	check(total_shots==264,"both destroyed arms emit33paired four-way volleys over10seconds")
	shots = Boss.advance(body(),parts([123,124]),0.9,player)
	check(shots.filter(func(s): return s.kind==6).size()==24,"large time steps preserve three volleys from each destroyed shoulder")
	check(not Boss.emit(body(),"left_enrage",Vector2(310,350))[0].velocity.distance_to(left[0].velocity)<0.001,"fan retargets current cockpit for each volley")
	Rng.state = 0x50000
	var before: int = Rng.state
	Boss.emit(body(),"left_enrage",player)
	Boss.emit(body(),"right_enrage",player)
	check(Rng.state==before,"shoulder fans consume no gameplay RNG")
	var missiles: Array = Boss.emit(body(),"missiles",player)
	check(missiles.size()==2 and missiles.all(func(s): return s.kind==2),"existing dual metallic missiles retained")
	shots = Boss.emit(body(),"left_enrage",left[0].pos-Pilot.COCKPIT)
	check(shots.all(func(s): return is_finite(s.velocity.x) and is_finite(s.velocity.y)),"coincident cockpit and shoulder have finite fallback")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	check(Catalog.validate_document(doc).is_empty(),"both-arm gates and orb metadata validate")
	doc.entities["93"].fire_channels[1].part_ids = [121,999]
	check(not Catalog.validate_document(doc).is_empty(),"missing-part gate rejects nonexistent part ID")
	for invalid_ids in [[], "121", [null], [121.5], [93]]:
		doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
		doc.entities["93"].fire_channels[1].part_ids = invalid_ids
		check(not Catalog.validate_document(doc).is_empty(),"invalid required-part list rejected: %s"%str(invalid_ids))
	doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["121"] = "invalid"
	check(not Catalog.validate_document(doc).is_empty(),"malformed referenced part returns validation errors without crashing")
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
	Pool.body(g,0.3)
	check(g.bullets.is_empty(),"actual bullet emitter suppresses enrage with one surviving arm")
	g.enemies.replace_all(parts([123,124]))
	Pool.body(g,0.3)
	var emitted: Array = []
	for shot in g.bullets:
		if shot.kind==6: emitted.append(shot)
	check(emitted.size()==8 and emitted[0].pos==Vector2(157,106) and emitted[4].pos==Vector2(243,106),"actual bullet emitter fires from both couplings after both arms are gone")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
