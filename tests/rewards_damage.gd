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
			check(g.hp==100-[12,18,24,30,36][difficulty-1] and is_equal_approx(g.invulnerability_seconds,1.5) and g.bullets.is_empty(),"difficulty%d projectile%d uniform damage with immunity and removal"%[difficulty,kind])
		for stage in range(1,5):
			for rush in [false,true]:
				g.boss_rush = rush
				g._load_stage(stage)
				g.delta_seconds = 0.03
				g.events = []
				g.score = 123
				g.boss = Catalog.create(90+stage,Vector2(200,100))
				g.boss.hp = 6
				var reward: int = [0,3000,5000,7000,10000][stage]*difficulty
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
	g.title.difficulty = 3
	g.delta_seconds = 0.03
	g.boss = Catalog.create(91,Vector2(200,100))
	g.boss.hp = 1
	g.player = Vector2(200,300)
	g.beam_remaining_seconds = 0.03
	g._apply_beam()
	check(g.boss.hp<=0 and g.score==9000 and g.boss_defeated,"beam lethal hit also rewards immediately with difficulty scaling")
	var parts_by_stage: Dictionary = {1:[101,102],2:[111,112,113],3:[121,122,123,124],4:[131,132,133]}
	for difficulty in range(1,6):
		g.title.difficulty = difficulty
		for stage in range(1,5):
			for rush in [false,true]:
				for already_killed in [false,true]:
					g.boss_rush = rush
					g._load_stage(stage)
					g.events = []
					g.invulnerability_seconds = 300
					g.score = 123
					g.boss = Catalog.create(90+stage,Vector2(200,100))
					for kind in parts_by_stage[stage]: g.enemies.append(Catalog.create(kind,Vector2(100,100)))
					var direct_part: Dictionary = g.enemies.at(0)
					if already_killed: direct_part.hp = 0
					g._damage_boss(g.boss.hp)
					g._update_lifecycle()
					check(bool(direct_part.get("auto_destroyed",false))!=already_killed,"stage%d difficulty%d rush%s distinguishes automatic destruction from pending direct kill%s"%[stage,difficulty,rush,already_killed])
					g._tick(Vector2.ZERO,false,false,false)
					var expected: int = 123+[0,3000,5000,7000,10000][stage]*difficulty+([0,500,750,1200,1500][stage]*difficulty if already_killed else 0)
					check(g.score==expected and g.enemies.is_empty(),"stage%d difficulty%d rush%s cleanup grants only body and direct-part rewards"%[stage,difficulty,rush])
					g._tick(Vector2.ZERO,false,false,false)
					check(g.score==expected,"repeated boss cleanup cannot award automatic part points")
	var part_scores: Dictionary = {101:500,102:500,111:750,112:750,113:1000,121:1200,122:1200,123:1200,124:1200,131:1500,132:1500,133:2000}
	g.boss_rush = false
	g._load_stage(1)
	for kind in part_scores:
		for difficulty in range(1,6):
			g.title.difficulty = difficulty
			g.score = 0
			var part: Dictionary = Catalog.create(kind,Vector2(100,100))
			part.hp = 0
			g._destroy_enemy(part)
			check(g.score==part_scores[kind]*difficulty,"part%d direct destruction awards base%d times difficulty%d"%[kind,part_scores[kind],difficulty])
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
