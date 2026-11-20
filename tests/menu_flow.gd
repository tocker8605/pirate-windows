extends SceneTree
const Game = preload("res://scripts/game.gd")
const Title = preload("res://scripts/title.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func key(g: Node, code: int, pressed: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	g._unhandled_key_input(event)
func advance_to(title: RefCounted, duration: float, delta: float) -> void:
	var remaining: float = duration
	while remaining>0.000000001:
		var step: float = minf(delta,remaining)
		title.advance(step)
		remaining -= step
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for fps in [30,60,120]:
		var title = Title.new()
		title.reset()
		title.confirm()
		advance_to(title,1.125,1.0/fps)
		check(title.screen==Title.OPENING and title.panel_offset()==120 and is_equal_approx(title.background_scroll(),45),"%dHz keeps the same opening midpoint and camera speed"%fps)
		advance_to(title,1.225,1.0/fps)
		check(title.screen==Title.MAIN and title.panel_offset()==250 and is_equal_approx(title.background_scroll(),94),"%dHz completes the opening in2.35 seconds"%fps)
		advance_to(title,10,1.0/fps)
		check(title.background_scroll()==479,"%dHz stops the camera at the original endpoint"%fps)
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.title.reset()
	key(g,KEY_SPACE)
	g.title.advance(Title.OPENING_DURATION)
	key(g,KEY_SPACE,true,true)
	key(g,KEY_SPACE)
	check(g.title.screen==Title.MAIN,"holding Space across the opening cannot confirm the next screen")
	key(g,KEY_SPACE,false)
	key(g,KEY_ENTER)
	check(g.title.screen==Title.SETTINGS and g.title.settings_selection==0,"released confirm permits exactly one screen transition")
	key(g,KEY_ENTER,true,true)
	key(g,KEY_ENTER,false)
	key(g,KEY_DOWN)
	key(g,KEY_DOWN,true,true)
	g.title.advance(0.1)
	check(g.title.selected_weapon()==1,"a short arrow press selects the first weapon without skipping")
	key(g,KEY_DOWN,false)
	key(g,KEY_DOWN)
	check(g.title.selected_weapon()==2,"a separate arrow press advances one more weapon")
	key(g,KEY_DOWN,false)
	key(g,KEY_DOWN)
	check(g.title.selected_weapon()==3,"third weapon selection does not depend on screen-state arithmetic")
	g.title.clear_input()
	g.title.advance(1)
	check(g.title.selected_weapon()==3 and g.title.navigation_key==0,"focus reset cancels held navigation")
	g.title.reset()
	g.title.block_confirmation_until_release(KEY_SPACE)
	key(g,KEY_SPACE)
	key(g,KEY_ENTER)
	check(g.title.screen==Title.RANKING,"name-confirm handoff waits for the submitting key to be released")
	key(g,KEY_SPACE,false)
	key(g,KEY_ENTER)
	check(g.title.screen==Title.OPENING,"a fresh confirmation opens the title after handoff release")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
