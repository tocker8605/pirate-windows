extends SceneTree
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
static func visible_bounds(source: Image, region: Rect2i) -> Rect2i:
	# Generated anti-alias fringe below5percent alpha can extend between components.
	# Measure the visible silhouette without editing the source pixels.
	var first: Vector2i = region.end
	var last: Vector2i = region.position-Vector2i.ONE
	for y in range(region.position.y,region.end.y):
		for x in range(region.position.x,region.end.x):
			if source.get_pixel(x,y).a<=0.05: continue
			first.x = mini(first.x,x)
			first.y = mini(first.y,y)
			last.x = maxi(last.x,x)
			last.y = maxi(last.y,y)
	return Rect2i(first,last-first+Vector2i.ONE)

func _initialize() -> void:
	var art = Mecha.new()
	var source: Image = art.bosses.get_image()
	for index in range(12):
		var texture: AtlasTexture = art.cell(art.bosses,index,4,3)
		var region: Rect2 = texture.region
		var row: int = int(index/4)
		var top_left := Vector2i(art.BOSS_COLUMN_EDGES[row][index%4],art.BOSS_ROW_EDGES[row])
		var bottom_right := Vector2i(art.BOSS_COLUMN_EDGES[row][index%4+1],art.BOSS_ROW_EDGES[row+1])
		var measured: Rect2i = visible_bounds(source,Rect2i(top_left,bottom_right-top_left))
		check(region==Rect2(measured) and region.size.x>10 and region.size.y>10 and region.position.y>art.BOSS_ROW_EDGES[row] and region.end.y<art.BOSS_ROW_EDGES[row+1] and region.position.x>art.BOSS_COLUMN_EDGES[row][index%4] and region.end.x<art.BOSS_COLUMN_EDGES[row][index%4+1],"mecha cell%d retains complete alpha silhouette without crossing/cutting its cell"%index)
	for pair in [[112,111],[121,122],[131,132]]:
		var symmetric: bool = true
		for vy in [-7,0,3]:
			var b = {"pos":Vector2(200,100),"velocity":(Vector2(0,vy))/0.03}
			var left = {"kind":pair[0],"pos":Vector2.ZERO}
			var right = {"kind":pair[1],"pos":Vector2.ZERO}
			Boss.attach(left,b)
			Boss.attach(right,b)
			var a: Vector2 = art.arm_joint(pair[0],left.pos)
			var z: Vector2 = art.arm_joint(pair[1],right.pos)
			symmetric = symmetric and is_equal_approx(a.x+z.x,400) and is_equal_approx(a.y,z.y)
		check(symmetric,"mecha shoulder couplings for%d/%d remain mirrored during boss movement"%pair)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
