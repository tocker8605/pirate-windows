extends RefCounted
## Actor position stays authoritative for collision and movement. Drawing uses this transform.
static func vector(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])
static func visual(d: Dictionary) -> Dictionary: return d.get("visual",{})
static func layer(d: Dictionary) -> String: return str(visual(d).get("layer","air"))
static func rotation(d: Dictionary) -> float: return float(visual(d).get("rotation_radians",0))
static func image_rect(d: Dictionary, native: Vector2 = Vector2.ZERO) -> Rect2:
	var size: Vector2=vector(d.draw_size)
	var painted: Vector2=vector(visual(d).get("painted_size",size))
	if d.get("sprite_fit","stretch")=="contain" and native.x>0 and native.y>0:
		painted=native*minf(size.x/native.x,size.y/native.y)
	return Rect2((size-painted)/2,painted)
static func hinge_offset(d: Dictionary, native: Vector2 = Vector2.ZERO) -> Vector2:
	var rect: Rect2=image_rect(d,native)
	var point: Vector2=rect.position+rect.size*vector(visual(d).hinge_uv)
	if visual(d).get("flip_h",false):point.x=vector(d.draw_size).x-point.x
	return point
static func transform(d: Dictionary, pos: Vector2, native: Vector2 = Vector2.ZERO, yaw: float = 0, scale: Vector2 = Vector2.ONE) -> Transform2D:
	var size: Vector2=vector(d.draw_size)
	var center: Vector2=pos+vector(d.draw_offset)+size/2
	match str(visual(d).get("anchor","top_left")):
		"top_center":center=pos+vector(d.draw_offset)+Vector2(0,size.y/2)
	if visual(d).get("flip_h",false):scale.x=-scale.x
	var result:=Transform2D(yaw+rotation(d),center).scaled_local(scale)
	if visual(d).get("anchor")=="hinge":
		var rect: Rect2=image_rect(d,native)
		var local_anchor: Vector2=rect.position+rect.size*vector(visual(d).hinge_uv)-size/2
		result.origin=pos-result.basis_xform(local_anchor)
	return result
static func image_point(d: Dictionary,pos: Vector2,uv: Vector2,native: Vector2 = Vector2.ZERO) -> Vector2:
	var rect: Rect2=image_rect(d,native)
	return transform(d,pos,native)*(rect.position+rect.size*uv-vector(d.draw_size)/2)
