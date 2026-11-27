extends RefCounted
## Keep authoring permissions aligned with the two runtime dispatchers.
const Check=preload("res://scripts/data_validation.gd")
const BOSS_GATES: Array=["always","any_parts","no_parts","part_missing","part_alive","parts_missing"]
const ACTOR_GATES: Array=["always","ground_ready","aim_window","moving","stationary_aim","sweep_y","descent_or_stationary","descending","flame_y","charge_y","fist_y","pod_y","orb_y","orb_y_stationary","orb_stationary","left_claw_y","right_claw_y","detached","core_settled"]
static func validate(channel: Dictionary,role: String,entities: Dictionary,prefix: String,errors: PackedStringArray) -> void:
	var gates: Array=BOSS_GATES if role=="boss" else ACTOR_GATES
	if channel.get("gate","") not in gates:
		errors.append(prefix+"fire gate is unsupported for role "+role)
		return
	if channel.gate not in ["part_missing","part_alive","parts_missing"]:return
	var ids: Variant=channel.get("part_ids") if channel.gate=="parts_missing" else [channel.get("part_id")]
	if not ids is Array or ids.is_empty():errors.append(prefix+"part gate requires a nonempty part list");return
	for id in ids:
		if not Check.number(id) or float(id)!=int(id):errors.append(prefix+"invalid referenced part ID");continue
		var definition: Variant=entities.get(str(int(id)),{})
		if not definition is Dictionary or definition.get("role","")!="part":errors.append(prefix+"part gate must reference a part")
