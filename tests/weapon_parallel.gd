extends SceneTree
const Weapons = preload("res://scripts/player_weapons.gd")
const Clock = preload("res://scripts/timing.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void:
	var player := Vector2(100,1000)
	for power in [3,4]:
		var spread: Array = Weapons.volley(player,1,power)
		var straight: Array = Weapons.volley(player,2,power)
		check(spread.size()==2 and spread.all(func(shot): return shot.kind==1),"power%d weapon1 emits two straight projectiles"%power)
		check(spread[1].pos.x-spread[0].pos.x==30 and straight[0].pos.x-straight[1].pos.x==12,"power%d weapon1 pair is wider than weapon2"%power)
		check(spread[0].pos.x+spread[1].pos.x==player.x*2+20,"power%d parallel pair is symmetric about the pilot muzzle centre"%power)
		var first: float = spread[0].pos.x
		for i in range(60):
			for shot in spread: Weapons.advance(shot,player,Clock.FIXED_STEP_SECONDS)
		check(spread[0].pos.x==first and spread[1].pos.x-spread[0].pos.x==30,"power%d pair stays parallel across60 native ticks"%power)
	for power in [5,6,7]:
		var shots: Array = Weapons.volley(player,1,power)
		check(shots.any(func(shot): return shot.kind==2) and shots.any(func(shot): return shot.kind==3),"higher power%d keeps authored spreading projectiles"%power)
	for power in [1,2]: check(Weapons.volley(player,1,power).size()==1,"power%d single-shot layout unchanged"%power)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
