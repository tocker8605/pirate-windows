extends RefCounted
const Check=preload("res://scripts/data_validation.gd")
static func validate(value: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not value is Array:errors.append(prefix+"beam_attacks must be an array");return
	var names: Array=[]
	for spec in value:
		if not spec is Dictionary:errors.append(prefix+"invalid beam attack");continue
		Check.unknown_fields(spec,["name","gate","origin","period_seconds","telegraph_seconds","active_seconds","length","width","telegraph_width","color","damage_scale","width_transition_seconds","beams","health_phases"],prefix,errors)
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
		if spec.has("health_phases"):validate_phases(spec.health_phases,prefix+"health_phases.",errors,float(spec.telegraph_seconds)+float(spec.active_seconds) if timing else 0)
static func validate_phases(phases: Variant,prefix: String,errors: PackedStringArray,minimum_period: float = 0) -> void:
	if not phases is Array:errors.append(prefix+"expected phase array");return
	var thresholds: Array=[]
	for phase in phases:
		if not phase is Dictionary:errors.append(prefix+"invalid phase");continue
		Check.unknown_fields(phase,["at_or_below_ratio","beams","beam_choices","period_seconds","continuous","swing"],prefix,errors)
		var ratio: Variant=phase.get("at_or_below_ratio")
		if not Check.number(ratio) or float(ratio)<=0 or float(ratio)>1:errors.append(prefix+"invalid health ratio")
		elif ratio in thresholds:errors.append(prefix+"duplicate health threshold")
		else:thresholds.append(ratio)
		if phase.has("continuous") and not phase.continuous is bool:errors.append(prefix+"continuous must be boolean")
		if phase.has("period_seconds"):
			var period: Variant=phase.period_seconds
			if not Check.number(period) or float(period)<=0 or float(period)<minimum_period:errors.append(prefix+"invalid phase period")
		if phase.has("beams")==phase.has("beam_choices"):errors.append(prefix+"provide exactly one of beams or beam_choices")
		elif phase.has("beam_choices"):
			var choices: Variant=phase.beam_choices
			if not choices is Array or choices.is_empty():errors.append(prefix+"empty beam choices")
			else:
				for beams in choices:validate_sweeps(beams,prefix+"beam_choices.",errors)
		else:validate_sweeps(phase.beams,prefix,errors)
		if phase.has("swing"):
			var swing: Variant=phase.swing
			if not swing is Dictionary:errors.append(prefix+"invalid swing");continue
			Check.unknown_fields(swing,["amplitude_degrees","period_seconds"],prefix+"swing.",errors)
			if not Check.number(swing.get("amplitude_degrees")) or float(swing.get("amplitude_degrees",0))<0:errors.append(prefix+"invalid swing amplitude")
			if not Check.number(swing.get("period_seconds")) or float(swing.get("period_seconds",0))<=0:errors.append(prefix+"invalid swing period")
static func validate_sweeps(beams: Variant,prefix: String,errors: PackedStringArray) -> void:
	if not beams is Array or beams.is_empty():errors.append(prefix+"beam attack needs sweep definitions");return
	for sweep in beams:
		if not sweep is Dictionary:errors.append(prefix+"invalid beam sweep");continue
		Check.unknown_fields(sweep,["from_degrees","to_degrees"],prefix+"sweep.",errors)
		if not Check.number(sweep.get("from_degrees")) or not Check.number(sweep.get("to_degrees")):errors.append(prefix+"invalid sweep angles")
