extends SceneTree
const Game = preload("res://scripts/game.gd")
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
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.start_game()
	game.events = []
	for i in range(256):
		game.enemies.append({"kind":1,"pos":Vector2(40+i%16*18,40+int(i/16)*9),"velocity":Vector2.ZERO,"pattern":0,"hp":100})
	game.clock.phase = 6
	for e in game.enemies: game._enemy_fire(e)
	check(game.enemies.size()==256 and game.bullets.size()==256,"all 256 simultaneously active enemies can fire")
	game.bullets.clear()
	var insert_begin: int = Time.get_ticks_usec()
	for i in range(6000): game._bullet(Vector2(10+i%380,100),Vector2.DOWN)
	var insert_us: int = Time.get_ticks_usec()-insert_begin
	check(game.bullets.size()==6000,"6000 live projectiles are admitted without wrapping or overwrite")
	var begin: int = Time.get_ticks_usec()
	for i in range(5): game._update_bullets()
	var update_us: int = Time.get_ticks_usec()-begin
	check(game.bullets.size()==6000 and game.bullets.all(func(b): return b.pos.y==105),"every projectile receives exactly one integration per update at high counts")
	for bullet in game.bullets:
		bullet.pos.y = 480
		bullet.velocity = Vector2(0,2)
	game._update_bullets()
	check(game.bullets.is_empty() and game.bullets.valid(),"6000 out-of-field projectiles are removed without skipped links")
	for e in game.enemies: e.pos.x = 500
	game.clock.phase = 0
	game._tick(Vector2.ZERO,false,false,false)
	check(game.enemies.is_empty() and game.enemies.valid(),"all 256 off-field enemies despawn without a slot leak")
	game._load_stage(4)
	check(game.enemies.is_empty() and game.bullets.is_empty() and game.items.is_empty(),"high-count stage reset releases all active state")
	print("GAME SCALE BENCH: 6000 bullets insert=%dus, 5 integrations=%dus, average=%dus"%[insert_us,update_us,int(update_us/5)])
	print("RESULT: %d checks, %d failures"%[checks,failures])
	game.audio.stop_all()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
