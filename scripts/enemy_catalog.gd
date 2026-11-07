extends RefCounted
## Shared, immutable entity defaults. Runtime HP lives only on created actors.
const PATH = "res://data/enemies.json"
const FIELDS: Array = ["name","role","hp","score","score_scales_with_difficulty","damageable","explosion_ticks","death_sound","draw_size","draw_offset","part_side","collision","damage_smoke","boss_rush_drop","drop","stage","music","open_at_y","open_kind","on_defeat"]
static var _entities: Dictionary = _load_definitions()
static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
static func _vector(value: Variant, length: int) -> bool:
	return value is Array and value.size()==length and value.all(func(n): return _number(n))
static func validate_document(document: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not document is Dictionary or document.get("schema_version",0)!=1 or not document.get("entities") is Dictionary:
		return PackedStringArray(["Expected schema_version1 and entities object"])
	var boss_stages: Array = []
	for key in document.entities:
		var d: Variant = document.entities[key]
		var prefix: String = "entity %s: "%key
		if not str(key).is_valid_int() or int(key)<=0 or not d is Dictionary:
			errors.append(prefix+"invalid ID or definition")
			continue
		for field in d:
			if field not in FIELDS: errors.append(prefix+"unexpected field "+str(field))
		if not d.get("name") is String or d.get("name","").is_empty(): errors.append(prefix+"name is required")
		if d.get("role")=="boss":
			if int(d.get("stage",0)) in boss_stages: errors.append(prefix+"duplicate boss stage")
			boss_stages.append(int(d.get("stage",0)))
		if not d.get("role","") in ["enemy","part","boss","supply"]: errors.append(prefix+"invalid role")
		if not _number(d.get("hp")) or float(d.get("hp",0))<=0: errors.append(prefix+"hp must be positive")
		if not _number(d.get("score")) or float(d.get("score",-1))<0: errors.append(prefix+"score must be nonnegative")
		if not d.get("damageable") is bool or not d.get("score_scales_with_difficulty") is bool: errors.append(prefix+"missing boolean flags")
		if not _vector(d.get("draw_size"),2) or not _vector(d.get("draw_offset"),2): errors.append(prefix+"invalid draw geometry")
		var collision: Variant = d.get("collision",{})
		if not collision is Dictionary:
			errors.append(prefix+"collision must be an object")
			continue
		if not _vector(collision.get("shot_bounds"),4) or not _vector(collision.get("beam_bounds"),2): errors.append(prefix+"invalid collision bounds")
		if _vector(collision.get("shot_bounds"),4) and (collision.shot_bounds[0]>=collision.shot_bounds[2] or collision.shot_bounds[1]>=collision.shot_bounds[3]): errors.append(prefix+"shot bounds must have increasing edges")
		if _vector(collision.get("beam_bounds"),2) and collision.beam_bounds[0]>=collision.beam_bounds[1]: errors.append(prefix+"beam bounds must have increasing edges")
		if not _number(d.get("explosion_ticks")) or float(d.get("explosion_ticks",0))<=0: errors.append(prefix+"invalid explosion duration")
		if d.get("role")=="boss" and (int(d.get("stage",0)) not in [1,2,3,4] or not d.get("music") is String): errors.append(prefix+"boss stage/music missing")
		if d.has("damage_smoke"):
			var smoke: Variant = d.damage_smoke
			if not smoke is Dictionary:
				errors.append(prefix+"damage_smoke must be an object")
				continue
			if smoke.has("below_hp")==smoke.has("below_ratio"): errors.append(prefix+"smoke needs exactly one threshold")
			if smoke.has("below_hp") and (not _number(smoke.below_hp) or float(smoke.below_hp)<0): errors.append(prefix+"invalid smoke HP")
			if smoke.has("below_ratio") and (not _number(smoke.below_ratio) or float(smoke.below_ratio)<0 or float(smoke.below_ratio)>1): errors.append(prefix+"invalid smoke ratio")
			if not _number(smoke.get("size")) or float(smoke.get("size",0))<=0: errors.append(prefix+"invalid smoke size")
			if not smoke.get("ports") is Array or not smoke.ports.all(func(p): return _vector(p,2)): errors.append(prefix+"invalid smoke ports")
		for field in ["drop","boss_rush_drop"]:
			if d.has(field) and (not d[field] is Dictionary or int(d[field].get("item",0)) not in [1,2] or not _vector(d[field].get("offset"),2)): errors.append(prefix+"invalid "+field)
		if d.has("open_kind") and not document.entities.has(str(int(d.open_kind))): errors.append(prefix+"unknown open_kind")
		if d.has("on_defeat"):
			if not d.on_defeat is Dictionary or d.on_defeat.get("action","")!="release_and_escape" or not document.entities.has(str(int(d.on_defeat.get("definition_id",0)))): errors.append(prefix+"invalid escape action/reference")
	return errors
static func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for child in value.values(): _freeze(child)
		value.make_read_only()
	elif value is Array:
		for child in value: _freeze(child)
		value.make_read_only()
static func _load_definitions() -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATH))!=OK:
		push_error("%s:%d: %s"%[PATH,parser.get_error_line(),parser.get_error_message()])
		return {}
	var errors: PackedStringArray = validate_document(parser.data)
	if not errors.is_empty():
		push_error(PATH+": "+"; ".join(errors))
		return {}
	var result: Dictionary = {}
	for key in parser.data.entities:
		var d: Dictionary = parser.data.entities[key]
		d.id = int(key)
		d.draw_size = Vector2(d.draw_size[0],d.draw_size[1])
		d.draw_offset = Vector2(d.draw_offset[0],d.draw_offset[1])
		if d.has("damage_smoke"): d.damage_smoke.ports = d.damage_smoke.ports.map(func(p): return Vector2(p[0],p[1]))
		for field in ["drop","boss_rush_drop"]:
			if d.has(field): d[field].offset = Vector2(d[field].offset[0],d[field].offset[1])
		result[int(key)] = d
	_freeze(result)
	return result
