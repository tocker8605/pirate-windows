extends SceneTree
const Scheduler = preload("res://scripts/attack_timer.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Boss = preload("res://scripts/boss.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
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
 var channel_count := 0
 for id in Catalog.ids():
  for channel in Catalog.definition(id).get("fire_channels",[]):
   channel_count += 1
   var owner: Dictionary = {}
   var events: Array = []
   for tick in range(540): events.append_array(Scheduler.advance(owner,[channel],1.0/60,func(_c): return true))
   var coarse: Array = Scheduler.advance({},[channel],9.0,func(_c): return true)
   var same: bool = events.size()==coarse.size()
   if same:
    for i in range(events.size()): same = same and is_equal_approx(events[i].at,coarse[i].at)
   check(same,"entity%d/%s native ticks and9second catchup produce identical event times"%[id,channel.name])
   if not channel.has("window_seconds"):
    check(events.size()==floori(9.0/float(channel.interval_seconds)+0.000001),"entity%d/%s maintains configured rate across all former wrap boundaries"%[id,channel.name])
    var uniform := true
    for i in range(1,events.size()): uniform = uniform and is_equal_approx(events[i].at-events[i-1].at,float(channel.interval_seconds))
    check(uniform,"entity%d/%s has constant event spacing"%[id,channel.name])
   else:
    var expected: int = {111:49,112:8,121:6,122:9}[id]
    check(events.size()==expected and events.all(func(e): return Scheduler.in_window(channel,e.at)),"entity%d preserves intentional local burst/rest windows without banking shots"%id)
 check(channel_count==41,"all41migrated attack channels are audited")
 var a: Dictionary = Catalog.create(1,Vector2(100,100))
 var b: Dictionary = Catalog.create(1,Vector2(100,100))
 var player := Vector2(175,380)
 check(Fire.advance(a,0.35,player).is_empty() and Fire.advance(b,0.1,player).is_empty(),"new actors each wait their own first interval")
 check(Fire.advance(a,0.01,player).size()==1 and Fire.advance(b,0.01,player).is_empty(),"one actor firing cannot advance another actor clock")
 a.velocity.y = 4
 check(Fire.advance(a,5,player).is_empty(),"disabled movement gate emits no queued attacks")
 a.velocity.y = 0
 check(Fire.advance(a,0.35,player).is_empty() and Fire.advance(a,0.01,player).size()==1,"reactivated gate waits one complete interval without a burst")
 a.hp = 0
 check(Fire.advance(a,10,player).is_empty(),"destroyed actors cannot fire")
 var body: Dictionary = Catalog.create(92,Vector2(200,100))
 var parts: Array = [Catalog.create(111,Vector2.ZERO)]
 check(Boss.advance(body,parts,10).is_empty(),"stage2 body does not bank attacks while any part survives")
 Rng.state = 0x50000
 check(Boss.advance(body,[],0.089).is_empty() and Rng.state==0x50000,"stage2 enrage waits90ms without consuming RNG")
 var shots: Array = Boss.advance(body,[],0.001)
 check(shots.size()==2 and shots.all(func(s): return s.kind==5),"stage2 emits simultaneous pink orb pair exactly at90ms")
 check(shots[0].pos==Vector2(215,160) and shots[1].pos==Vector2(185,160),"stage2 retains both original muzzle positions")
 var total := 0
 body = Catalog.create(92,Vector2(200,100))
 for tick in range(540): total += Boss.advance(body,[],1.0/60).size()
 check(total==200,"stage2 has exactly100paired volleys over9seconds without wrap gaps")
 check(Boss.advance(Catalog.create(92,Vector2(200,100)),[],0.27).size()==6,"large stage2 time step retains all three due volleys")
 body = Catalog.create(93,Vector2(200,100))
 shots = Boss.advance(body,[],9,player)
 check(shots.filter(func(s): return s.kind==6).size()==240 and shots.filter(func(s): return s.kind==2).size()==36,"stage3 independent300ms fan and480ms missile channels retain both rates")
 var window_channel: Dictionary = Catalog.definition(121).fire_channels[0]
 check(Scheduler.advance({},[window_channel],1.8,func(_c): return true).is_empty(),"left arm rests before its local firing window opens")
 var invalid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 invalid.entities["1"].fire_channels[0].interval_seconds = 0
 check(not Catalog.validate_document(invalid).is_empty(),"invalid zero channel interval rejected")
 invalid = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 invalid.entities["111"].fire_channels[0].window_seconds = [2,1,3]
 check(not Catalog.validate_document(invalid).is_empty(),"invalid rest window rejected")
 var g = Game.new()
 g.automatic = false
 g.mute = true
 root.add_child(g)
 await process_frame
 g.set_process(false)
 g._load_stage(2)
 g.events = []
 g.boss = Catalog.create(92,Vector2(200,100))
 g.enemies.clear()
 g.bullets.clear()
 g.invulnerable = 10000
 for i in range(5): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.bullets.is_empty(),"native stage2 loop emits nothing before90ms")
 g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.bullets.size()==2 and g.bullets.all(func(s): return s.kind==5),"native stage2 sixth tick emits pink orb pair using independent90ms clock")
 var velocity_before: Vector2 = g.bullets.at(0).velocity
 g._update_bullets()
 check(g.bullets.at(0).velocity==velocity_before,"pink orbs have no fireball gravity")
 print("RESULT: %d checks, %d failures"%[checks,failures])
 g.audio.stop_all()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if failures==0 else 1)
