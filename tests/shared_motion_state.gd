extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Pool=preload("res://scripts/bullet_pool.gd")
const Motion=preload("res://scripts/projectile_motion.gd")
const Pose=preload("res://scripts/entity_pose_motion.gd")
const Store=preload("res://scripts/entity_store.gd")
class Storage extends Node:
	var bullets=Store.new()
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var actor: Dictionary=Catalog.create(141,Vector2(200,100))
	var first: Array=Fire.advance(actor,0.48)
	var second: Array=Fire.advance(actor,0.48)
	var profile: Dictionary=Catalog.fire_channel(141,"gatling").volley.formation_profile
	check(profile.is_read_only(),"formation constants are immutable")
	for shot in first+second:
		check(is_same(shot.formation.profile,profile),"all bullets and subsequent volleys share the catalog profile")
		check(shot.formation.keys().size()==3 and not shot.formation.has("start_radius"),"runtime formation stores only profile reference, age and radial direction")
	var storage=Storage.new()
	Pool.group(storage,first)
	Pool.group(storage,first)
	for shot in storage.bullets:check(is_same(shot.formation.profile,profile),"admission does not deep-copy immutable settings")
	check(not is_same(storage.bullets.at(0).formation,first[0].formation) and not is_same(storage.bullets.at(0).formation,storage.bullets.at(6).formation),"each admitted bullet has independent mutable state even when emitted data is reused")
	Motion.advance(storage.bullets.at(0),0.5)
	check(first[0].formation.age==0 and storage.bullets.at(1).formation.age==0 and storage.bullets.at(6).formation.age==0,"advancing one bullet cannot age source data or siblings")
	check(storage.bullets.at(0).formation.age==0.5,"only the advanced bullet ages")
	storage.bullets.remove(storage.bullets.at(0).entity_id)
	Motion.advance(storage.bullets.at(0),1.5)
	check(storage.bullets.at(0).formation.age==1.5,"removing a formation member does not affect independent growth")
	storage.free()
	for kind in [141,142,143,144]:
		var definition: Dictionary=Catalog.definition(kind)
		var curve: Dictionary=definition.pose_curve
		check(curve.is_read_only(),"prepared pose curve is immutable")
		check(curve.pivot is Vector2,"pose pivot is converted once at catalog loading")
		if curve.type=="swing_range":check(curve.has("centre") and curve.has("amplitude") and curve.has("phase"),"range swing has precomputed constants")
		else:check(curve.has("amplitude_radians"),"simple swing has precomputed radians")
		var e: Dictionary=Catalog.create(kind,Vector2.ZERO)
		for tick in range(60):Pose.advance(e,1.0/60)
		check(is_same(Catalog.definition(kind).pose_curve,curve),"simulation reuses its prepared curve")
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	check(not raw.entities["141"].has("pose_curve") and not raw.entities["141"].fire_channels[0].volley.has("formation_profile"),"compiled runtime data does not leak into authoring JSON")
	print("RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
