extends RefCounted
## Shared hatch/collar materials and separate rising weapon assemblies; floor layer only.
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Textures=preload("res://scripts/entity_textures.gd")
var textures=Textures.new()
func draw_turret(c: Node2D, actor: Dictionary, pos: Vector2) -> void:
	var settings: Dictionary = Catalog.for_actor(actor).ground_turret
	var center: Vector2 = pos+Geometry.vector(settings.center)
	var progress: float = float(actor.get("deployment_progress",0))
	var opening: float = smoothstep(0,0.45,progress)
	var extension: float = smoothstep(0.25,1,progress)
	var hatch: Texture2D = textures.for_asset(settings.hatch)
	c.draw_texture_rect(hatch,Rect2(center-Vector2(32,32),Vector2(64,64)),false)
	c.draw_colored_polygon(aperture_polygon(center),Color("101011"))
	if extension>0:
		var body: Texture2D = textures.for_definition(Catalog.for_actor(actor))
		var size := Vector2(settings.body_size[0],settings.body_size[1])
		size *= 0.68+0.32*extension
		var full := Rect2(Vector2(-size.x/2,-size.y*0.42+6*(1-extension)),size)
		c.draw_set_transform(center,float(actor.get("ground_angle",0)))
		var shade: float = 0.6+0.4*extension
		c.draw_texture_rect(body,full,false,Color(shade,shade,shade,smoothstep(0,0.2,extension)))
		c.draw_set_transform(Vector2.ZERO)
	if opening<1:
		_draw_doors(c,center,opening,settings.hatch)
static func aperture_polygon(center: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in [Vector2(-13,-25),Vector2(13,-25),Vector2(25,-13),Vector2(25,13),Vector2(13,25),Vector2(-13,25),Vector2(-25,13),Vector2(-25,-13)]:
		result.append(center+p)
	return result
static func door_polygons(opening: float, side: int) -> Array:
	# Slide the original octagonal leaves beneath the fixed collar, clipping to its aperture.
	var half := PackedVector2Array([Vector2(-13,-25),Vector2(0,-25),Vector2(0,25),Vector2(-13,25),Vector2(-25,13),Vector2(-25,-13)])
	var shift := Vector2(side*50*opening,0)
	for i in range(half.size()):
		half[i].x *= -side
		half[i] += shift
	return Geometry2D.intersect_polygons(aperture_polygon(),half)
func _draw_doors(c: Node2D, center: Vector2, opening: float, asset: Dictionary) -> void:
	var hatch: AtlasTexture = textures.for_asset(asset)
	for side in [-1,1]:
		var shift := Vector2(side*50*opening,0)
		for polygon in door_polygons(opening,side):
			var points := PackedVector2Array()
			var uv := PackedVector2Array()
			for p in polygon:
				points.append(center+p)
				uv.append((hatch.region.position+(p-shift+Vector2(32,32))/64*hatch.region.size)/hatch.atlas.get_size())
			c.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,hatch.atlas)
func draw_wreck(c: Node2D, remains: Dictionary, pos: Vector2) -> void:
	var settings: Dictionary=Catalog.definition(int(remains.kind)).ground_turret
	c.draw_texture_rect(textures.for_asset(settings.wreck),Rect2(pos+Geometry.vector(settings.center)-Vector2(32,32),Vector2(64,64)),false)
func draw_floor_actor(c: Node2D, actor: Dictionary, pos: Vector2) -> void:
	var d: Dictionary=Catalog.for_actor(actor)
	var texture: Texture2D=textures.for_definition(d)
	c.draw_set_transform_matrix(Geometry.sprite_transform(actor,d,texture.get_size(),pos))
	var rect: Rect2=Geometry.image_rect(d,texture.get_size())
	rect.position-=d.draw_size/2
	c.draw_texture_rect(texture,rect,false)
	c.draw_set_transform(Vector2.ZERO)

static func decoration_rect(d: Dictionary,pos: Vector2) -> Rect2:
	var settings: Dictionary=d.floor_decoration
	var size: Vector2=Geometry.vector(settings.size)
	var center: Vector2=Geometry.transform(d,pos,Textures.native_size(d)).origin+Geometry.vector(settings.offset)
	return Rect2(center-size/2,size)
func draw_floor_decoration(c: Node2D,actor: Dictionary,pos: Vector2) -> void:
	var d: Dictionary=Catalog.for_actor(actor)
	if not d.has("floor_decoration"):return
	c.draw_texture_rect(textures.for_asset(d.floor_decoration.asset),decoration_rect(d,pos),false)
