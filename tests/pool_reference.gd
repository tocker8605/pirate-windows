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
func enemy(kind: int, velocity: Vector2 = Vector2.ZERO) -> Dictionary:
	return {"kind":kind,"pos":Vector2(100,100),"velocity":velocity,"pattern":0,"hp":100}
func occupied(slot: int) -> Dictionary:
	return {"kind":1,"slot":slot,"pos":Vector2(999,999),"velocity":Vector2.DOWN,"alive":true}
func clear(g: Node, cursor: int, phase: int) -> void:
	g.bullets.clear()
	g.items.clear()
	g.bullet_cursor = cursor
	g.clock.phase = phase
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.start_game()
	clear(g,149,1)
	g._enemy_fire(enemy(2))
	check(g.bullet_cursor==5 and g.bullets.is_empty(),"type 2 resets >148 and advances two slots even without firing")
	clear(g,149,6)
	g._enemy_fire(enemy(2))
	check(g.bullets.size()==1 and g.bullets[0].slot==4 and g.bullets[0].kind==3 and g.bullet_cursor==5,"type 2 stationary shot uses the second unconditional cursor slot")
	clear(g,3,6)
	g.bullets = [occupied(3)]
	g._enemy_fire(enemy(1))
	check(g.bullets.size()==1 and g.bullet_cursor==3,"occupied source cursor suppresses a guarded single shot")
	clear(g,3,9)
	g.bullets = [occupied(4)]
	g._enemy_fire(enemy(7))
	check(g.bullets.size()==3 and g.bullet_cursor==6 and g.bullets.all(func(b): return b.pos!=Vector2(999,999)),"spread burst guards first slot then overwrites its inner slots")
	clear(g,3,12)
	g.bullets = [occupied(5)]
	g._enemy_fire(enemy(21))
	check(g.bullets.size()==3 and g.bullet_cursor==5 and g.bullets.any(func(b): return b.slot==5 and b.pos==Vector2(999,999)),"type 21 missile pair and aimed shot retain separate occupancy guards")
	clear(g,3,6)
	g.boss = {"stage":4,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0,"age":0}
	g.enemies = [enemy(132)]
	g.bullets = [occupied(4)]
	g.BulletPool.body(g)
	check(g.bullets.size()==2 and g.bullet_cursor==4,"final boss replacement cannon and beam pair use separate source guards")
	clear(g,0,6)
	g._bullet(Vector2(100,100),Vector2.DOWN)
	g.item_cursor = 0
	g._drop_item({"pos":Vector2(120,120),"kind":1})
	check(g.bullets.is_empty() and g.items.size()==1 and g.items[0].slot==0,"original shared item slot can replace a bullet")
	g.bullet_cursor = 0
	g._enemy_fire(enemy(1))
	check(g.bullets.is_empty() and g.bullet_cursor==0,"item in a shared slot blocks guarded bullet emission")
	clear(g,200,6)
	g._enemy_fire(enemy(1))
	check(g.bullets[0].slot==3 and g.bullet_cursor==4,"global bullet cursor wraps to slot 3, reserving item entries")
	for stage in [2,3]:
		clear(g,147 if stage==3 else 146,8 if stage==3 else 2)
		g.enemies.clear()
		g.boss.stage = stage
		g.BulletPool.body(g)
		check(g.bullets.size()==2 and g.bullets[0].slot==3 and g.bullet_cursor==5,"boss %d retains original limited cursor reset"%stage)
	g.start_game()
	g.events = []
	for i in range(6): g.events.append([0,1,100,-50,1011,5])
	g.frame = 1
	g._read_events()
	check(g.event_cursor==5 and g.enemies.size()==5,"source event reader creates at most five actor records per tick")
	g._read_events()
	check(g.event_cursor==6 and g.enemies.size()==6,"remaining same-time actor record is handled on following reader tick")
	g.start_game()
	g.events = [[0,2,100,-50,1011,5]]
	var active: Dictionary = enemy(1)
	active.slot = 0
	g.enemies = [active]
	g.frame = 1
	g._read_events()
	check(g.enemies.size()==1 and g.event_cursor==1 and g.enemy_cursor==1 and g.stats.skipped==1,"occupied enemy pool slot consumes and skips source event")
	g.start_game()
	g.events = [[0,1,100,-50,1011,5]]
	g.explosions = [{"owner_slot":0},{"owner_slot":1}]
	g.frame = 1
	g._read_events()
	check(g.explosions.size()==1 and g.explosions[0].owner_slot==1,"reusing an enemy slot hides that slot's remaining explosion")
	g.start_game()
	g.events = []
	g.hp = 1
	g.invulnerable = 0
	g.bullet_cursor = 3
	g._bullet(g.player+Vector2(25,25),Vector2(0,0.1))
	g._drop_item({"pos":g.player+Vector2(25,25),"kind":2})
	g._tick(Vector2.ZERO,false,false,false)
	check(g.hp==17,"repair item is collected before incoming bullet damage as in ew slot order")
	g.bullets.clear()
	g.bullet_cursor = 3
	g._bullet(Vector2(100,100),Vector2.ZERO)
	g._update_bullets()
	check(g.bullets.is_empty(),"stationary source projectile is discarded rather than hanging forever")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
