extends RefCounted
## Compile validated authoring data once; sampling only depends on elapsed simulation time.
static func prepare(settings: Dictionary) -> Dictionary:
	var curve: Dictionary={"type":settings.type,"period_seconds":float(settings.period_seconds),"pivot":Vector2(settings.pivot[0],settings.pivot[1])}
	if settings.type=="swing_range":
		curve.centre=(float(settings.min_degrees)+float(settings.max_degrees))/2
		curve.amplitude=(float(settings.max_degrees)-float(settings.min_degrees))/2
		curve.phase=acos(clampf((float(settings.initial_degrees)-float(curve.centre))/float(curve.amplitude),-1,1))
		if settings.initial_direction>0:curve.phase=-float(curve.phase)
	else:curve.amplitude_radians=deg_to_rad(float(settings.angle_degrees))
	curve.make_read_only()
	return curve
static func sample(curve: Dictionary,age: float) -> float:
	var phase: float=TAU*fposmod(age,float(curve.period_seconds))/float(curve.period_seconds)
	if curve.type=="swing_range":return deg_to_rad(float(curve.centre)+float(curve.amplitude)*cos(phase+float(curve.phase)))
	return float(curve.amplitude_radians)*(1-cos(phase))/2
