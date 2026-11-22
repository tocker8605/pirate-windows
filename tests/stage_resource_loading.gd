extends SceneTree
const Game=preload("res://scripts/game.gd")
const Resources=preload("res://scripts/stage_resources.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Rng=preload("res://scripts/random.gd")
const Campaign=preload("res://scripts/campaign_rules.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func loads(g: Node) -> Array:
	return [g.view.renewal.texture_cache.source_loads,g.view.ground_art.textures.source_loads if g.view.ground_art!=null else 0,g.audio.stream_loads,g.art.textures.size()]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=Game.new();g.automatic=false;g.mute=true;root.add_child(g);await process_frame;g.set_process(false)
	for rush in [false,true]:
		g.run_settings=g.run_settings.with_boss_rush(rush)
		for stage in range(1,Campaign.stage_count(rush)+1):
			g._load_stage(stage)
			await process_frame;await process_frame # Ordinary first-stage HUD/player rendering precedes the boss.
			var manifest: Dictionary=Resources.manifest(stage,g.events,rush)
			check(int(Catalog.boss_definition(stage).id) in manifest.entities,"stage%d rush%s prepares its own boss from the timeline"%[stage,rush])
			check(g.frame==0 and g.stage_elapsed_seconds==0 and g.boss.is_empty() and g.enemies.is_empty(),"preparing stage assets never spawns entities or advances the timeline")
			check(g.music_track==("" if rush else Campaign.music(stage)),"preparing boss audio does not play it ahead of its event")
			var before: Array=loads(g)
			var rng: int=Rng.state
			Resources.prepare(g)
			check(loads(g)==before and Rng.state==rng,"repeated stage preparation is cached and consumes no gameplay RNG")
			for id in manifest.entities:
				check(Catalog.definition(id).sprite_path.begins_with("res://assets/"),"all authored entity assets come from the catalog")
			var at: float=-1
			for event in g.events:
				if event.get("action")=="spawn" and Catalog.definition(int(event.definition_id)).role=="boss":at=event.at;break
			check(at>=0,"each stage has an authored boss event")
			g.events=g.events.filter(func(event):return is_equal_approx(float(event.at),at))
			g.event_cursor=0;g.stage_elapsed_seconds=at+0.01
			g._read_events();g._redraw();await process_frame;await process_frame
			check(loads(g)==before,"stage%d rush%s boss appearance and initial drawing perform zero texture/music cache misses %s -> %s"%[stage,rush,before,loads(g)])
			check(g.music_track==Catalog.boss_definition(stage).music and not g.music.stream.loop,"boss music still starts at its spawn and does not loop")
			var stream=g.music.stream
			g._stop_music();g._play_music(Catalog.boss_definition(stage).music)
			check(is_same(stream,g.music.stream) and loads(g)==before,"music remains prepared across stop and replay")
	# Keep the original sprite option on the same preparation path.
	g.run_settings=g.run_settings.with_boss_rush(false);g.renewed_art=false
	for stage in range(1,Campaign.stage_count()+1):
		g._load_stage(stage)
		var before: Array=loads(g);Resources.prepare(g)
		check(loads(g)==before,"classic stage%d preparation also reuses prebuilt frames"%stage)
	var custom: Array=[{"action":"spawn","definition_id":91},{"action":"spawn","definition_id":141},{"action":"spawn","definition_id":141}]
	var manifest: Dictionary=Resources.manifest(1,custom,true)
	check(manifest.entities==[91,141] and manifest.music==["boss01"],"manifest follows authored IDs across stages and deduplicates resources without stage-specific branches")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout;quit(0 if failures==0 else 1)
