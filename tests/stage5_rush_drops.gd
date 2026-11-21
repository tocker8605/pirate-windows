extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Rules=preload("res://scripts/enemy_rules.gd")
const Pose=preload("res://scripts/entity_pose_motion.gd")
const Game=preload("res://scripts/game.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in Catalog.ids():
		if Catalog.is_part(kind):
			var e: Dictionary=Catalog.create(kind,Vector2(150,100))
			var item: Dictionary=Rules.drop(e,true)
			check(not item.is_empty() and item.kind==1,"boss part%d drops power in BossRush"%kind)
	for kind in [141,142,143,144,145,146]:
		var e: Dictionary=Catalog.create(kind,Vector2(200,200))
		Pose.advance(e,3)
		var offset: Array=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH)).entities[str(kind)].boss_rush_drop.offset
		var expected: Vector2=e.pos+Vector2(offset[0],offset[1]).rotated(float(e.get("pose_angle",0)))
		check(Rules.drop(e,true).pos.distance_to(expected)<0.001,"drop follows the current pose of part%d"%kind)
		check(Rules.drop(e,false).is_empty(),"normal campaign part%d does not gain an item drop"%kind)
		e.auto_destroyed=true
		check(Rules.drop(e,true).kind==1,"automatic destruction keeps the same drop policy as existing boss parts")
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	for rush in [false,true]:
		g.run_settings=g.run_settings.with_boss_rush(rush)
		g._load_stage(5);g.events=[];g.supply_director.schedule.clear();g.items.clear()
		for kind in [141,142,143,144,145,145,146,146]:
			var e: Dictionary=Catalog.create(kind,Vector2(150,150))
			Pose.advance(e,3);e.hp=0
			g._destroy_enemy(e)
		check(g.items.size()==(8 if rush else 0),"stage5 destruction path drops eight power items only in BossRush")
		check(g.items.all(func(item):return item.kind==1),"all generated rewards use the power-item type")
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
