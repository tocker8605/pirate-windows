extends RefCounted
const Geometry=preload("res://scripts/entity_geometry.gd")
const Textures=preload("res://scripts/entity_textures.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Depth = preload("res://scripts/enemy_depth.gd")
const Pose = preload("res://scripts/enemy_pose.gd")
var poses: Dictionary = {}
var last_frame: int = -1
var render_fraction: float = 1.0
## Each entity resolves its own editable PNG through the catalog.
var texture_cache=Textures.new()
var wing_textures: Array = []
func enemy_texture(kind: int) -> Texture2D:
	return texture_cache.for_definition(Catalog.definition(kind))
func station_texture() -> Texture2D:
	return enemy_texture(3)
func draw_station(c: Node2D, center: Vector2, scale: Vector2, phase: float, tint: Color = Color.WHITE) -> void:
	# v22 habitat/truss only. The separate axial spindle is intentionally omitted.
	c.draw_set_transform(center,phase,scale)
	c.draw_texture_rect(station_texture(),Rect2(-25,-25,50,50),false,tint)
	c.draw_set_transform(Vector2.ZERO)
static func dimensions(kind: int) -> Vector2:
	return Catalog.definition(kind).get("draw_size",Vector2(50,50))
func reset_motion() -> void:
	poses.clear()
	last_frame = -1
func forget(id: int) -> void: poses.erase(id)
func observe(g: Node) -> void:
	if g.state in ["menu","loading"]:
		reset_motion()
		return
	if g.frame<last_frame: reset_motion()
	if g.frame==last_frame: return
	last_frame = g.frame
	for e in g.enemies:
		if Geometry.layer(Catalog.definition(int(e.kind)))=="floor": continue
		var id: int = e.entity_id
		if not poses.has(id): poses[id] = Pose.target(int(e.kind),e.velocity,g.animation)
		else: Pose.advance(poses[id],int(e.kind),e.velocity,g.animation,g.delta_seconds)
func draw_enemy(c: Node2D, e: Dictionary, pos: Vector2, _frame: int) -> void:
	var size: Vector2 = dimensions(int(e.kind))
	var sprite: Texture2D = enemy_texture(int(e.kind))
	var center: Vector2 = Geometry.sprite_transform(e,Catalog.definition(int(e.kind)),sprite.get_size(),pos).origin
	var id: int = e.get("entity_id",-1)
	var pose: Dictionary = poses[id] if poses.has(id) else Pose.target(int(e.kind),e.velocity,0)
	var pitch: float = lerpf(pose.previous_pitch,pose.pitch,render_fraction)
	var bank: float = lerpf(pose.previous_bank,pose.bank,render_fraction)
	var pulse: float = lerpf(pose.previous_pulse,pose.pulse,render_fraction)
	var spin: float = lerpf(pose.get("previous_spin",0.0),pose.get("spin",0.0),render_fraction)
	var projected: Vector2 = Pose.project(pitch,bank,int(e.kind))*Depth.scale_for(e)
	if e.kind in [4,5]: projected *= Vector2(1-pulse*0.18,1-pulse*0.06)
	var shade: float = 0.76+0.24*absf(projected.y)
	var tint: Color = Color(shade,shade,shade)*Depth.tint_for(e)
	if e.kind in [1,10]:
		tint *= Color.WHITE.lerp(Color(0.78,0.86,0.96),clampf(-cos(pitch),0,1))
	else:
		if pitch>PI/2: tint *= Color(0.78,0.86,0.96)
	if e.kind==10: tint *= Color(0.72,0.72,0.72)
	if Geometry.visual(Catalog.definition(int(e.kind))).get("flip_h",false): projected.x *= -1
	if e.kind==3:
		draw_station(c,center,projected,spin+float(e.get("pose_angle",0)),tint)
		return
	var yaw: float = Pose.bank_yaw(bank,projected.y,int(e.kind))+Geometry.rotation(Catalog.definition(int(e.kind)))+(spin if e.kind==9 else 0.0)+float(e.get("pose_angle",0))
	c.draw_set_transform(center,yaw,projected)
	var definition: Dictionary=Catalog.definition(int(e.kind))
	var painted_size: Vector2=Geometry.image_rect(definition,sprite.get_size()).size
	if e.kind in [1,10]:
		# Blend the two readable faces instead of collapsing the hull into a line.
		var height: float = Pose.crescent_height(pitch)*Depth.scale_for(e)
		var front: float = smoothstep(-0.35,0.35,cos(pitch))
		for facing in [1,-1]:
			var opacity: float = front if facing==1 else 1-front
			if opacity<=0: continue
			c.draw_set_transform(center,yaw,Vector2(projected.x,height*facing))
			c.draw_texture_rect(sprite,Rect2(-painted_size/2,painted_size),false,Color(tint,tint.a*opacity))
	elif e.kind==8: draw_hinged_wings(c,center,yaw,projected,Pose.wing_fold(bank),tint)
	else: c.draw_texture_rect(sprite,Rect2(-painted_size/2,painted_size),false,tint)
	if e.kind in [4,5,9]:
		# Keep the generated metal/lens shading; only modulate its emissive centre.
		c.draw_circle(Vector2.ZERO,3+pulse,Color(1,0.45,0.12,pulse*0.18)*Depth.tint_for(e),true,-1,true)
	c.draw_set_transform(Vector2.ZERO)

func draw_hinged_wings(c: Node2D, center: Vector2, yaw: float, scale: Vector2, fold: float, tint: Color) -> void:
	if wing_textures.is_empty():
		var source: Texture2D = enemy_texture(8)
		for band in [Vector2(0,0.35),Vector2(0.35,0.30),Vector2(0.65,0.35)]:
			var texture := AtlasTexture.new()
			texture.atlas = source
			texture.region = Rect2(Vector2(source.get_width()*band.x,0),source.get_size()*Vector2(band.y,1))
			texture.filter_clip = true
			wing_textures.append(texture)
	var base := Transform2D(yaw,center).scaled_local(scale)
	var angle: float = clampf(fold,0,1)*deg_to_rad(55)
	var wing_base := base.scaled_local(Vector2(1-0.35*fold,1))
	c.draw_set_transform_matrix(wing_base*Transform2D(angle,Vector2(-7.5,-4)))
	c.draw_texture_rect(wing_textures[0],Rect2(-17.5,-21,17.5,50),false,tint)
	c.draw_set_transform_matrix(wing_base*Transform2D(-angle,Vector2(7.5,-4)))
	c.draw_texture_rect(wing_textures[2],Rect2(0,-21,17.5,50),false,tint)
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect(wing_textures[1],Rect2(-7.5,-25,15,50),false,tint)

func draw_boss(c: Node2D, stage: int, pos: Vector2, actor: Dictionary = {}) -> void:
	var definition: Dictionary=Catalog.boss_definition(stage)
	var sprite: Texture2D=enemy_texture(int(definition.id))
	c.draw_set_transform_matrix(Geometry.transform(definition,pos,sprite.get_size()) if actor.is_empty() else Geometry.sprite_transform(actor,definition,sprite.get_size(),pos))
	var rect: Rect2=Geometry.image_rect(definition,sprite.get_size())
	rect.position-=definition.draw_size/2
	c.draw_texture_rect(sprite,rect,false)
	c.draw_set_transform(Vector2.ZERO)
