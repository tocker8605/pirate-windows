extends RefCounted
const Check=preload("res://scripts/data_validation.gd")
const TYPES: Array=["aimed","oscillating","revolving","expanding_ring","fixed","fixed_pair","motion_deflection","height_sweep","motion_or_aim","random","pod_twin","aimed_sequence","sweeping_pair","inherited_fan","diving_pair","rotating","shoulder_fan"]
static func validate(v: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not v is Dictionary:errors.append(prefix+"expected volley object");return
	Check.unknown_fields(v,["type","clock_origin","initial_phase_degrees","initial_degrees","rotation_directions","period_seconds","sweep_degrees","ports","aim_from_muzzle","zero_aim_direction","speed","projectile_kind","angles_degrees","velocity","velocities","down_speed","speed_y","secondary_speed_y","primary_speed_scale","x_random","y_random","abs_x_factor","origin_x_random","velocity_offsets","port_index","count","start_radius","end_radius","expand_seconds"],prefix,errors)
	if v.get("type") not in TYPES:errors.append(prefix+"unknown volley type")
	if v.get("type")!="shoulder_fan" and (not v.get("ports") is Array or v.ports.is_empty() or not v.ports.all(func(p):return Check.vector(p,2))):errors.append(prefix+"invalid ports")
	for field in ["speed","down_speed","speed_y","secondary_speed_y","primary_speed_scale","abs_x_factor","port_index"]:
		if v.has(field) and not Check.number(v[field]):errors.append(prefix+"invalid "+field)
	if v.has("aim_from_muzzle") and (not v.aim_from_muzzle is bool or v.get("type")!="aimed"):errors.append(prefix+"aim_from_muzzle requires an aimed volley and boolean value")
	if v.has("zero_aim_direction"):
		if v.get("type")!="aimed" or not Check.vector(v.zero_aim_direction,2):errors.append(prefix+"invalid zero-distance aim direction")
		elif float(v.zero_aim_direction[0])==0 and float(v.zero_aim_direction[1])==0:errors.append(prefix+"zero-distance aim direction must be nonzero")
	if v.has("projectile_kind") and (not Check.number(v.projectile_kind) or float(v.projectile_kind)!=int(v.projectile_kind) or int(v.projectile_kind) not in range(1,9)):errors.append(prefix+"invalid projectile_kind")
	for field in ["x_random","y_random","origin_x_random"]:
		if not v.has(field):continue
		var spec: Variant=v[field]
		if not spec is Dictionary:errors.append(prefix+"invalid "+field);continue
		Check.unknown_fields(spec,["base","step","count"],prefix+field+".",errors)
		if not Check.number(spec.get("base")) or not Check.number(spec.get("step")) or not Check.number(spec.get("count")):errors.append(prefix+"invalid random range")
		elif int(spec.count)<1 or float(spec.count)!=int(spec.count):errors.append(prefix+"invalid random count")
	for field in ["velocity_offsets","velocities"]:
		if v.has(field) and (not v[field] is Array or v[field].is_empty() or not v[field].all(func(p):return Check.vector(p,2))):errors.append(prefix+"invalid "+field)
	if v.has("velocity") and not Check.vector(v.velocity,2):errors.append(prefix+"invalid velocity")
	if v.has("angles_degrees") and (not v.angles_degrees is Array or v.angles_degrees.is_empty() or not v.angles_degrees.all(func(n):return Check.number(n))):errors.append(prefix+"invalid fan angles")
	var required: Dictionary={"revolving":["speed","projectile_kind","period_seconds","initial_degrees","rotation_directions"],"oscillating":["speed","projectile_kind","period_seconds","sweep_degrees"],"expanding_ring":["speed","projectile_kind","count","start_radius","end_radius","expand_seconds"],"aimed":["speed","projectile_kind"],"fixed":["velocity","projectile_kind"],"fixed_pair":["velocities","projectile_kind"],"motion_deflection":["down_speed","projectile_kind"],"height_sweep":["speed_y","projectile_kind"],"motion_or_aim":["speed","speed_y","projectile_kind"],"random":["x_random","projectile_kind"],"inherited_fan":["velocity_offsets","projectile_kind"],"aimed_sequence":["speed","projectile_kind","angles_degrees"],"sweeping_pair":["speed","projectile_kind"],"pod_twin":["projectile_kind","secondary_speed_y","primary_speed_scale"],"diving_pair":["projectile_kind"],"shoulder_fan":["port_index"]}
	for field in required.get(v.get("type"),[]):
		if not v.has(field):errors.append(prefix+"missing "+field)
	if v.get("type")=="random" and not v.has("y_random") and not v.has("speed_y"):errors.append(prefix+"random volley needs vertical speed")
	if v.get("type")=="fixed_pair" and v.get("ports") is Array and v.get("velocities") is Array and v.ports.size()!=v.velocities.size():errors.append(prefix+"fixed pair port count mismatch")

	if v.get("type")=="expanding_ring":
		if not Check.number(v.get("count")) or float(v.count)!=int(v.count) or int(v.count)<3:errors.append(prefix+"invalid formation vertex count")
		for field in ["start_radius","end_radius","expand_seconds","speed"]:
			if not Check.number(v.get(field)) or float(v.get(field,0))<=0:errors.append(prefix+"invalid formation "+field)
		if Check.number(v.get("start_radius")) and Check.number(v.get("end_radius")) and v.end_radius<v.start_radius:errors.append(prefix+"formation radius must grow")

	if v.has("clock_origin") and (v.get("type")!="oscillating" or v.clock_origin not in ["spawn","first_shot"]):errors.append(prefix+"invalid oscillation clock origin")
	if v.has("initial_phase_degrees") and (v.get("type")!="oscillating" or not Check.number(v.initial_phase_degrees)):errors.append(prefix+"invalid oscillation initial phase")
	if v.get("type")=="oscillating":
		for field in ["period_seconds","speed"]:
			if not Check.number(v.get(field)) or float(v.get(field,0))<=0:errors.append(prefix+"invalid oscillation "+field)
		if not v.get("sweep_degrees") is Array or not v.get("ports") is Array:errors.append(prefix+"oscillation needs port angle ranges")
		elif v.sweep_degrees.size()!=v.ports.size() or not v.sweep_degrees.all(func(span):return Check.vector(span,2)):errors.append(prefix+"oscillation angle ranges must match ports")

	if v.get("type")=="revolving":
		for field in ["period_seconds","speed"]:
			if not Check.number(v.get(field)) or float(v.get(field,0))<=0:errors.append(prefix+"invalid revolution "+field)
		if not Check.number(v.get("initial_degrees")):errors.append(prefix+"invalid initial revolution angle")
		if not v.get("rotation_directions") is Array or not v.get("ports") is Array:errors.append(prefix+"revolution needs port directions")
		elif v.rotation_directions.size()!=v.ports.size() or not v.rotation_directions.all(func(value):return Check.number(value) and absf(float(value))==1):errors.append(prefix+"revolution directions must match ports and be1or-1")

	if v.get("type")=="pod_twin":
		for field in ["secondary_speed_y","primary_speed_scale"]:
			if not Check.number(v.get(field)) or float(v.get(field,0))<=0:errors.append(prefix+"invalid pod twin "+field)
