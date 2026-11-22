extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Combat=preload("res://scripts/combat.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Game=preload("res://scripts/game.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in [1,113,91,92,93,94,95]:
		var d: Dictionary=Catalog.definition(kind)
		var offset: float=60 if d.role=="boss" else 40
		var actor: Dictionary=Catalog.create(kind,Vector2(175,-50-offset))
		var origin:=Vector2(actor.pos.x+(d.collision.beam_bounds[0]+d.collision.beam_bounds[1])/2,300)
		var point: Variant=Combat.beam_contact(origin,actor)
		check(point!=null and point.y==-50 and Combat.beam_origin_hits(origin,actor),"entity%d allows contact exactly atYminus50"%kind)
		actor.pos.y-=0.01
		check(Combat.beam_contact(origin,actor)==null and not Combat.beam_origin_hits(origin,actor),"entity%d rejects contact aboveYminus50"%kind)
		actor.pos.y+=0.02
		check(Combat.beam_contact(origin,actor)!=null,"entity%d allows contact below the upper boundary"%kind)
	for kind in [141,142,143,144]:
		for angle in [-15,0,15]:
			var actor: Dictionary=Catalog.create(kind,Vector2(200,0));actor.pose_angle=deg_to_rad(angle)
			var origin:=Vector2(Geometry.sprite_center(actor,Catalog.for_actor(actor)).x,300)
			var initial: Vector2=Combat.beam_contact(origin,actor)
			actor.pos.y+=-49.99-initial.y
			check(Combat.beam_contact(origin,actor)!=null,"rotated part%d allows painted contact inside upper limit"%kind)
			actor.pos.y-=0.02
			check(Combat.beam_contact(origin,actor)==null,"rotated part%d uses actual painted contactY for upper cutoff"%kind)
	var g=Game.new();g.automatic=false;g.mute=true;root.add_child(g);await process_frame;g.set_process(false)
	g._load_stage(1);g.events=[];g.enemies.clear();g.player=Vector2(175,300);g.delta_seconds=0.03
	for kind in [1,95]:
		var is_boss: bool=kind==95
		var actor: Dictionary=Catalog.create(kind,Vector2(175,-110.01 if is_boss else -90.01))
		if is_boss:g.boss=actor;g.enemies.clear()
		else:g.boss={};g.enemies.replace_all([actor])
		var hp: float=actor.hp
		g.beam_remaining_seconds=1;g.laser_contacts.clear();g._apply_beam()
		check(actor.hp==hp and g.laser_contacts.is_empty(),"actual damage and sparks skip out-of-range entity%d"%kind)
		actor.pos.y=-110 if is_boss else -90
		g.beam_remaining_seconds=1;g._apply_beam()
		check(actor.hp<hp and g.laser_contacts.size()==1 and g.laser_contacts[0].y==-50,"actual damage and sparks begin at inclusive boundary for entity%d"%kind)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout;quit(0 if failures==0 else 1)
