extends RefCounted
## Logical player anchor stays50px for weapons/items; visible hull is40px around the same centre.
const CENTRE: Vector2 = Vector2(25,25)
const DRAW_SIZE: Vector2 = Vector2(40,40)
const COCKPIT: Vector2 = Vector2(25,18)
const HIT_RADIUS: float = 4.0
const VERTICAL_LIMITS := Vector2(0,440)
const HORIZONTAL_OVERSCAN: float = 5.0
static func centred_x(screen_width: float = 400.0) -> float:
	return screen_width/2-COCKPIT.x
static func clamp_horizontal(x: float, screen_width: float = 400.0) -> float:
	# Permit the visible hull to extend5px beyond either screen edge.
	var left: float = DRAW_SIZE.x/2-CENTRE.x-HORIZONTAL_OVERSCAN
	var right: float = screen_width-DRAW_SIZE.x/2-CENTRE.x+HORIZONTAL_OVERSCAN
	return clampf(x,left,right)
static func clamp_vertical(y: float) -> float:
	return clampf(y,VERTICAL_LIMITS.x,VERTICAL_LIMITS.y)
static func visual_point(original: Vector2) -> Vector2:
	return CENTRE+(original-CENTRE)*0.8
static func hits(player: Vector2, point: Vector2) -> bool:
	return point.distance_squared_to(player+COCKPIT)<HIT_RADIUS*HIT_RADIUS
