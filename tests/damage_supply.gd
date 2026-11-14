extends SceneTree
const Game = preload("res://scripts/game.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func seed_for(success: bool) -> int:
	var probe := RandomNumberGenerator.new()
	for seed_value in range(1000):
		probe.seed = seed_value
		if (probe.randf()<0.3)==success: return seed_value
	return -1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	var win: int = seed_for(true)
	var miss: int = seed_for(false)
	check(win>=0 and miss>=0,"deterministic success and failure seeds exist")
	g._load_stage(1)
	var planned: Array = g.supply_director.schedule.duplicate(true)
	g.supply_director.rng.seed = miss
	g._hurt_player(15)
	check(g.hp==85 and g.enemies.is_empty() and not g.supply_director.damage_supply_used,"failed real-hit roll preserves stage allowance")
	g.supply_director.rng.seed = win
	var before: int = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.hp==85 and g.enemies.is_empty() and g.supply_director.rng.state==before,"invulnerable hit neither rolls nor spawns")
	g.invulnerability_seconds = 0
	var gameplay_before: int = Rng.state
	g._hurt_player(15)
	check(g.hp==70 and g.enemies.size()==1 and g.supply_director.damage_supply_used,"next successful actual hit spawns one extra health carrier")
	var carrier: Dictionary = g.enemies.at(0)
	check(carrier.kind==202 and carrier.pos.x>=100 and carrier.pos.x<=300 and carrier.pos.y==480 and carrier.pattern==1074,"emergency carrier uses standard approach and random X100..300")
	check(g.stats.spawned==1 and g.stats.supply_spawned==1 and Rng.state==gameplay_before,"spawn accounting is correct without consuming combat RNG")
	check(g.supply_director.schedule==planned and planned.filter(func(e): return e.kind==202).size()==3,"emergency supply is additional to unchanged three scheduled HP carriers")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.hp==55 and g.enemies.size()==1 and g.supply_director.rng.state==before,"later hits cannot roll or spawn after allowance consumed")
	g._load_stage(2)
	check(not g.supply_director.damage_supply_used,"stage load resets emergency allowance")
	g.boss = {"hp":100}
	g.stage_elapsed_seconds = 200
	g.supply_director.rng.seed = win
	g._hurt_player(15)
	check(g.enemies.size()==1 and g.enemies.at(0).kind==202,"normal boss fight permits emergency supply outside schedule window")
	g.boss_rush = true
	g._load_stage(2)
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.enemies.is_empty() and not g.supply_director.damage_supply_used and before==g.supply_director.rng.state,"BossRush actual hit never rolls or spawns supplies")
	g.boss_rush = false
	g._load_stage(1)
	g.hp = 15
	g.supply_director.rng.seed = win
	g._hurt_player(15)
	check(g.hp==0 and g.enemies.is_empty() and not g.supply_director.damage_supply_used,"fatal hit does not spawn an unusable supply")
	g._load_stage(1)
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(0)
	check(g.enemies.is_empty() and before==g.supply_director.rng.state,"zero damage does not roll")
	g.invulnerability_seconds = 0
	g.death_remaining_seconds = 1
	g._hurt_player(15)
	check(g.enemies.is_empty() and before==g.supply_director.rng.state,"death animation cannot trigger delivery")
	g._load_stage(1)
	g.state = "menu"
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.enemies.is_empty() and before==g.supply_director.rng.state,"nonplaying state cannot trigger delivery")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
