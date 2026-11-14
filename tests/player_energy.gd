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
			var expected_cost: float = 0.67 if power%2==0 else 1.0
			var expected_period: float = 0.06 if power%2==0 else 0.09
			var expected_count: int = 1 if power<=2 else (2 if power<=4 else (3 if power<=6 else 4))
			var ok: bool = is_equal_approx(100-g.energy,expected_cost) and is_equal_approx(g.fire_cooldown_seconds,expected_period) and g.shots.size()==expected_count and is_equal_approx(Weapons.cost(power),expected_cost)
			checks += 1
			if ok: print("PASS: weapon%d power%d charges once per volley with matching cadence"%[weapon,power])
			else:
				failures += 1
				push_error("FAIL: weapon%d power%d cost/cadence/volley mismatch"%[weapon,power])
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
