extends SceneTree
const Fire = preload("res://scripts/enemy_fire.gd")
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
	return {"kind":kind,"pos":pos,"velocity":velocity,"pattern":1011,"hp":100.0}

func near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b)<0.0001

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var player := Vector2(170,380)
	# Golden values calculated directly from frmtmrs.frm ewcontrol, not from port helpers.
	var a: Array = Fire.burst(enemy(1,Vector2(100,100)),player,6,0)
	check(a.size()==1 and a[0].pos==Vector2(125,120),"type 1 keeps original top-left muzzle anchor")
	check(near(a[0].velocity,Vector2(1.59090909,6.36363636)),"type 1 original floor(sqrt(dx²+(dy+20)²)) aim")
	check(Fire.burst(enemy(1,Vector2(100,100),Vector2(0,4)),player,6,0).is_empty(),"type 1 upward/downward velocity firing gate")
	check(Fire.burst(enemy(1,Vector2(100,100)),player,5,0).is_empty(),"original global firing phase gate")
	a = Fire.burst(enemy(2,Vector2(100,100),Vector2(-6,2)),player,3,0)
	check(a.size()==1 and a[0].velocity==Vector2(6,5),"type 2 horizontal motion reverses shot X direction")
	a = Fire.burst(enemy(2,Vector2(100,100),Vector2(0,0)),player,6,0)
	check(a.size()==1 and a[0].kind==3 and a[0].velocity==Vector2(0,9),"type 2 stationary X changes bullet kind")
	check(Fire.burst(enemy(3,Vector2(100,20)),player,2,0).is_empty(),"type 3 lower Y boundary is strict")
	a = Fire.burst(enemy(3,Vector2(100,21)),player,2,0)
	check(a.size()==1 and a[0].pos==Vector2(120,51) and near(a[0].velocity,Vector2(3,8)),"type 3 Y=21 pixel modulo direction")
	a = Fire.burst(enemy(3,Vector2(100,41)),player,2,0)
	check(near(a[0].velocity,Vector2(-10.0/3,8)),"type 3 Y=41 wraps modulo, not a sine wave")
	check(Fire.burst(enemy(3,Vector2(100,199)),player,2,0).is_empty(),"type 3 upper Y boundary is strict")
	a = Fire.burst(enemy(5,Vector2(175,25)),player,2,0)
	var b: Array = Fire.burst(enemy(5,Vector2(176,25)),player,2,0)
	check(near(a[0].velocity,Vector2(25.0/3,0)) and near(b[0].velocity,Vector2(-25.0/3,0)),"type 5 reverses X at original 175/176 pixel boundary")
	a = Fire.burst(enemy(5,Vector2(175,50)),player,2,0)
	b = Fire.burst(enemy(5,Vector2(175,51)),player,2,0)
	check(a[0].velocity==Vector2(0,-12.5) and b[0].velocity==Vector2(0,12.5),"type 5 Y modulo 51 flips vertical velocity")
	a = Fire.burst(enemy(6,Vector2(100,100),Vector2(2,3)),player,4,0)
	check(a.size()==2 and a[0].pos==Vector2(105,130) and a[1].pos==Vector2(135,130) and a[0].velocity==Vector2(-2,7),"type 6 two original muzzle locations and motion-linked velocity")
	a = Fire.burst(enemy(6,Vector2(100,100),Vector2(0,-1)),player,4,0)
	check(a.size()==2 and near(a[0].velocity,Vector2(630.0/308,2520.0/308)),"type 6 rising aircraft switches to aimed fire")
	check(Fire.burst(enemy(6,Vector2(100,100),Vector2(1,-1)),player,4,0).is_empty(),"type 6 rising horizontal motion suppresses firing")
	a = Fire.burst(enemy(7,Vector2(100,100)),player,9,0)
	check(a.size()==3 and near(a[1].velocity,Vector2(490.0/308-2,1960.0/308)) and near(a[2].velocity,Vector2(490.0/308+2,1960.0/308)),"type 7 three-shot spread restored")
	a = Fire.burst(enemy(8,Vector2(100,100),Vector2(0,6)),player,3,0)
	check(a.size()==2 and a[0].velocity==Vector2(7,5) and a[1].velocity==Vector2(-7,5),"type 8 both velocity-dependent side shots restored")
	a = Fire.burst(enemy(8,Vector2(100,100)),player,10,0)
	check(a.size()==1 and a[0].pos==Vector2(125,130) and a[0].velocity==Vector2(0,-1),"type 8 missile launch coordinate")
	a = Fire.burst(enemy(10,Vector2(100,100),Vector2(0,2)),player,6,0)
	check(a.size()==2 and a[0].pos==Vector2(110,140) and a[1].pos==Vector2(140,140),"type 10 double muzzles use original XY offsets")
	a = Fire.burst(enemy(11,Vector2(100,100),Vector2(3,0)),player,7,0)
	check(a.size()==2 and a[0].velocity==Vector2(-1.5,9) and a[1].velocity==Vector2(-1,6),"type 11 preserves fractional horizontal speeds")
	a = Fire.burst(enemy(21,Vector2(100,100)),player,12,0)
	check(a.size()==3 and a[0].velocity==Vector2(-1,-1) and a[1].velocity==Vector2(1,-1),"type 21 original dual missiles plus aimed bullet")
	check(Fire.burst(enemy(22,Vector2(100,100)),player,2,0).is_empty(),"type 22 Y=100 firing boundary")
	a = Fire.burst(enemy(22,Vector2(100,101)),player,2,0)
	check(a.size()==2 and near(a[0].velocity,Vector2(630.0/307,2511.0/307)),"type 22 pixel modulo adjustment at Y=101")
	check(Fire.burst(enemy(22,Vector2(100,150)),player,2,0).is_empty(),"type 22 Y=150 firing boundary")
	a = Fire.burst(enemy(41,Vector2(100,100)),player,3,1)
	b = Fire.burst(enemy(41,Vector2(100,100)),player,3,2)
	check(a[0].pos==Vector2(170,140) and b[0].pos==Vector2(80,140),"type 41 alternates original left/right muzzle with timer")
	a = Fire.burst(enemy(101,Vector2(100,391)),player,1,0)
	check(a.size()==1 and a[0].pos==Vector2(125,411) and a[0].velocity.y==-10+absf(a[0].velocity.x),"wing shots couple random X to original Y velocity")
	check(Fire.burst(enemy(101,Vector2(100,390)),player,1,0).is_empty(),"wing firing threshold is strictly Y>390")
	check(Fire.aim(Vector2(100,100),Vector2(100,80),7)==Vector2.ZERO,"zero denominator handled without a crash")
	# Original shot anchors, power-specific layout and image lifecycle.
	a = Weapons.volley(player,1,3)
	check(a.size()==2 and a[0].pos==Vector2(177,383) and a[0].kind==2 and a[1].pos==Vector2(183,383) and a[1].kind==3,"spread power 3 restores exact two launch anchors")
	a = Weapons.volley(player,2,7)
	check(a.size()==4 and a[0].pos==Vector2(175,382) and a[3].pos==Vector2(195,385),"straight power 7 original staggered anchors")
	a = Weapons.volley(player,1,1)
	Weapons.advance(a[0],player)
	var visual: Dictionary = Weapons.visual(a[0],player)
	check(a[0].pos==Vector2(181,361) and visual.phase=="launch" and visual.rect==Rect2i(40,0,40,30) and visual.offset==Vector2(-5,0),"first firing tick uses original 40x30 launch sprite")
	Weapons.advance(a[0],player)
	visual = Weapons.visual(a[0],player)
	check(visual.phase=="flight" and visual.rect==Rect2i(10,0,20,30) and visual.offset==Vector2(5,0),"second tick switches to original 20x30 flight sprite")
	var shot: Dictionary = {"pos":Vector2(181,200),"impact_ticks":9}
	check(Weapons.visual(shot,player).rect==Rect2i(0,60,80,30),"impact first three ticks use sheet row 60")
	shot.impact_ticks = 6
	check(Weapons.visual(shot,player).rect==Rect2i(0,120,80,30),"impact middle three ticks use sheet row 120")
	shot.impact_ticks = 3
	check(Weapons.visual(shot,player).rect==Rect2i(0,180,80,30),"impact last three ticks use sheet row 180")
	shot = {"pos":Vector2(190,350),"kind":4}
	Weapons.advance(shot,player)
	check(near(shot.pos,Vector2(190+9.0/14,339)),"scatter weapon uses original player-relative nonlinear trajectory")
	check(Weapons.vb_integer(2.5)==2 and Weapons.vb_integer(3.5)==4 and Weapons.vb_integer(-1.5)==-2,"VB6 ties-to-even pixel assignment")
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.start_game()
	game.enemies = [enemy(1,Vector2(100,100))]
	game.shots = [{"pos":Vector2(110,140),"kind":1,"alive":true,"impact_ticks":-1}]
	game._update_shots()
	check(game.enemies[0].hp==97 and game.shots.size()==1 and game.shots[0].impact_ticks==9,"collision retains shot for impact animation")
	var rows: Array = []
	for i in range(9):
		game._update_shots()
		rows.append(game.shots[0].visual.rect.position.y)
	check(rows==[60,60,60,120,120,120,180,180,180],"all nine impact frames are displayed in original order")
	check(game.enemies[0].hp==97,"impact sprite cannot damage the enemy a second time")
	game._update_shots()
	check(game.shots.is_empty(),"spent impact returns projectile slot")
	game.bullets.clear()
	game._bullet(Vector2(100,100),Vector2(0,-1),2)
	game._update_bullets()
	check(is_equal_approx(game.bullets[0].velocity.y,-0.7) and game.bullets[0].pos.y==99,"missile acceleration +0.3 and integer Y restored")
	game.bullets.clear()
	game._bullet(Vector2(100,100),Vector2(0,-1),8)
	game._update_bullets()
	check(is_equal_approx(game.bullets[0].velocity.y,-0.8),"type 8 acceleration +0.2 restored")
	print("RESULT: %d checks, %d failures" % [checks,failed])
	game._stop_music()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit(0 if failed==0 else 1)