static func cargo_drop() -> Dictionary:
	for d in _entities.values():
		if d.get("drop",{}).get("cargo_release",false): return d.drop
	return {}
static func ids() -> Array: return _entities.keys()
static func definition(kind: int) -> Dictionary: return _entities.get(kind,{})
static func boss_definition(stage: int) -> Dictionary:
	for d in _entities.values():
		if d.role=="boss" and int(d.stage)==stage: return d
	return {}
static func for_actor(actor: Dictionary) -> Dictionary:
	return definition(int(actor.kind)) if actor.has("kind") else boss_definition(int(actor.get("stage",1)))
static func is_part(kind: int) -> bool: return definition(kind).get("role","")=="part"
static func create(kind: int, pos: Vector2, pattern: int = 0, overrides: Dictionary = {}) -> Dictionary:
	var d: Dictionary = definition(kind)
	if d.is_empty():
		push_error("Unknown entity ID: %d"%kind)
		return {}
	var hp: float = float(overrides.get("hp",d.hp))
	var actor := {"kind":kind,"pos":pos,"velocity":Vector2.ZERO,"pattern":pattern,"hp":hp,"max_hp":hp}
	if d.role=="boss":
		actor.stage = int(d.stage)
		actor.age = 0.0
	return actor
static func smoke_settings(actor: Dictionary) -> Dictionary: return for_actor(actor).get("damage_smoke",{})
static func smoke_threshold(actor: Dictionary) -> float:
	var settings: Dictionary = smoke_settings(actor)
	if settings.has("below_hp"): return float(settings.below_hp)
	return float(settings.get("below_ratio",0))*float(actor.get("max_hp",for_actor(actor).get("hp",0)))
static func smoking(actor: Dictionary) -> bool:
	return actor.get("hp",0)>0 and actor.hp<smoke_threshold(actor)
