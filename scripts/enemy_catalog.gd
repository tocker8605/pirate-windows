extends RefCounted
## Shared, immutable entity defaults. Runtime HP lives only on created actors.
const PATH = "res://data/enemies.json"
const FIELDS: Array = ["name","role","hp","score","score_scales_with_difficulty","damageable","explosion_ticks","death_sound","draw_size","draw_offset","part_side","collision","damage_smoke","boss_rush_drop","drop","stage","music","open_at_y","open_kind","on_defeat","attack","fire_channels","motion"]
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
		if not _vector(collision.get("contact_bounds"),4): errors.append(prefix+"invalid contact bounds")
		elif collision.contact_bounds[0]>=collision.contact_bounds[2] or collision.contact_bounds[1]>=collision.contact_bounds[3]: errors.append(prefix+"contact bounds must have increasing edges")
		if d.has("motion"):
			var motion: Variant = d.motion
			if not motion is Dictionary:
				errors.append(prefix+"motion must be an object")
			else:
				if motion.get("type","")!="boss_health_stations": errors.append(prefix+"unknown motion type")
				for field in ["upper_center","lower_center"]:
					if not _vector(motion.get(field),2): errors.append(prefix+"invalid station "+field)
				if not _number(motion.get("speed")) or float(motion.speed)<=0: errors.append(prefix+"invalid station speed")
				if motion.has("lower_follow"):
					var follow: Variant = motion.lower_follow
					if not follow is Dictionary: errors.append(prefix+"lower_follow must be an object")
					else:
						if not _number(follow.get("x_offset")): errors.append(prefix+"invalid follow X offset")
						if not _number(follow.get("speed")) or float(follow.speed)<=0: errors.append(prefix+"invalid follow speed")
				if not _number(motion.get("lower_below_ratio")) or float(motion.lower_below_ratio)<=0 or float(motion.lower_below_ratio)>=1: errors.append(prefix+"invalid station health threshold")
		if d.has("fire_channels"):
			if not d.fire_channels is Array: errors.append(prefix+"fire_channels must be an array")
			else:
				var names: Array = []
				for channel in d.fire_channels:
					if not channel is Dictionary:
						errors.append(prefix+"invalid fire channel")
						continue
					if not channel.get("name") is String or channel.get("name","").is_empty() or channel.get("name") in names: errors.append(prefix+"invalid/duplicate fire channel name")
					names.append(channel.get("name"))
					if not _number(channel.get("interval_seconds")) or float(channel.interval_seconds)<=0: errors.append(prefix+"invalid fire channel interval")
					if channel.has("projectile_kind") and (not _number(channel.projectile_kind) or float(channel.projectile_kind)!=int(channel.projectile_kind) or int(channel.projectile_kind) not in range(1,9)): errors.append(prefix+"invalid channel projectile kind")
					if channel.get("gate","") not in ["always","aim_window","moving","stationary_aim","sweep_y","descent_or_stationary","descending","flame_y","charge_y","fist_y","pod_y","orb_y","orb_y_stationary","orb_stationary","left_claw_y","right_claw_y","detached","core_settled","no_parts","part_missing","left_missing","right_missing"]: errors.append(prefix+"unknown fire gate")
					if channel.get("gate")=="part_missing":
						if not _number(channel.get("part_id")) or float(channel.part_id)!=int(channel.part_id): errors.append(prefix+"invalid missing-part ID")
						else:
							var part_definition: Variant = document.entities.get(str(int(channel.part_id)),{})
							if not part_definition is Dictionary or part_definition.get("role","")!="part": errors.append(prefix+"missing-part gate must reference a part")
					if channel.has("rotation_direction") and (not _number(channel.rotation_direction) or absf(float(channel.rotation_direction))!=1.0): errors.append(prefix+"invalid rotation direction")
					if channel.get("name") in ["radial","rotating_cross"]:
						for field in ["speed","spacing_degrees","rotation_step_degrees","projectile_kind"]:
							if not _number(channel.get(field)) or float(channel[field])<=0: errors.append(prefix+"invalid radial "+field)
						if not _number(channel.get("initial_degrees")): errors.append(prefix+"invalid radial initial angle")
						if not _number(channel.get("count")) or float(channel.count)!=int(channel.count) or int(channel.count)<2: errors.append(prefix+"invalid radial count")
						elif _number(channel.get("spacing_degrees")) and not is_equal_approx(float(channel.count)*float(channel.spacing_degrees),360.0): errors.append(prefix+"radial spacing must cover360degrees")
					if channel.has("window_seconds"):
						if not _vector(channel.window_seconds,3): errors.append(prefix+"invalid attack window")
						elif channel.window_seconds[0]<=0 or channel.window_seconds[1]<0 or channel.window_seconds[2]<=channel.window_seconds[1] or channel.window_seconds[2]>channel.window_seconds[0]: errors.append(prefix+"invalid attack window bounds")
		if d.has("attack") and not d.attack is Dictionary: errors.append(prefix+"attack must be an object")
		if d.get("attack") is Dictionary:
			var attack: Dictionary = d.attack
			var attack_type: String = str(attack.get("type",""))
			if attack_type not in ["spiral","alternating","speed_spread","aimed_fan","paired_aimed_fan"]: errors.append(prefix+"unknown attack type")
			if attack_type!="paired_aimed_fan" and (not _number(attack.get("interval_seconds")) or float(attack.interval_seconds)<=0): errors.append(prefix+"invalid attack interval")
			if not _number(attack.get("projectile_kind")) or int(attack.projectile_kind) not in range(1,9): errors.append(prefix+"invalid attack projectile")
			if attack.has("opposed") and not attack.opposed is bool: errors.append(prefix+"invalid opposed-shot flag")
			if attack.has("requires_stationary_x") and not attack.requires_stationary_x is bool: errors.append(prefix+"invalid stationary-X attack flag")
			if attack.has("min_y") and not _number(attack.min_y): errors.append(prefix+"invalid attack minimumY")
			if attack.has("ports"):
				if not attack.ports is Array or attack.ports.is_empty() or not attack.ports.all(func(p): return _vector(p,2)): errors.append(prefix+"invalid attack ports")
			if attack_type=="spiral":
				for field in ["speed","step_degrees"]:
					if not _number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid attack "+field)
				if not _number(attack.get("initial_degrees")): errors.append(prefix+"invalid spiral initial angle")
				if attack.has("ports"):
					if not attack.get("rotation_directions") is Array or not attack.ports is Array: errors.append(prefix+"attack port directions missing")
					elif attack.rotation_directions.size()!=attack.ports.size() or not attack.rotation_directions.all(func(v): return _number(v) and absf(float(v))==1.0): errors.append(prefix+"invalid attack rotation directions")
			elif attack_type in ["aimed_fan","paired_aimed_fan"]:
				for field in ["speed","spread_degrees"]:
					if not _number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid aimed fan "+field)
				if not _number(attack.get("count")): errors.append(prefix+"aimed fan count missing")
				elif float(attack.count)!=int(attack.count) or int(attack.count)<1 or (attack_type=="aimed_fan" and int(attack.count)%2!=1): errors.append(prefix+"aimed fan needs positive odd count")
				if attack_type=="paired_aimed_fan" and (not attack.get("ports") is Array or attack.ports.size()!=2): errors.append(prefix+"paired fan needs two ports")
			elif attack_type=="speed_spread":
				for field in ["speed","max_vertical_speed","max_spread_degrees"]:
					if not _number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid speed spread "+field)
				if not attack.get("ports") is Array or not attack.get("spread_directions") is Array: errors.append(prefix+"speed spread ports/directions missing")
				elif attack.ports.size()!=attack.spread_directions.size() or not attack.spread_directions.all(func(v): return _number(v) and absf(float(v))==1.0): errors.append(prefix+"invalid spread directions")
			elif attack_type=="alternating":
				for field in ["enraged_interval_seconds","speed_y","side_hold_seconds"]:
					if not _number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid alternating attack "+field)
				if not _number(attack.get("horizontal_base")): errors.append(prefix+"invalid alternating horizontal base")
				if not attack.get("ports") is Array or attack.ports.size()!=2: errors.append(prefix+"alternating attack needs two ports")
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
