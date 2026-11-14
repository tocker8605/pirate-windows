class_name PirateMovement
extends RefCounted
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Depth = preload("res://scripts/enemy_depth.gd")
## Sampled steering rules; all public velocities are pixels/second.
static func steer(e: Dictionary, player: Vector2, boss: Vector2) -> void:
	var p: Vector2 = e.pos
	if int(e.pattern)==int(Catalog.definition(int(e.kind)).get("core_motion",{}).get("pattern",-1)): return
	var v: Vector2 = quantize_velocity(e.velocity)
	match int(e.pattern):
		0: pass
		1011, 1012:
			if p.y < (200 if e.pattern == 1011 else 300): v.y = 166.66666666666669
			else: e.pattern = 1091
		1021, 1022:
			if p.y < 150: v.y = 100
			else: v.x += 33.333333333333336 if e.pattern == 1021 else -33.333333333333336
		1025, 1026:
			var right: bool = e.pattern == 1025
			if (right and p.x < 160) or (not right and p.x > 190): v.x = 166.66666666666669 if right else -166.66666666666669
			else:
				v.x += -33.333333333333336 if right else 33.333333333333336
				v.y += 33.333333333333336
		1031:
			v.x += -33.333333333333336 if p.x > player.x else 33.333333333333336
			if p.x < 50: v.x += 66.66666666666667
			if p.x > 300: v.x -= 66.66666666666667
			v.x = clampf(v.x, -133.33333333333334, 133.33333333333334)
			v.y = v.y + 33.333333333333336 if p.y > 275 else 33.333333333333336
		1032, 1033:
			var right: bool = e.pattern == 1032
			v.y = -33.333333333333336
			if ((right and p.x < 0) or (not right and p.x > 350)) and p.y > 250: v.x = 200 if right else -200
			if p.y < 250 and p.y > 100 and ((right and v.x > (0 + 0.0001)) or (not right and v.x < (0 - 0.0001))): v.x += -33.333333333333336 if right else 33.333333333333336
			if p.y < 100: v.x += 66.66666666666667 if right else -66.66666666666667
		1034, 1035:
			var right: bool = e.pattern == 1034
			v.y = 33.333333333333336
			if ((right and p.x < 0) or (not right and p.x > 350)) and p.y < 140: v.x = 200 if right else -200
			if p.y < 140 and ((right and v.x > (0 + 0.0001)) or (not right and v.x < (0 - 0.0001))): v.x += -33.333333333333336 if right else 33.333333333333336
			if p.y > 240: v.x += -33.333333333333336 if right else 33.333333333333336
		1041, 1042:
			if e.pattern == 1041 and p.x < player.x - 50: v.x = 133.33333333333334
			elif e.pattern == 1042 and p.x > player.x + 50: v.x = -133.33333333333334
			else: e.pattern = 1094
		1051, 1052:
			var sign_x: float = 1 if e.pattern == 1051 else -1
			if p.y < 50: v = Vector2(166.66666666666669 * sign_x, 100)
			if p.y>49 and p.y<200: v.x -= 66.66666666666667*sign_x
			if p.y>199: v.x += 66.66666666666667*sign_x
		1053, 1054:
			var sign_x: float = 1 if e.pattern == 1053 else -1
			if p.y > 200: v = Vector2(200 * sign_x, -33.333333333333336)
			if p.y<201 and p.y>100: v.x -= 33.333333333333336*sign_x
			if p.y<101: v.x += 66.66666666666667*sign_x
		1061, 1062:
			v.x = 66.66666666666667 if e.pattern == 1061 else -66.66666666666667
			if (e.pattern==1061 and p.x< -20) or (e.pattern==1062 and p.x>370): v.y = 0
			else: v.y += 66.66666666666667
			if v.y > (133.33333333333334 + 0.0001): e.pattern += 2
		1063, 1064:
			v.y -= 66.66666666666667
			if v.y < (-133.33333333333334 - 0.0001): e.pattern -= 2
		1071, 1074:
			if p.y > (Depth.SURFACE_Y if e.pattern == Depth.ASCENT_PATTERN else 460): v.y = -333.33333333333337
			elif v.y < (-33.333333333333336 - 0.0001): v.y += 100
		1072, 1073:
			if p.y < (205 if e.pattern == 1072 else 150): v.y = 33.333333333333336
			else: v.x += -66.66666666666667 if p.x < 175 else 66.66666666666667
		1091: v = Vector2(0, v.y - 33.333333333333336)
		1092: v = Vector2(0, v.y + 33.333333333333336)
		1093: v = Vector2(0, v.y - 66.66666666666667)
		1094: v = Vector2(0, v.y + 66.66666666666667)
		2101:
			if p.y < boss.y + 25: v.y += 166.66666666666669
			elif p.y < boss.y + 70: v.y = 0
			else: v.y -= 66.66666666666667
			if absf(p.x - player.x) < 40: e.pattern = 2102
		2102:
			if p.y < 420:
				v.x = 0
				v.y += 133.33333333333334
			else:
				v.y = 0
				e.pattern = 2101
		2201:
			v.y = 266.6666666666667
			if p.y>400:
				v.y = -66.66666666666667
				e.pattern = 2202
		2202:
			v.y = -66.66666666666667
			if p.y<boss.y+50:
				v.y = 266.6666666666667
				e.pattern = 2201
		_: push_error("Unknown enemy movement pattern: %s"%e.pattern)
	e.velocity = quantize_velocity(v.clamp(Vector2(-333.33333333333337, -333.33333333333337), Vector2(333.33333333333337, 333.33333333333337)))

static func displacement(velocity: Vector2, seconds: float) -> Vector2:
	# Steering rates lie on this discrete grid. Quantize before multiplying to keep
	# float32 boundary crossings identical to the reference game after SI conversion.
	const RATE_GRID: float = 100.0/3.0
	var coefficients := Vector2(snappedf(velocity.x/RATE_GRID,0.00001),snappedf(velocity.y/RATE_GRID,0.00001))
	return coefficients*(seconds*RATE_GRID)

static func quantize_velocity(value: Vector2) -> Vector2:
	const RATE_GRID: float = 100.0/3.0
	return Vector2(snappedf(value.x/RATE_GRID,0.00001)*RATE_GRID,snappedf(value.y/RATE_GRID,0.00001)*RATE_GRID)
