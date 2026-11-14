extends SceneTree
const Motion = preload("res://scripts/boss_orb_motion.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok: print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var boss: Dictionary = Catalog.create(93,Vector2(200,50))
 var player := Vector2(175,380)
 for id in [123,124]:
  boss.hp = 1500
  boss.max_hp = 1500
  boss.pos.x = 200
  var e: Dictionary = Catalog.create(id,Vector2(100 if id==123 else 250,-50))
  var centre_x: float = 100 if id==123 else 300
  var follow_x: float = 165 if id==123 else 235
  check(e.hp==400 and e.max_hp==400,"orb%d starts with400HP"%id)
  Motion.prepare(e,boss)
  check(not e.orb_stationary and e.orb_target==Vector2(centre_x-25,75),"orb%d initial target centres sprite at(%s,100)"%[id,centre_x])
  check(Fire.advance(e,2,player,boss).is_empty(),"orb%d entry travel never fires or banks shots"%id)
  Motion.advance(e,1000)
  check(e.pos==Vector2(centre_x-25,75) and e.orb_stationary and e.velocity==Vector2.ZERO,"orb%d stops exactly at upper station without overshoot"%id)
  check(Fire.advance(e,0.299,player,boss).is_empty() and Fire.advance(e,0.001,player,boss).size()==4,"orb%d waits300ms after upper arrival then emits complete cross"%id)
  var rotation: float = e.radial_angle
  Fire.advance(e,0.15,player,boss)
  boss.hp = 750.01
  Motion.prepare(e,boss)
  check(e.orb_stationary and e.pos.y==75 and not e.get("orb_lowered",false),"orb%d above50percent bossHP remains at upper station"%id)
  boss.hp = 750
  Motion.prepare(e,boss)
  check(not e.orb_stationary and e.orb_target==Vector2(follow_x-25,215) and e.velocity.y>0,"orb%d at50percent immediately starts lower transfer"%id)
  check(Fire.advance(e,0.01,player,boss).is_empty() and e.fire_timers.rotating_cross==0,"orb%d lower transition clears partial firing interval before emission"%id)
  Motion.advance(e,14)
  check(e.pos.y==145 and not e.orb_y_stationary and e.pos.x==centre_x-25+(14 if id==123 else -14),"orb%d lower transfer keeps originalYspeed and slower independentXspeed"%id)
  check(Fire.advance(e,1,player,boss).is_empty() and e.radial_angle==rotation,"orb%d transfer pauses fire and preserves last rotation angle"%id)
  Motion.advance(e,1000)
  check(e.pos==Vector2(follow_x-25,215) and e.velocity==Vector2.ZERO and e.orb_stationary,"orb%d lower station centres sprite at(%s,240)"%[id,follow_x])
  check(Fire.advance(e,0.299,player,boss).is_empty() and Fire.advance(e,0.001,player,boss).size()==4,"orb%d lower arrival starts a fresh300ms interval"%id)
  boss.hp = 1500
  Motion.prepare(e,boss)
  check(e.orb_stationary and e.orb_target.y==215,"orb%d lower phase remains latched after debug healing"%id)
  var a: Dictionary = Catalog.create(id,Vector2(100,-50))
  var b: Dictionary = Catalog.create(id,Vector2(100,-50))
  Motion.prepare(a,boss)
  Motion.prepare(b,boss)
  Motion.advance(a,2.0/Clock.AUTHORED_TICK_SECONDS)
  for i in range(120):
   Motion.prepare(b,boss)
   Motion.advance(b,Clock.units_per_tick())
  check(a.pos==b.pos and a.orb_stationary and b.orb_stationary,"orb%d one large step matches120native ticks"%id)
  var entering: Dictionary = Catalog.create(id,Vector2(100,-50))
  Motion.prepare(entering,boss)
  Motion.advance(entering,1)
  boss.hp = 749
  Motion.prepare(entering,boss)
  check(entering.orb_target.y==215 and Fire.advance(entering,1,player,boss).is_empty(),"orb%d early threshold crossing redirects entry without firing"%id)
  var weak_orb: Dictionary = Catalog.create(id,Vector2(centre_x-25,75))
  weak_orb.hp = 1
  boss.hp = 1500
  Motion.prepare(weak_orb,boss)
  check(weak_orb.orb_stationary and weak_orb.orb_target.y==75,"orb%d own lowHP cannot trigger body-health phase"%id)
  boss.hp = 750
  boss.pos.x = 200
  var follower: Dictionary = Catalog.create(id,Vector2(centre_x-25,215))
  Motion.prepare(follower,boss)
  check(follower.orb_y_stationary and not follower.orb_stationary and follower.orb_target==Vector2(follow_x-25,215),"orb%d lower target is bodyXplus/minus35 whileYremains240"%id)
  check(absf(follower.velocity.x)==1 and follower.velocity.y==0,"orb%d Xfollow is33.33pixels/second with noYdrift"%id)
  check(Fire.advance(follower,0.3,player,boss).size()==4,"orb%d fires whileXmoves andYisfixed"%id)
  var original: Vector2 = follower.pos
  Motion.advance(follower,1)
  check(follower.pos==original+Vector2(1 if id==123 else -1,0),"orb%d Xchase step is bounded rather than snapping to boss"%id)
  check(Fire.advance(follower,0.3,player,boss).size()==4,"orb%d horizontal tracking cannot reset300ms cadence"%id)
  boss.pos.x = 260
  Motion.prepare(follower,boss)
  check(follower.orb_target==Vector2(follow_x+60-25,215),"orb%d follows changes in actual bossX"%id)
  Motion.advance(follower,1000)
  check(follower.pos==follower.orb_target and follower.velocity==Vector2.ZERO,"orb%d catches a stopped boss without overshooting offset"%id)
  boss.pos.x = 100
  Motion.prepare(follower,boss)
  original = follower.pos
  Motion.advance(follower,1)
  check(follower.pos==original-Vector2(1,0) and follower.pos.y==215,"orb%d reversesXslowly when boss changes direction"%id)
 var scaled: Dictionary = Catalog.create(123,Vector2(75,75))
 Motion.prepare(scaled,{"hp":1500.01,"max_hp":3000})
 check(scaled.orb_target.y==75,"threshold uses actual maxHP and keeps above half upper")
 Motion.prepare(scaled,{"hp":1500,"max_hp":3000})
 check(scaled.orb_target.y==215,"inclusive threshold scales with actual maxHP instead of hardcoded750")
 var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 doc.entities["123"].motion.lower_below_ratio = 1.1
 check(not Catalog.validate_document(doc).is_empty(),"invalid health-phase ratio rejected")
 doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 doc.entities["124"].motion.lower_center = [300]
 check(not Catalog.validate_document(doc).is_empty(),"invalid station centre rejected")
 doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 doc.entities["123"].motion.lower_follow.speed = 0
 check(not Catalog.validate_document(doc).is_empty(),"zero follow speed rejected")
 doc = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 doc.entities["124"].motion.lower_follow.x_offset = "invalid"
 check(not Catalog.validate_document(doc).is_empty(),"nonnumeric follow offset rejected")
 var horizontal: Dictionary = Catalog.create(123,Vector2(0,75))
 Motion.prepare(horizontal,{"hp":1500,"max_hp":1500,"pos":Vector2(200,50)})
 check(horizontal.orb_y_stationary and Fire.advance(horizontal,0.3,player).size()==4,"onlyYmotion controls firing even during upper-rowXalignment")
 var g = Game.new()
 g.automatic = false
 g.mute = true
 root.add_child(g)
 await process_frame
 g.set_process(false)
 g._load_stage(3)
 g.events = []
 g.enemies.clear()
 g.boss = Catalog.create(93,Vector2(200,50))
 for id in [123,124]: g.enemies.append(Catalog.create(id,Vector2(100 if id==123 else 250,-50)))
 g.invulnerable = 10000
 for i in range(120): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.enemies.all(func(e): return e.orb_stationary and e.pos==Vector2(75 if e.kind==123 else 275,75)),"actual game places and holds both upper stations")
 check(g.bullets.any(func(b): return b.kind==3),"stationary upper orbs emit long orange crosses")
 g.boss.hp = 750.01
 g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.enemies.all(func(e): return e.orb_stationary and e.pos.y==75),"actual game above half threshold does not move orbs")
 g.boss.hp = 750
 g.bullets.clear()
 g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.enemies.all(func(e): return not e.orb_stationary and e.velocity.y>0 and e.fire_timers.rotating_cross==0),"actual game closes fire gate before first lower-transfer movement")
 var travel_quiet := true
 for i in range(120):
  g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
  travel_quiet = travel_quiet and not g.bullets.any(func(b): return b.kind==3)
  if g.enemies.all(func(e): return e.orb_y_stationary): break
 check(travel_quiet and g.enemies.all(func(e): return e.orb_y_stationary and e.pos.y==215),"both Ytransfers remain silent until row240arrival")
 for i in range(17): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(not g.bullets.any(func(b): return b.kind==3),"native lower arrival waits17ticks before300ms")
 g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.bullets.snapshot().filter(func(b): return b.kind==3).size()==8,"18thnative tick after lower arrival emits both complete crosses")
 check(g.enemies.any(func(e): return not e.orb_stationary and e.velocity.x!=0) and g.enemies.all(func(e): return e.velocity.y==0),"native lower orbs fire complete crosses while still followingXinmotion")
 print("RESULT: %d checks, %d failures"%[checks,failures])
 g.audio.stop_all()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if failures==0 else 1)
