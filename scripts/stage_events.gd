extends RefCounted
## Named timeline events, validated before play. No per-frame legacy actor quota.
const Check = preload("res://scripts/data_validation.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
static func validate_document(document: Variant) -> PackedStringArray:
	if not document is Dictionary or document.get("schema_version",0)!=2 or document.get("time_unit","")!="seconds" or not document.get("events") is Array:
		return PackedStringArray(["Expected version2 timeline with seconds time unit"])
	var errors := PackedStringArray()
	var previous: float = -1
	for i in range(document.events.size()):
		var e: Variant = document.events[i]
		var prefix: String = "event %d: "%i
		if not e is Dictionary:
			errors.append(prefix+"expected object")
			continue
		if not Check.number(e.get("at")) or float(e.get("at",-1))<0 or float(e.get("at",-1))<previous:
			errors.append(prefix+"at must be nonnegative and ordered")
		else: previous = float(e.at)
		var allowed: Array = ["at","action"]
		match e.get("action",""):
			"spawn":
				allowed += ["definition_id","position","pattern","overrides"]
				if not Check.number(e.get("definition_id")) or float(e.get("definition_id",0))!=int(e.get("definition_id",0)) or Catalog.definition(int(e.get("definition_id",0))).is_empty(): errors.append(prefix+"unknown definition_id")
				if Check.number(e.get("definition_id")) and Catalog.definition(int(e.definition_id)).get("role","")=="supply": errors.append(prefix+"supply carriers belong to SupplyDirector, not timelines")
				if not Check.vector(e.get("position"),2): errors.append(prefix+"position must contain X,Y")
				if not Check.number(e.get("pattern",0)): errors.append(prefix+"invalid pattern")
				if e.has("overrides"):
					if not e.overrides is Dictionary or e.overrides.keys().any(func(key): return key!="hp") or not Check.number(e.overrides.get("hp")) or float(e.overrides.get("hp",0))<=0: errors.append(prefix+"only a positive HP override is supported")
			"scroll":
				allowed += ["mode","speed"]
				if int(e.get("mode",0)) not in [1,2,3] or not Check.number(e.get("speed")) or float(e.get("speed",-1))<0: errors.append(prefix+"invalid scroll mode/speed")
			"banner":
				allowed += ["name"]
				if e.get("name","") not in ["warning","mission"]: errors.append(prefix+"unknown banner")
			_: errors.append(prefix+"unknown action")
		for key in e:
			if key not in allowed: errors.append(prefix+"unexpected field "+str(key))
	return errors
static func load_stage(stage: int, boss_rush: bool = false) -> Array:
	var path: String = "res://data/stage%02d.json"%(stage+10 if boss_rush else stage)
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:
		push_error("%s:%d: %s"%[path,parser.get_error_line(),parser.get_error_message()])
		return []
	var errors: PackedStringArray = validate_document(parser.data)
	if not errors.is_empty():
		push_error(path+": "+"; ".join(errors))
		return []
	return parser.data.events
static func consume(g: Node) -> void:
	while g.event_cursor<g.events.size():
		var raw: Variant = g.events[g.event_cursor]
		if not raw is Dictionary or not raw.has("at") or not raw.has("action"):
			push_error("Timeline event %d was not loaded through the validated event loader"%g.event_cursor)
			g.event_cursor = g.events.size()
			return
		var event: Dictionary = raw
		if float(event.at)+0.000000003>=g.stage_elapsed_seconds: break
		g.event_cursor += 1
		match event.action:
			"banner":
				g.banner = "WARNING / BOSS APPROACHING" if event.name=="warning" else "MISSION %02d / TAKE OFF"%g.stage
				g.banner_remaining_seconds = 2.4
			"scroll":
				g.map_mode = int(event.mode)
				g.scroll_target = float(event.speed)
			"spawn":
				var kind: int = int(event.definition_id)
				if Catalog.definition(kind).get("role","")=="supply": continue
				var actor: Dictionary = Catalog.create(kind,Vector2(event.position[0],event.position[1]),int(event.get("pattern",0)),event.get("overrides",{}))
				if Catalog.definition(kind).role=="boss":
					g.boss = actor
					g.stats.boss_spawned = true
					g._play_music(Catalog.definition(kind).music)
					g.banner = ""
					g.banner_remaining_seconds = 0
				else:
					g.enemies.append(actor)
					g.stats.spawned += 1
