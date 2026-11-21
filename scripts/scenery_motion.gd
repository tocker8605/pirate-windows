extends RefCounted
## Actual travelled scenery distance, including easing and stops, determines displacement.
static func y(anchor_y: float,anchor_distance: float,distance: float) -> float:
	return anchor_y+distance-anchor_distance
