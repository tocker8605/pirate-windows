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
		var roll: float = probe.randf()
		if (success and roll<0.2) or (not success and roll>=0.5): return seed_value
	return -1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for rush in [false,true]:
		g.run_settings = g.run_settings.with_boss_rush(rush)
		for used in range(3):
			for band in range(4):
				g._load_stage(1)
				g.supply_director.damage_supply_count = used
				var probe := RandomNumberGenerator.new()
				var lower: float = [0.0,0.2,0.35,0.5][band]
				var upper: float = [0.2,0.35,0.5,1.0][band]
				var chosen: int = -1
				for seed_value in range(1000):
					probe.seed = seed_value
					var roll: float = probe.randf()
					if roll>=lower and roll<upper:
						chosen = seed_value
						break
				g.supply_director.rng.seed = chosen
				g._hurt_player(1)
				var expected: int = 1 if band<3-used else 0
				check(chosen>=0 and g.enemies.size()==expected and g.supply_director.damage_supply_count==used+expected,"rush%s remaining%d roll band%d uses50/35/20percent and only successes consume allowance"%[rush,3-used,band])
	g.run_settings = g.run_settings.with_boss_rush(false)
	var win: int = seed_for(true)
	var miss: int = seed_for(false)
	check(win>=0 and miss>=0,"deterministic success and failure seeds exist")
	g._load_stage(1)
	var planned: Array = g.supply_director.schedule.duplicate(true)
	g.supply_director.rng.seed = miss
	g._hurt_player(15)
	check(g.hp==85 and g.enemies.is_empty() and g.supply_director.damage_supply_count==0,"failed real-hit roll preserves stage allowance")
	g.supply_director.rng.seed = win
	var before: int = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.hp==85 and g.enemies.is_empty() and g.supply_director.rng.state==before,"invulnerable hit neither rolls nor spawns")
	g.invulnerability_seconds = 0
	var gameplay_before: int = Rng.state
	g._hurt_player(15)
	check(g.hp==70 and g.enemies.size()==1 and g.supply_director.damage_supply_count==1,"next successful actual hit spawns one extra health carrier")
	var carrier: Dictionary = g.enemies.at(0)
	check(carrier.kind==202 and carrier.pos.x>=75 and carrier.pos.x<=275 and carrier.pos.y==480 and carrier.pattern==1074,"emergency carrier uses standard approach and random X75..275")
	check(g.stats.spawned==1 and g.stats.supply_spawned==1 and Rng.state==gameplay_before,"spawn accounting is correct without consuming combat RNG")
	check(g.supply_director.schedule==planned and planned.filter(func(e): return e.kind==202).size()==3,"emergency supply is additional to three scheduled HP carriers")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.hp==55 and g.enemies.size()==2 and g.supply_director.damage_supply_count==2,"second successful hit uses the second emergency allowance")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.hp==40 and g.enemies.size()==3 and g.supply_director.damage_supply_count==3,"third successful hit uses the third emergency allowance")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.hp==25 and g.enemies.size()==3 and g.supply_director.rng.state==before,"fourth hit cannot roll or spawn after three allowances consumed")
	g._load_stage(2)
	check(g.supply_director.damage_supply_count==0,"stage load resets emergency allowance")
	g.boss = {"hp":100}
	g.stage_elapsed_seconds = 200
	g.supply_director.rng.seed = win
	g._hurt_player(15)
	check(g.enemies.size()==1 and g.enemies.at(0).kind==202,"normal boss fight permits emergency supply outside schedule window")
	g.run_settings = g.run_settings.with_boss_rush(true)
	g._load_stage(2)
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.enemies.size()==1 and g.enemies.at(0).kind==202 and g.supply_director.damage_supply_count==1 and g.supply_director.schedule.is_empty(),"BossRush successful hit spawns emergency HP carrier without scheduled supplies")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.enemies.size()==2 and g.supply_director.damage_supply_count==2,"BossRush permits two successful emergency deliveries per stage")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.enemies.size()==3 and g.supply_director.damage_supply_count==3,"BossRush permits the third emergency delivery")
	g.invulnerability_seconds = 0
	g.supply_director.rng.seed = win
	before = g.supply_director.rng.state
	g._hurt_player(15)
	check(g.enemies.size()==3 and before==g.supply_director.rng.state,"BossRush cannot exceed three emergency deliveries per stage")
	g._load_stage(3)
	g.supply_director.rng.seed = win
	g._hurt_player(15)
	check(g.enemies.size()==1 and g.supply_director.damage_supply_count==1,"next BossRush stage resets emergency HP allowance")
	g.run_settings = g.run_settings.with_boss_rush(false)
	g._load_stage(1)
	g.hp = 15
	g.supply_director.rng.seed = win
	g._hurt_player(15)
	check(g.hp==0 and g.enemies.is_empty() and g.supply_director.damage_supply_count==0,"fatal hit does not spawn an unusable supply")
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
	g.flow.state = "menu"
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
