extends RefCounted
const Check = preload("res://scripts/data_validation.gd")
const FIELDS: Array = ["name","role","hp","score","score_scales_with_difficulty","damageable","explosion_seconds","death_sound","draw_size","draw_offset","part_side","collision","damage_smoke","boss_rush_drop","drop","stage","music","open_at_y","open_kind","on_defeat","attack","fire_channels","motion","attachment","core_motion"]
static func validate_document(document: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not document is Dictionary or document.get("schema_version",0)!=2 or not document.get("entities") is Dictionary:
		return PackedStringArray(["Expected schema_version2 and entities object"])
	Check.unknown_fields(document,["schema_version","time_unit","speed_unit","entities"],"catalog.",errors)
	if document.get("time_unit")!="seconds" or document.get("speed_unit")!="pixels_per_second": errors.append("catalog requires explicit seconds and pixels_per_second units")
	var boss_stages: Array = []
	for key in document.entities:
		var d: Variant = document.entities[key]
		var prefix: String = "entity %s: "%key
		if not str(key).is_valid_int() or int(key)<=0 or not d is Dictionary:
			errors.append(prefix+"invalid ID or definition")
			continue
		for field in d:
			if field not in FIELDS: errors.append(prefix+"unexpected field "+str(field))
		Check.nested_fields(d.get("collision",{}),["beam_bounds", "contact_bounds", "shot_bounds"],prefix+"collision.",errors)
		Check.nested_fields(d.get("motion",{}),["type", "upper_center", "lower_center", "lower_below_ratio", "speed", "lower_follow"],prefix+"motion.",errors)
		Check.nested_fields(d.get("fire_channels",{}),["name", "gate", "interval_seconds", "projectile_kind", "part_id", "part_ids", "count", "initial_degrees", "rotation_direction", "rotation_step_degrees", "spacing_degrees", "speed", "window_seconds"],prefix+"fire_channels.",errors)
		Check.nested_fields(d.get("attack",{}),["count", "enraged_interval_seconds", "horizontal_base", "initial_degrees", "interval_seconds", "max_spread_degrees", "max_vertical_speed", "min_y", "opposed", "ports", "projectile_kind", "requires_stationary_x", "rotation_directions", "side_hold_seconds", "speed", "speed_y", "spread_degrees", "spread_directions", "step_degrees", "type"],prefix+"attack.",errors)
		Check.nested_fields(d.get("damage_smoke",{}),["below_hp", "below_ratio", "ports", "size"],prefix+"damage_smoke.",errors)
		Check.nested_fields(d.get("drop",{}),["cargo_release", "item", "offset"],prefix+"drop.",errors)
		Check.nested_fields(d.get("boss_rush_drop",{}),["cargo_release", "item", "offset"],prefix+"boss_rush_drop.",errors)
		Check.nested_fields(d.get("on_defeat",{}),["action", "definition_id", "pattern"],prefix+"on_defeat.",errors)
		Check.nested_fields(d.get("attachment",{}),["offset", "follow_y", "velocity_y_offset_seconds"],prefix+"attachment.",errors)
		Check.nested_fields(d.get("core_motion",{}),["detach_hp", "speed", "launch_speed", "launch_deceleration", "target_center", "vertical_margin", "pattern"],prefix+"core_motion.",errors)
		if d.get("motion",{} ) is Dictionary and d.get("motion",{}).get("lower_follow") is Dictionary:
			Check.unknown_fields(d.motion.lower_follow,["x_offset","speed","acceleration_seconds"],prefix+"motion.lower_follow.",errors)
		if d.has("attachment"):
			var attachment: Variant = d.attachment
			if not attachment is Dictionary or not Check.vector(attachment.get("offset"),2) or not attachment.get("follow_y") is bool or not Check.number(attachment.get("velocity_y_offset_seconds")): errors.append(prefix+"invalid attachment")
		if d.has("core_motion"):
			var core: Variant = d.core_motion
			if not core is Dictionary: errors.append(prefix+"core_motion must be an object")
			else:
				for field in ["detach_hp","speed","launch_speed","launch_deceleration","vertical_margin","pattern"]:
					if not Check.number(core.get(field)) or float(core.get(field,0))<=0: errors.append(prefix+"invalid core "+field)
				if not Check.vector(core.get("target_center"),2): errors.append(prefix+"invalid core target")
		if not d.get("name") is String or d.get("name","").is_empty(): errors.append(prefix+"name is required")
		if d.get("role")=="boss":
			if int(d.get("stage",0)) in boss_stages: errors.append(prefix+"duplicate boss stage")
			boss_stages.append(int(d.get("stage",0)))
		if not d.get("role","") in ["enemy","part","boss","supply"]: errors.append(prefix+"invalid role")
		if not Check.number(d.get("hp")) or float(d.get("hp",0))<=0: errors.append(prefix+"hp must be positive")
		if not Check.number(d.get("score")) or float(d.get("score",-1))<0: errors.append(prefix+"score must be nonnegative")
		if not d.get("damageable") is bool or not d.get("score_scales_with_difficulty") is bool: errors.append(prefix+"missing boolean flags")
		if not Check.vector(d.get("draw_size"),2) or not Check.vector(d.get("draw_offset"),2): errors.append(prefix+"invalid draw geometry")
		var collision: Variant = d.get("collision",{})
		if not collision is Dictionary:
			errors.append(prefix+"collision must be an object")
			continue
		if not Check.vector(collision.get("shot_bounds"),4) or not Check.vector(collision.get("beam_bounds"),2): errors.append(prefix+"invalid collision bounds")
		if Check.vector(collision.get("shot_bounds"),4) and (collision.shot_bounds[0]>=collision.shot_bounds[2] or collision.shot_bounds[1]>=collision.shot_bounds[3]): errors.append(prefix+"shot bounds must have increasing edges")
		if Check.vector(collision.get("beam_bounds"),2) and collision.beam_bounds[0]>=collision.beam_bounds[1]: errors.append(prefix+"beam bounds must have increasing edges")
		if not Check.vector(collision.get("contact_bounds"),4): errors.append(prefix+"invalid contact bounds")
		elif collision.contact_bounds[0]>=collision.contact_bounds[2] or collision.contact_bounds[1]>=collision.contact_bounds[3]: errors.append(prefix+"contact bounds must have increasing edges")
		if d.has("motion"):
			var motion: Variant = d.motion
			if not motion is Dictionary:
				errors.append(prefix+"motion must be an object")
			else:
				if motion.get("type","")!="boss_health_stations": errors.append(prefix+"unknown motion type")
				for field in ["upper_center","lower_center"]:
					if not Check.vector(motion.get(field),2): errors.append(prefix+"invalid station "+field)
				if not Check.number(motion.get("speed")) or float(motion.speed)<=0: errors.append(prefix+"invalid station speed")
				if motion.has("lower_follow"):
					var follow: Variant = motion.lower_follow
					if not follow is Dictionary: errors.append(prefix+"lower_follow must be an object")
					else:
						if not Check.number(follow.get("x_offset")): errors.append(prefix+"invalid follow X offset")
						if not Check.number(follow.get("speed")) or float(follow.speed)<=0: errors.append(prefix+"invalid follow speed")
						if not Check.number(follow.get("acceleration_seconds")) or float(follow.acceleration_seconds)<=0: errors.append(prefix+"invalid follow acceleration time")
				if not Check.number(motion.get("lower_below_ratio")) or float(motion.lower_below_ratio)<=0 or float(motion.lower_below_ratio)>=1: errors.append(prefix+"invalid station health threshold")
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
					if not Check.number(channel.get("interval_seconds")) or float(channel.interval_seconds)<=0: errors.append(prefix+"invalid fire channel interval")
					if channel.has("projectile_kind") and (not Check.number(channel.projectile_kind) or float(channel.projectile_kind)!=int(channel.projectile_kind) or int(channel.projectile_kind) not in range(1,9)): errors.append(prefix+"invalid channel projectile kind")
					if channel.get("gate","") not in ["always","aim_window","moving","stationary_aim","sweep_y","descent_or_stationary","descending","flame_y","charge_y","fist_y","pod_y","orb_y","orb_y_stationary","orb_stationary","left_claw_y","right_claw_y","detached","core_settled","no_parts","part_missing","parts_missing","left_missing","right_missing"]: errors.append(prefix+"unknown fire gate")
					if channel.get("gate") in ["part_missing","parts_missing"]:
						var part_ids: Variant = [channel.get("part_id")] if channel.gate=="part_missing" else channel.get("part_ids")
						if not part_ids is Array or part_ids.is_empty(): errors.append(prefix+"missing-part gate requires a nonempty part list")
						else:
							for part_id in part_ids:
								if not Check.number(part_id) or float(part_id)!=int(part_id): errors.append(prefix+"invalid missing-part ID")
								else:
									var part_definition: Variant = document.entities.get(str(int(part_id)),{})
									if not part_definition is Dictionary or part_definition.get("role","")!="part": errors.append(prefix+"missing-part gate must reference a part")
					if channel.has("rotation_direction") and (not Check.number(channel.rotation_direction) or absf(float(channel.rotation_direction))!=1.0): errors.append(prefix+"invalid rotation direction")
					if channel.get("name") in ["radial","rotating_cross"]:
						for field in ["speed","spacing_degrees","rotation_step_degrees","projectile_kind"]:
							if not Check.number(channel.get(field)) or float(channel[field])<=0: errors.append(prefix+"invalid radial "+field)
						if not Check.number(channel.get("initial_degrees")): errors.append(prefix+"invalid radial initial angle")
						if not Check.number(channel.get("count")) or float(channel.count)!=int(channel.count) or int(channel.count)<2: errors.append(prefix+"invalid radial count")
						elif Check.number(channel.get("spacing_degrees")) and not is_equal_approx(float(channel.count)*float(channel.spacing_degrees),360.0): errors.append(prefix+"radial spacing must cover360degrees")
					if channel.has("window_seconds"):
						if not Check.vector(channel.window_seconds,3): errors.append(prefix+"invalid attack window")
						elif channel.window_seconds[0]<=0 or channel.window_seconds[1]<0 or channel.window_seconds[2]<=channel.window_seconds[1] or channel.window_seconds[2]>channel.window_seconds[0]: errors.append(prefix+"invalid attack window bounds")
		if d.has("attack") and not d.attack is Dictionary: errors.append(prefix+"attack must be an object")
		if d.get("attack") is Dictionary:
			var attack: Dictionary = d.attack
			var attack_type: String = str(attack.get("type",""))
			if attack_type not in ["spiral","alternating","speed_spread","aimed_fan","paired_aimed_fan"]: errors.append(prefix+"unknown attack type")
			if attack_type!="paired_aimed_fan" and (not Check.number(attack.get("interval_seconds")) or float(attack.interval_seconds)<=0): errors.append(prefix+"invalid attack interval")
			if not Check.number(attack.get("projectile_kind")) or int(attack.projectile_kind) not in range(1,9): errors.append(prefix+"invalid attack projectile")
			if attack.has("opposed") and not attack.opposed is bool: errors.append(prefix+"invalid opposed-shot flag")
			if attack.has("requires_stationary_x") and not attack.requires_stationary_x is bool: errors.append(prefix+"invalid stationary-X attack flag")
			if attack.has("min_y") and not Check.number(attack.min_y): errors.append(prefix+"invalid attack minimumY")
			if attack.has("ports"):
				if not attack.ports is Array or attack.ports.is_empty() or not attack.ports.all(func(p): return Check.vector(p,2)): errors.append(prefix+"invalid attack ports")
			if attack_type=="spiral":
				for field in ["speed","step_degrees"]:
					if not Check.number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid attack "+field)
				if not Check.number(attack.get("initial_degrees")): errors.append(prefix+"invalid spiral initial angle")
				if attack.has("ports"):
					if not attack.get("rotation_directions") is Array or not attack.ports is Array: errors.append(prefix+"attack port directions missing")
					elif attack.rotation_directions.size()!=attack.ports.size() or not attack.rotation_directions.all(func(v): return Check.number(v) and absf(float(v))==1.0): errors.append(prefix+"invalid attack rotation directions")
			elif attack_type in ["aimed_fan","paired_aimed_fan"]:
				for field in ["speed","spread_degrees"]:
					if not Check.number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid aimed fan "+field)
				if not Check.number(attack.get("count")): errors.append(prefix+"aimed fan count missing")
				elif float(attack.count)!=int(attack.count) or int(attack.count)<1 or (attack_type=="aimed_fan" and int(attack.count)%2!=1): errors.append(prefix+"aimed fan needs positive odd count")
				if attack_type=="paired_aimed_fan" and (not attack.get("ports") is Array or attack.ports.size()!=2): errors.append(prefix+"paired fan needs two ports")
			elif attack_type=="speed_spread":
				for field in ["speed","max_vertical_speed","max_spread_degrees"]:
					if not Check.number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid speed spread "+field)
				if not attack.get("ports") is Array or not attack.get("spread_directions") is Array: errors.append(prefix+"speed spread ports/directions missing")
				elif attack.ports.size()!=attack.spread_directions.size() or not attack.spread_directions.all(func(v): return Check.number(v) and absf(float(v))==1.0): errors.append(prefix+"invalid spread directions")
			elif attack_type=="alternating":
				for field in ["enraged_interval_seconds","speed_y","side_hold_seconds"]:
					if not Check.number(attack.get(field)) or float(attack[field])<=0: errors.append(prefix+"invalid alternating attack "+field)
				if not Check.number(attack.get("horizontal_base")): errors.append(prefix+"invalid alternating horizontal base")
				if not attack.get("ports") is Array or attack.ports.size()!=2: errors.append(prefix+"alternating attack needs two ports")
		if not Check.number(d.get("explosion_seconds")) or float(d.get("explosion_seconds",0))<=0: errors.append(prefix+"invalid explosion duration")
		if d.get("role")=="boss" and (int(d.get("stage",0)) not in [1,2,3,4] or not d.get("music") is String): errors.append(prefix+"boss stage/music missing")
		if d.has("damage_smoke"):
			var smoke: Variant = d.damage_smoke
			if not smoke is Dictionary:
				errors.append(prefix+"damage_smoke must be an object")
				continue
			if smoke.has("below_hp")==smoke.has("below_ratio"): errors.append(prefix+"smoke needs exactly one threshold")
			if smoke.has("below_hp") and (not Check.number(smoke.below_hp) or float(smoke.below_hp)<0): errors.append(prefix+"invalid smoke HP")
			if smoke.has("below_ratio") and (not Check.number(smoke.below_ratio) or float(smoke.below_ratio)<0 or float(smoke.below_ratio)>1): errors.append(prefix+"invalid smoke ratio")
			if not Check.number(smoke.get("size")) or float(smoke.get("size",0))<=0: errors.append(prefix+"invalid smoke size")
			if not smoke.get("ports") is Array or not smoke.ports.all(func(p): return Check.vector(p,2)): errors.append(prefix+"invalid smoke ports")
		for field in ["drop","boss_rush_drop"]:
			if d.has(field) and (not d[field] is Dictionary or int(d[field].get("item",0)) not in [1,2] or not Check.vector(d[field].get("offset"),2)): errors.append(prefix+"invalid "+field)
		if d.has("open_kind") and not document.entities.has(str(int(d.open_kind))): errors.append(prefix+"unknown open_kind")
		if d.has("on_defeat"):
			if not d.on_defeat is Dictionary or d.on_defeat.get("action","")!="release_and_escape" or not document.entities.has(str(int(d.on_defeat.get("definition_id",0)))): errors.append(prefix+"invalid escape action/reference")
	return errors
