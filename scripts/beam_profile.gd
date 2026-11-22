extends RefCounted
## Prepare validated authoring data once. Runtime snapshots consume native immutable values.
static func prepare_sweeps(beams: Array) -> Array:
	var sweeps: Array=[]
	for authored in beams:
		var sweep: Dictionary={"from_radians":deg_to_rad(float(authored.from_degrees)),"to_radians":deg_to_rad(float(authored.to_degrees))}
		sweep.make_read_only();sweeps.append(sweep)
	sweeps.make_read_only()
	return sweeps
static func prepare_phase(authored: Dictionary) -> Dictionary:
	var swing: Dictionary=authored.get("swing",{})
	var phase: Dictionary={
		"at_or_below_ratio":float(authored.get("at_or_below_ratio",1)),
		"beams":prepare_sweeps(authored.beams),
		"continuous":bool(authored.get("continuous",false)),
		"swing_radians":deg_to_rad(float(swing.get("amplitude_degrees",0))),
		"swing_period_seconds":float(swing.get("period_seconds",1))}
	phase.make_read_only()
	return phase
static func prepare(spec: Dictionary) -> Dictionary:
	var profile: Dictionary={"name":spec.name,"gate":spec.gate,"origin":Vector2(spec.origin[0],spec.origin[1]),"color":Color(spec.color),"default_phase":prepare_phase(spec)}
	for field in ["period_seconds","telegraph_seconds","active_seconds","length","width","telegraph_width"]:profile[field]=float(spec[field])
	profile.damage_scale=float(spec.get("damage_scale",1))
	profile.width_transition_seconds=float(spec.get("width_transition_seconds",0))
	var phases: Array=[]
	for authored in spec.get("health_phases",[]):phases.append(prepare_phase(authored))
	phases.sort_custom(func(a,b):return a.at_or_below_ratio<b.at_or_below_ratio)
	phases.make_read_only();profile.health_phases=phases
	profile.make_read_only()
	return profile
