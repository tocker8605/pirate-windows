extends SceneTree
const Fire = preload("res://scripts/enemy_fire.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Combat = preload("res://scripts/combat.gd")
const Game = preload("res://scripts/game.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: "+description)
	else:
		failures += 1
		push_error("FAIL: "+description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var left: Dictionary = Catalog.create(5,Vector2(175,100))
	var right: Dictionary = Catalog.create(5,Vector2(176,100))
	left.velocity = Vector2(0,3)
	var a: Array = []
	for i in range(5): a.append_array(Fire.advance(left,1.0/60))
	check(a.is_empty(),"spiral waits for100ms instead of legacy phase cadence")
	a.append_array(Fire.advance(left,1.0/60))
	check(a.size()==2 and a[0].pos==Vector2(200,125) and a[0].velocity.is_equal_approx(Vector2(0,-7)),"sixth native tick fires centrally while moving vertically with zero horizontal speed")
	check(a[0].velocity.is_equal_approx(-a[1].velocity) and a[0].pos==a[1].pos,"paired spiral rays share the centre and point exactly180degrees apart")
	var b: Array = Fire.advance(left,0.1)
	check(b.size()==2 and is_equal_approx(b[0].velocity.angle(),deg_to_rad(-75)),"centre-line belongs to the left half: clockwise from upward")
	Fire.advance(right,0.1)
	b = Fire.advance(right,0.1)
	check(is_equal_approx(b[0].velocity.angle(),deg_to_rad(-105)),"right half rotates counterclockwise from upward")
	left.pos.x = 300
	var before: float = left.attack_angle
	Fire.advance(left,0.1)
	check(is_equal_approx(left.attack_angle,before-deg_to_rad(15)),"crossing the screen centre reverses sweep without resetting angle")
	var moving: Dictionary = Catalog.create(5,Vector2(100,100))
	Fire.advance(moving,0.05)
	for vx in [-3.0,3.0,0.0001]:
		moving.velocity.x = vx
		check(Fire.advance(moving,1.0).is_empty(),"nonzero horizontal speed%s blocks firing"%vx)
	moving.velocity.x = 0
	check(Fire.advance(moving,0.05).is_empty(),"stopping does not release queued or partially accumulated shots")
	var resumed: Array = Fire.advance(moving,0.05)
	check(resumed.size()==2 and resumed[0].velocity.is_equal_approx(Vector2(0,-7)),"stopped actor fires after100ms and moving did not advance sweep angle")
	var fresh: Dictionary = Catalog.create(5,Vector2(100,100))
	var emitted := 0
	var all_angles := []
	for i in range(600):
		var volley: Array = Fire.advance(fresh,1.0/60)
		emitted += volley.size()
		if not volley.is_empty(): all_angles.append(volley[0].velocity.angle())
	check(emitted==200,"ten seconds at60Hz yields100opposed pairs without accumulated drift")
	check(absf(angle_difference(all_angles[0],all_angles[12]))>3,"spiral sweeps both upper and lower hemispheres")
	var pairs: Array = Fire.advance(Catalog.create(5,Vector2(100,100)),0.5)
	var opposite: bool = true
	for i in range(0,pairs.size(),2): opposite = opposite and pairs[i].velocity.is_equal_approx(-pairs[i+1].velocity)
	check(opposite and pairs.size()==10,"all rotated volleys keep two opposed rays while stepping15degrees per pair")
	check(Fire.advance(Catalog.create(5,Vector2.ZERO),0.3).size()==6,"large integration steps preserve all due shots")
	check(Fire.advance(Catalog.create(4,Vector2.ZERO),1).size()==3,"ordinary aimed attack now uses its own300ms timer")
	fresh.hp = 0
	check(Fire.advance(fresh,1).is_empty(),"dead actors cannot emit spiral bullets")
	var p := Vector2(100,300)
	var e: Dictionary = Catalog.create(1,p)
	check(Combat.touches_player(p,e),"cockpit circle inside enemy hull makes contact")
	check(not Combat.touches_player(p+Vector2(50,0),e),"nearby hull without cockpit overlap does not hit")
	e.hp = 0
	check(not Combat.touches_player(p,e),"dead hull cannot cause contact damage")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(1)
	g.events = []
	g.player = p
	g.enemies.replace_all([Catalog.create(1,p),Catalog.create(2,p)])
	for difficulty in range(1,6):
		g.hp = 100
		g.invulnerable = 0
		g.title.difficulty = difficulty
		g._resolve_body_contacts()
		check(g.hp==100-10*difficulty and g.invulnerable==50 and g.hit_flash_ticks==19,"difficulty%d applies one10x-scale contact hit with normal feedback"%difficulty)
		g._resolve_body_contacts()
		check(g.hp==100-10*difficulty,"difficulty%d overlapping enemies cannot bypass hit immunity"%difficulty)
	g.enemies.clear()
	g.boss = Catalog.create(91,p+Vector2(25,0))
	g.hp = 100
	g.invulnerable = 0
	g._resolve_body_contacts()
	check(g.hp==50,"boss torso contact uses explicit hull bounds and maximum50 damage")
	g.boss = {}
	g.enemies.append(Catalog.create(131,p))
	g.hp = 100
	g.invulnerable = 0
	g._resolve_body_contacts()
	check(g.hp==50,"boss arm contact damages the cockpit")
	for state in [{"kind":201,"rescued":false},{"kind":19,"rescued":false},{"kind":201,"rescued":true}]:
		var supply: Dictionary = Catalog.create(state.kind,p)
		supply.rescued = state.rescued
		g.enemies.replace_all([supply])
		g.hp = 100
		g.invulnerable = 0
		g.hit_flash_ticks = 0
		g._resolve_body_contacts()
		check(g.hp==100 and g.invulnerable==0 and g.hit_flash_ticks==0,"supply kind%d rescued%s never inflicts contact damage or feedback"%[state.kind,state.rescued])
	g.enemies.append(Catalog.create(1,p))
	g._resolve_body_contacts()
	check(g.hp==50,"overlapping exempt supply does not hide contact with a hostile enemy")
	g.hp = 100
	g.invulnerable = 0
	g.death_ticks = 1
	g._resolve_body_contacts()
	check(g.hp==100,"dying player receives no repeated contact damage")
	g.death_ticks = 0
	g.hp = 100
	g.invulnerable = 0
	g.enemies.replace_all([Catalog.create(5,p+Vector2(0,-100))])
	g.bullets.clear()
	for i in range(12): g._tick(Vector2.ZERO,false,false,false,g.Clock.units_per_tick())
	check(g.bullets.size()==4,"actual game loop emits opposed spiral at100ms independent of global phases")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
