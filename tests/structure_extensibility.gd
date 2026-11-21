extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Stages=preload("res://scripts/stage_catalog.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Textures=preload("res://scripts/entity_textures.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const CombatRandom=preload("res://scripts/random.gd")
const VisualRandom=preload("res://scripts/visual_random.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Stages.PATH))
	check(Stages.validate(registry).is_empty(),"stage registry is valid")
	var stage6: Dictionary=registry.stages[-1].duplicate(true)
	stage6.id=6
	registry.stages.append(stage6)
	check(Stages.validate(registry).is_empty(),"a sixth ordinary stage requires no parallel code arrays")
	stage6.boss_rush=true
	check(not Stages.validate(registry).is_empty(),"discontinuous Boss Rush membership is rejected")
	stage6.boss_rush=false
	stage6.regions=[]
	check(not Stages.validate(registry).is_empty(),"background layout and region count are checked together")
	check(Stages.initial(4,false).map_mode==2 and Stages.initial(4,true).map_mode==1,"stage4 preserves the distinct normal and Boss Rush takeoff modes")
	check(Stages.initial(5).scroll_speed==60 and Stages.initial(5).scroll_target==60,"stage5 preserves60px/s initial floor scroll")
	var document: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	var body: Dictionary=document.entities["95"]
	body.visual.layer="air"
	body.boss_scroll.stop_on_spawn=false
	check(Catalog.validate_document(document).is_empty(),"stationary movement is valid independently of air layer and moving background")
	body.visual.layer="floor"
	body.movement_mode="pattern"
	check(Catalog.validate_document(document).is_empty(),"floor layer does not force a stationary boss")
	body.sprite_path="res://assets/enemies/ring_rotor.png"
	check(Catalog.validate_document(document).is_empty(),"sprite registration has no hardcoded stage5 filename whitelist")
	body.sprite_region=[0,0,-1,10]
	check(not Catalog.validate_document(document).is_empty(),"negative texture crop width is rejected")
	var malformed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	malformed.entities["1"].fire_channels[0].volley=[]
	check(not Catalog.validate_document(malformed).is_empty(),"malformed volley data is rejected without a parser/runtime error")
	var cache=Textures.new()
	check(cache.textures.is_empty(),"creating a ground texture cache performs no eager boss loads")
	var turret: Dictionary=Catalog.definition(51)
	var image: Texture2D=cache.for_definition(turret)
	check(image.get_size()==Vector2(713,891) and cache.textures.size()==1,"only the requested turret image is cached with its original crop")
	for kind in [141,142,143,144]:
		var d: Dictionary=Catalog.definition(kind).duplicate(true)
		d.visual=d.visual.duplicate()
		d.visual.rotation_radians=0.37
		var anchor:=Vector2(120,130)
		var uv:=Vector2(d.visual.hinge_uv[0],d.visual.hinge_uv[1])
		check(Geometry.image_point(d,anchor,uv,Textures.native_size(d)).distance_to(anchor)<0.0001,"part%d hinge remains anchored after mirroring, fitting and future rotation"%kind)
	var scout: Dictionary=Catalog.create(1,Vector2(120,100))
	scout.velocity=Vector2(0,100)
	check(Fire.advance(scout,0.35,Vector2(200,400)).is_empty(),"scout waits for a complete360ms enabled interval")
	check(Fire.advance(scout,0.01,Vector2(200,400)).size()==1,"scout fires at360ms")
	Fire.advance(scout,0.2)
	scout.velocity.y=166.6666666666667
	check(Fire.advance(scout,0.2).is_empty(),"scout speed gate still disables firing")
	scout.velocity.y=100
	check(Fire.advance(scout,0.35).is_empty() and Fire.advance(scout,0.01).size()==1,"scout re-enters with a fresh interval rather than a queued shot")
	var delta: Dictionary=Catalog.create(7,Vector2(120,100))
	check(Fire.advance(delta,0.71).is_empty() and Fire.advance(delta,0.01).size()==3,"delta retains720ms and simultaneous three-way emission")
	CombatRandom.state=0x50000
	var expected: int=CombatRandom.between(0,59)
	var expected_state: int=CombatRandom.state
	CombatRandom.state=0x50000
	var event=VisualRandom.legacy_event()
	check(event.between(0,59)==expected and CombatRandom.state==expected_state,"legacy visual event preserves its original first sample and combat reservation")
	for i in range(100):event.between(0,999);VisualRandom.between(0,999)
	check(CombatRandom.state==expected_state,"additional cosmetic draws cannot change combat RNG")
	CombatRandom.state=0x50000
	VisualRandom.reserve_transition_history()
	check(CombatRandom.state==expected_state,"retired loading selection retains exactly one historical combat slot")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
