extends RefCounted
## Development-only deterministic screenshots. Excluded from normal game flow.
static func run(g: Node) -> void:
	g.automatic = false
	g.mute = true
	if g.preview_mode in ["menu","opening","title","weapons","weapons2","weapons3"]:
		g.title.loading_ticks = 0
		if g.preview_mode!="menu":
			g.title.confirm()
			for i in range(45 if g.preview_mode=="opening" else 94): g.title.tick()
			if g.preview_mode.begins_with("weapons"):
				g.title.confirm()
				g.title.phase = 24 if g.preview_mode=="weapons2" else (25 if g.preview_mode=="weapons3" else 23)
				g.title.preview_clock = 12
	elif g.preview_mode!="menu":
		g._load_stage(g.preview_stage)
		var stills: Dictionary = {"stage-start":0,"stage-start-late":600,"region1":0,"region2":0,"region3":0,"region4":0,"earth-horizon":0,"lunar-entry":0,"connector12":0,"connector23":0,"turn-up":0,"turn-finished":0}
		var preview_ticks: int = stills.get(g.preview_mode,1100)
		if g.preview_mode == "boss":
			for row in g.events:
				if int(row[1]) in [91,92,93,94]: preview_ticks = int(row[0])*30+180
		for i in range(preview_ticks):
			g.invulnerable = 100
			g._tick(Vector2.ZERO if g.preview_mode=="boss" else Vector2(sin(i * 0.013),0),g.preview_mode!="boss",false,false)
		if g.preview_mode in ["region1","region2","region3","region4","earth-horizon","lunar-entry","connector12","connector23"]:
			g.background_y = {"region1":3360,"region2":1920,"region3":960 if g.stage==4 else 480,"region4":480,"earth-horizon":2880,"lunar-entry":800,"connector12":2640,"connector23":1200}[g.preview_mode]
			g.events = []
			g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
		if g.preview_mode in ["turn-up","turn-finished"]:
			g.events = []
			g.enemies.append({"kind":1,"pos":Vector2(80,0),"velocity":Vector2.ZERO,"pattern":1011,"hp":1000.0})
			g.enemies.append({"kind":10,"pos":Vector2(250,0),"velocity":Vector2.ZERO,"pattern":1011,"hp":1000.0})
			for i in range(125 if g.preview_mode=="turn-up" else 150):
				g.invulnerable = 100
				g._tick(Vector2.ZERO,false,false,false)
			for actor in g.enemies:
				print("TURN CHECK: kind=%d vy=%.1f pitch=%.4f"%[actor.kind,actor.velocity.y,g.view.renewal.poses[actor.entity_id].pitch])
		if g.preview_mode == "effects":
			g.start_game()
			g.enemies.replace_all([{"kind":1,"pos":Vector2(170,120),"velocity":Vector2.ZERO,"pattern":1011,"hp":100.0},{"kind":10,"pos":Vector2(170,230),"velocity":Vector2.ZERO,"pattern":1012,"hp":100.0}])
			g._tick(Vector2.ZERO,false,true,true)
			for i in range(6): g._tick(Vector2.ZERO,false,false,false)
			g._bullet(g.shield_center+Vector2(10,-10),Vector2.ZERO)
			g._tick(Vector2.ZERO,false,false,false)
		if g.preview_mode=="entity-stress":
			g._load_stage(4)
			g.events = []
			g.background_y = 2160
			g.scenery_distance = 1200
			g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
			for i in range(60):
				g.enemies.append({"kind":1,"pos":Vector2(5+i%10*39,12+int(i/10)*42),"velocity":Vector2.ZERO,"pattern":0,"hp":10.0})
			for i in range(600):
				g._bullet(Vector2(10+i%30*13,200+int(i/30)*12),Vector2(0,2),1+i%8)
			g._tick(Vector2.ZERO,false,false,false)
			print("RELEASE SCALE: %d enemies, %d bullets"%[g.enemies.size(),g.bullets.size()])
		if g.preview_mode in ["particles","particles2","particles3"]:
			g._load_stage(4)
			g.events = []
			g.weapon = 2 if g.preview_mode=="particles2" else (3 if g.preview_mode=="particles3" else 1)
			g.background_y = 2160
			g.scenery_distance = 1200
			g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
			g.player = Vector2(170,350)
			g.power = 7
			g.enemies.replace_all([{"kind":22,"pos":Vector2(70,110),"velocity":Vector2.ZERO,"pattern":0,"hp":120.0},{"kind":8,"pos":Vector2(290,120),"velocity":Vector2.ZERO,"pattern":0,"hp":35.0}])
			g._explosion(Vector2(80,245),35)
			g._explosion(Vector2(270,230),20)
			for i in range(7):
				g._tick(Vector2.ZERO,true,false,false)
				for k in range(1,9):
					g._bullet(Vector2(35+k*39,130+k*10),Vector2(sin(k),2+k*0.25),k)
			g.shots.append({"pos":Vector2(195,200),"kind":1,"impact_ticks":7,"alive":true})
			g.shield_center = g.player+Vector2(25,3)
			g.shield_render_ticks = 150
			g.shield = 150
			g.view.vfx.burst(Vector2(210,213),18,g.view.vfx.CYAN,3.5)
		if g.preview_mode=="preparation":
			g._load_stage(4)
			g.boss = {"stage":4,"pos":Vector2(200,100),"velocity":Vector2.ZERO,"hp":1500.0,"max_hp":1500.0,"age":0}
			g.enemies.replace_all([{"kind":22,"pos":Vector2(70,240),"velocity":Vector2.ZERO,"pattern":1073,"hp":100.0},{"kind":131,"pos":Vector2(120,165),"velocity":Vector2.ZERO,"pattern":0,"hp":600.0},{"kind":132,"pos":Vector2(230,165),"velocity":Vector2.ZERO,"pattern":0,"hp":600.0}])
		if g.preview_mode=="damage":
			g._load_stage(2)
			g.hp = 25
			g.render_hp = 25
			g.animation = 1
			g.scroll_speed = 2
			g.clouds = [Vector2(-500,-500),Vector2(-500,-500)]
			g.enemies.replace_all([{"kind":1,"pos":Vector2(70,100),"velocity":Vector2(2,1),"hp":2,"pattern":0},{"kind":21,"pos":Vector2(250,170),"velocity":Vector2(-1,0),"hp":20,"pattern":0}])
			g.explosions = [{"pos":Vector2(70,250),"render_pos":Vector2(70,250),"ticks":19,"render_ticks":19},{"pos":Vector2(250,250),"render_pos":Vector2(250,250),"ticks":34,"render_ticks":34}]
		if g.preview_mode=="damage":
			for i in range(6): g._tick(Vector2.ZERO,false,false,false)
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
