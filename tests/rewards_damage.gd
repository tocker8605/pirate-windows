extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for difficulty in range(1,6):
		g.title.difficulty = difficulty
		for kind in range(1,9):
			g._load_stage(1)
			g.delta_seconds = 0.03
			g.events = []
			g.player = Vector2(150,300)
			g._bullet(g.player+Pilot.COCKPIT,(Vector2(0,0.1))/0.03,kind)
			g._update_bullets()
			check(g.hp==100-(10+5*difficulty) and is_equal_approx(g.invulnerability_seconds,1.5) and g.bullets.is_empty(),"difficulty%d projectile%d uniform damage with immunity and removal"%[difficulty,kind])
		for stage in range(1,5):
			for rush in [false,true]:
				g.boss_rush = rush
				g._load_stage(stage)
				g.delta_seconds = 0.03
				g.events = []
				g.score = 123
				g.boss = Catalog.create(90+stage,Vector2(200,100))
				g.boss.hp = 6
				var reward: int = [0,5000,10000,20000,30000][stage]
				g.shots.replace_all([{"pos":Vector2(200,120),"impact_remaining_seconds":-1}])
				g._resolve_shots()
				check(g.boss.hp==3 and g.score==123 and not g.boss_defeated,"stage%d difficulty%d rush%s nonlethal shot gives no score"%[stage,difficulty,rush])
				g.shots.replace_all([{"pos":Vector2(200,120),"impact_remaining_seconds":-1}])
				g._resolve_shots()
				check(g.boss.hp==0 and g.score==123+reward and g.last_score==g.score and g.boss_defeated and is_equal_approx(g.boss_death_remaining_seconds,7.2),"stage%d difficulty%d rush%s lethal shot rewards immediately before next tick"%[stage,difficulty,rush])
				g._finish_stage()
				g._update_lifecycle()
				check(g.score==123+reward,"stage%d repeated death handling cannot duplicate reward"%stage)
				g._complete_stage()
				check((g.score==123+reward if stage<4 else g.last_score==123+reward),"stage%d transition never adds a second reward"%stage)
	g.boss_rush = false
	g._load_stage(1)
	g.delta_seconds = 0.03
	g.boss = Catalog.create(91,Vector2(200,100))
	g.boss.hp = 1
	g.player = Vector2(200,300)
	g.beam_remaining_seconds = 0.03
	g._apply_beam()
	check(g.boss.hp<=0 and g.score==5000 and g.boss_defeated,"beam lethal hit also rewards immediately")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
