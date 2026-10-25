class_name PirateMovement
extends RefCounted
## Independent enemy motion state; velocities use pixels per original 25 ms tick.
static func steer(e: Dictionary, player: Vector2, boss: Vector2) -> void:
	var p: Vector2 = e.pos
	var v: Vector2 = e.velocity
	match int(e.pattern):
		0: pass
		1011, 1012:
			if p.y < (200 if e.pattern == 1011 else 300): v.y = 5
			else: e.pattern = 1091
		1021, 1022:
			if p.y < 150: v.y = 3
			else: v.x += 1 if e.pattern == 1021 else -1
		1025, 1026:
			var right: bool = e.pattern == 1025
			if (right and p.x < 160) or (not right and p.x > 190): v.x = 5 if right else -5
			else:
				v.x += -1 if right else 1
				v.y += 1
		1031:
			v.x += -1 if p.x > player.x else 1
			if p.x < 50: v.x += 2
			if p.x > 300: v.x -= 2
			v.x = clampf(v.x, -4, 4)
			v.y = v.y + 1 if p.y > 275 else 1
		1032, 1033:
			var right: bool = e.pattern == 1032
			v.y = -1
			if ((right and p.x < 0) or (not right and p.x > 350)) and p.y > 250: v.x = 6 if right else -6
			if p.y < 250 and p.y > 100 and ((right and v.x > 0) or (not right and v.x < 0)): v.x += -1 if right else 1
			if p.y < 100: v.x += 2 if right else -2
		1034, 1035:
			var right: bool = e.pattern == 1034
			v.y = 1
			if ((right and p.x < 0) or (not right and p.x > 350)) and p.y < 140: v.x = 6 if right else -6
			if p.y < 140 and ((right and v.x > 0) or (not right and v.x < 0)): v.x += -1 if right else 1
			if p.y > 240: v.x += -1 if right else 1
		1041, 1042:
			if e.pattern == 1041 and p.x < player.x - 50: v.x = 4
			elif e.pattern == 1042 and p.x > player.x + 50: v.x = -4
			else: e.pattern = 1094
		1051, 1052:
			var sign_x: float = 1 if e.pattern == 1051 else -1
			if p.y < 50: v = Vector2(5 * sign_x, 3)
			if p.y>49 and p.y<200: v.x -= 2*sign_x
			if p.y>199: v.x += 2*sign_x
		1053, 1054:
			var sign_x: float = 1 if e.pattern == 1053 else -1
			if p.y > 200: v = Vector2(6 * sign_x, -1)
			if p.y<201 and p.y>100: v.x -= sign_x
			if p.y<101: v.x += 2*sign_x
		1061, 1062:
			v.x = 2 if e.pattern == 1061 else -2
			if (e.pattern==1061 and p.x< -20) or (e.pattern==1062 and p.x>370): v.y = 0
			else: v.y += 2
			if v.y > 4: e.pattern += 2
		1063, 1064:
			v.y -= 2
			if v.y < -4: e.pattern -= 2
		1071, 1074:
			if p.y > (250 if e.pattern == 1071 else 460): v.y = -10
			elif v.y < -1: v.y += 3
		1072, 1073:
			if p.y < (205 if e.pattern == 1072 else 150): v.y = 1
			else: v.x += -2 if p.x < 175 else 2
		1091: v = Vector2(0, v.y - 1)
		1092: v = Vector2(0, v.y + 1)
		1093: v = Vector2(0, v.y - 2)
		1094: v = Vector2(0, v.y + 2)
		2101:
			if p.y < boss.y + 25: v.y += 5
			elif p.y < boss.y + 70: v.y = 0
			else: v.y -= 2
			if absf(p.x - player.x) < 40: e.pattern = 2102
		2102:
			if p.y < 420:
				v.x = 0
				v.y += 4
			else:
				v.y = 0
				e.pattern = 2101
		2201:
			v.y = 8
			if p.y>400:
				v.y = -2
				e.pattern = 2202
		2202:
			v.y = -2
			if p.y<boss.y+50:
				v.y = 8
				e.pattern = 2201
		2203,2204:
			if p.y<boss.y or p.y>boss.y+100: v.y = 0
			if p.x<boss.x-80 or p.x>boss.x+80: v.x = 0
			var ay: float = 3 if e.pattern==2203 else 2
			var ax: float = 2 if e.pattern==2203 else 3
			v.y += -ay if p.y>boss.y+50 else ay
			v.x += -ax if p.x>boss.x-10 else ax
		2401: v.y += 1
		_: push_error("Unknown enemy movement pattern: %s"%e.pattern)
	e.velocity = v.clamp(Vector2(-10, -10), Vector2(10, 10))
