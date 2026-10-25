extends RefCounted
## Shared three-region stages plus stage4: one-shot Earth/surface and looping space/cavern.
const SCREEN: float = 480.0
const EDGES: Vector4 = Vector4(SCREEN*2,SCREEN*3,SCREEN*5,SCREEN*6)
const NAMES: Array = [
 ["OCEAN","COAST","FOREST"],
 ["GREEN VALLEYS","SNOW PEAKS","FOREST RIDGES"],
 ["NIGHT SNOW","NIGHT OUTPOST","NIGHT OCEAN"],
 ["EARTH","SPACE","MOON SURFACE","LUNAR CAVERN"]]
static func count(stage: int) -> int: return NAMES[clampi(stage,1,4)-1].size()
static func earth_phase(source_y: float) -> float: return (source_y-SCREEN*6)/(SCREEN*2)
static func sample(source_y: float, stage: int = 1) -> Dictionary:
	if stage==4:
		var region: int = 1 if source_y>=SCREEN*6 else (2 if source_y>=SCREEN*3 else (3 if source_y>=SCREEN*2 else 4))
		return {"near":region,"far":region,"blend":0.0}
	if source_y>=EDGES.w: return {"near":1,"far":1,"blend":0.0}
	if source_y>=EDGES.z: return {"near":2,"far":1,"blend":smoothstep(EDGES.z,EDGES.w,source_y)}
	if source_y>=EDGES.y: return {"near":2,"far":2,"blend":0.0}
	if source_y>=EDGES.x: return {"near":3,"far":2,"blend":smoothstep(EDGES.x,EDGES.y,source_y)}
	return {"near":3,"far":3,"blend":0.0}
static func source_phase(source_y: float) -> float: return fposmod(source_y,SCREEN)/SCREEN

static func wrap(source_top: float, mode: int) -> float:
	var boundary: float = EDGES.w if mode==1 else (EDGES.y if mode==2 else 0.0)
	return source_top+SCREEN if source_top<boundary else source_top