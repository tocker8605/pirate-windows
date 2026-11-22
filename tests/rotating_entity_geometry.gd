extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Motion=preload("res://scripts/entity_pose_motion.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Shapes=preload("res://scripts/collision_geometry.gd")
const Combat=preload("res://scripts/combat.gd")
const Pilot=preload("res://scripts/pilot_geometry.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Game=preload("res://scripts/game.gd")
class SmokeRecorder extends "res://scripts/combat_vfx.gd":
	var sources: Array=[]
	func emit_smoke(pos: Vector2,_size: float) -> void:sources.append(pos)
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in [143,144]:
		var actor: Dictionary=Catalog.create(kind,Vector2(200,200))
		var d: Dictionary=Catalog.definition(kind)
		var side: int=1 if kind==143 else -1
		var uv:=Vector2(d.visual.hinge_uv[0],d.visual.hinge_uv[1])
		var raw_hinge: Vector2=Geometry.image_rect(d,Vector2(1281,1007)).position+Geometry.image_rect(d,Vector2(1281,1007)).size*uv-d.draw_size/2
		for tick in range(361):
			var time: float=tick/60.0
			if tick>0:Motion.advance(actor,1.0/60)
			var expected: float=deg_to_rad(side*15)*(1-cos(TAU*time/6))/2
			check(absf(float(actor.get("pose_angle",0))-expected)<0.000001,"wing pose follows smooth0to15to0in6seconds")
			check((Geometry.sprite_transform(actor,d,Vector2(1281,1007))*raw_hinge).distance_to(actor.pos)<0.001,"painted hinge remains attached during mirror and rotation")
			if tick%90!=0:continue
			var bounds: Array=d.collision.shot_bounds
			for local in [Vector2((bounds[0]+bounds[2])/2,(bounds[1]+bounds[3])/2),Vector2(bounds[0]-2,bounds[1]-2)]:
				var point: Vector2=actor.pos+local.rotated(expected)
				check(Combat.shot_point_hits(point,actor)==Shapes.point_inside(local,bounds),"normal-shot hit rectangle follows the same hinge rotation")
			var contact: Array=d.collision.contact_bounds
			var middle:=Vector2((contact[0]+contact[2])/2,(contact[1]+contact[3])/2)
			check(Combat.touches_player(actor.pos+middle.rotated(expected)-Pilot.COCKPIT,actor),"player hull contact uses the rotated rectangle")
			check(not Combat.touches_player(actor.pos+Vector2(contact[0]-20,contact[1]-20).rotated(expected)-Pilot.COCKPIT,actor),"distant hull contact is rejected after rotation")
			var centre: Vector2=actor.pos+Vector2((bounds[0]+bounds[2])/2,(bounds[1]+bounds[3])/2).rotated(expected)
			check(Combat.beam_origin_hits(centre+Vector2(0,150),actor),"upward laser intersects the actual rotated hull")
			check(not Combat.beam_origin_hits(centre-Vector2(0,150),actor),"laser cannot hit a target behind its origin")
			var fx=SmokeRecorder.new()
			actor.hp=100
			fx.emit_actor_smoke(actor)
			var smoke_offset: Vector2=Catalog.smoke_settings(actor).ports[0]
			check(fx.sources.size()==1 and fx.sources[0].distance_to(actor.pos+smoke_offset.rotated(expected))<0.001,"smoke source rotates with the damaged wing")
		check(absf(float(actor.pose_angle))<0.000001,"wing returns to its original orientation at6seconds")
	# Generic geometry: arbitrary actor anchor, nonzero local pivot and both rotation signs.
	for angle in [0.0,0.2617994,-0.2617994,0.91]:
		var actor: Dictionary={"pos":Vector2(150,100),"pose_pivot":Vector2(8,-6),"pose_angle":angle}
		var frame: Transform2D=Geometry.local_frame(actor)
		var bounds: Array=[-20,-10,20,10]
		check(Geometry.world_point(actor,actor.pose_pivot).distance_to(actor.pos+actor.pose_pivot)<0.0001,"generic local pivot is fixed in world space")
		for point in [Vector2.ZERO,Vector2(19,9),Vector2(21,11)]:
			check(Shapes.point_hits(frame*point,bounds,frame)==Shapes.point_inside(point,bounds),"local inverse tests work for reusable poses")
		check(Shapes.circle_hits(frame*Vector2(22,0),3,bounds,frame) and not Shapes.circle_hits(frame*Vector2(24,0),3,bounds,frame),"circle-to-rotated-rectangle preserves radius")
		check(Shapes.ray_hits(frame*Vector2(0,30),frame.basis_xform(Vector2.UP),bounds,frame),"ray intersection supports any rigid frame")
		check(not Shapes.ray_hits(frame*Vector2(30,30),frame.basis_xform(Vector2.UP),bounds,frame),"ray rejects empty corners of the world bounding box")
		check(not Shapes.ray_hits(frame*Vector2(0,-30),frame.basis_xform(Vector2.UP),bounds,frame),"ray direction matters")
		check(not Shapes.ray_hits(frame*Vector2(0,30),frame.basis_xform(Vector2.UP),bounds,frame,15),"finite ray range is respected")
	# An enclosing world AABB would report these empty rotated corners as hits.
	var tilted:=Transform2D(PI/4,Vector2.ZERO)
	check(not Shapes.point_hits(Vector2(15,-15),[-20,-5,20,5],tilted),"rotated point test rejects empty AABB corners")
	check(not Shapes.circle_hits(Vector2(15,-15),1,[-20,-5,20,5],tilted),"rotated circle test rejects empty AABB corners")
	check(not Shapes.ray_hits(Vector2(15,0),Vector2.UP,[-20,-5,20,5],tilted),"world-vertical laser cannot hit the empty region above a tilted hull")
	check(not Shapes.ray_hits(Vector2(20,30),Vector2.UP,[-20,-10,20,10],Transform2D.IDENTITY),"laser tangent to a strict rectangle edge is excluded")
	# Catchup launch origins sample each event angle, while world-axis velocities remain unchanged.
	var e: Dictionary=Catalog.create(143,Vector2(168,107))
	var channel: Dictionary=Catalog.fire_channel(143,"missiles")
	var shots: Array=Fire.advance(e,3)
	check(shots.size()==25,"3seconds still emits25missiles")
	for i in range(shots.size()):
		var expected_angle: float=deg_to_rad(15)*(1-cos(TAU*(i+1)*0.12/6))/2
		var local:=Vector2(channel.volley.ports[0][0],channel.volley.ports[0][1])
		check(shots[i].pos.distance_to(e.pos+local.rotated(expected_angle))<0.001,"catchup shot uses its firing-time port, not the final frame angle")
		check(shots[i].velocity.x>=-100 and shots[i].velocity.x<=-5 and is_equal_approx(shots[i].velocity.y,-33.333333333333336),"rotation does not alter missile velocity")
	var g=Game.new()
	g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g._load_stage(5)
	g.events=[];g.supply_director.schedule.clear();g.invulnerability_seconds=999
	var wing: Dictionary=Catalog.create(143,Vector2(168,107))
	g.enemies.append(wing)
	for tick in range(180):g._tick(Vector2.ZERO,false,false,false)
	check(absf(float(wing.pose_angle)-deg_to_rad(15))<0.000001,"actual game advances the pose once per frame and reaches15degrees at3seconds")
	var missile={"pos":Vector2(200,200),"velocity":Vector2(-20,-33.333333333333336),"kind":2,"alive":true}
	g.bullets.clear();g.bullets.append(missile)
	g._update_bullets()
	check(is_equal_approx(missile.velocity.x,-20) and is_equal_approx(missile.velocity.y,-33.333333333333336+333.33333333333337/60),"missile retains its existing world-axis acceleration after leaving the rotating wing")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["143"].pose_motion.period_seconds=0
	check(not Catalog.validate_document(doc).is_empty(),"zero pose period is rejected")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
