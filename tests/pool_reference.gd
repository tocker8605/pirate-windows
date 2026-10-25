extends SceneTree
const Game = preload("res://scripts/game.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: "+text)
	else:
		failures += 1
		push_error("FAIL: "+text)
func enemy(kind: int) -> Dictionary:
	return {"kind":kind,"pos":Vector2(100,100),"velocity":Vector2.ZERO,"pattern":0,"hp":100}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.start_game()
	g.events = []
	for i in range(1000): g._bullet(Vector2(100,100),Vector2.DOWN)
	check(g.bullets.size()==1000 and g.bullets.valid(),"all 1000 enemy bullets survive admission without a 200-slot cap")
	var oldest: int = g.bullets.at(0).entity_id
	g.clock.phase = 9
	g._enemy_fire(enemy(7))
	check(g.bullets.size()==1003 and g.bullets.contains(oldest),"complete spread burst appends without overwriting old bullets")
	g.clock.phase = 6
	g._enemy_fire(enemy(2))
	check(g.bullets.size()==1004 and g.bullets.at(1003).kind==3,"type2 retains its authored stationary projectile without empty-slot gating")
	g.clock.phase = 1
	g._enemy_fire(enemy(2))
	check(g.bullets.size()==1004,"a non-firing phase does not allocate a dummy projectile")
	for i in range(20): g._drop_item({"pos":Vector2(120,120),"kind":1})
	check(g.items.size()==20 and g.bullets.size()==1004,"items are independent and neither replace nor block enemy bullets")
	g.clock.phase = 6
	g._enemy_fire(enemy(1))
	check(g.bullets.size()==1005,"items cannot suppress authored enemy fire")
	g.start_game()
	g.events = []
	for i in range(150): g.events.append([0,1,100,-50,1011,5])
	g.frame = 1
	g._read_events()
	check(g.event_cursor==5 and g.enemies.size()==5,"original five-record reader timing is preserved")
	while g.event_cursor<g.events.size(): g._read_events()
	check(g.enemies.size()==150 and g.stats.spawned==150 and g.stats.get("skipped",0)==0,"150 simultaneous enemies have unique identities with no 30-slot event loss")
	check(g.enemies.valid(),"enemy links and ID map remain consistent under dense admission")
	g.explosions = [{"owner_id":g.enemies.at(0).entity_id,"ticks":15}]
	g.events.append([0,2,100,-50,1011,5])
	g._read_events()
	check(g.enemies.size()==151 and g.explosions.size()==1,"new spawns do not cancel another entity's lingering explosion")
	g.bullets.clear()
	g.enemies.clear()
	g.boss = {"stage":4,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0,"age":0}
	g.clock.phase = 6
	for i in range(300): g._bullet(Vector2(50,50),Vector2.DOWN)
	g.BulletPool.body(g)
	check(g.bullets.size()==303,"all final-boss cannon and missile groups fire above the old bullet limit")
	g.start_game()
	g.events = []
	g.hp = 1
	g._bullet(g.player+Vector2(25,25),Vector2(0,0.1))
	g._drop_item({"pos":g.player+Vector2(25,25),"kind":2})
	g._tick(Vector2.ZERO,false,false,false)
	check(g.hp==17,"repair pickups still resolve before incoming damage")
	g.bullets.clear()
	g._bullet(Vector2(100,100),Vector2.ZERO)
	g._bullet(Vector2(399,100),Vector2(4,0))
	g._update_bullets()
	check(g.bullets.is_empty() and g.bullets.valid(),"stationary and offscreen bullets unlink without leaving stale records")
	g._load_stage(4)
	check(g.enemies.is_empty() and g.bullets.is_empty() and g.items.is_empty(),"stage transition releases all three independent stores")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
