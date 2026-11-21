extends SceneTree
const Game=preload("res://scripts/game.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Ground=preload("res://scripts/ground_turret.gd")
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func capture(g: Node) -> Image:
	g._redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func delta(a: Color,b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(5)
	g.events=[]
	g.supply_director.schedule.clear()
	g.background_y=1920
	g.player=Vector2(175,125)
	var bare: Image=await capture(g)
	var actor: Dictionary=Catalog.create(52,Vector2(175,125))
	Ground.initialize(actor,g.scenery_distance,true)
	g.enemies.append(actor)
	var covered: Image=await capture(g)
	check(delta(bare.get_pixel(400,286),covered.get_pixel(400,286))<0.005,"player cockpit remains visibly above a ground turret")
	check(g.view.ground_art!=null and g.view.foreground.ground_art==null,"ground art is drawn only in the background-adjacent parent canvas")
	g.bullets.append({"pos":Vector2(200,150),"velocity":Vector2.DOWN,"kind":5,"alive":true})
	var bullet_floor: Image=await capture(g)
	g.enemies.clear()
	var bullet_bare: Image=await capture(g)
	check(delta(bullet_floor.get_pixel(400,300),bullet_bare.get_pixel(400,300))<0.01,"enemy projectile core remains above ground turrets")
	g.bullets.clear()
	Ground.wreck(g,{"kind":52,"pos":Vector2(175,125)})
	var wreck: Image=await capture(g)
	check(delta(bare.get_pixel(400,286),wreck.get_pixel(400,286))<0.005,"persistent wreck stays below the player")
	g.ground_wrecks.clear()
	g.player=Vector2(175,380)
	var forms: Array=[]
	for progress in [0.0,0.5,1.0]:
		g.enemies.clear()
		var e: Dictionary=Catalog.create(52,Vector2(175,150))
		Ground.initialize(e,g.scenery_distance,false)
		e.deployment_progress=progress
		g.enemies.append(e)
		var shot: Image=await capture(g)
		forms.append(hash(shot.get_data()))
	check(forms[0]!=forms[1] and forms[1]!=forms[2],"closed hatch, rising mechanism and exposed turret have distinct rendered states")
	var regions: Array=[]
	for source in [3360,1920,480]:
		g.background_y=source
		var shot: Image=await capture(g)
		regions.append(hash(shot.get_data()))
	check(regions[0]!=regions[1] and regions[1]!=regions[2],"stage5 renders three distinct ground environments")
	g.enemies.clear()
	g.boss=Catalog.create(95,Vector2(200,100))
	for kind in [141,142,143,144]:
		var offset: Array=Catalog.definition(kind).attachment.offset
		g.enemies.append(Catalog.create(kind,g.boss.pos+Vector2(offset[0],offset[1])))
	var boss: Image=await capture(g)
	boss.save_png("res://preview-stage5-mainframe.png")
	check(hash(boss.get_data())!=regions[2] and g.boss.hp==3000,"floor-mounted3000HP supercomputer is rendered independently of chamber terrain")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
