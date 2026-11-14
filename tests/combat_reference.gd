extends SceneTree
const Fire = preload("res://tests/fixtures/fire_probe.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const Game = preload("res://scripts/game.gd")
var checks: int = 0
var failed: int = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition: print("PASS: "+description)
	else:
		failed += 1
		push_error("FAIL: "+description)

func enemy(kind: int, pos: Vector2, velocity: Vector2 = Vector2.ZERO) -> Dictionary:
	return {"kind":kind,"pos":pos,"velocity":velocity/0.03,"pattern":1011,"hp":100.0}

func near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b)<0.0001

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var b: Array = []
	var player := Vector2(170,380)
	# Golden values calculated directly from frmtmrs.frm ewcontrol, not from port helpers.
	var a: Array = Fire.burst(enemy(1,Vector2(100,100)),player,6,0)
	check(a.size()==1 and a[0].pos==Vector2(125,120),"type 1 keeps original top-left muzzle anchor")
	check(near(a[0].velocity,(Vector2(1.59090909,6.36363636))/0.03),"type 1 original floor(sqrt(dx²+(dy+20)²)) aim")
	check(Fire.burst(enemy(1,Vector2(100,100),Vector2(0,4)),player,6,0).is_empty(),"type 1 upward/downward velocity firing gate")
	check(Fire.burst(enemy(1,Vector2(100,100)),player,5,0).is_empty(),"original global firing phase gate")
	a = Fire.burst(enemy(2,Vector2(100,100),Vector2(-6,2)),player,3,0)
	check(a.size()==1 and a[0].velocity.distance_to((Vector2(6,5))/0.03)<0.001,"type 2 horizontal motion reverses shot X direction")
	a = Fire.burst(enemy(2,Vector2(100,100),Vector2(0,0)),player,6,0)
	check(a.size()==1 and a[0].kind==3 and near(a[0].velocity,(Vector2(630,2520)/308.0)/0.03),"type2 stationary long projectile aims toward player while retaining kind3")
	a = Fire.burst(enemy(2,Vector2(100,100)),Vector2(50,30),6,0)
	check(a.size()==1 and near(a[0].velocity,(Vector2(-450,-630)/70.0)/0.03),"type2 can aim upward-left at a player above it")
	check(Fire.burst(enemy(2,Vector2(100,100),Vector2(0,-1)),player,6,0).is_empty(),"type2 retains its vertical movement firing gate")
	check(Fire.burst(enemy(2,Vector2(100,100)),player,5,0).is_empty(),"type2 retains its original phase6 shot cadence")
	check(Fire.burst(enemy(3,Vector2(100,20)),player,2,0).is_empty(),"type 3 lower Y boundary is strict")
	a = Fire.burst(enemy(3,Vector2(100,21)),player,2,0)
	check(a.size()==1 and a[0].pos==Vector2(125,51) and near(a[0].velocity,(Vector2(3,8))/0.03),"type 3 Y=21 pixel modulo direction")
	a = Fire.burst(enemy(3,Vector2(100,41)),player,2,0)
	check(near(a[0].velocity,(Vector2(-10.0/3,8))/0.03),"type 3 Y=41 wraps modulo, not a sine wave")
	check(Fire.burst(enemy(3,Vector2(100,199)),player,2,0).is_empty(),"type 3 upper Y boundary is strict")
	check(Fire.burst(enemy(5,Vector2(175,25)),player,2,0).is_empty(),"type5 no longer fires via legacy phase/Y modulo rules")
	a = Fire.burst(enemy(6,Vector2(100,100),Vector2(2,3)),player,4,0)
	check(a.size()==2 and a[0].pos==Vector2(105,130) and a[1].pos==Vector2(135,130) and a[0].velocity.distance_to((Vector2(-2,7))/0.03)<0.001,"type 6 two original muzzle locations and motion-linked velocity")
	a = Fire.burst(enemy(6,Vector2(100,100),Vector2(0,-1)),player,4,0)
	check(a.size()==2 and near(a[0].velocity,(Vector2(630.0/308,2520.0/308))/0.03),"type 6 rising aircraft switches to aimed fire")
	check(Fire.burst(enemy(6,Vector2(100,100),Vector2(1,-1)),player,4,0).is_empty(),"type 6 rising horizontal motion suppresses firing")
	a = Fire.burst(enemy(7,Vector2(100,100)),player,9,0)
	check(a.size()==3 and near(a[1].velocity,(Vector2(490.0/308-2,1960.0/308))/0.03) and near(a[2].velocity,(Vector2(490.0/308+2,1960.0/308))/0.03),"type 7 three-shot spread restored")
	a = Fire.burst(enemy(8,Vector2(100,100),Vector2(0,6)),player,3,0)
	check(a.is_empty(),"type8 descent twins no longer use the legacy phase3 fire gate")
	a = Fire.burst(enemy(8,Vector2(100,100)),player,10,0)
	check(a.size()==1 and a[0].pos==Vector2(125,130) and a[0].velocity.distance_to((Vector2(0,-1))/0.03)<0.001,"type 8 missile launch coordinate")
	a = Fire.burst(enemy(10,Vector2(100,100),Vector2(0,2)),player,6,0)
	check(a.size()==2 and a[0].pos==Vector2(110,140) and a[1].pos==Vector2(140,140),"type 10 double muzzles use original XY offsets")
	a = Fire.burst(enemy(11,Vector2(100,100),Vector2(3,0)),player,7,0)
	check(a.size()==2 and a[0].velocity.distance_to((Vector2(-1.5,9))/0.03)<0.001 and a[1].velocity.distance_to((Vector2(-1,6))/0.03)<0.001,"type 11 preserves fractional horizontal speeds")
	a = Fire.burst(enemy(21,Vector2(100,100)),player,12,0)
	check(a.size()==3 and a[0].velocity.distance_to((Vector2(-1,-1))/0.03)<0.001 and a[1].velocity.distance_to((Vector2(1,-1))/0.03)<0.001,"type 21 original dual missiles plus aimed bullet")
	check(Fire.burst(enemy(22,Vector2(100,100)),player,2,0).is_empty(),"type 22 Y=100 firing boundary")
	a = Fire.burst(enemy(22,Vector2(100,101)),player,2,0)
	check(a.size()==2 and near(a[0].velocity,(Vector2(630.0/307,2511.0/307))/0.03),"type 22 pixel modulo adjustment at Y=101")
	check(Fire.burst(enemy(22,Vector2(100,150)),player,2,0).is_empty(),"type 22 Y=150 firing boundary")
	a = Fire.burst(enemy(41,Vector2(100,100)),player,3,1)
	b = Fire.burst(enemy(41,Vector2(100,100)),player,3,2)
	check(a.size()==2 and b.size()==2 and a[0].pos==Vector2(80,140) and a[1].pos==Vector2(170,140) and a==b,"type41 both aimed cannons fire together independently of the old side timer")
	check(Fire.burst(enemy(41,Vector2(100,100)),player,2,0).is_empty(),"type41 aimed cannon cadence remains phase3")
	a = Fire.burst(enemy(41,Vector2(100,100)),player,12,0)
	check(a.size()==3 and a[0].kind==6 and a[1].kind==6 and a[2].kind==2,"type41 missile volley retains two simultaneous aimed cannon shots")
	a = Fire.burst(enemy(101,Vector2(100,391)),player,1,0)
	check(a.size()==1 and a[0].pos==Vector2(125,411) and is_equal_approx(a[0].velocity.y,(-10/0.03)+absf(a[0].velocity.x)),"wing shots couple random X to original Y velocity")
	check(Fire.burst(enemy(101,Vector2(100,390)),player,1,0).is_empty(),"wing firing threshold is strictly Y>390")
	check(Fire.aim(Vector2(100,100),Vector2(100,80),7)==Vector2.ZERO,"zero denominator handled without a crash")
	# Original shot anchors, power-specific layout and image lifecycle.
	a = Weapons.volley(player,1,3)
	check(a.size()==2 and a[0].pos==Vector2(165,383) and a[0].kind==1 and a[1].pos==Vector2(195,383) and a[1].kind==1,"weapon1 power3 uses a wider parallel pair")
	a = Weapons.volley(player,2,7)
	check(a.size()==4 and a[0].pos==Vector2(175,382) and a[3].pos==Vector2(195,385),"straight power 7 original staggered anchors")
	a = Weapons.volley(player,1,1)
	Weapons.advance(a[0],player,0.03)
	var visual: Dictionary = Weapons.visual(a[0],player)
	check(a[0].pos==Vector2(181,361) and visual.phase=="launch" and visual.rect==Rect2i(40,0,40,30) and visual.offset==Vector2(-5,0),"first firing tick uses original 40x30 launch sprite")
	Weapons.advance(a[0],player,0.03)
	visual = Weapons.visual(a[0],player)
	check(visual.phase=="flight" and visual.rect==Rect2i(10,0,20,30) and visual.offset==Vector2(5,0),"second tick switches to original 20x30 flight sprite")
	var shot: Dictionary = {"pos":Vector2(181,200),"impact_remaining_seconds":0.27}
	check(Weapons.visual(shot,player).rect==Rect2i(0,60,80,30),"impact first three ticks use sheet row 60")
	shot.impact_remaining_seconds = 0.18
	check(Weapons.visual(shot,player).rect==Rect2i(0,120,80,30),"impact middle three ticks use sheet row 120")
	shot.impact_remaining_seconds = 0.09
	check(Weapons.visual(shot,player).rect==Rect2i(0,180,80,30),"impact last three ticks use sheet row 180")
	shot = {"pos":Vector2(190,350),"kind":4}
	Weapons.advance(shot,player,0.03)
	check(near(shot.pos,Vector2(190,338.75)),"accelerating weapon keeps X fixed and retains player-Y-based speed")
	check(Weapons.vb_integer(2.5)==2 and Weapons.vb_integer(3.5)==4 and Weapons.vb_integer(-1.5)==-2,"VB6 ties-to-even pixel assignment")
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.start_game()
	game.delta_seconds = 0.03
	game.enemies.replace_all([enemy(1,Vector2(100,100))])
	game.shots.replace_all([{"pos":Vector2(110,140),"kind":1,"alive":true,"impact_remaining_seconds":-1}])
	game._update_shots()
	check(game.enemies.at(0).hp==97 and game.shots.size()==1 and game.shots.at(0).impact_remaining_seconds==0.27,"collision retains shot for impact animation")
	var rows: Array = []
	for i in range(9):
		game._update_shots()
		rows.append(game.shots.at(0).visual.rect.position.y)
	check(rows==[60,60,60,120,120,120,180,180,180],"all nine impact frames are displayed in original order")
	check(game.enemies.at(0).hp==97,"impact sprite cannot damage the enemy a second time")
	game._update_shots()
	check(game.shots.is_empty(),"spent impact returns projectile slot")
	game.bullets.clear()
	game._bullet(Vector2(100,100),(Vector2(0,-1))/0.03,2)
	game._update_bullets()
	check(is_equal_approx(game.bullets.at(0).velocity.y,(-0.7/0.03)) and is_equal_approx(game.bullets.at(0).pos.y,99.3),"missile acceleration +0.3 and integer Y restored")
	game.bullets.clear()
	game._bullet(Vector2(100,100),(Vector2(0,-1))/0.03,8)
	game._update_bullets()
	check(is_equal_approx(game.bullets.at(0).velocity.y,(-0.8/0.03)),"type 8 acceleration +0.2 restored")
	print("RESULT: %d checks, %d failures" % [checks,failed])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	# Allow the freed audio player to leave the asynchronous mixer.
	await create_timer(0.2).timeout
	quit(0 if failed==0 else 1)
