extends RefCounted
## Logical player anchor stays50px for weapons/items; visible hull is40px around the same centre.
const CENTRE: Vector2 = Vector2(25,25)
const DRAW_SIZE: Vector2 = Vector2(40,40)
const COCKPIT: Vector2 = Vector2(25,18)
const HIT_RADIUS: float = 4.0
static func clamp_horizontal(x: float, screen_width: float = 400.0) -> float:
	# The40px drawing is centred on the50px logical anchor, leaving a5px inset.
	var left: float = DRAW_SIZE.x/2-CENTRE.x
	var right: float = screen_width-DRAW_SIZE.x/2-CENTRE.x
	return clampf(x,left,right)
static func visual_point(original: Vector2) -> Vector2:
	return CENTRE+(original-CENTRE)*0.8
static func hits(player: Vector2, point: Vector2) -> bool:
	return point.distance_squared_to(player+COCKPIT)<HIT_RADIUS*HIT_RADIUS
