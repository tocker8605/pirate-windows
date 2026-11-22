extends RefCounted
## Owner-local start gate, health phase latch and cyclic/continuous exposure time.
## Pattern geometry, colors and particle emission stay outside the clock.
const EPSILON: float=0.0000001
static func new_clock() -> Dictionary:
	return {"started":false,"age":0.0,"cycle":-1,"phase":{},"phase_start":0.0}
static func phase_for(owner: Dictionary,spec: Dictionary) -> Dictionary:
	var maximum: float=float(owner.get("max_hp",0))
	if maximum>0:
		for phase in spec.health_phases:
			if float(owner.hp)/maximum<=float(phase.at_or_below_ratio):return phase
	return spec.default_phase
static func should_select_phase(clock: Dictionary,selected: Dictionary,cycle: int) -> bool:
	var current: Dictionary=clock.phase
	if current.is_empty():return true
	if current.continuous:return not is_same(selected,current)
	return int(clock.cycle)!=cycle
static func advance(clock: Dictionary,owner: Dictionary,spec: Dictionary,seconds: float,scroll_stopped: bool) -> bool:
	if not clock.started:
		if spec.gate=="scroll_stopped" and not scroll_stopped:return false
		clock.started=true # First activation samples age zero; the gate does not restart later.
	else:clock.age=float(clock.age)+seconds
	var cycle: int=floori((float(clock.age)+EPSILON)/float(spec.period_seconds))
	var selected: Dictionary=phase_for(owner,spec)
	if should_select_phase(clock,selected,cycle):
		clock.cycle=cycle
		clock.phase=selected # One path for both prediction and live damage.
		clock.phase_start=cycle*float(spec.period_seconds)
	return true
static func sample_age(clock: Dictionary) -> float:
	return float(clock.age)-float(clock.phase_start) if clock.phase.continuous else float(clock.age)
static func exposure(spec: Dictionary,pattern: Dictionary,age: float) -> Dictionary:
	var continuous: bool=pattern.continuous
	var phase: float=age+EPSILON if continuous else fposmod(age+EPSILON,float(spec.period_seconds))
	var telegraph: bool=phase<float(spec.telegraph_seconds)
	if not continuous and not telegraph and phase>=float(spec.telegraph_seconds)+float(spec.active_seconds):return {}
	var active_age: float=maxf(0,phase-float(spec.telegraph_seconds))
	var progress: float=0.0 if telegraph or continuous else clampf(active_age/float(spec.active_seconds),0,1)
	return {"telegraph":telegraph,"active_age":active_age,"progress":progress}
