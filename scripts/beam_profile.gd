extends RefCounted
## Prepare validated authoring data once. Runtime snapshots consume native immutable values.
static func prepare(spec: Dictionary) -> Dictionary:
	var sweeps: Array=[]
	for authored in spec.beams:
		var sweep: Dictionary={"from_radians":deg_to_rad(float(authored.from_degrees)),"to_radians":deg_to_rad(float(authored.to_degrees))}
		sweep.make_read_only();sweeps.append(sweep)
	sweeps.make_read_only()
	var profile: Dictionary={"name":spec.name,"gate":spec.gate,"origin":Vector2(spec.origin[0],spec.origin[1]),"color":Color(spec.color),"beams":sweeps}
	for field in ["period_seconds","telegraph_seconds","active_seconds","length","width","telegraph_width"]:profile[field]=float(spec[field])
	profile.damage_scale=float(spec.get("damage_scale",1))
	profile.width_transition_seconds=float(spec.get("width_transition_seconds",0))
	profile.make_read_only()
	return profile
