extends SceneTree
const Geometry=preload("res://scripts/entity_geometry.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Art=preload("res://scripts/renewed_art.gd")
const Classic=preload("res://scripts/art.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func _initialize() -> void:
	var art=Art.new()
	var classic=Classic.new()
	var paths: Dictionary={}
	var legacy_paths: Dictionary={}
	var count: int=0
	for kind in Catalog.ids():
		var definition: Dictionary=Catalog.definition(kind)
		if Geometry.layer(definition)=="floor":continue
		count+=1
		var path: String=definition.sprite_path
		check(not paths.has(path),"entity%d owns an independently replaceable image path"%kind)
		paths[path]=true
		var image: Texture2D=art.enemy_texture(kind)
		check(not image is AtlasTexture and image.resource_path==path and image.get_width()>0,"entity%d loads a whole PNG without a packed-sheet cell index"%kind)
		var old_path: String=definition.classic_sprite.path
		check(not legacy_paths.has(old_path),"classic entity%d has a separate same-entity animation strip"%kind)
		legacy_paths[old_path]=true
		var frame: Texture2D=classic.classic_frame(kind,0)
		check(frame.get_size()==Vector2(definition.classic_sprite.frame_size[0],definition.classic_sprite.frame_size[1]),"classic entity%d retains its original frame dimensions"%kind)
		if definition.role=="enemy" and kind<90:
			check(maxi(image.get_width(),image.get_height())>=832,"regular enemy%d meets ring_rotor's832px source resolution"%kind)
	check(count==35,"all35 non-floor entity definitions use independent modern and classic images")
	check(Catalog.boss_definition(5).hp==2000,"stage5 body and gameplay remain unchanged by sprite separation")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
