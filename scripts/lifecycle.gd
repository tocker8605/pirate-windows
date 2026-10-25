extends RefCounted
const Rng = preload("res://scripts/random.gd")
## Original 240-tick boss/player destruction and stage loading transitions.
static func update(g: Node) -> void:
	if not g.boss.is_empty() and g.boss.hp<=0 and not g.boss_defeated: g._finish_stage()
	if g.hp<=0 and g.death_ticks==0:
		g.hp = 0
		g.death_ticks = 240
		g.state = "dying"
		g.laser = 0
		g.laser_render_ticks = 0
		if g.music_track!="boss01": g._stop_music()
	if g.boss_death_ticks>0:
		g.boss_death_ticks -= 1
		for e in g.enemies: e.hp = 0
		g.bullets.clear()
		g.items.clear()
		if g.boss_death_ticks%10==0:
			g._explosion(g.boss.pos+Vector2(20-Rng.between(0,59),-30),20,true)
		if g.boss_death_ticks==0 and g.death_ticks==0:
			g._complete_stage()
			return
	if g.death_ticks>0:
		g.death_ticks -= 1
		if g.death_ticks>0 and g.death_ticks%10==0:
			g._explosion(g.player+Vector2(20-Rng.between(0,39),-10),20,true)
		if g.death_ticks==0:
			g._return_title()
			g.score = 0

static func begin_boss_death(g: Node) -> void:
	if g.boss_defeated: return
	g.boss_defeated = true
	g.boss_death_ticks = 240
	g.scroll_target = 4
	if g.death_ticks==0: g.state = "boss_dying"

static func complete_stage(g: Node) -> void:
	g._stop_music()
	g.score += [0,5000,10000,20000,30000][g.stage]
	g._save_score()
	var image: String = "loading2" if Rng.between(0,1)==0 else "loading3"
	if g.stage<4:
		g.loading_image = image
		g.loading_target = g.stage+1
		g.loading_preserve = true
		g.loading_ticks = 0
		g.state = "loading"
	else:
		g._return_title()
		g.score = 0
