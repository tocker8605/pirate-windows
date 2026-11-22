extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Combat=preload("res://scripts/combat.gd")
const Shapes=preload("res://scripts/collision_geometry.gd")
const Rules=preload("res://scripts/enemy_rules.gd")
const Actions=preload("res://scripts/combat_actions.gd")
const Game=preload("res://scripts/game.gd")
const PilotShots=preload("res://scripts/player_projectile_geometry.gd")
class Recorder extends "res://scripts/combat_vfx.gd":
	var centres: Array=[]
	func burst(p: Vector2,_count: int,_color: Color,_force: float = 4.0) -> void:centres.append(p)
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g);await process_frame;g.set_process(false)
	g._load_stage(5);g.events=[];g.boss={};g.enemies.clear();g.shots.clear();g.bullets.clear()
	for kind in [141,142,143,144]:
		var d: Dictionary=Catalog.definition(kind)
		var native:=Vector2(d.sprite_region[2],d.sprite_region[3])
		for angle in [-30,-15,0,15,30]:
			var actor: Dictionary=Catalog.create(kind,Vector2(200,130))
			actor.pose_angle=deg_to_rad(angle)
			var bounds: Array=d.collision.beam_rect
			var local:=Vector2((bounds[0]+bounds[2])/2,(bounds[1]+bounds[3])/2)
			var middle: Vector2=Geometry.world_point(actor,local)
			var origin: Vector2=middle+Vector2(0,180)
			var point: Variant=Combat.beam_contact(origin,actor)
			check(point!=null and is_equal_approx(point.x,origin.x),"part%d beam contact shares the actual laser column at%ddegrees"%[kind,angle])
			var painted_rect: Rect2=Geometry.image_rect(d,native)
			var start: Vector2=painted_rect.position-d.draw_size/2
			var end: Vector2=start+painted_rect.size
			var painted_bounds: Array=[start.x,start.y,end.x,end.y]
			var painted_frame: Transform2D=Geometry.sprite_transform(actor,d,native)
			check(Shapes.point_hits(point+Vector2.UP*0.01,painted_bounds,painted_frame) and not Shapes.point_hits(point+Vector2.DOWN*0.01,painted_bounds,painted_frame),"particle starts on nearest painted edge without gameplay collision padding")
			check(Combat.beam_contact(origin+Vector2(300,0),actor)==null,"missed beam has no phantom contact")
			g.enemies.replace_all([actor]);g.beam_remaining_seconds=1;g.delta_seconds=1.0/60
			g.player=origin-PilotShots.beam_origin(Vector2.ZERO);g.laser_contacts.clear()
			var hp: float=actor.hp
			Actions.apply_beam(g)
			check(g.laser_contacts.size()==1 and g.laser_contacts[0].distance_to(point)<0.0001,"live beam particles use painted intersection in world coordinates")
			check(is_equal_approx(actor.hp,hp-133.33333333333334/60),"contact correction preserves laser damage")
			var expected: Vector2=Geometry.local_frame(actor)*Geometry.image_point(d,Vector2.ZERO,Vector2(0.5,0.5),native)
			check(Rules.destruction_center(actor).distance_to(expected)<0.001,"part destruction centre matches mirrored rotated sprite centre")
			g.explosions.clear();g.laser_contacts.clear();g.enemies.clear()
			actor.hp=0;g._destroy_enemy(actor)
			check(g.explosions.size()==1 and (g.explosions[0].pos+Vector2(25,25)).distance_to(expected)<0.001,"destruction record resolves to painted centre instead of hinge")
			var fx=Recorder.new();g.frame+=1;fx.observe(g)
			check(fx.centres.size()==1 and fx.centres[0].distance_to(expected)<0.001,"explosion particle source matches the corrected destruction record")
	var legacy: Dictionary=Catalog.create(1,Vector2(100,100))
	check(Rules.destruction_center(legacy)==Vector2(125,125),"existing non-hinge destruction anchor remains unchanged")
	check(Combat.beam_contact(Vector2(125,400),legacy)==Vector2(125,140),"existing non-rotating beam effect placement remains unchanged")
	check(Shapes.ray_contact(Vector2(20,30),Vector2.UP,[-20,-10,20,10],Transform2D.IDENTITY)==null,"strict tangent ray still misses")
	check(Shapes.ray_contact(Vector2(0,30),Vector2.UP,[-20,-10,20,10],Transform2D.IDENTITY,15)==null,"finite ray range is preserved")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
