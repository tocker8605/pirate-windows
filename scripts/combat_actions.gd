extends RefCounted
const Weapons = preload("res://scripts/player_weapons.gd")
const Effects = preload("res://scripts/special_effects.gd")
const Combat = preload("res://scripts/combat.gd")
static func apply_beam(g: Node) -> void:
	if g.beam_remaining_seconds<=0.000001: return
	for e in g.enemies:
		if Combat.beam_hits(g.player,e):
			e.hp -= 133.33333333333334*g.delta_seconds
			g.laser_contacts.append(Vector2(g.player.x+10,e.pos.y+25))
	if Combat.beam_hits_boss(g.player,g.boss):
		g._damage_boss(66.66666666666667*g.delta_seconds)
		g.laser_contacts.append(Vector2(g.player.x+10,g.boss.pos.y+45))
	g.beam_remaining_seconds = maxf(0,g.beam_remaining_seconds-g.delta_seconds)

static func resolve_shots(g: Node) -> void:
	for shot in g.shots:
		if float(shot.get("impact_remaining_seconds",-1))>=0: continue
		var hit: bool = false
		for e in g.enemies:
			if Combat.shot_hits(shot.pos,e):
				e.hp -= 3
				hit = true
				g.stats.hits += 1
		# Original outer cw>0 guard is evaluated once: overlapping units AND body can be hit.
		if Combat.shot_hits_boss(shot.pos,g.boss):
			g._damage_boss(3)
			hit = true
			g.stats.hits += 1
		if hit: shot.impact_remaining_seconds = 0.27

static func damage_boss(g: Node, amount: float) -> void:
	if g.boss.is_empty() or g.boss.hp<=0: return
	g.boss.hp -= amount
	if g.boss.hp<=0: g._finish_stage()

static func update_bullets(g: Node) -> void:
	for bullet in g.bullets:
		bullet.render_pos = bullet.pos
		bullet.render_velocity = bullet.velocity
		if int(bullet.kind)==2: bullet.velocity.y = minf(500.0,bullet.velocity.y+333.33333333333337*g.delta_seconds)
		if int(bullet.kind)==8: bullet.velocity.y = minf(333.33333333333337,bullet.velocity.y+222.222222222222*g.delta_seconds)
		bullet.pos.x += bullet.velocity.x*g.delta_seconds
		bullet.pos.y = bullet.pos.y+bullet.velocity.y*g.delta_seconds
		if bullet.velocity==Vector2.ZERO or bullet.pos.x<0 or bullet.pos.x>400 or bullet.pos.y<0 or bullet.pos.y>480:
			bullet.alive = false
			continue
		if Effects.shield_contains(g.shield_center,bullet.pos,g.shield_remaining_seconds):
			bullet.alive = false
			g.shield_contacts.append(bullet.pos)
			g.shield_remaining_seconds = maxf(0,g.shield_remaining_seconds-0.12)
			if g.boss.is_empty(): g.score += 25*g.title.difficulty
		elif g.hp>0 and g.invulnerability_seconds==0 and Combat.hurts_player(g.player,bullet.pos):
			g._hurt_player(Combat.incoming_damage(g.title.difficulty))
			bullet.alive = false
	for bullet in g.bullets:
		if not bullet.alive: g.bullets.remove(bullet.entity_id)

static func hurt_player(g: Node, damage: float) -> void:
	if g.hp<=0 or g.invulnerability_seconds>0 or g.death_remaining_seconds>0: return
	g.hp -= damage
	g.invulnerability_seconds = 1.5
	g.hit_flash_remaining_seconds = 0.57
	g._sound("damage")

static func resolve_body_contacts(g: Node) -> void:
	if g.hp<=0 or g.invulnerability_seconds>0 or g.death_remaining_seconds>0: return
	if Combat.touches_player(g.player,g.boss):
		g._hurt_player(Combat.incoming_damage(g.title.difficulty))
		return
	for e in g.enemies:
		if Combat.touches_player(g.player,e):
			g._hurt_player(Combat.incoming_damage(g.title.difficulty))
			return
