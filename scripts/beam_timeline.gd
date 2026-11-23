extends RefCounted
## Owner-local start gate, health phase latch and cyclic/continuous exposure time.
## Pattern geometry, colors and particle emission stay outside the clock.
const EPSILON: float=0.0000001
const Random=preload("res://scripts/random.gd")
static func new_clock() -> Dictionary:
	return {"started":false,"age":0.0,"cycle":-1,"phase":{},"phase_start":0.0,"cycle_start":0.0,"phase_origin":0.0,"choice":0,"base_period":0.0}
static func phase_for(owner: Dictionary,spec: Dictionary) -> Dictionary:
	var maximum: float=float(owner.get("max_hp",0))
	if maximum>0:
		for phase in spec.health_phases:
			if float(owner.hp)/maximum<=float(phase.at_or_below_ratio):return phase
	return spec.default_phase
static func choose(clock: Dictionary) -> void:
	var count: int=clock.phase.beam_choices.size()
	clock.choice=Random.between(0,count-1) if count>1 else 0
static func advance(clock: Dictionary,owner: Dictionary,spec: Dictionary,seconds: float,scroll_stopped: bool) -> bool:
	if not clock.started:
		if spec.gate=="scroll_stopped" and not scroll_stopped:return false
		clock.started=true # First activation samples age zero; the gate does not restart later.
	else:clock.age=float(clock.age)+seconds
	var selected: Dictionary=phase_for(owner,spec)
	clock.base_period=float(spec.period_seconds)
	if clock.phase.is_empty():
		clock.phase=selected;clock.cycle=0
		choose(clock)
	elif clock.phase.continuous:
		if not is_same(selected,clock.phase):
			clock.cycle=floori((float(clock.age)+EPSILON)/float(spec.period_seconds))
			clock.phase_start=clock.cycle*float(spec.period_seconds)
			clock.cycle_start=clock.phase_start;clock.phase_origin=clock.phase_start
			clock.phase=selected;choose(clock)
	else:
		while float(clock.age)+EPSILON>=float(clock.cycle_start)+float(clock.phase.period_seconds):
			clock.cycle_start=float(clock.cycle_start)+float(clock.phase.period_seconds)
			clock.phase_start=clock.cycle_start
			clock.cycle=int(clock.cycle)+1
			if not is_same(selected,clock.phase):
				clock.phase=selected;clock.phase_origin=clock.cycle_start
			choose(clock) # Prediction and attack retain this choice for the whole cycle.
			if clock.phase.continuous:break
	return true
static func sample_age(clock: Dictionary) -> float:
	if clock.phase.continuous:return float(clock.age)-float(clock.phase_start)
	return float(clock.age)-float(clock.phase_origin) if clock.phase.period_seconds!=clock.base_period else float(clock.age)
static func exposure(spec: Dictionary,pattern: Dictionary,age: float) -> Dictionary:
	var continuous: bool=pattern.continuous
	var phase: float=age+EPSILON if continuous else fposmod(age+EPSILON,float(pattern.period_seconds))
	var telegraph: bool=phase<float(spec.telegraph_seconds)
	if not continuous and not telegraph and phase>=float(spec.telegraph_seconds)+float(spec.active_seconds):return {}
	var active_age: float=maxf(0,phase-float(spec.telegraph_seconds))
	var progress: float=0.0 if telegraph or continuous else clampf(active_age/float(spec.active_seconds),0,1)
	return {"telegraph":telegraph,"active_age":active_age,"progress":progress}
