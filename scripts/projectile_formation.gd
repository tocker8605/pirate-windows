extends RefCounted
## Immutable expansion settings are shared; each bullet owns only its age and radial direction.
static func profile(start_radius: float,end_radius: float,expand_seconds: float) -> Dictionary:
	var result: Dictionary={"start_radius":start_radius,"end_radius":end_radius,"expand_seconds":expand_seconds}
	result.make_read_only()
	return result
static func state(settings: Dictionary,direction: Vector2) -> Dictionary:
	return {"profile":settings,"direction":direction,"age":0.0}
static func advance(bullet: Dictionary,seconds: float) -> Vector2:
	if not bullet.has("formation"):return Vector2.ZERO
	var motion: Dictionary=bullet.formation
	var settings: Dictionary=motion.profile
	var before: float=float(motion.age)
	var after: float=minf(float(settings.expand_seconds),before+seconds)
	motion.age=after
	var radius_delta: float=(float(settings.end_radius)-float(settings.start_radius))*(after-before)/float(settings.expand_seconds)
	return motion.direction*radius_delta
