extends SceneTree
const Effects = preload("res://scripts/special_effects.gd")
const Game = preload("res://scripts/game.gd")
var checks: int = 0
var failed: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failed += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var frames: Array = []
	for ticks in range(15,0,-1): frames.append(Effects.beam_frame(ticks))
	check(frames==[0,0,0,1,1,1,2,2,2,2,1,1,0,0,0],"original beam grows and contracts over all 15 ticks")
	check(Effects.beam_frame(0)==-1,"beam ends without an extra frame")
	check(Effects.shield_frame(200)==0,"shield starts with compact deployment frame")
	check(Effects.shield_frame(199)==1 and Effects.shield_frame(198)==1,"shield expands for two ticks")
	check(Effects.shield_frame(197)==3 and Effects.shield_frame(196)==2,"shield alternates original rotating frames")
	check(Effects.shield_frame(51)==3 and Effects.shield_frame(50)==2 and Effects.shield_frame(49)==-1 and Effects.shield_frame(48)==2,"last 50 ticks blink during shield collapse")
	check(Effects.shield_frame(0)==-1,"shield fully disappears on expiry")
	check(not Effects.shield_contains(Vector2(200,200),Vector2(200,200),199) and not Effects.shield_contains(Vector2(200,200),Vector2(200,200),198),"deployment does not intercept before original threshold")
	check(Effects.shield_contains(Vector2(200,200),Vector2(200,200),197),"shield activates interception after deployment")
	check(not Effects.shield_contains(Vector2(200,200),Vector2(158,200),100) and Effects.shield_contains(Vector2(200,200),Vector2(159,200),100),"shield uses original left pixel boundary")
	check(not Effects.shield_contains(Vector2(200,200),Vector2(238,200),100) and Effects.shield_contains(Vector2(200,200),Vector2(237,200),100),"shield uses original right pixel boundary")
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.start_game()
	game._tick(Vector2.ZERO,false,true,true)
	check(game.laser_render_ticks==15 and game.laser==14,"first laser sprite preserved before lifetime decrement")
	check(game.shield_render_ticks==200 and game.shield==199,"first shield sprite preserved before lifetime decrement")
	var center: Vector2 = game.player+Vector2(25,25)
	check(game.shield_center==center-Vector2(0,1),"shield immediately drifts up one original pixel")
	game._tick(Vector2.RIGHT,false,false,false)
	check(game.shield_center==center-Vector2(0,2),"shield retains activation location as ship moves away")
	game._tick(Vector2.ZERO,false,false,false)
	game._bullet(game.shield_center,Vector2(0,0.1))
	var remaining: int = game.shield
	game._update_bullets()
	check(game.bullets.is_empty() and game.shield==remaining-4 and game.shield_contacts.size()==1,"interception spawns original hit sprite and reduces lifetime")
	game.start_game()
	game.enemies.replace_all([{"kind":1,"pos":Vector2(170,120),"velocity":Vector2.ZERO,"pattern":1011,"hp":100.0}])
	game._tick(Vector2.ZERO,false,true,false)
	check(game.laser_contacts==[Vector2(180,145)] and game.enemies.at(0).hp==96,"beam contact keeps original hit artwork anchor")
	for i in range(14): game._tick(Vector2.ZERO,false,false,false)
	check(game.laser==0 and game.laser_render_ticks==1,"last beam sprite is visible on final active tick")
	game._tick(Vector2.ZERO,false,false,false)
	check(game.laser_render_ticks==0 and game.laser_contacts.is_empty(),"beam contacts clear after expiry")
	game.shield = 2
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	game._tick(Vector2.ZERO,false,false,false)
	check(game.shield==0 and game.shield_render_ticks==0,"shield expires without stale visual")
	for i in range(3):
		var image: Image = game.art.sprite("picpil",Rect2i(i*15,0,15,480),Vector2i(45+i*15,0)).get_image()
		check(image.get_width()==15 and image.get_height()==480,"beam frame %d extracts full original sprite"%i)
	for i in range(4):
		var image: Image = game.art.sprite("picshi",Rect2i(i*100,0,100,100),Vector2i(i*100,100)).get_image()
		check(image.get_width()==100 and image.get_pixel(0,0).a==0,"shield frame %d keeps transparent background"%i)
	game.start_game()
	check(game.laser_render_ticks==0 and game.shield_render_ticks==0 and game.shield_contacts.is_empty(),"restart clears special effect snapshots")
	print("RESULT: %d checks, %d failures"%[checks,failed])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failed==0 else 1)
