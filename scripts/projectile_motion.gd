extends RefCounted
## Motion only. Collision, damage, scoring and lifetime/removal policies remain with combat.
const Formation=preload("res://scripts/projectile_formation.gd")
static func advance(bullet: Dictionary,seconds: float) -> void:
	bullet.render_pos=bullet.pos
	bullet.render_velocity=bullet.velocity
	match int(bullet.kind):
		2:bullet.velocity.y=minf(500.0,bullet.velocity.y+333.33333333333337*seconds)
		8:bullet.velocity.y=minf(333.33333333333337,bullet.velocity.y+222.222222222222*seconds)
	# Preserve acceleration-before-displacement and the existing component update order.
	bullet.pos.x+=bullet.velocity.x*seconds
	bullet.pos.y=bullet.pos.y+bullet.velocity.y*seconds
	if bullet.has("formation"):bullet.pos+=Formation.advance(bullet,seconds)
