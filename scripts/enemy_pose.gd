extends RefCounted
## One source of truth for the old frame selectors and the renewed projected attitude.
const STATION_PHASE_STEP: float = TAU/240.0
const TURN_STEP: float = PI/10.0
static func sprite_x(kind: int, v: Vector2, cycle: int, y: float = 0) -> int:
	match kind:
		1: return 0 if v.y>(66.66666666666667 + 0.0001) else (50 if v.y>=0 else (100 if v.y> (-133.33333333333334 + 0.0001) else 150))
		2,6,7:
			var base: int = 200 if kind==2 else (1100 if kind==6 else 1400)
			return base+(150 if (v.y>(0 + 0.0001))==(kind==7) else 0)+(100 if v.x>(66.66666666666667 + 0.0001) else (50 if v.x< (-66.66666666666667 - 0.0001) else 0))
		3: return 500+cycle*50
		4: return 700+cycle*50
		5: return 900+cycle*50
		8: return 1700+(100 if v.x>(33.333333333333336 + 0.0001) else (50 if v.x< (-33.333333333333336 - 0.0001) else 0))
		9: return 1850+cycle*50
		10: return 2050+sprite_x(1,v,cycle)
		11: return 2250+(100 if v.x>(66.66666666666667 + 0.0001) else (50 if v.x< (-66.66666666666667 - 0.0001) else 0))
		19,20: return 2400
		201,202: return 2500 if y>290 else 2450
	return 0
static func pitch_target(kind: int, velocity: Vector2) -> float:
	if kind==1 or kind==10:
		return 0.0 if velocity.y>(66.66666666666667 + 0.0001) else (PI/3 if velocity.y>=0 else (PI*2/3 if velocity.y> (-133.33333333333334 + 0.0001) else PI))
	if kind==2 or kind==6 or kind==7: return 0.0 if velocity.y>(0 + 0.0001) else PI
	return 0.0
static func bank_target(kind: int, velocity: Vector2) -> float:
	if kind!=2 and kind!=6 and kind!=7 and kind!=8 and kind!=11: return 0.0
	var threshold: float = 33.333333333333336 if kind==8 else 66.66666666666667
	return 1.0 if velocity.x>threshold+0.0001 else (-1.0 if velocity.x< -threshold-0.0001 else 0.0)
static func pulse_target(cycle: int) -> float:
	match posmod(cycle,4):
		0: return 0.0
		2: return 1.0
	return 0.5
static func target(kind: int, velocity: Vector2, cycle: int) -> Dictionary:
	var pitch: float = pitch_target(kind,velocity)
	var bank: float = bank_target(kind,velocity)
	var pulse: float = pulse_target(cycle)
	return {"pitch":pitch,"bank":bank,"pulse":pulse,"previous_pitch":pitch,"previous_bank":bank,"previous_pulse":pulse,"spin":0.0,"previous_spin":0.0}
static func advance(pose: Dictionary, kind: int, velocity: Vector2, cycle: int, seconds: float = 1.0/60.0) -> void:
	pose.previous_spin = pose.get("spin",0.0)
	pose.spin = pose.previous_spin+seconds*33.333333333333336*(STATION_PHASE_STEP if kind==3 else (PI/36 if kind==9 else 0.0))
	pose.previous_pitch = pose.pitch
	pose.previous_bank = pose.bank
	pose.previous_pulse = pose.pulse
	pose.pitch = move_toward(pose.pitch,pitch_target(kind,velocity),TURN_STEP*seconds*33.333333333333336)
	pose.bank = move_toward(pose.bank,bank_target(kind,velocity),0.2*seconds*33.333333333333336)
	pose.pulse = lerpf(pose.pulse,pulse_target(cycle),1-pow(0.7,seconds*33.333333333333336))
static func projection(pose: Dictionary) -> Vector2:
	return project(pose.pitch,pose.bank)
static func wing_fold(bank: float) -> float:
	return clampf(1-absf(bank),0,1)
static func project(pitch: float, bank: float, kind: int = 0) -> Vector2:
	var y: float = cos(pitch)
	# Keep a visible wing edge while pitching through 90 degrees.
	if absf(y)<0.12: y = 0.12 if pitch<=PI/2 else -0.12
	var span: float = 1.0-absf(bank)*0.08 if kind==8 else 1.0-absf(bank)*0.2
	return Vector2(span,y)

static func bank_yaw(bank: float, projected_y: float) -> float:
	return -bank*0.1*projected_y
