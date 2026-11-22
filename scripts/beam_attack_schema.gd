extends RefCounted
const Check=preload("res://scripts/data_validation.gd")
static func validate(value: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not value is Array:errors.append(prefix+"beam_attacks must be an array");return
	var names: Array=[]
	for spec in value:
		if not spec is Dictionary:errors.append(prefix+"invalid beam attack");continue
		Check.unknown_fields(spec,["name","gate","origin","period_seconds","telegraph_seconds","active_seconds","length","width","telegraph_width","color","damage_scale","width_transition_seconds","beams","low_health"],prefix,errors)
		if not spec.get("name") is String or spec.name.is_empty() or spec.name in names:errors.append(prefix+"invalid/duplicate beam attack name")
		names.append(spec.get("name"))
		if spec.get("gate") not in ["immediate","scroll_stopped"]:errors.append(prefix+"unknown beam start gate")
		if not Check.vector(spec.get("origin"),2):errors.append(prefix+"invalid beam origin")
		var timing: bool=true
		for field in ["period_seconds","active_seconds","length","width","telegraph_width"]:
			if not Check.number(spec.get(field)) or float(spec.get(field,0))<=0:errors.append(prefix+"invalid beam "+field);timing=false
		if not Check.number(spec.get("telegraph_seconds")) or float(spec.get("telegraph_seconds",-1))<0:errors.append(prefix+"invalid telegraph duration");timing=false
		if timing and (spec.period_seconds<spec.telegraph_seconds+spec.active_seconds or spec.telegraph_width>spec.width):errors.append(prefix+"invalid beam phase durations or widths")
		if spec.has("width_transition_seconds"):
			if not Check.number(spec.width_transition_seconds) or float(spec.width_transition_seconds)<0:errors.append(prefix+"invalid visual width transition")
			elif timing and float(spec.width_transition_seconds)*2>float(spec.active_seconds):errors.append(prefix+"visual width transitions exceed the active duration")
		if spec.has("damage_scale") and (not Check.number(spec.damage_scale) or float(spec.damage_scale)<=0):errors.append(prefix+"invalid beam damage scale")
		if not spec.get("color") is String or not Color.html_is_valid(spec.get("color","")):errors.append(prefix+"invalid beam color")
		validate_sweeps(spec.get("beams"),prefix,errors)
		if spec.has("low_health"):
			var low: Variant=spec.low_health
			if not low is Dictionary:errors.append(prefix+"invalid low-health beam variant");continue
			Check.unknown_fields(low,["at_or_below_ratio","beams"],prefix+"low_health.",errors)
			if not Check.number(low.get("at_or_below_ratio")) or float(low.get("at_or_below_ratio",0))<=0 or float(low.get("at_or_below_ratio",0))>1:errors.append(prefix+"invalid low-health ratio")
			validate_sweeps(low.get("beams"),prefix+"low_health.",errors)
static func validate_sweeps(beams: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not beams is Array or beams.is_empty():errors.append(prefix+"beam attack needs sweep definitions");return
	for sweep in beams:
		if not sweep is Dictionary:errors.append(prefix+"invalid beam sweep");continue
		Check.unknown_fields(sweep,["from_degrees","to_degrees"],prefix+"sweep.",errors)
		if not Check.number(sweep.get("from_degrees")) or not Check.number(sweep.get("to_degrees")):errors.append(prefix+"invalid sweep angles")
