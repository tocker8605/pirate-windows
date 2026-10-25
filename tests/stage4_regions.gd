extends SceneTree
const Game = preload("res://scripts/game.gd")
const Regions = preload("res://scripts/background_regions.gd")
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
	check(Regions.count(4)==4 and Regions.count(1)==3,"stage4 has four environments while the other stages retain three")
	for pair in [[3360,1],[2880,1],[2879,2],[2400,2],[1920,2],[1440,2],[1439,3],[960,3],[959,4],[480,4],[0,4]]:
		var region: Dictionary = Regions.sample(pair[0],4)
		check(region.near==pair[1] and region.far==pair[1],"stage4 original source Y%d identifies environment%d"%pair)
	check(Regions.earth_phase(3360)==0.5 and Regions.earth_phase(2880)==0 and Regions.earth_phase(2400)== -0.5,"Earth panorama phase is unwrapped and never repeats by modulo")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(4)
	check(g.map_mode==2 and g.scroll_speed==2,"normal stage4 starts in map2 at the original slow speed")
	var monotonic: bool = true
	for i in range(480):
		var before: float = g.background_y
		g._update_scenery()
		monotonic = monotonic and g.background_y==before-2
	check(monotonic and g.background_y==2400,"Earth departure crosses all 960px once with no 480px restart")
	check(Regions.sample(g.background_y,4).near==2 and Regions.sample(g.background_y+479,4).near==2,"after departure the complete viewport shows space without lingering Earth tiles")
	g.background_y = 1920
	var space_only: bool = true
	for i in range(500):
		g._update_scenery()
		space_only = space_only and Regions.sample(g.background_y,4).near==2 and Regions.sample(g.background_y+479,4).near==2
	check(space_only,"map2 repeats only space for as long as its original loop remains active")
	g.background_y = 1920
	g.map_mode = 3
	var path: Array = []
	for i in range(1100):
		g._update_scenery()
		var section: int = Regions.sample(g.background_y+240,4).near
		if path.is_empty() or path[-1]!=section: path.append(section)
	check(path==[2,3,4],"released space loop traverses the Moon surface once before the cavern loop")
	check(g.background_y>=0 and g.background_y<=480 and Regions.sample(g.background_y+479,4).near==4,"map3's final loop stays entirely underground and never repeats the surface")
	g._load_stage(4)
	g.events = g.events.filter(func(row): return int(row[1])==71)
	g.frame = 2730
	g._read_events()
	check(g.map_mode==2 and g.scroll_target==25,"surface approach remains gated by the original t91 event")
	g.background_y = 1920
	g.frame = 2731
	g._read_events()
	check(g.map_mode==3 and g.scroll_target==2 and g.background_y==1920,"t91 releases space and decelerates without teleporting the viewport")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	await create_timer(0.15).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
