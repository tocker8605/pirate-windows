extends RefCounted
const Check=preload("res://scripts/data_validation.gd")
static func asset(d: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not d is Dictionary:errors.append(prefix+"expected texture asset");return
	Check.unknown_fields(d,["path","region"],prefix,errors)
	if not d.get("path") is String or not str(d.get("path","")).begins_with("res://assets/") or not str(d.get("path","")).ends_with(".png"):errors.append(prefix+"expected project PNG path")
	if d.has("region"):
		if not Check.vector(d.region,4):errors.append(prefix+"invalid crop rectangle")
		elif d.region[0]<0 or d.region[1]<0 or d.region[2]<=0 or d.region[3]<=0:errors.append(prefix+"crop must have positive size")
static func validate(d: Dictionary,prefix: String,errors: PackedStringArray) -> void:
	if d.has("sprite_path"):
		var a: Dictionary={"path":d.sprite_path}
		if d.has("sprite_region"):a.region=d.sprite_region
		asset(a,prefix,errors)
	elif d.has("sprite_region"):errors.append(prefix+"sprite crop requires sprite_path")
	if d.has("movement_mode") and d.movement_mode not in ["pattern","stationary","scenery"]:errors.append(prefix+"invalid movement_mode")
	if d.has("visual"):
		var v: Variant=d.visual
		if not v is Dictionary:errors.append(prefix+"visual must be an object")
		else:
			Check.unknown_fields(v,["layer","anchor","flip_h","rotation_radians","painted_size","hinge_uv","order"],prefix+"visual.",errors)
			if v.get("layer","air") not in ["air","floor"]:errors.append(prefix+"invalid render layer")
			if v.get("anchor","top_left") not in ["top_left","top_center","hinge"]:errors.append(prefix+"invalid visual anchor")
			if v.has("flip_h") and not v.flip_h is bool:errors.append(prefix+"invalid mirror flag")
			for field in ["rotation_radians","order"]:
				if v.has(field) and not Check.number(v[field]):errors.append(prefix+"invalid visual "+field)
			if v.has("painted_size") and (not Check.vector(v.painted_size,2) or v.painted_size.any(func(n):return n<=0)):errors.append(prefix+"invalid painted_size")
			if v.get("anchor")=="hinge" and (not Check.vector(v.get("hinge_uv"),2) or v.hinge_uv.any(func(n):return n<0 or n>1)):errors.append(prefix+"invalid hinge UV")
	if d.has("pose_motion"):
		var motion: Variant=d.pose_motion
		if not motion is Dictionary:errors.append(prefix+"pose_motion must be an object")
		else:
			Check.unknown_fields(motion,["type","period_seconds","angle_degrees","pivot","min_degrees","max_degrees","initial_degrees","initial_direction"],prefix+"pose_motion.",errors)
			if motion.get("type") not in ["swing","swing_range"]:errors.append(prefix+"unknown pose motion")
			if not Check.number(motion.get("period_seconds")) or float(motion.get("period_seconds",0))<=0:errors.append(prefix+"pose period must be positive")
			if motion.get("type")=="swing" and not Check.number(motion.get("angle_degrees")):errors.append(prefix+"invalid pose angle")
			if motion.get("type")=="swing_range":
				var valid: bool=true
				for field in ["min_degrees","max_degrees","initial_degrees","initial_direction"]:
					if not Check.number(motion.get(field)):valid=false;errors.append(prefix+"invalid pose "+field)
				if valid:
					if motion.min_degrees>=motion.max_degrees or motion.initial_degrees<motion.min_degrees or motion.initial_degrees>motion.max_degrees:errors.append(prefix+"invalid pose range or initial angle")
					if absf(float(motion.initial_direction))!=1:errors.append(prefix+"pose initial direction must be1or-1")
			if not Check.vector(motion.get("pivot"),2):errors.append(prefix+"invalid pose pivot")
			if not d.get("collision") is Dictionary or not d.collision.has("beam_rect"):errors.append(prefix+"pose motion requires a beam rectangle")
	if d.has("boss_scroll"):
		var policy: Variant=d.boss_scroll
		if not policy is Dictionary:errors.append(prefix+"boss_scroll must be an object")
		else:
			Check.unknown_fields(policy,["stop_on_spawn","defeat_speed","stop_after_y"],prefix+"boss_scroll.",errors)
			if not policy.get("stop_on_spawn") is bool or not Check.number(policy.get("defeat_speed")):errors.append(prefix+"invalid boss scroll policy")
			if policy.has("stop_after_y") and not Check.number(policy.stop_after_y):errors.append(prefix+"invalid boss scroll stop Y")
	if d.has("floor_decoration"):
		var decoration: Variant=d.floor_decoration
		if not decoration is Dictionary:errors.append(prefix+"floor_decoration must be an object")
		else:
			Check.unknown_fields(decoration,["asset","size","offset"],prefix+"floor_decoration.",errors)
			asset(decoration.get("asset"),prefix+"floor_decoration.asset.",errors)
			if not Check.vector(decoration.get("size"),2) or decoration.size.any(func(n):return n<=0):errors.append(prefix+"invalid floor decoration size")
			if not Check.vector(decoration.get("offset"),2):errors.append(prefix+"invalid floor decoration offset")
	if d.has("ground_turret"):
		var ground: Variant=d.ground_turret
		if not ground is Dictionary:errors.append(prefix+"ground_turret must be an object");return
		Check.unknown_fields(ground,["body_size","ports","reveal_y","raise_seconds","center","hatch","wreck","boss_hatch","projectile_kinds","parallel","rotation"],prefix+"ground_turret.",errors)
		for field in ["body_size","center"]:
			if not Check.vector(ground.get(field),2):errors.append(prefix+"invalid turret "+field)
		for field in ["hatch","wreck"]:asset(ground.get(field),prefix+field+".",errors)
		if not ground.get("ports") is Array or ground.ports.is_empty() or not ground.ports.all(func(port):return Check.vector(port,2)):errors.append(prefix+"invalid ground ports")
		if not Check.number(ground.get("reveal_y")) or not Check.number(ground.get("raise_seconds")) or float(ground.get("raise_seconds",0))<=0:errors.append(prefix+"invalid deployment timing")
		if not d.has("sprite_path") or d.get("movement_mode")!="scenery":errors.append(prefix+"turret requires a sprite and scenery movement")

		if ground.has("parallel") and not ground.parallel is bool:errors.append(prefix+"invalid parallel fire flag")
		if ground.has("projectile_kinds"):
			if not ground.projectile_kinds is Array or not ground.get("ports") is Array:errors.append(prefix+"projectile kinds require ports")
			elif ground.projectile_kinds.size()!=ground.ports.size() or not ground.projectile_kinds.all(func(k):return Check.number(k) and float(k)==int(k) and int(k) in range(1,9)):errors.append(prefix+"invalid per-port projectile kinds")
		if ground.has("boss_hatch"):
			var hatch: Variant=ground.boss_hatch
			if not hatch is Dictionary:errors.append(prefix+"invalid boss hatch")
			else:
				Check.unknown_fields(hatch,["boss_id","hp_ratio"],prefix+"boss_hatch.",errors)
				if not Check.number(hatch.get("boss_id")) or float(hatch.boss_id)!=int(hatch.boss_id) or not Check.number(hatch.get("hp_ratio")) or float(hatch.hp_ratio)<=0 or float(hatch.hp_ratio)>1:errors.append(prefix+"invalid boss hatch threshold")
		if ground.has("rotation"):
			var rotation: Variant=ground.rotation
			if not rotation is Dictionary:errors.append(prefix+"invalid turret rotation")
			else:
				Check.unknown_fields(rotation,["initial_degrees","period_seconds"],prefix+"rotation.",errors)
				if not Check.number(rotation.get("initial_degrees")) or not Check.number(rotation.get("period_seconds")) or float(rotation.period_seconds)<=0:errors.append(prefix+"invalid turret rotation angle")
