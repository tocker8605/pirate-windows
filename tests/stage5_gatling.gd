extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Motion=preload("res://scripts/entity_pose_motion.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Formation=preload("res://scripts/projectile_formation.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Pool=preload("res://scripts/bullet_pool.gd")
const Game=preload("res://scripts/game.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var left: Dictionary=Catalog.create(141,Vector2(168,107))
	var right: Dictionary=Catalog.create(142,Vector2(232,107))
	var a: Dictionary=Catalog.definition(141)
	var b: Dictionary=Catalog.definition(142)
	check(absf(Motion.angle(a.pose_curve,0))<0.00001 and absf(Motion.angle(b.pose_curve,0))<0.00001,"both arms start in the existing down90degree orientation")
	for tick in range(1201):
		var time: float=tick/60.0
		var angle: float=Motion.angle(a.pose_curve,time)
		var opposite: float=Motion.angle(b.pose_curve,time)
		check(absf(angle+opposite)<0.000001,"arm rotations remain mirror symmetric")
		check(rad_to_deg(angle)>=-10.00001 and rad_to_deg(angle)<=30.00001,"left arm stays within minus10to30degrees")
		check(absf(Motion.angle(a.pose_curve,time+10)-angle)<0.000001,"arm pose repeats every10seconds")
	check(absf(rad_to_deg(Motion.angle(a.pose_curve,10.0/3))-30)<0.00001 and absf(rad_to_deg(Motion.angle(a.pose_curve,25.0/3))+10)<0.00001,"arm sweep reaches both authored endpoints smoothly")
	for kind in [141,142]:
		var e: Dictionary=Catalog.create(kind,Vector2(168 if kind==141 else 232,107))
		var d: Dictionary=Catalog.definition(kind)
		var bounds: Rect2=Geometry.image_rect(d,Vector2(677,1552))
		var hinge: Vector2=bounds.position+bounds.size*Vector2(d.visual.hinge_uv[0],d.visual.hinge_uv[1])-d.draw_size/2
		check(Fire.advance(e,0.479).is_empty(),"arm waits one complete480ms firing interval")
		var shots: Array=Fire.advance(e,0.001)
		check(shots.size()==6,"each gatling volley has exactly6small pink bullets")
		var angle: float=Motion.angle(d.pose_curve,0.48)
		var local_port:=Vector2(d.fire_channels[0].volley.ports[0][0],d.fire_channels[0].volley.ports[0][1])
		var muzzle: Vector2=e.pos+local_port.rotated(angle)
		var centroid:=Vector2.ZERO
		for shot in shots:
			centroid+=shot.pos/6
			check(shot.kind==5 and absf(shot.pos.distance_to(muzzle)-10)<0.001,"initial hexagon radius is10px and projectile is the existing small pink orb")
			check(shot.velocity.distance_to(Vector2.DOWN.rotated(angle)*200)<0.001,"formation travels at200px/s in the firing-time barrel direction")
			var original: Vector2=shot.pos
			var drift:=Vector2.ZERO
			for frame in range(90):drift+=Formation.advance(shot,1.0/60)
			check(absf((original+drift).distance_to(muzzle)-20)<0.001,"hexagon radius reaches20px after1.5seconds")
			for frame in range(90):drift+=Formation.advance(shot,1.0/60)
			check(absf((original+drift).distance_to(muzzle)-30)<0.001,"hexagon radius reaches30px after3seconds")
			check(Formation.advance(shot,5).length()<0.00001,"formation stops expanding after3seconds")
		check(centroid.distance_to(muzzle)<0.001,"hexagon centroid is the actual barrel muzzle")
		check((Geometry.sprite_transform(e,d,Vector2(677,1552))*hinge).distance_to(e.pos)<0.001,"upper arm hinge remains fixed while the barrel rotates")
		e.hp=0
		check(Fire.advance(e,10).is_empty(),"destroyed arm emits no more bullets")
	var fresh: Dictionary=Catalog.create(141,Vector2(168,107))
	check(Fire.advance(fresh,7.2).size()==90,"15complete hexagonal volleys are retained over7.2seconds")
	var simple: Dictionary={"formation":Formation.state(Formation.profile(10,30,3),Vector2.RIGHT)}
	check(Formation.advance(simple,10).distance_to(Vector2(20,0))<0.001,"coarse step clamps radial expansion at the final30px radius")
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g._load_stage(5);g.events=[];g.supply_director.schedule.clear();g.invulnerability_seconds=999
	g.bullets.clear()
	var actor: Dictionary=Catalog.create(141,Vector2(200,-35))
	var volley: Array=Fire.advance(actor,0.48)
	Pool.group(g,volley)
	check(g.bullets.size()==6 and g.bullets.at(0).has("formation"),"bullet storage preserves independent formation metadata")
	for tick in range(90):g._update_bullets()
	check(g.bullets.size()==6,"all6formation bullets survive the on-screen integration interval")
	var center:=Vector2.ZERO
	for bullet in g.bullets:center+=bullet.pos/6
	for bullet in g.bullets:check(absf(bullet.pos.distance_to(center)-20)<0.002 and absf(bullet.velocity.length()-200)<0.001,"actual game advances the moving hexagon without changing its forward velocity")
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["141"].pose_motion.max_degrees=-20
	check(not Catalog.validate_document(doc).is_empty(),"invalid arm angle range is rejected")
	doc=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	doc.entities["141"].fire_channels[0].volley.expand_seconds=0
	check(not Catalog.validate_document(doc).is_empty(),"zero expansion duration is rejected")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
