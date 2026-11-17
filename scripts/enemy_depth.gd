extends RefCounted
## Shared lower-plane presentation for ascending enemies and protected supplies.
## The original enemy position is a top-left anchor; surface_y uses that same Y.
const Catalog = preload("res://scripts/enemy_catalog.gd")
const ASCENT_PATTERN: int = 1071
const SURFACE_Y: float = 250.0
const BLEND_DISTANCE: float = 60.0
const LOWER_SCALE: float = 0.8
const LOWER_BRIGHTNESS: float = 0.65
static func is_below(actor: Dictionary) -> bool:
	if int(actor.get("pattern",0))==ASCENT_PATTERN and actor.pos.y>SURFACE_Y: return true
	var definition: Dictionary = Catalog.definition(int(actor.get("kind",0)))
	return definition.get("role","")=="supply" and not definition.get("damageable",false)
static func amount(actor: Dictionary) -> float:
	if not is_below(actor): return 0.0
	var definition: Dictionary = Catalog.definition(int(actor.get("kind",0)))
	if definition.get("role","")=="supply":
		if actor.get("rescued",false): return 1.0
		var surface: float = float(definition.get("open_at_y",SURFACE_Y))
		return smoothstep(surface,surface+BLEND_DISTANCE,actor.pos.y)
	return smoothstep(SURFACE_Y,SURFACE_Y+BLEND_DISTANCE,actor.pos.y)
static func scale_for(actor: Dictionary) -> float:
	return lerpf(1.0,LOWER_SCALE,amount(actor))
static func tint_for(actor: Dictionary) -> Color:
	var brightness: float = lerpf(1.0,LOWER_BRIGHTNESS,amount(actor))
	return Color(brightness,brightness,brightness)
