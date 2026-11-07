extends RefCounted
## Shared movement/collision/presentation rule for the lower-plane ascent.
## The original enemy position is a top-left anchor; surface_y uses that same Y.
const ASCENT_PATTERN: int = 1071
const SURFACE_Y: float = 250.0
const BLEND_DISTANCE: float = 60.0
const LOWER_SCALE: float = 0.8
const LOWER_BRIGHTNESS: float = 0.65
static func is_below(actor: Dictionary) -> bool:
	return int(actor.get("pattern",0))==ASCENT_PATTERN and actor.pos.y>SURFACE_Y
static func amount(actor: Dictionary) -> float:
	if not is_below(actor): return 0.0
	return smoothstep(SURFACE_Y,SURFACE_Y+BLEND_DISTANCE,actor.pos.y)
static func scale_for(actor: Dictionary) -> float:
	return lerpf(1.0,LOWER_SCALE,amount(actor))
static func tint_for(actor: Dictionary) -> Color:
	var brightness: float = lerpf(1.0,LOWER_BRIGHTNESS,amount(actor))
	return Color(brightness,brightness,brightness)
