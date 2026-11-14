extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const Store = preload("res://scripts/entity_store.gd")
const Rng = preload("res://scripts/random.gd")
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
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	for field in ["collision","motion","attack","damage_smoke","attachment","core_motion","drop","on_defeat"]:
		var altered: Dictionary = document.duplicate(true)
		var found := false
		for definition in altered.entities.values():
			if definition.has(field):
				definition[field].typo_field = 1
				found = true
				break
		check(found and not Catalog.validate_document(altered).is_empty(),"unknown nested field rejected in "+field)
	var altered: Dictionary = document.duplicate(true)
	altered.entities["93"].fire_channels[0].typo_field = 1
	check(not Catalog.validate_document(altered).is_empty(),"unknown attack-channel field rejected")
	for invalid in [0,-1,3,4.5,"50"]:
		check(not Weapons.validate_settings({"schema_version":1,"max_active_shots":invalid}).is_empty(),"invalid projectile gameplay budget rejected: "+str(invalid))
	check(not Weapons.validate_settings({"schema_version":1,"max_active_shots":50,"typo":1}).is_empty(),"player settings reject unknown fields")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(1)
	g.weapon = 3
	g.power = 7
	g.energy = 100
	for i in range(Weapons.active_limit()-3): g.shots.append({"pos":Vector2(100,100),"kind":1,"alive":true,"impact_remaining_seconds":-1})
	var first_id: int = g.shots.at(0).entity_id
	var random_state: int = Rng.state
	g._fire()
	check(g.shots.size()==47 and g.shots.contains(first_id) and g.energy==100 and Rng.state==random_state,"full-volley admission never overwrites old bullets, consumes energy or RNG when blocked")
	g.shots.remove(first_id)
	g._fire()
	check(g.shots.size()==50 and g.shots.valid() and not g.shots.contains(first_id),"freed capacity admits a complete volley with fresh stable identities")
	check(g.shots.at(49).entity_id>first_id and not g.shots.at(49).has("slot"),"player bullets have no recycled legacy slot numbers")
	g.shots.clear()
	for i in range(1000): g.shots.append({"pos":Vector2(100,100),"kind":1,"alive":true,"impact_remaining_seconds":-1})
	check(g.shots.size()==1000 and g.shots.valid(),"dynamic storage itself has no gameplay-budget capacity limit")
	g.shots.at(0).alive = false
	g._advance_shots()
	check(g.shots.size()==999 and g.shots.valid(),"in-place expired-bullet removal preserves all other linked entries")
	check(g.delta_seconds==1.0/60 and is_equal_approx(Catalog.definition(133).core_motion.detach_hp,200),"public timestep is seconds and core threshold lives in metadata")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
