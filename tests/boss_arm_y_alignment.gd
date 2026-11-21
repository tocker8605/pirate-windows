extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Boss=preload("res://scripts/boss.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func _initialize() -> void:
	# Measured landmarks retain the restored Y placement and fixed lateral attachment.
	var landmarks: Array=[
		{"stage":2,"kinds":[112,111],"body_y":[564.5/1183.0,565.0/1183.0],"arm_uv":Vector2(864.0/955.0,268.0/1575.0)},
		{"stage":4,"kinds":[131,132],"body_y":[576.0/1210.0,576.5/1210.0],"arm_uv":Vector2(910.0/956.0,250.0/1563.0)}]
	for row in landmarks:
		for velocity_y in [-200.0,0.0,100.0]:
			var body: Dictionary=Catalog.create(90+int(row.stage),Vector2(200,120))
			body.velocity=Vector2(40,velocity_y)
			var heights: Array=[]
			for side in range(2):
				var kind: int=int(row.kinds[side])
				var actor: Dictionary=Catalog.create(kind,Vector2.ZERO)
				Boss.attach(actor,body)
				var d: Dictionary=Catalog.definition(kind)
				var local: Vector2=(row.arm_uv-Vector2(0.5,0.5))*d.draw_size
				if Boss.part_side(kind)>0:local.x=-local.x
				var shoulder: Vector2=actor.pos+d.draw_offset+d.draw_size/2+local.rotated(Geometry.rotation(d))
				var socket_y: float=body.pos.y+float(row.body_y[side])*Catalog.for_actor(body).draw_size.y
				heights.append(shoulder.y)
				check(absf(shoulder.y-socket_y)<0.5,"stage%d arm%d restores its socket-aligned Y at vertical speed%s"%[row.stage,kind,velocity_y])
				if int(row.stage)==2:
					check(is_equal_approx(actor.pos.x-body.pos.x,-80 if side==0 else 30),"stage2 arm%d keeps a fixedX attachment despite vertical speed%s"%[kind,velocity_y])
			check(is_equal_approx(heights[0],heights[1]),"stage%d keeps both shoulder heights symmetric at vertical speed%s"%[row.stage,velocity_y])
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
