extends SceneTree
const Game = preload("res://scripts/game.gd")
const VFX = preload("res://scripts/combat_vfx.gd")
const Rng = preload("res://scripts/random.gd")
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
	game._load_stage(4)
	game.events = []
	var fx = game.view.vfx
	game._explosion(Vector2(110,140),35)
	game.shots = [{"pos":Vector2(90,90),"kind":1,"impact_ticks":8,"alive":true}]
	game.shield_contacts = [Vector2(100,300)]
	var before: String = var_to_str([game.player,game.enemies.snapshot(),game.shots,game.bullets.snapshot(),game.explosions,game.hp,game.energy,game.score,game.background_y])
	var random_state: int = Rng.state
	game.frame = 1
	fx.observe(game)
	check(fx.particles.size()>=70,"explosions, weapon impacts and shield hits emit independent moving particles")
	check(var_to_str([game.player,game.enemies.snapshot(),game.shots,game.bullets.snapshot(),game.explosions,game.hp,game.energy,game.score,game.background_y])==before,"presentation does not mutate gameplay state or collision anchors")
	check(Rng.state==random_state,"visual randomness never consumes the VB gameplay random stream")
	var snapshot: String = var_to_str(fx.particles)
	fx.observe(game)
	check(var_to_str(fx.particles)==snapshot,"redrawing or pausing on the same simulation tick cannot emit or age particles")
	game.state = "paused"
	game._redraw()
	check(var_to_str(fx.particles)==snapshot,"paused refresh freezes all particle lifetimes")
	game.state = "playing"
	game.frame += 1
	fx.observe(game)
	check(fx.particles[0].p!=str_to_var(snapshot)[0].p,"particles integrate velocity on the next simulation tick")
	check(fx.blasts.size()==1 and fx.blasts[0].duration==35,"large explosion retains its lifetime across its later small-tick range")
	game.explosions[0].ticks = 19
	game.frame += 1
	fx.observe(game)
	check(fx.blasts.size()==1 and fx.blasts[0].duration==35,"one source explosion cannot respawn bursts or restart its flash halfway through")
	fx.reset()
	for i in range(VFX.LIMIT+100): fx.emit(Vector2.ZERO,Vector2.ONE,1,2,VFX.CYAN)
	check(fx.particles.size()==VFX.LIMIT,"particle pool is bounded under extreme bullet and explosion load")
	game.death_ticks = 1
	game.shots.clear()
	game.explosions.clear()
	game.shield_contacts.clear()
	game.frame = 5
	fx.observe(game)
	check(fx.particles.is_empty(),"expired particles are reclaimed without retaining a dead emitter")
	fx.burst(Vector2.ZERO,10,VFX.HOT)
	game.state = "loading"
	fx.observe(game)
	check(fx.particles.is_empty() and fx.blasts.is_empty() and fx.impacts.is_empty(),"loading clears particles and stale source references")
	game.state = "playing"
	fx.burst(Vector2.ZERO,10,VFX.HOT)
	game._load_stage(1)
	check(fx.blasts.is_empty() and fx.particles.all(func(p): return p.p.distance_to(game.player)<80),"stage load clears old effects even when the frame number repeats")
	check(VFX.player_color(1)!=VFX.enemy_color(1) and VFX.player_color(3)!=VFX.enemy_color(4),"friendly and hostile projectile palettes remain distinct")
	check(game.view.foreground.vfx==fx,"foreground and simulation share a single particle pool")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	game.audio.stop_all()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
