extends RefCounted
const Check=preload("res://scripts/data_validation.gd")
const TYPES: Array=["aimed","fixed","fixed_pair","motion_deflection","height_sweep","motion_or_aim","random","pod_twin","aimed_sequence","sweeping_pair","inherited_fan","diving_pair","biased_aim","rotating","shoulder_fan"]
static func validate(v: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not v is Dictionary:errors.append(prefix+"expected volley object");return
	Check.unknown_fields(v,["type","ports","speed","projectile_kind","angles_degrees","velocity","velocities","down_speed","speed_y","x_random","y_random","abs_x_factor","origin_x_random","velocity_offsets","port_index"],prefix,errors)
	if v.get("type") not in TYPES:errors.append(prefix+"unknown volley type")
	if v.get("type")!="shoulder_fan" and (not v.get("ports") is Array or v.ports.is_empty() or not v.ports.all(func(p):return Check.vector(p,2))):errors.append(prefix+"invalid ports")
	for field in ["speed","down_speed","speed_y","abs_x_factor","port_index"]:
		if v.has(field) and not Check.number(v[field]):errors.append(prefix+"invalid "+field)
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
	var required: Dictionary={"aimed":["speed","projectile_kind"],"fixed":["velocity","projectile_kind"],"fixed_pair":["velocities","projectile_kind"],"motion_deflection":["down_speed","projectile_kind"],"height_sweep":["speed_y","projectile_kind"],"motion_or_aim":["speed","speed_y","projectile_kind"],"random":["x_random","projectile_kind"],"inherited_fan":["velocity_offsets","projectile_kind"],"aimed_sequence":["speed","projectile_kind","angles_degrees"],"sweeping_pair":["speed","projectile_kind"],"pod_twin":["projectile_kind"],"diving_pair":["projectile_kind"],"biased_aim":["projectile_kind"],"shoulder_fan":["port_index"]}
	for field in required.get(v.get("type"),[]):
		if not v.has(field):errors.append(prefix+"missing "+field)
	if v.get("type")=="random" and not v.has("y_random") and not v.has("speed_y"):errors.append(prefix+"random volley needs vertical speed")
	if v.get("type")=="fixed_pair" and v.get("ports") is Array and v.get("velocities") is Array and v.ports.size()!=v.velocities.size():errors.append(prefix+"fixed pair port count mismatch")
