extends SceneTree
const Game=preload("res://scripts/game.gd")
const Items=preload("res://scripts/item_system.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if ok:print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for rush in [false,true]:
		g.run_settings = g.run_settings.with_boss_rush(rush)
		for initial in [0.0,20.0,33.3,50.0,90.0,100.0]:
			g._load_stage(1)
			g.energy=initial
			g._drop_item({"kind":1,"pos":g.player+Vector2(25,25)})
			g._update_items()
			check(is_equal_approx(g.energy,minf(100,initial+50)) and g.power==2 and g.score==200 and g.items.is_empty(),"rush%s power item at energy%.1f adds50points capped100 with original power/score"%[rush,initial])
		g._load_stage(1)
		g.energy=20
		g.power=7
		g._drop_item({"kind":1,"pos":g.player+Vector2(25,25)})
		g._update_items()
		check(g.power==7 and g.energy==70,"maximum power still receives exactly50energy")
		g.hp=50
		g.energy=20
		g._drop_item({"kind":2,"pos":g.player+Vector2(25,25)})
		g._update_items()
		check(g.hp==80 and g.energy==20,"HP item recovery is30 without restoring energy")
	g._load_stage(1)
	g.delta_seconds=0
	g.hp=50
	g.energy=20
	var point: Vector2=g.player+Vector2(25,25)
	g._drop_item({"kind":99,"pos":point})
	var unknown_id: int=g.items.at(0).entity_id
	g._update_items()
	check(g.hp==50 and g.energy==20 and g.power==1 and g.score==0 and g.items.contains(unknown_id),"unknown item kind grants no health, power, energy or score")
	g._drop_item({"kind":Items.Kind.POWER,"pos":point})
	var collected: Dictionary=g.items.at(1)
	g._drop_item({"kind":Items.Kind.HEALTH,"pos":point})
	g._drop_item({"kind":Items.Kind.HEALTH,"pos":Vector2(0,520)})
	g._drop_item({"kind":Items.Kind.HEALTH,"pos":Vector2(0,519.9)})
	var retained_id: int=g.items.at(4).entity_id
	g._update_items()
	check(g.hp==80 and g.energy==70 and g.power==2 and g.score==400,"consecutive pickups apply both item definitions exactly once")
	check(collected.pos==point,"collection removes by entity ID without moving the item offscreen")
	check(g.items.size()==2 and g.items.contains(unknown_id) and g.items.contains(retained_id) and g.items.valid(),"collection and offscreen cleanup preserve following entries and store integrity")
	g._update_items()
	check(g.score==400 and g.hp==80 and g.energy==70,"removed pickups cannot grant duplicate rewards")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
