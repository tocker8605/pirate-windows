extends RefCounted
## Logical player anchor stays50px for weapons/items; visible hull is40px around the same centre.
const CENTRE: Vector2 = Vector2(25,25)
const DRAW_SIZE: Vector2 = Vector2(40,40)
const COCKPIT: Vector2 = Vector2(25,18)
const HIT_RADIUS: float = 4.0
static func visual_point(original: Vector2) -> Vector2:
	return CENTRE+(original-CENTRE)*0.8
static func hits(player: Vector2, point: Vector2) -> bool:
	return point.distance_squared_to(player+COCKPIT)<HIT_RADIUS*HIT_RADIUS
