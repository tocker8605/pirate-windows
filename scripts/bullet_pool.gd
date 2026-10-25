extends RefCounted
## Original ewsh_a shared bullet/item ring, including type-2 unconditional cursor steps.
const Fire = preload("res://scripts/enemy_fire.gd")
const Boss = preload("res://scripts/boss.gd")
const LIMITS: Dictionary = {2:148,6:148,7:147,8:148,10:146,11:148,21:147,22:148,41:148,42:148,112:147,113:148,121:147,122:147,131:148,132:148}
static func normalize(g: Node, limit: int = 199) -> void:
	if g.bullet_cursor>limit: g.bullet_cursor = 3
static func available(g: Node) -> bool:
	for bullet in g.bullets:
		if bullet.get("slot",-1)==g.bullet_cursor and bullet.alive: return false
	for item in g.items:
		if item.get("slot",-1)==g.bullet_cursor: return false
	return true
static func write(g: Node, projectile: Dictionary) -> void:
	var slot: int = g.bullet_cursor
	g.bullets = g.bullets.filter(func(b): return b.get("slot",-1)!=slot)
	g.items = g.items.filter(func(item): return item.get("slot",-1)!=slot)
	g.bullets.append({"pos":projectile.pos,"velocity":projectile.velocity,"kind":projectile.kind,"alive":true,"slot":slot})
static func advance(g: Node) -> void:
	g.bullet_cursor += 1
	normalize(g)
static func group(g: Node, projectiles: Array) -> void:
	if projectiles.is_empty() or not available(g): return
	for projectile in projectiles:
		write(g,projectile)
		advance(g)
static func single(g: Node, pos: Vector2, velocity: Vector2, kind: int) -> void:
	normalize(g)
	group(g,[{"pos":pos,"velocity":velocity,"kind":kind}])
static func enemy(g: Node, e: Dictionary) -> void:
	normalize(g)
	if g.player.x==e.pos.x and g.player.y==e.pos.y-20: return
	var kind: int = int(e.kind)
	normalize(g,int(LIMITS.get(kind,199)))
	if kind!=2 and not available(g): return
	var candidates: Array = Fire.burst(e,g.player,g.clock.phase,int((g.frame-1)/30),g.boss)
	if kind==2:
		if not candidates.is_empty() and candidates[0].kind==1 and available(g): write(g,candidates[0])
		advance(g)
		if not candidates.is_empty() and candidates[0].kind==3 and available(g): write(g,candidates[0])
		advance(g)
	elif kind==21 and candidates.size()==3:
		group(g,candidates.slice(0,2))
		group(g,candidates.slice(2))
	elif kind in [22,41,131,132]:
		for candidate in candidates: group(g,[candidate])
	else: group(g,candidates)
static func body(g: Node) -> void:
	if g.boss.is_empty(): return
	var stage: int = int(g.boss.stage)
	normalize(g,[199,199,145,146,145][stage])
	if stage==4:
		for section in [1,2,3]:
			if available(g): group(g,Boss.fire(g.boss,g.enemies,g.clock.phase,int((g.frame-1)/30),section))
	elif available(g):
		group(g,Boss.fire(g.boss,g.enemies,g.clock.phase,int((g.frame-1)/30)))
