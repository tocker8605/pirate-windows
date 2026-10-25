extends SceneTree
const Game = preload("res://scripts/game.gd")
const Combat = preload("res://scripts/combat.gd")
const Clock = preload("res://scripts/timing.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const FX = preload("res://scripts/world_effects.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func enemy(kind: int, pos: Vector2 = Vector2(100,100), hp: float = 20) -> Dictionary:
	return {"kind":kind,"pos":pos,"hp":hp,"pattern":0,"velocity":Vector2.ZERO}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var clock = Clock.new()
	var moves: Array = []
	var fires: Array = []
	var recoveries: Array = []
	for n in range(1,76):
		var due: Dictionary = clock.begin()
		if due.move: moves.append(n)
		if due.fire: fires.append(n)
		if clock.finish(true): recoveries.append(n)
	check(moves.slice(0,4)==[10,19,28,37],"original first movement update at tick 10, then every 9")
	check(fires.slice(0,4)==[3,5,7,9] and clock.phase==13,"original firing phase increments and wraps at 25")
	check(recoveries.slice(0,4)==[4,8,12,16],"energy recovery is one whole unit every four ticks")
	clock.recovery = 8
	check(not clock.finish(false) and clock.finish(true),"death suspends recovery without losing its counter")
	for kind in [1,21,41,111]:
		var e: Dictionary = enemy(kind)
		var low: int = 85 if kind in [1,111] else (60 if kind==21 else 35)
		var high: int = 135 if kind in [1,111] else (160 if kind==21 else 185)
		check(not Combat.shot_hits(Vector2(low,100),e) and Combat.shot_hits(Vector2(low+1,100),e),"kind %d strict left hit boundary"%kind)
		check(not Combat.shot_hits(Vector2(high,100),e) and Combat.shot_hits(Vector2(high-1,100),e),"kind %d strict right hit boundary"%kind)
		check(not Combat.shot_hits(Vector2(100,75),e) and not Combat.shot_hits(Vector2(100,130),e),"kind %d original point-based Y bounds"%kind)
	check(not Combat.shot_hits(Vector2(100,100),enemy(201)),"closed carrier cannot be shot")
	check(Combat.shot_hits(Vector2(100,100),enemy(19)),"opened carrier can be rescued")
	var boss: Dictionary = {"pos":Vector2(200,100)}
	check(not Combat.shot_hits_boss(Vector2(110,100),boss) and Combat.shot_hits_boss(Vector2(111,100),boss),"boss original asymmetric left point boundary")
	check(not Combat.shot_hits_boss(Vector2(260,100),boss) and Combat.shot_hits_boss(Vector2(259,100),boss),"boss original asymmetric right point boundary")
	for pair in [[1,15],[21,35],[41,55],[131,15]]:
		check(not Combat.beam_hits(Vector2(100,300),enemy(pair[0],Vector2(100+pair[1],100))) and Combat.beam_hits(Vector2(100,300),enemy(pair[0],Vector2(99+pair[1],100))),"kind %d laser uses original top-left X threshold"%pair[0])
	check(not Combat.beam_hits(Vector2(100,300),enemy(201)),"beam cannot destroy an unopened carrier")
	check(not Combat.hurts_player(Vector2(100,100),Vector2(113,120)) and Combat.hurts_player(Vector2(100,100),Vector2(114,120)),"player damage rectangle has strict pixel edges")
	check(not Combat.collects_item(Vector2(100,100),Vector2(95,120)) and Combat.collects_item(Vector2(100,100),Vector2(96,120)),"pickup rectangle has strict pixel edges")
	check(Weapons.vb_integer(2.5000001)==3 and Weapons.vb_integer(2.5)==2,"VB rounding does not treat near-half values as exact ties")
	check(FX.enemy_smoke(enemy(1,Vector2.ZERO,3),0,2).is_empty(),"enemy smoke begins strictly below threshold")
	check(FX.enemy_smoke(enemy(1,Vector2.ZERO,2),0,2).size()==3,"small damaged enemy has three smoke trails")
	check(FX.enemy_smoke(enemy(21,Vector2.ZERO,39),0,2).size()==6,"medium damaged enemy has six smoke trails")
	check(FX.enemy_smoke(enemy(41,Vector2.ZERO,89),0,2).size()==9,"large damaged enemy has nine smoke trails")
	check(FX.player_smoke(Vector2.ZERO,0,2).map(func(x): return x.pos)==[Vector2(0,10),Vector2(0,29),Vector2(0,48)],"player smoke preserves scroll-dependent offsets")
	for pair in [[35,0],[34,3],[20,0],[19,1],[14,2],[8,1],[0,0]]:
		check(FX.explosion({"pos":Vector2.ZERO,"render_ticks":pair[0]},2).size()==pair[1],"original explosion composition at remaining tick %d"%pair[0])
	check(Rules.explosion_ticks(1)==20 and Rules.explosion_ticks(21)==35 and Rules.explosion_ticks(111)==30,"small/medium/boss-part destruction lifetimes")
	check(Rules.drop(enemy(19),false).pos==Vector2(125,115),"carrier drop original position")
	check(Rules.drop(enemy(41),false).pos==Vector2(125,140),"large enemy repair drop original Y+40")
	check(Rules.drop(enemy(22),false).is_empty(),"type 22 does not drop a repair item")
	check(Rules.drop(enemy(111),true).pos==Vector2(125,140),"Boss Rush attachment drops original power item")
	var e: Dictionary = enemy(201,Vector2(100,292),1)
	Rules.carrier(e)
	check(e.kind==201,"carrier stays closed above exact release coordinate")
	e.pos.y = 291
	Rules.carrier(e)
	check(e.kind==19,"carrier opens at original exact Y=291")
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.start_game()
	check(game.player==Vector2(170,300) and game.invulnerable==0,"stage starts at original coordinates without invented invulnerability")
	game.events = []
	game.clock.recovery = 0
	game.energy = 50
	for i in range(3): game._tick(Vector2.ZERO,false,false,false)
	check(game.energy==50,"energy does not recover fractionally between ticks")
	game._tick(Vector2.ZERO,false,false,false)
	check(game.energy==51,"energy recovers exactly on the fourth tick")
	game.energy = 7.1
	game.clock.recovery = 0
	game._tick(Vector2.ZERO,false,true,false)
	check(game.laser_render_ticks==15 and game.energy<0,"original X threshold is energy>7, not energy>=8")
	game.start_game()
	game.events = [[1,61,0,0,0,0]]
	game.frame = 30
	game._read_events()
	check(game.event_cursor==0,"event t=1 does not fire at tick 30")
	game.frame = 31
	game._read_events()
	check(game.event_cursor==1 and game.banner_ticks==80,"event t=1 fires at tick 31 and warning lasts 80 ticks")
	game.enemies = [enemy(1,Vector2(100,100),10),enemy(1,Vector2(100,100),10)]
	game.boss = {"pos":Vector2(100,100),"hp":10.0}
	game.shots = [{"pos":Vector2(110,121),"kind":1,"alive":true,"impact_ticks":-1}]
	game._update_shots()
	check(game.enemies[0].hp==7 and game.enemies[1].hp==7 and game.boss.hp==7,"one original shot can hit overlapping enemies and boss body")
	check(game.shots[0].impact_ticks==9,"overlap still produces one impact lifecycle")
	game.start_game()
	var carrier: Dictionary = enemy(19,Vector2(100,291),0)
	game.enemies = [carrier]
	game._destroy_enemy(carrier)
	check(carrier.kind==201 and carrier.hp==1 and carrier.pattern==1091,"rescued carrier escapes instead of exploding")
	check(game.score==500 and game.explosions.is_empty() and game.items[0].pos==Vector2(125,306),"carrier rescue preserves score/drop without a fake explosion")
	for i in range(4): game._drop_item({"pos":Vector2(i,0),"kind":1})
	check(game.items.size()==3,"three-slot original item ring overwrites oldest slots")
	game.start_game()
	game.events = []
	game.hp = 0
	game.score = 1234
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="dying" and game.death_ticks==239,"death enters original 240-tick sequence")
	var position: Vector2 = game.player
	game._tick(Vector2.ONE,true,true,true)
	check(game.player==position and game.laser==0,"exploding player cannot move/fire/use beam")
	for i in range(238): game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="menu" and game.last_score==1234 and game.score==0,"death returns to original title with last-run score")
	game.start_game()
	game.events = []
	game.hp = 25
	game._debug_controls([KEY_C,KEY_R,KEY_U])
	game._debug_controls([KEY_F6,KEY_F8])
	check(game.debug_enabled and game.hp==100 and game.power==2,"original C+R+U and F6/F8 developer inputs")
	game.clock.phase = 17
	game.clock.movement = 4
	game._load_stage(2,true)
	check(game.clock.phase==17 and game.clock.movement==4,"global original movement/fire counters survive stage loading")
	for sheet in ["enemy_sm","picsmo"]:
		var clipped: Image = game.art.sprite(sheet,Rect2i(-50,0,50,50),Vector2i(-50,50)).get_image()
		check(clipped.get_pixel(0,0).a==0,"GDI out-of-sheet region clips transparently for "+sheet)
	var right: Image = game.art.enemy(8,Vector2(2,0),0).get_image()
	var expected: Image = game.art.sprite("enemy_sm",Rect2i(1800,0,50,50),Vector2i(1800,50)).get_image()
	check(right.get_data()==expected.get_data(),"type 8 right-bank sprite restored to sheet X=1800")
	right = game.art.enemy(7,Vector2(0,1),0).get_image()
	expected = game.art.sprite("enemy_sm",Rect2i(1550,0,50,50),Vector2i(1550,50)).get_image()
	check(right.get_data()==expected.get_data(),"type 7 downward orientation restored to sheet X=1550")
	game.audio.effect.volume_db = -80
	game.audio.sound("get",false)
	game.audio.sound("damage",false)
	check(game.audio.effect.stream.resource_path.ends_with("damage.wav") and game.audio.get_child_count()==2,"sndPlaySound emulation uses one interruptible effect voice")
	check(game.music.stream!=null and not game.music.stream.loop,"MCI music plays once rather than invented infinite looping")
	var old_clouds: Array = [Vector2(10,80),Vector2(230,400)]
	game.clouds = old_clouds.duplicate()
	game.selected_stage = 2
	game._begin_run()
	check(game.state=="loading" and game.loading_image=="loading1" and game.loading_ticks==1,"New Game and Continue use original loading1 artwork before stage entry")
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="loading","initial loading picture lasts for a presented simulation frame")
	game._tick(Vector2.ZERO,false,false,false)
	check(game.state=="playing" and game.stage==2 and game.clouds==old_clouds,"original cloud state also survives New Game and Continue loads")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	game.audio.stop_all()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
