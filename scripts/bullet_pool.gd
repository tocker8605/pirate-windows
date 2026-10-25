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
static func enemy(g: Node, e: Dictionary) -> void:
	group(g,Fire.burst(e,g.player,g.clock.phase,int((g.frame-1)/30),g.boss))
static func body(g: Node) -> void:
	if g.boss.is_empty(): return
	if int(g.boss.stage)==4:
		for section in [1,2,3]: group(g,Boss.fire(g.boss,g.enemies,g.clock.phase,int((g.frame-1)/30),section))
	else: group(g,Boss.fire(g.boss,g.enemies,g.clock.phase,int((g.frame-1)/30)))
