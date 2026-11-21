extends SceneTree
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Mecha = preload("res://scripts/renewed_art.gd")
const Boss = preload("res://scripts/boss.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void:
	var art = Mecha.new()
	for kind in Catalog.ids():
		var definition: Dictionary=Catalog.definition(kind)
		if definition.role not in ["boss","part"] or not definition.has("sprite_path"):continue
		var texture: Texture2D=art.enemy_texture(kind)
		var source: Texture2D=texture.atlas if texture is AtlasTexture else texture
		var independent: bool=source.resource_path==definition.sprite_path and texture.get_width()>0 and texture.get_height()>0
		if texture is AtlasTexture:independent=independent and definition.has("sprite_region") and texture.region==Rect2(definition.sprite_region[0],definition.sprite_region[1],definition.sprite_region[2],definition.sprite_region[3])
		check(independent,"boss entity%d uses its own PNG with only its declared transparent-border crop"%kind)
		check(maxi(source.get_width(),source.get_height())>=1024,"boss entity%d has native high-resolution artwork comparable to stage5"%kind)
	for pair in [[112,111],[121,122],[131,132]]:
		var symmetric: bool = true
		for vy in [-7,0,3]:
			var b = {"pos":Vector2(200,100),"velocity":(Vector2(0,vy))/0.03}
			var left = {"kind":pair[0],"pos":Vector2.ZERO}
			var right = {"kind":pair[1],"pos":Vector2.ZERO}
			Boss.attach(left,b)
			Boss.attach(right,b)
			var a: Vector2 = left.pos+Vector2(25,0)
			var z: Vector2 = right.pos+Vector2(25,0)
			symmetric = symmetric and is_equal_approx(a.x+z.x,400) and is_equal_approx(a.y,z.y)
		check(symmetric,"mecha arm anchors for%d/%d remain mirrored during boss movement"%pair)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
