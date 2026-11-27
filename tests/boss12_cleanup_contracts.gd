extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Gates=preload("res://scripts/fire_gate_schema.gd")
const Motion=preload("res://scripts/rocket_fist_motion.gd")
const Boss=preload("res://scripts/boss.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Scheduler=preload("res://scripts/attack_timer.gd")
const Volleys=preload("res://scripts/projectile_volley.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	check(Catalog.validate_document(source).is_empty(),"migrated channel data validates")
	var changed: Dictionary=source.duplicate(true)
	changed.entities["1"].fire_channels[0].gate="part_alive"
	changed.entities["1"].fire_channels[0].part_id=113
	check(not Catalog.validate_document(changed).is_empty(),"ordinary enemy cannot author a boss-only part condition")
	changed=source.duplicate(true);changed.entities["92"].fire_channels[1].gate="charge_y"
	check(not Catalog.validate_document(changed).is_empty(),"boss cannot author an actor-only movement gate")
	check(not Boss.enabled([],{"gate":"unknown"}),"unknown boss gate fails closed")
	check(not Fire.enabled(Catalog.create(1,Vector2.ZERO),{"gate":"part_alive","part_id":113}),"unsupported actor gate cannot silently fire")
	var part: Dictionary=Catalog.create(101,Vector2.ZERO)
	check(Boss.enabled([part],{"gate":"any_parts"}) and not Boss.enabled([part],{"gate":"no_parts"}),"normal and enraged gates are complementary")
	part.hp=0
	check(not Boss.enabled([part],{"gate":"any_parts"}) and Boss.enabled([part],{"gate":"no_parts"}),"dead pending-removal parts cannot retain normal phase")
	for id in [101,102]:
		var actor: Dictionary=Catalog.create(id,Vector2.ZERO)
		actor.fist_phase=Motion.Phase.DOCKED
		var before: Vector2=actor.pos
		var parent: Dictionary=Catalog.create(91,Vector2(200,80))
		Motion.steer(actor,Vector2(-1000,400),parent.pos,1.0/60)
		check(actor.pos==before,"steering does not change position even when socket moved")
		Motion.advance(actor,parent,1.0/60)
		check(actor.pos==Motion.dock(actor,parent.pos) and actor.fist_phase==Motion.Phase.DOCKED,"integration exclusively applies docked position")
		check(not actor.has("fist_step_origin") and actor.pattern==2101,"temporary steering snapshot is consumed and pattern is an output projection")
	var definition: Dictionary=Catalog.definition(91)
	check(not definition.has("attack") and definition.fire_channels.size()==2,"first boss has only common attack channels")
	var extra: Dictionary={"name":"extra","interval_seconds":0.3,"gate":"always","volley":{"type":"fixed","ports":[[0,60]],"velocity":[0,100],"projectile_kind":1}}
	var channels: Array=definition.fire_channels.duplicate()
	channels.append(extra)
	var owner: Dictionary=Catalog.create(91,Vector2(200,80))
	part.hp=250
	var events: Array=Scheduler.advance(owner,channels,0.3,func(c):return Boss.enabled([part],c))
	check(events.size()==2 and events[0].name=="eye_sweep" and events[1].name=="extra","additional channels coexist with first-boss sweep")
	check(Volleys.emit(owner,Vector2(175,400),extra).size()==1,"additional volley uses common geometry")
	changed=source.duplicate(true);changed.entities["91"].fire_channels.append(extra)
	check(Catalog.validate_document(changed).is_empty(),"first boss can add channels without special attack configuration")
	var aimed: Dictionary=definition.fire_channels[1]
	var origin:=Vector2(193,99.3)
	var overlap: Array=Volleys.emit(Catalog.create(91,Vector2(200,80)),origin-Vector2(25,18),aimed)
	check(overlap[0].velocity==Vector2(0,250),"coincident cockpit keeps the original downward aim fallback")
	for invalid in [0,-1,"8"]:
		changed=source.duplicate(true);changed.entities["91"].fire_channels[0].volley.period_seconds=invalid
		check(not Catalog.validate_document(changed).is_empty(),"invalid shared oscillation period rejected")
	changed=source.duplicate(true);changed.entities["91"].fire_channels[0].volley.sweep_degrees.pop_back()
	check(not Catalog.validate_document(changed).is_empty(),"oscillation angle ranges must match port count")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
