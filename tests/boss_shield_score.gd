extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func intercept(g: Node,count: int = 1) -> void:
	g.shield_remaining_seconds = 3.0
	g.shield_center = Vector2(100,100)
	g.shield_contacts.clear()
	g.bullets.clear()
	for i in range(count): g._bullet(Vector2(100,100),(Vector2.DOWN)/0.03,5)
	g._update_bullets()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(1)
	g.delta_seconds = 0.03
	g.events = []
	for difficulty in range(1,6):
		g.run_settings = g.run_settings.with_difficulty(difficulty)
		g.boss = {}
		g.score = 123
		intercept(g)
		check(g.score==123+25*difficulty and g.bullets.is_empty() and is_equal_approx(g.shield_remaining_seconds,2.94) and g.shield_contacts.size()==1,"difficulty%d ordinary shield_remaining_seconds interception retains points,absorption and shield_remaining_seconds cost"%difficulty)
		for stage in range(1,6):
			g.boss = Catalog.create(90+stage,Vector2(200,60))
			g.score = 123
			intercept(g)
			check(g.score==123+25*difficulty and g.bullets.is_empty() and is_equal_approx(g.shield_remaining_seconds,2.88) and g.shield_contacts.size()==1,"difficulty%d stage%d boss grants shield points and keeps doubled interception cost to120ms"%[difficulty,stage])
	g.run_settings = g.run_settings.with_difficulty(5)
	g.score = 123
	for i in range(100): intercept(g)
	check(g.score==123+100*125 and g.bullets.is_empty() and is_equal_approx(g.shield_remaining_seconds,2.88) and g.shield_contacts.size()==1,"100boss-phase interceptions grant their points and retain doubled shield costs")
	g.score = 123
	g.boss.hp = 0
	g.boss_death_remaining_seconds = 7.2
	intercept(g)
	check(g.score==248 and g.bullets.is_empty(),"remaining intercepted bullets use the same scoring during boss death")
	g.boss = {}
	g.boss_death_remaining_seconds = 0
	g.score = 123
	g.banner = "WARNING / BOSS APPROACHING"
	intercept(g)
	check(g.score==248,"warning before actual boss appearance still permits ordinary shield_remaining_seconds reward")
	g._load_stage(2,true)
	g.delta_seconds = 0.03
	g.events = []
	g.score = 123
	intercept(g)
	check(g.score==248 and g.boss.is_empty(),"next-stage reset restores ordinary shield_remaining_seconds score")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["92"].fire_channels[0].projectile_kind = 99
	check(not Catalog.validate_document(doc).is_empty(),"invalid editable boss projectile kind is rejected")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
