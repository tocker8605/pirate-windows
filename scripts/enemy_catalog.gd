extends RefCounted
## Shared, immutable entity defaults. Runtime HP lives only on created actors.
const PATH = "res://data/enemies.json"
const Schema = preload("res://scripts/entity_schema.gd")
static var _entities: Dictionary = _load_definitions()
static func validate_document(document: Variant) -> PackedStringArray:
	return Schema.validate_document(document)
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
static func fire_channel(kind: int, name: String) -> Dictionary:
	for channel in definition(kind).get("fire_channels",[]):
		if channel.name==name: return channel
	return {}

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
