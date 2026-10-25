extends RefCounted
## One source of truth for the old frame selectors and the renewed projected attitude.
const TURN_STEP: float = PI/10.0
static func sprite_x(kind: int, v: Vector2, cycle: int, y: float = 0) -> int:
	match kind:
		1: return 0 if v.y>2 else (50 if v.y>=0 else (100 if v.y> -4 else 150))
		2,6,7:
			var base: int = 200 if kind==2 else (1100 if kind==6 else 1400)
			return base+(150 if (v.y>0)==(kind==7) else 0)+(100 if v.x>2 else (50 if v.x< -2 else 0))
		3: return 500+cycle*50
		4: return 700+cycle*50
		5: return 900+cycle*50
		8: return 1700+(100 if v.x>1 else (50 if v.x< -1 else 0))
		9: return 1850+cycle*50
		10: return 2050+sprite_x(1,v,cycle)
		11: return 2250+(100 if v.x>2 else (50 if v.x< -2 else 0))
		19: return 2400
		201: return 2500 if y>290 else 2450
	return 0
static func pitch_target(kind: int, velocity: Vector2) -> float:
	if kind==1 or kind==10:
		return 0.0 if velocity.y>2 else (PI/3 if velocity.y>=0 else (PI*2/3 if velocity.y> -4 else PI))
	if kind==2 or kind==6 or kind==7: return 0.0 if velocity.y>0 else PI
	return 0.0
static func bank_target(kind: int, velocity: Vector2) -> float:
	if kind!=2 and kind!=6 and kind!=7 and kind!=8 and kind!=11: return 0.0
	var threshold: float = 1.0 if kind==8 else 2.0
	return 1.0 if velocity.x>threshold else (-1.0 if velocity.x< -threshold else 0.0)
static func pulse_target(cycle: int) -> float:
	match posmod(cycle,4):
		0: return 0.0
		2: return 1.0
	return 0.5
static func target(kind: int, velocity: Vector2, cycle: int) -> Dictionary:
	var pitch: float = pitch_target(kind,velocity)
	var bank: float = bank_target(kind,velocity)
	var pulse: float = pulse_target(cycle)
	return {"pitch":pitch,"bank":bank,"pulse":pulse,"previous_pitch":pitch,"previous_bank":bank,"previous_pulse":pulse}
static func advance(pose: Dictionary, kind: int, velocity: Vector2, cycle: int) -> void:
	pose.previous_pitch = pose.pitch
	pose.previous_bank = pose.bank
	pose.previous_pulse = pose.pulse
	pose.pitch = move_toward(pose.pitch,pitch_target(kind,velocity),TURN_STEP)
	pose.bank = move_toward(pose.bank,bank_target(kind,velocity),0.2)
	pose.pulse = lerpf(pose.pulse,pulse_target(cycle),0.3)
static func projection(pose: Dictionary) -> Vector2:
	return project(pose.pitch,pose.bank)
static func project(pitch: float, bank: float, kind: int = 0) -> Vector2:
	var y: float = cos(pitch)
	# Keep a visible wing edge while pitching through 90 degrees.
	if absf(y)<0.12: y = 0.12 if pitch<=PI/2 else -0.12
	var span: float = 0.65+absf(bank)*0.35 if kind==8 else 1.0-absf(bank)*0.2
	return Vector2(span,y)

static func bank_yaw(bank: float, projected_y: float) -> float:
	return -bank*0.1*projected_y
