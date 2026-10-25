extends SceneTree
const Game = preload("res://scripts/game.gd")
func _initialize() -> void: call_deferred("run")
func byte(value: float) -> int: return int(round(value*255))
func _rop(dest: Color, source: Color, mask: Color) -> Color:
	return Color(float((byte(mask.r)&(~byte(dest.r)))^byte(source.r))/255.0,float((byte(mask.g)&(~byte(dest.g)))^byte(source.g))/255.0,float((byte(mask.b)&(~byte(dest.b)))^byte(source.b))/255.0,1)
func run() -> void:
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game._load_stage(3)
	game.background_y = 1800
	game.clouds = [Vector2(10,100),Vector2(30,140)]
	game.player = Vector2(340,430)
	game.enemies.clear()
	game.bullets.clear()
	game.shots.clear()
	game.items.clear()
	game.banner_ticks = 0
	game._redraw()
	await RenderingServer.frame_post_draw
	var actual: Image = root.get_texture().get_image()
	var background: Image = game.art.sheet("stage3")
	var atlas: Image = game.art.sheet("cl01")
	var errors: int = 0
	var total: int = 0
	var changed: int = 0
	for y in range(150,390,7):
		for x in range(35,290,7):
			var expected: Color = background.get_pixel(x,y+1800)
			var base: Color = expected
			for cloud in game.clouds:
				var local: Vector2i = Vector2i(Vector2(x,y)-cloud)
				if Rect2i(0,0,300,300).has_point(local):
					expected = _rop(expected,atlas.get_pixelv(local),atlas.get_pixelv(local+Vector2i(300,0)))
			var pixel: Color = actual.get_pixel(x*2+1,y*2+1)
			if expected!=base: changed += 1
			var delta: float = maxf(absf(pixel.r-expected.r),maxf(absf(pixel.g-expected.g),absf(pixel.b-expected.b)))
			if delta>1.1/255.0:
				errors += 1
				if errors<4: print("PIXEL DIFFERENCE ",Vector2(x,y)," actual ",pixel," expected ",expected)
			total += 1
	actual.save_png("res://preview-cloud-rop-v6.png")
	print("GDI CLOUD PIXELS: %d samples, %d nontrivial composited samples, %d mismatches"%[total,changed,errors])
	var failures: int = int(errors>0)+int(changed<20)
	game.score = 1234
	game._return_title()
	game._redraw()
	await RenderingServer.frame_post_draw
	actual = root.get_texture().get_image()
	var digit: Image = game.art.sprite("pichud",Rect2i(40,156,10,20),Vector2i(40,176)).get_image()
	var score_errors: int = 0
	var score_samples: int = 0
	for y in range(20):
		for x in range(10):
			var reference: Color = digit.get_pixel(x,y)
			if reference.a<0.99: continue
			if actual.get_pixel((380+x)*2+1,(5+y)*2+1).is_equal_approx(reference)==false: score_errors += 1
			score_samples += 1
	if score_samples==0 or score_errors>0: failures += 1
	print("TITLE SCORE PIXELS: %d opaque samples, %d mismatches"%[score_samples,score_errors])
	game.start_game()
	game.events = []
	game.hp = 0
	game._tick(Vector2.ZERO,false,false,false)
	game._redraw()
	await RenderingServer.frame_post_draw
	actual = root.get_texture().get_image()
	var over: Image = game.art.sprite("picgov",Rect2i(0,0,200,30),Vector2i(0,30)).get_image()
	var over_errors: int = 0
	var over_samples: int = 0
	for y in range(0,30,2):
		for x in range(0,200,2):
			var reference: Color = over.get_pixel(x,y)
			if reference.a<0.99: continue
			if actual.get_pixel((100+x)*2+1,(230+y)*2+1).is_equal_approx(reference)==false: over_errors += 1
			over_samples += 1
	if over_samples==0 or over_errors>0: failures += 1
	print("GAME OVER PIXELS: %d opaque samples, %d mismatches"%[over_samples,over_errors])
	print("RESULT: 4 checks, %d failures"%failures)
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
