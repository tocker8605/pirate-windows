extends RefCounted
## Emit complete authored volleys into independent dynamic storage; no legacy slot gating.
const Fire = preload("res://scripts/enemy_fire.gd")
const Boss = preload("res://scripts/boss.gd")
static func write(g: Node, projectile: Dictionary) -> void:
	g.bullets.append({"pos":projectile.pos,"velocity":projectile.velocity,"kind":projectile.kind,"alive":true})
static func group(g: Node, projectiles: Array) -> void:
	for projectile in projectiles: write(g,projectile)
static func single(g: Node, pos: Vector2, velocity: Vector2, kind: int) -> void:
	write(g,{"pos":pos,"velocity":velocity,"kind":kind})
static func enemy(g: Node, e: Dictionary, seconds: float) -> void:
	group(g,Fire.advance(e,seconds,g.player,g.boss))
static func body(g: Node, seconds: float) -> void:
	if not g.boss.is_empty(): group(g,Boss.advance(g.boss,g.enemies,seconds,g.player))
