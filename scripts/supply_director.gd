extends RefCounted
## Independent supply scheduling; authored stage timelines contain combat events only.
const Catalog = preload("res://scripts/enemy_catalog.gd")
const EARLY_POWER_SECONDS: float = 1.0
const START_SECONDS: float = 10.0
const BOSS_MARGIN_SECONDS: float = 10.0
const POWER_COUNT: int = 3
const CATCHUP_POWER_COUNT: int = 6
const HEALTH_COUNT: int = 3
const DAMAGE_HEALTH_CHANCE: float = 0.3
const SPAWN_X := Vector2(100,300)
var rng := RandomNumberGenerator.new()
var schedule: Array = []
var cursor: int = 0
var window_end: float = 0.0
var damage_supply_used: bool = false
func _init() -> void: rng.randomize()
func plan(stage: int, starting_power: int, events: Array, boss_rush: bool = false) -> void:
	schedule.clear()
	cursor = 0
	window_end = 0
	damage_supply_used = false
	if boss_rush: return
	for event in events:
		if event.action=="spawn" and Catalog.definition(int(event.definition_id)).get("role","")=="boss":
			window_end = float(event.at)-BOSS_MARGIN_SECONDS
			break
	var power_count: int = CATCHUP_POWER_COUNT if stage>=2 and starting_power==1 else POWER_COUNT
	if stage>=2:
		schedule.append(_delivery(EARLY_POWER_SECONDS,201))
		power_count -= 1
	if window_end<=START_SECONDS: return
	var kinds: Array = []
	for i in range(HEALTH_COUNT): kinds.append(202)
	for i in range(power_count): kinds.append(201)
	# Shuffle payload order, then choose one random time in each equal window slice.
	# This remains random while avoiding stacked or heavily clustered deliveries.
	for i in range(kinds.size()-1,0,-1):
		var j: int = rng.randi_range(0,i)
		var saved: int = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = saved
	var slice: float = (window_end-START_SECONDS)/kinds.size()
	for i in range(kinds.size()):
		schedule.append(_delivery(START_SECONDS+slice*(i+rng.randf_range(0.1,0.9)),int(kinds[i])))
func _delivery(at: float, kind: int) -> Dictionary:
	return {"at":at,"kind":kind,"pos":Vector2(rng.randf_range(SPAWN_X.x,SPAWN_X.y),480),"pattern":1074}
func advance(g: Node) -> void:
	if g.boss_rush or g.state!="playing" or not g.boss.is_empty(): return
	while cursor<schedule.size() and float(schedule[cursor].at)<=g.stage_elapsed_seconds+0.000000003:
		var delivery: Dictionary = schedule[cursor]
		cursor += 1
		_spawn(g,delivery)
func on_player_hit(g: Node) -> void:
	# Extra delivery: only a successful roll consumes the once-per-stage allowance.
	# Unlike scheduled deliveries this may also happen during a normal boss fight.
	if g.boss_rush or g.state!="playing" or g.hp<=0 or damage_supply_used: return
	if rng.randf()>=DAMAGE_HEALTH_CHANCE: return
	damage_supply_used = true
	_spawn(g,_delivery(g.stage_elapsed_seconds,202))
func _spawn(g: Node, delivery: Dictionary) -> void:
	g.enemies.append(Catalog.create(int(delivery.kind),delivery.pos,int(delivery.pattern)))
	g.stats.spawned += 1
	g.stats.supply_spawned += 1
