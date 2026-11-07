extends SceneTree
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const Combat = preload("res://scripts/combat.gd")
const Clock = preload("res://scripts/timing.gd")
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
	var carrier = {"kind":201,"pos":Vector2(75,290.7)}
	Rules.carrier(carrier,292.4)
	check(carrier.kind==19,"fractional carrier crossing opens without requiring exact Y291")
	carrier.kind = 201
	carrier.rescued = true
	Rules.carrier(carrier,292.4)
	check(carrier.kind==201,"rescued carrier cannot reopen at the same boundary")
	carrier = {"kind":201,"pos":Vector2(75,292.4)}
	Rules.carrier(carrier,294.0)
	check(carrier.kind==201 and not Combat.shot_hits(carrier.pos,carrier),"approaching carrier stays protected before reaching the boundary")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	for speed in range(1,6):
		g._load_stage(1)
		g.clock = Clock.new()
		g.events = g.events.filter(func(row): return int(row.get("definition_id",0))==201).slice(0,1)
		var units: float = Clock.units_per_tick(speed)
		var found: Dictionary = {}
		for i in range(2000):
			g._tick(Vector2.ZERO,false,false,false,units)
			if not g.enemies.is_empty() and g.enemies.at(0).kind==19:
				found = g.enemies.at(0)
				break
		check(not found.is_empty() and found.pos.y<=291.001,"speed%d actual authored carrier becomes vulnerable at native60Hz"%speed)
		if found.is_empty(): continue
		g.shots = [{"pos":found.pos,"kind":1,"alive":true,"impact_ticks":-1}]
		g._resolve_shots()
		check(found.hp<=0 and g.stats.hits==1,"speed%d player shot damages the opened supply craft"%speed)
		g._tick(Vector2.ZERO,false,false,false,units)
		check(found.kind==201 and found.get("rescued",false) and g.items.size()==1 and g.items.at(0).kind==1,"speed%d rescue produces exactly one power item"%speed)
		for i in range(int(ceil(20.0/units))): g._tick(Vector2.ZERO,false,false,false,units)
		check(found.kind==201 and g.items.size()==1 and g.score==500,"speed%d escaping carrier does not reopen or duplicate rewards"%speed)
		g.player = g.items.at(0).pos-Vector2(25,25)
		g._update_items()
		check(g.power==2 and g.energy==100 and g.items.is_empty(),"speed%d power item is collectible and raises weapon power"%speed)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
