extends SceneTree
const Fire = preload("res://scripts/enemy_fire.gd")
const Core = preload("res://scripts/boss_core_motion.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok: print("PASS: "+message)
 else:
  failures += 1
  push_error("FAIL: "+message)
func settled() -> Dictionary:
 var e: Dictionary = Catalog.create(133,Vector2(175,150))
 e.hp = 199
 Core.detach(e)
 Core.advance(e,1000)
 return e
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var player := Vector2(175,380)
 var e: Dictionary = Catalog.create(133,Vector2(175,150))
 e.hp = 199
 check(Fire.advance(e,0.3,player).is_empty(),"attached core has no radial or travel attack")
 Core.detach(e)
 var moving: Array = Fire.advance(e,0.3,player)
 check(moving.size()==5 and moving.all(func(s): return s.kind==8),"upward/transfer phase retains60ms fireballs without radial shots")
 Core.advance(e,1000)
 check((e.pos+Catalog.definition(133).draw_offset+Catalog.definition(133).draw_size/2)==Vector2(200,240),"core settles at screen centre again")
 var state: int = Rng.state
 check(Fire.advance(e,0.249,player).is_empty(),"arrival starts a fresh250ms radial interval without queued fireballs")
 var a: Array = Fire.advance(e,0.001,player)
 check(a.size()==30,"one radial volley contains30shots")
 check(a.all(func(s): return s.kind==5 and is_equal_approx(s.velocity.length(),7)),"all radial shots are pink spheres with constant speed7")
 check(a.all(func(s): return s.pos==e.pos+Vector2(25,20)),"complete ring shares original core muzzle")
 var regular := true
 for i in range(30): regular = regular and is_equal_approx(angle_difference(a[i].velocity.angle(),a[(i+1)%30].velocity.angle()),deg_to_rad(12))
 check(regular,"full360degree ring including closing gap uses uniform12degree spacing")
 check(a[0].velocity.is_equal_approx(Vector2(0,7)),"initial ring begins downward and covers all quadrants")
 var b: Array = Fire.advance(e,0.25,Vector2.ZERO)
 var rotated := true
 for i in range(30): rotated = rotated and is_equal_approx(angle_difference(a[i].velocity.angle(),b[i].velocity.angle()),deg_to_rad(1))
 check(rotated,"next entire ring rotates clockwise by1degree independently of player aim")
 check(Rng.state==state,"settled radial pattern consumes no random values or old flame attack")
 e = settled()
 var count := 0
 for i in range(600): count += Fire.advance(e,1.0/60,player).size()
 check(count==1200,"ten seconds emits40complete rings at250ms without drift")
 check(is_equal_approx(angle_difference(deg_to_rad(90),e.radial_angle),deg_to_rad(40)),"rotation advances once per volley rather than once per tick or bullet")
 check(Fire.advance(settled(),0.75,player).size()==90,"large time step retains three whole rotated rings")
 e = settled()
 var round_trip: Array = []
 for i in range(361):
  var shots: Array = Fire.advance(e,0.25,player)
  if i==360: round_trip = shots
 check(round_trip[0].velocity.is_equal_approx(Vector2(0,7)),"clockwise rotation wraps cleanly after360volleys")
 e.hp = 0
 check(Fire.advance(e,1,player).is_empty(),"destroyed core cannot fire radial rings")
 e = settled()
 check(Fire.advance(e,0.25,e.pos-Vector2(0,20)).size()==30,"non-aimed ring is not suppressed by legacy player coincidence case")
 var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
 doc.entities["133"].fire_channels[1].spacing_degrees = 13
 check(not Catalog.validate_document(doc).is_empty(),"invalid ring coverage metadata rejected")
 var g = Game.new()
 g.automatic = false
 g.mute = true
 root.add_child(g)
 await process_frame
 g.set_process(false)
 g._load_stage(4)
 g.events = []
 g.enemies.clear()
 g.boss = Catalog.create(94,Vector2(200,80))
 e = Catalog.create(133,Vector2.ZERO)
 e.hp = 199
 g.enemies.append(e)
 g.invulnerable = 10000
 for i in range(360):
  g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
  if e.get("core_phase","")=="settled": break
 check(e.get("core_phase","")=="settled","native game reaches centre before radial activation")
 g.boss = {} # Isolate core's emission from body replacement cannons.
 g.bullets.clear()
 for i in range(14): g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.bullets.is_empty(),"native loop waits14ticks after arrival")
 g._tick(Vector2.ZERO,false,false,false,Clock.units_per_tick())
 check(g.bullets.size()==30 and g.bullets.all(func(s): return s.kind==5),"15thnative tick after arrival emits complete pink ring")
 print("RESULT: %d checks, %d failures"%[checks,failures])
 g.audio.stop_all()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if failures==0 else 1)
