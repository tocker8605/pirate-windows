extends RefCounted
## One ordered stage registry for campaign, backgrounds, clouds and initial scrolling.
const PATH: String="res://data/stages.json"
const Check=preload("res://scripts/data_validation.gd")
static var _stages: Array=_load_stages()
static func validate(document: Variant) -> PackedStringArray:
	var errors:=PackedStringArray()
	if not document is Dictionary or document.get("schema_version")!=1 or not document.get("stages") is Array:
		return PackedStringArray(["Expected stage registry schema_version1 and stages array"])
	if document.stages.is_empty():errors.append("stages must not be empty")
	var rush_ended: bool=false
	for i in range(document.stages.size()):
		var d: Variant=document.stages[i]
		var prefix: String="stage%d: "%[i+1]
		if not d is Dictionary: errors.append(prefix+"expected object");continue
		Check.unknown_fields(d,["id","boss_rush","music","regions","layout","initial","boss_rush_initial","cloud_texture","classic_background"],prefix,errors)
		if d.get("id")!=i+1:errors.append(prefix+"IDs must be contiguous and ordered")
		if not d.get("boss_rush") is bool or not d.get("music") is String:errors.append(prefix+"invalid mode/music")
		if not d.get("boss_rush",false):rush_ended=true
		elif rush_ended:errors.append(prefix+"Boss Rush stages must form a contiguous prefix")
		if d.get("layout") not in ["three_region","earth_lunar"]:errors.append(prefix+"unknown background layout")
		var regions: Variant=d.get("regions")
		if not regions is Array:errors.append(prefix+"regions must be an array")
		else:
			if regions.size()!=(4 if d.get("layout")=="earth_lunar" else 3):errors.append(prefix+"region count does not match layout")
			for region in regions:
				if not region is Dictionary or not region.get("name") is String or not region.get("path","").begins_with("res://assets/backgrounds/"):errors.append(prefix+"invalid background region")
		for field in ["cloud_texture","classic_background"]:
			if not d.get(field) is String:errors.append(prefix+"missing "+field)
		for field in ["initial","boss_rush_initial"]:
			var initial: Variant=d.get(field,{})
			if not initial is Dictionary:errors.append(prefix+"invalid "+field);continue
			Check.unknown_fields(initial,["background_y","map_mode","scroll_speed","scroll_target"],prefix+field+".",errors)
			for key in initial:
				if not Check.number(initial[key]):errors.append(prefix+"invalid initial "+key)
			if field=="initial":
				for key in ["background_y","map_mode","scroll_speed","scroll_target"]:
					if not initial.has(key):errors.append(prefix+"missing initial "+key)
	return errors
static func _load_stages() -> Array:
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATH))!=OK:push_error("Invalid stage registry JSON");return []
	var errors: PackedStringArray=validate(parser.data)
	if not errors.is_empty():push_error("; ".join(errors));return []
	var result: Array=parser.data.stages
	for d in result:_freeze(d)
	result.make_read_only()
	return result
static func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for child in value.values():_freeze(child)
		value.make_read_only()
	elif value is Array:
		for child in value:_freeze(child)
		value.make_read_only()
static func count(boss_rush: bool = false) -> int:
	return _stages.filter(func(d):return d.boss_rush).size() if boss_rush else _stages.size()
static func definition(stage: int) -> Dictionary:return _stages[clampi(stage,1,_stages.size())-1]
static func initial(stage: int,boss_rush: bool = false) -> Dictionary:
	var d: Dictionary=definition(stage)
	var state: Dictionary=d.initial.duplicate()
	if boss_rush:state.merge(d.get("boss_rush_initial",{}),true)
	return state
