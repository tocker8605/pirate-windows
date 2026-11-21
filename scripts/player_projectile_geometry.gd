extends RefCounted
## One boundary between stored player positions and visible projectile coordinates.
const SHOT_CENTRE:=Vector2(15,15)
const BEAM_CENTRE:=Vector2(25,0)
static func shot_centre(stored: Vector2) -> Vector2:return stored+SHOT_CENTRE
static func beam_origin(player: Vector2) -> Vector2:return player+BEAM_CENTRE
