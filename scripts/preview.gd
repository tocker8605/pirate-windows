extends RefCounted
## Development-only deterministic screenshots. Excluded from normal game flow.
static func run(g: Node) -> void:
	g.automatic = false
	g.mute = true
	if g.preview_mode in ["menu","opening","title","weapons"]:
		g.title.loading_ticks = 0
		if g.preview_mode!="menu":
			g.title.confirm()
			for i in range(45 if g.preview_mode=="opening" else 94): g.title.tick()
			if g.preview_mode=="weapons": g.title.confirm()
	elif g.preview_mode!="menu":
		g._load_stage(g.preview_stage)
		var preview_ticks: int = {"stage-start":0,"stage-start-late":600}.get(g.preview_mode,1100)
		if g.preview_mode == "boss":
			for row in g.events:
				if int(row[1]) in [91,92,93,94]: preview_ticks = int(row[0])*30+180
		for i in range(preview_ticks):
			g.invulnerable = 100
			g._tick(Vector2.ZERO if g.preview_mode=="boss" else Vector2(sin(i * 0.013),0),g.preview_mode!="boss",false,false)
		if g.preview_mode == "effects":
			g.start_game()
			g.enemies = [{"kind":1,"pos":Vector2(170,120),"velocity":Vector2.ZERO,"pattern":1011,"hp":100.0},{"kind":10,"pos":Vector2(170,230),"velocity":Vector2.ZERO,"pattern":1012,"hp":100.0}]
			g._tick(Vector2.ZERO,false,true,true)
			for i in range(6): g._tick(Vector2.ZERO,false,false,false)
			g._bullet(g.shield_center+Vector2(10,-10),Vector2.ZERO)
			g._tick(Vector2.ZERO,false,false,false)
		if g.preview_mode=="preparation":
			g._load_stage(4)
			g.boss = {"stage":4,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0,"max_hp":1500.0,"age":0}
			g.enemies = [{"kind":22,"pos":Vector2(70,240),"velocity":Vector2.ZERO,"pattern":1073,"hp":100.0},{"kind":131,"pos":Vector2(120,165),"velocity":Vector2.ZERO,"pattern":0,"hp":600.0},{"kind":132,"pos":Vector2(230,165),"velocity":Vector2.ZERO,"pattern":0,"hp":600.0}]
		if g.preview_mode=="damage":
			g._load_stage(2)
			g.hp = 25
			g.render_hp = 25
			g.animation = 1
			g.scroll_speed = 2
			g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
			g.enemies = [{"kind":1,"pos":Vector2(70,100),"velocity":Vector2(2,1),"hp":2,"pattern":0},{"kind":21,"pos":Vector2(250,170),"velocity":Vector2(-1,0),"hp":20,"pattern":0}]
			g.explosions = [{"pos":Vector2(70,250),"render_pos":Vector2(70,250),"ticks":19,"render_ticks":19},{"pos":Vector2(250,250),"render_pos":Vector2(250,250),"ticks":34,"render_ticks":34}]
		if g.preview_mode in ["boss-death","gameover","loading"]:
			g._load_stage(4 if g.preview_mode=="boss-death" else 1)
			g.events = []
			if g.preview_mode=="boss-death":
				g.boss = {"stage":4,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":0,"max_hp":1500.0,"age":0}
				g._play_music("boss01")
			else: g.hp = 0
			for i in range(60): g._tick(Vector2.ZERO,false,false,false)
			if g.preview_mode=="loading":
				g.state = "loading"
				g.loading_image = "loading2"
		g.invulnerable = 0
		if g.preview_mode not in ["boss-death","gameover","loading"]: g.state = "playing"
	g._redraw()
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png(g.preview_path)
	g._stop_music()
	await g.get_tree().create_timer(0.15).timeout
	g.get_tree().quit()
