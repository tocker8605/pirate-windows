extends RefCounted
## Actor position stays authoritative for collision and movement. Drawing uses this transform.
const Shapes=preload("res://scripts/collision_geometry.gd")
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

## Local metadata is authored after sprite mirroring, relative to the actor's logical anchor.
## The same rigid frame drives collisions, muzzles, smoke and sprite placement.
static func local_frame(actor: Dictionary,position: Variant = null,angle_override: Variant = null) -> Transform2D:
	var pos: Vector2=actor.pos if position==null else position
	var pivot: Vector2=actor.get("pose_pivot",Vector2.ZERO)
	var angle: float=float(actor.get("pose_angle",0)) if angle_override==null else float(angle_override)
	return Transform2D(angle,pos+pivot-pivot.rotated(angle))
static func world_point(actor: Dictionary,local: Vector2,angle_override: Variant = null) -> Vector2:
	var angle: float=float(actor.get("pose_angle",0)) if angle_override==null else float(angle_override)
	if angle==0:return actor.pos+local
	return local_frame(actor,null,angle)*local
static func sprite_transform(actor: Dictionary,d: Dictionary,native: Vector2,position: Variant = null) -> Transform2D:
	return local_frame(actor,position)*transform(d,Vector2.ZERO,native)

static func local_point(actor: Dictionary,world: Vector2) -> Vector2:
	if float(actor.get("pose_angle",0))==0:return world-actor.pos
	return local_frame(actor).affine_inverse()*world

## Centre of the displayed sprite, including crop aspect, mirroring and rigid pose.
static func sprite_native_size(d: Dictionary) -> Vector2:
	var region: Array=d.get("sprite_region",[])
	return Vector2(region[2],region[3]) if region.size()==4 else Vector2.ZERO
static func sprite_center(actor: Dictionary,d: Dictionary) -> Vector2:
	return sprite_transform(actor,d,sprite_native_size(d)).origin
## Visual contact may differ from the forgiving gameplay collider. It never changes damage.
static func sprite_ray_contact(actor: Dictionary,d: Dictionary,origin: Vector2,direction: Vector2) -> Variant:
	var native: Vector2=sprite_native_size(d)
	var rect: Rect2=image_rect(d,native)
	var start: Vector2=rect.position-vector(d.draw_size)/2
	var end: Vector2=start+rect.size
	return Shapes.ray_contact(origin,direction,[start.x,start.y,end.x,end.y],sprite_transform(actor,d,native))
