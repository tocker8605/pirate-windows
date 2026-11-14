class_name PiratePlayerWeapons
extends RefCounted
const Check = preload("res://scripts/data_validation.gd")
static var _settings: Dictionary = _load_settings()
static func validate_settings(value: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not value is Dictionary: return PackedStringArray(["player settings must be an object"])
	Check.unknown_fields(value,["schema_version","max_active_shots"],"player.",errors)
	if value.get("schema_version")!=1: errors.append("invalid player schema version")
	if not Check.number(value.get("max_active_shots")) or float(value.max_active_shots)!=int(value.max_active_shots) or int(value.max_active_shots)<4: errors.append("max_active_shots must be an integer >=4")
	return errors
static func _load_settings() -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/player.json"))
	var errors := validate_settings(value)
	if not errors.is_empty():
		push_error("; ".join(errors))
		return {}
	value.make_read_only()
	return value
static func volley_count(power: int) -> int: return mini(4,(power+1)/2)
static func active_limit() -> int: return int(_settings.max_active_shots)
const Rng = preload("res://scripts/random.gd")
## Position is the original cwx/cwy anchor, NOT the visible sprite centre.
static func volley(player: Vector2, weapon: int, power: int, random_source: Variant = null) -> Array:
	var random: Variant = Rng if random_source==null else random_source
	var plan: Array = []
	var kind: int = 4 if weapon == 3 else 1
	if power <= 2:
		_add(plan,player,11,0,kind)
	elif power <= 4:
		if weapon == 1:
			_add(plan,player,-5,3,1)
			_add(plan,player,25,3,1)
		elif weapon == 2:
			_add(plan,player,17,3,1)
			_add(plan,player,5,3,1)
		else:
			for i in range(2): _add(plan,player,7+random.between(0,8),0,4)
	elif power <= 6:
		if weapon == 1:
			_add(plan,player,-5,5,2)
			_add(plan,player,25,5,3)
		elif weapon == 2:
			_add(plan,player,0,2,1)
			_add(plan,player,20,2,1)
		else:
			for i in range(3): _add(plan,player,5+random.between(0,12),-random.between(0,1),4)
		if weapon < 3: _add(plan,player,10,0,1)
	else:
		if weapon == 1:
			_add(plan,player,-5,2,1)
			_add(plan,player,25,2,1)
			_add(plan,player,-10,5,2)
			_add(plan,player,30,5,3)
		elif weapon == 2:
			_add(plan,player,5,2,1)
			_add(plan,player,-5,5,1)
			_add(plan,player,15,2,1)
			_add(plan,player,25,5,1)
		else:
			for i in range(4): _add(plan,player,3+random.between(0,16),-random.between(0,2),4)
	return plan

static func _add(plan: Array, player: Vector2, x: float, y: float, kind: int) -> void:
	plan.append({"pos":player+Vector2(x,y),"kind":kind,"alive":true,"impact_remaining_seconds":-1})

static func cadence_seconds(power: int) -> float:
	return 0.06 if power%2==0 else 0.09

static func advance(shot: Dictionary, player: Vector2, seconds: float = 1.0/60.0) -> void:
	var p: Vector2 = shot.pos
	match int(shot.get("kind",1)):
		1: p.y -= 633.3333333333334*seconds
		2: p += Vector2(-33.333333333333336,-566.6666666666667)*seconds
		3: p += Vector2(33.333333333333336,-566.6666666666667)*seconds
		4:
			var dy: float = absf(player.y+20-p.y)
			var next_y: float = p.y-(dy*4.16666666666667+166.66666666666669 if dy<120 else 666.6666666666667)*seconds
			p.y = next_y
	shot.pos = p

static func vb_integer(value: float) -> int:
	# Assignment to VB6 Integer uses ties-to-even, unlike Godot's round().
	var low: float = floorf(value)
	if value-low==0.5: return int(low) if int(low)%2==0 else int(low)+1
	return int(floorf(value+0.5))

static func visual(shot: Dictionary, player: Vector2) -> Dictionary:
	var ticks: int = int(floor(float(shot.get("impact_remaining_seconds",-1))*33.333333333333336+0.000001))
	if ticks >= 0:
		var row: int = 60 if ticks>6 else (120 if ticks>3 else 180)
		return {"phase":"impact","rect":Rect2i(0,row,80,30),"mask":Vector2i(0,row+30),"offset":Vector2(-25,0)}
	if shot.pos.y < player.y-19:
		return {"phase":"flight","rect":Rect2i(10,0,20,30),"mask":Vector2i(10,30),"offset":Vector2(5,0)}
	return {"phase":"launch","rect":Rect2i(40,0,40,30),"mask":Vector2i(40,30),"offset":Vector2(-5,0)}
