extends SceneTree
const Game = preload("res://scripts/game.gd")
const Art = preload("res://scripts/renewed_art.gd")
const Fire = preload("res://tests/fixtures/fire_probe.gd")
const Boss = preload("res://scripts/boss.gd")
const Scenery = preload("res://scripts/scenery.gd")
const FX = preload("res://scripts/combat_vfx.gd")
const Clock = preload("res://scripts/timing.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var art = Art.new()
	check(art.enemies.resource_path.ends_with("enemies-v18.png"),"regular enemies use the restored v18 renewal atlas")
	check(art.bosses.resource_path.ends_with("bosses-v15.png"),"current boss artwork remains unchanged")
	var raw: Image = art.bosses.get_image()
	for kind in [131,132]:
		var body = {"pos":Vector2(200,60 if kind==131 else 130),"velocity":Vector2.ZERO}
		var arm = {"kind":kind,"pos":Vector2.ZERO,"velocity":Vector2.ZERO,"pattern":0,"hp":600}
		Boss.attach(arm,body)
		var muzzle: Vector2 = Boss.claw_muzzle(arm)
		var local: Vector2 = muzzle-(arm.pos-Vector2(0,50))
		if kind==132: local.x = 50-local.x
		var rect: Rect2i = art.BOSS_RECTS[6]
		var point := Vector2i(rect.position)+Vector2i(local/Vector2(50,100)*Vector2(rect.size))
		check(raw.get_pixelv(point).a<0.05,"arm%d firing point is inside the transparent claw opening"%kind)
		var left: Color = raw.get_pixelv(point-Vector2i(40,0))
		var right: Color = raw.get_pixelv(point+Vector2i(40,0))
		check(left.a>0.5 and right.a>0.5,"arm%d muzzle is between actual opaque claw fingers"%kind)
		var shots: Array = Fire.burst(arm,Vector2(170,400),2,0,body)
		check(shots.size()==2 and shots.all(func(shot): return shot.pos==muzzle),"arm%d all projectile kinds spawn in the claw opening"%kind)
		var prep: Dictionary = Scenery.preparation(arm,body)
		check(prep.pos+Vector2(25,25)==muzzle,"arm%d preparation centre matches projectile muzzle"%kind)
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(4)
	g.delta_seconds = 0.03
	g.events = []
	g.death_remaining_seconds = 0.03
	g.frame = 1
	var fx = g.view.vfx
	fx.reset()
	fx.observe(g)
	fx.emit(Vector2(100,100),Vector2.ZERO,30,10,FX.SMOKE_COLOR,true)
	g.scroll_speed = (2/0.03)
	g.frame += 1
	fx.observe(g)
	check(is_equal_approx(fx.particles[0].p.y,102),"smoke follows slow scroll2px per authored unit")
	g.scroll_speed = (10/0.03)
	g.frame += 1
	fx.observe(g)
	check(is_equal_approx(fx.particles[0].p.y,112),"existing smoke immediately follows changed scroll speed10")
	g.delta_seconds = Clock.FIXED_STEP_SECONDS
	g.scroll_speed = (18/0.03)
	g.frame += 1
	fx.observe(g)
	check(is_equal_approx(fx.particles[0].p.y,122),"smoke advection uses the native60Hz conversion")
	g.scroll_speed = (0/0.03)
	g.frame += 1
	fx.observe(g)
	check(is_equal_approx(fx.particles[0].p.y,122),"zero scroll causes no artificial downward smoke motion")
	fx.emit_smoke(Vector2(120,150),12)
	check(fx.particles[-1].color.r<0.1 and fx.particles[-1].v.y==0 and is_equal_approx(fx.particles[-1].life,0.84),"damage smoke is dark and longer-lived without baked vertical drift")
	check(fx.smoke_puff.get_image().get_pixel(32,32).a>0.99,"new smoke texture has a dense opaque core")
	fx.reset()
	g.render_hp = 25
	g.death_remaining_seconds = 0
	g.enemies.append({"kind":1,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":2})
	for i in range(4):
		g.frame += 1
		fx.observe(g)
	var emitted: int = 0
	for particle in fx.particles:
		if particle.smoke: emitted += 1
	check(emitted>=4,"damaged pilot and enemy actually emit the dense smoke through the game observer")
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
