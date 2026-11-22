extends SceneTree
## Compare first boss asset preparation against the already-cached path.
const Game=preload("res://scripts/game.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const GroundArt=preload("res://scripts/ground_art.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Campaign=preload("res://scripts/campaign_rules.gd")
func _initialize() -> void:call_deferred("run")
func resolve(g: Node,ids: Array) -> void:
	for id in ids:
		var d: Dictionary=Catalog.definition(id)
		if Geometry.layer(d)=="floor" or d.has("ground_turret"):
			if g.view.ground_art==null:g.view.ground_art=GroundArt.new()
			g.view.ground_art.textures.for_definition(d)
			if d.has("ground_turret"):
				for asset in [d.ground_turret.hatch,d.ground_turret.wreck]:g.view.ground_art.textures.for_asset(asset)
			if d.has("floor_decoration"):g.view.ground_art.textures.for_asset(d.floor_decoration.asset)
		else:g.view.renewal.enemy_texture(id)
	g._play_music(Catalog.boss_definition(g.stage).music)
func run() -> void:
	var g=Game.new();g.automatic=false;g.mute=true;root.add_child(g);await process_frame;g.set_process(false)
	for stage in range(1,Campaign.stage_count()+1):
		var start: int=Time.get_ticks_usec();g._load_stage(stage)
		var stage_ms: float=(Time.get_ticks_usec()-start)/1000.0
		var ids: Array=[]
		for event in g.events:
			if event.get("action")=="spawn" and Catalog.definition(int(event.definition_id)).role in ["boss","part"] and int(event.definition_id) not in ids:ids.append(int(event.definition_id))
		start=Time.get_ticks_usec();resolve(g,ids);var first_ms: float=(Time.get_ticks_usec()-start)/1000.0
		g._stop_music();start=Time.get_ticks_usec();resolve(g,ids);var repeat_ms: float=(Time.get_ticks_usec()-start)/1000.0
		print("STAGE%d stage_load_ms=%.3f boss_assets_first_ms=%.3f boss_assets_repeat_ms=%.3f"%[stage,stage_ms,first_ms,repeat_ms])
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout;quit()
