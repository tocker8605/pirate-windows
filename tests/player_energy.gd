extends SceneTree
const Game = preload("res://scripts/game.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for weapon in range(1,4):
		for power in range(1,8):
			g.shots.clear()
			g.fire_cooldown_seconds = 0
			g.energy = 100
			g.weapon = weapon
			g.power = power
			g._fire()
			var expected_period: float = 0.06 if power%2==0 else 0.09
			var expected_count: int = 1 if power<=2 else (2 if power<=4 else (3 if power<=6 else 4))
			var ok: bool = g.energy==100 and is_equal_approx(g.fire_cooldown_seconds,expected_period) and g.shots.size()==expected_count
			checks += 1
			if ok: print("PASS: weapon%d power%d fires without energy cost at unchanged cadence"%[weapon,power])
			else:
				failures += 1
				push_error("FAIL: weapon%d power%d cost/cadence/volley mismatch"%[weapon,power])
	g._load_stage(1)
	g.events = []
	g.energy = 0
	for i in range(180): g._tick(Vector2.ZERO,true,false,false)
	check(g.energy==0 and g.stats.shots>0,"holding Z for3seconds fires at zero energy without cost or recovery")
	for i in range(180): g._tick(Vector2.ZERO,false,false,false)
	check(g.energy==25,"releasing Z restores25energy per3seconds at existing rate")
	g.energy = 50
	for i in range(180): g._tick(Vector2.ZERO,true,false,false)
	check(g.energy==50,"holding Z at partial energy neither drains nor restores energy")
	g.energy = 100
	g.clock.recovery = 0
	g._tick(Vector2.ZERO,true,true,false)
	check(g.energy==92 and g.beam_remaining_seconds>0,"X still costs8 while Z held")
	g._tick(Vector2.ZERO,true,false,true)
	check(g.energy==52 and g.shield_remaining_seconds>0,"C still costs40 while Z held")
	g._load_stage(1)
	g.events = []
	g.energy = 50
	g.clock.recovery = 0
	g._tick(Vector2.ZERO,false,true,false)
	check(g.energy==42,"X without Z still costs8")
	for i in range(7): g._tick(Vector2.ZERO,false,false,false)
	check(g.energy==43,"energy recovers while laser active when Z is released")
	g._tick(Vector2.ZERO,false,false,true)
	check(g.energy==3,"C without Z still costs40")
	for i in range(7): g._tick(Vector2.ZERO,false,false,false)
	check(g.energy==4,"energy recovers while shield active when Z is released")
	g.energy = 100
	for i in range(60): g._tick(Vector2.ZERO,false,false,false)
	check(g.energy==100,"recovery remains capped at100")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)

func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
