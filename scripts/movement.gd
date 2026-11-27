class_name PirateMovement
extends RefCounted
const RocketFist=preload("res://scripts/rocket_fist_motion.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Depth = preload("res://scripts/enemy_depth.gd")
## Velocities are px/s and acceleration is px/s². No steering timer or tick grid.
const BASE_ACCELERATION: float = 123.45679012345679
const MAX_SPEED: float = 333.3333333333333
const OSCILLATION_SPEED: float = 200.0
static func steer(e: Dictionary, player: Vector2, boss: Vector2, seconds: float = 1.0/60.0) -> void:
	if Catalog.definition(int(e.kind)).get("movement_mode","pattern")=="stationary":
		e.velocity=Vector2.ZERO
		return
	if seconds<=0: return
	if RocketFist.active(e):
		RocketFist.steer(e,player,boss,seconds)
		return
	var p: Vector2 = e.pos
	if int(e.pattern)==int(Catalog.definition(int(e.kind)).get("core_motion",{}).get("pattern",-1)): return
	var v: Vector2 = e.velocity
	var acceleration: float = BASE_ACCELERATION*seconds
	match int(e.pattern):
		0: pass
		1011,1012:
			if p.y<(200 if e.pattern==1011 else 300): v.y=166.6666666666667
			else:
				e.pattern=1091
				v=Vector2(0,v.y-acceleration)
		1021,1022:
			if p.y<150: v.y=100
			else: v.x+=acceleration if e.pattern==1021 else -acceleration
		1025,1026:
			var right: bool=e.pattern==1025
			if (right and p.x<160) or (not right and p.x>190): v.x=166.6666666666667 if right else -166.6666666666667
			else:
				v.x+= -acceleration if right else acceleration
				v.y+=acceleration
		1031:
			v.x+= -acceleration if p.x>player.x else acceleration
			if p.x<50: v.x+=acceleration*2
			if p.x>300: v.x-=acceleration*2
			v.x=clampf(v.x,-133.3333333333333,133.3333333333333)
			v.y=v.y+acceleration if p.y>275 else 33.3333333333333
		1032,1033:
			var right: bool=e.pattern==1032
			v.y= -33.3333333333333
			if ((right and p.x<0) or (not right and p.x>350)) and p.y>250: v.x=200 if right else -200
			if p.y<250 and p.y>100 and ((right and v.x>0) or (not right and v.x<0)): v.x=move_toward(v.x,0,acceleration)
			if p.y<100: v.x+=acceleration*2 if right else -acceleration*2
		1034,1035:
			var right: bool=e.pattern==1034
			v.y=33.3333333333333
			if ((right and p.x<0) or (not right and p.x>350)) and p.y<140: v.x=200 if right else -200
			if p.y<140 and ((right and v.x>0) or (not right and v.x<0)): v.x=move_toward(v.x,0,acceleration)
			if p.y>240: v.x+= -acceleration if right else acceleration
		1041,1042:
			if e.pattern==1041 and p.x<player.x-10: v.x=133.3333333333333
			elif e.pattern==1042 and p.x>player.x+10: v.x= -133.3333333333333
			else:
				e.pattern=1094
				v=Vector2(0,v.y+acceleration*2)
		1051,1052:
			var sign_x: float=1 if e.pattern==1051 else -1
			if p.y<50: v=Vector2(166.6666666666667*sign_x,100)
			elif p.y<200: v.x-=acceleration*2*sign_x
			else: v.x+=acceleration*2*sign_x
		1053,1054:
			var sign_x: float=1 if e.pattern==1053 else -1
			if p.y>200: v=Vector2(200*sign_x,-33.3333333333333)
			elif p.y>100: v.x-=acceleration*sign_x
			else: v.x+=acceleration*2*sign_x
		1061,1062:
			v.x=66.6666666666667 if e.pattern==1061 else -66.6666666666667
			if (e.pattern==1061 and p.x< -20) or (e.pattern==1062 and p.x>370): v.y=0
			else: v.y=move_toward(v.y,OSCILLATION_SPEED,acceleration*2)
			if v.y>=OSCILLATION_SPEED-0.0001: e.pattern+=2
		1063,1064:
			v.y=move_toward(v.y,-OSCILLATION_SPEED,acceleration*2)
			if v.y<= -OSCILLATION_SPEED+0.0001: e.pattern-=2
		1071,1074:
			if p.y>(Depth.SURFACE_Y if e.pattern==Depth.ASCENT_PATTERN else 460): v.y= -MAX_SPEED
			elif v.y< -33.3333333333333: v.y=move_toward(v.y,-33.3333333333333,acceleration*3)
		1072,1073:
			if p.y<(205 if e.pattern==1072 else 150): v.y=33.3333333333333
			else: v.x+= -acceleration*2 if p.x<175 else acceleration*2
		1091: v=Vector2(0,v.y-acceleration)
		1092: v=Vector2(0,v.y+acceleration)
		1093: v=Vector2(0,v.y-acceleration*2)
		1094: v=Vector2(0,v.y+acceleration*2)
		2201:
			v.y=266.6666666666667
			if p.y>400:
				v.y= -66.6666666666667
				e.pattern=2202
		2202:
			v.y= -66.6666666666667
			if p.y<boss.y+50:
				v.y=266.6666666666667
				e.pattern=2201
		_: push_error("Unknown enemy movement pattern: %s"%e.pattern)
	e.velocity=v.clamp(Vector2(-MAX_SPEED,-MAX_SPEED),Vector2(MAX_SPEED,MAX_SPEED))

static func displacement(velocity: Vector2, seconds: float) -> Vector2:
	return velocity*seconds
