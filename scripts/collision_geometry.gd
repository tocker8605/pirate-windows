extends RefCounted
## Local rectangles under any rigid pose (translation/rotation). No entity IDs or gameplay rules.
static func point_inside(point: Vector2,bounds: Array) -> bool:
	return point.x>bounds[0] and point.x<bounds[2] and point.y>bounds[1] and point.y<bounds[3]
static func point_hits(point: Vector2,bounds: Array,frame: Transform2D) -> bool:
	return point_inside(frame.affine_inverse()*point,bounds)
static func circle_hits(center: Vector2,radius: float,bounds: Array,frame: Transform2D) -> bool:
	return circle_inside(frame.affine_inverse()*center,radius,bounds)
static func circle_inside(local: Vector2,radius: float,bounds: Array) -> bool:
	var closest:=Vector2(clampf(local.x,bounds[0],bounds[2]),clampf(local.y,bounds[1],bounds[3]))
	return local.distance_squared_to(closest)<radius*radius
static func ray_hits(origin: Vector2,direction: Vector2,bounds: Array,frame: Transform2D,max_distance: float = INF) -> bool:
	var inverse: Transform2D=frame.affine_inverse()
	var local: Vector2=inverse*origin
	var heading: Vector2=inverse.basis_xform(direction)
	var entry: float=0
	var exit: float=max_distance
	if heading==Vector2.ZERO or max_distance<=0:return false
	for axis in range(2):
		var lo: float=bounds[axis]
		var hi: float=bounds[axis+2]
		if absf(heading[axis])<0.0000001:
			if local[axis]<=lo or local[axis]>=hi:return false
			continue
		var a: float=(lo-local[axis])/heading[axis]
		var b: float=(hi-local[axis])/heading[axis]
		entry=maxf(entry,minf(a,b))
		exit=minf(exit,maxf(a,b))
		if entry>=exit:return false
	return exit>entry

## Circle versus a finite thick segment (capsule), reusable for beams and contact hazards.
static func circle_segment_hits(center: Vector2,radius: float,start: Vector2,end: Vector2,width: float) -> bool:
	var delta: Vector2=end-start
	var length_squared: float=delta.length_squared()
	var progress: float=clampf((center-start).dot(delta)/length_squared,0,1) if length_squared>0 else 0
	var combined: float=radius+width/2
	return center.distance_squared_to(start+delta*progress)<combined*combined
