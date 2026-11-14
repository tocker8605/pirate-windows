extends RefCounted
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const Rng = preload("res://scripts/random.gd")
## Boss/player destruction lasts7.2seconds; stage transitions preserve run state.
static func update(g: Node) -> void:
	if not g.boss.is_empty() and g.boss.hp<=0 and not g.boss_defeated: g._finish_stage()
	if g.hp<=0 and g.death_remaining_seconds==0:
		g.hp = 0
		g.death_remaining_seconds = 7.2
		g.state = "dying"
		g.beam_remaining_seconds = 0
		g.beam_render_seconds = 0
		if g.music_track!="boss01": g._stop_music()
	if g.boss_death_remaining_seconds>0:
		var previous: float = g.boss_death_remaining_seconds
		g.boss_death_remaining_seconds = maxf(0,g.boss_death_remaining_seconds-g.delta_seconds)
		if g.boss_death_remaining_seconds<0.000001: g.boss_death_remaining_seconds = 0
		for e in g.enemies: e.hp = 0
		g.bullets.clear()
		g.items.clear()
		if int(ceil(previous/0.3))!=int(ceil(g.boss_death_remaining_seconds/0.3)):
			g._explosion(g.boss.pos+Vector2(20-Rng.between(0,59),-30),0.6,true)
		if g.boss_death_remaining_seconds==0 and g.death_remaining_seconds==0:
			g._complete_stage()
			return
	if g.death_remaining_seconds>0:
		var previous: float = g.death_remaining_seconds
		g.death_remaining_seconds = maxf(0,g.death_remaining_seconds-g.delta_seconds)
		if g.death_remaining_seconds<0.000001: g.death_remaining_seconds = 0
		if g.death_remaining_seconds>0 and int(ceil(previous/0.3))!=int(ceil(g.death_remaining_seconds/0.3)):
			g._explosion(g.player+Vector2(20-Rng.between(0,39),-10),0.6,true)
		if g.death_remaining_seconds==0:
			g._return_title()
			g.score = 0

static func begin_boss_death(g: Node) -> void:
	if g.boss_defeated: return
	g.boss_defeated = true
	g.score += Rules.score(int(Catalog.for_actor(g.boss).id),g.title.difficulty)
	g._save_score()
	g.boss_death_remaining_seconds = 7.2
	g.scroll_target = 133.33333333333334
	if g.death_remaining_seconds==0: g.state = "boss_dying"

static func complete_stage(g: Node) -> void:
	g._stop_music()
	g._save_score()
	var image: String = "loading2" if Rng.between(0,1)==0 else "loading3"
	if g.stage<4:
		g.loading_image = image
		g.loading_target = g.stage+1
		g.loading_preserve = true
		g.loading_remaining_seconds = 0
		g.state = "loading"
	else:
		g._return_title()
		g.score = 0
