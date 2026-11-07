extends RefCounted
const Pose = preload("res://scripts/enemy_pose.gd")
const Boss = preload("res://scripts/boss.gd")
var poses: Dictionary = {}
var last_frame: int = -1
var render_fraction: float = 1.0
## Generated alpha atlases are consumed non-destructively at the original game anchors.
var carrier: Texture2D = preload("res://assets/renewed/carrier-v20.png")
var enemies: Texture2D = preload("res://assets/renewed/enemies-v18.png")
var bosses: Texture2D = preload("res://assets/renewed/bosses-v15.png")
var earth: Texture2D = preload("res://assets/renewed/earth-departure-v12.png")
var cavern: Texture2D = preload("res://assets/renewed/lunar-cavern-v12.png")
var environments: Texture2D = preload("res://assets/renewed/regions-v11.png")
var cells: Dictionary = {}
var images: Dictionary = {}
var wing_textures: Array = []
const ENEMY_ROW_EDGES: Array = [0, 333, 631, 922, 1254]
const ENEMY_COLUMN_EDGES: Array = [[0, 324, 641, 924, 1254], [0, 320, 634, 930, 1254], [0, 321, 639, 929, 1254], [0, 317, 618, 939, 1254]]
const ENEMY_RECTS: Array = [
 Rect2i(24,86,269,227),
 Rect2i(357,25,251,292),
 Rect2i(675,45,218,275),
 Rect2i(957,25,290,294),
 Rect2i(18,355,279,262),
 Rect2i(344,347,267,270),
 Rect2i(659,361,251,253),
 Rect2i(952,349,291,271),
 Rect2i(10,652,291,240),
 Rect2i(342,690,271,220),
 Rect2i(666,644,237,266),
 Rect2i(956,644,290,266),
 Rect2i(9,950,297,209),
 Rect2i(329,936,280,246),
 Rect2i(628,962,306,203),
 Rect2i(945,962,305,203)]
const BOSS_COLUMN_EDGES: Array = [[0,384,714,1090,1448],[0,362,724,1086,1448],[0,362,724,1086,1448]]
const BOSS_ROW_EDGES: Array = [0,369,800,1086] # Native1448x1086 sheet has unequal row heights.
# Measured once from alpha>5percent; avoid scanning the atlas when a boss first appears.
const BOSS_RECTS: Array = [
 Rect2i(20,14,361,352),Rect2i(387,10,314,356),Rect2i(727,14,360,352),Rect2i(1093,10,339,358),
 Rect2i(81,375,260,415),Rect2i(455,376,241,412),Rect2i(794,370,268,423),Rect2i(1149,482,228,230),
 Rect2i(53,810,279,259),Rect2i(435,811,252,239),Rect2i(844,802,138,269),Rect2i(1173,840,202,203)]
const BOSS_PARTS: Dictionary = {101:7,102:7,111:4,112:4,113:8,121:5,122:5,123:9,124:9,131:6,132:6,133:10}
const SMALL: Dictionary = {1:0,2:1,3:2,4:3,5:4,6:5,7:6,8:7,9:8,10:9,11:10,19:11,201:11,21:12,22:13,41:14,42:15}
func cell(atlas: Texture2D, index: int, columns: int, rows: int) -> AtlasTexture:
	var key: String = "%s:%d"%[atlas.resource_path,index]
	if not cells.has(key):
		var crop: Rect2i
		if atlas==bosses: crop = BOSS_RECTS[index]
		elif atlas==enemies: crop = ENEMY_RECTS[index]
		else:
			var size := Vector2i(atlas.get_width()/columns,atlas.get_height()/rows)
			var region := Rect2i(Vector2i(index%columns,int(index/columns))*size,size)
			if not images.has(atlas.resource_path): images[atlas.resource_path] = atlas.get_image()
			var used: Rect2i = images[atlas.resource_path].get_region(region).get_used_rect()
			crop = Rect2i(region.position+used.position,used.size)
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(crop)
		texture.filter_clip = true
		cells[key] = texture
	return cells[key]
func enemy_texture(kind: int) -> Texture2D:
	if kind in [19,201]: return carrier
	if SMALL.has(kind): return cell(enemies,int(SMALL[kind]),4,4)
	return cell(bosses,int(BOSS_PARTS.get(kind,11)),4,3)
static func dimensions(kind: int) -> Vector2:
	if kind in [21,22]: return Vector2(100,100)
	if kind in [41,42]: return Vector2(150,100)
	if kind in [111,112,121,122,131,132]: return Vector2(50,100)
	if kind==133: return Vector2(50,80)
	return Vector2(50,50)
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
		var id: int = e.entity_id
		if not poses.has(id): poses[id] = Pose.target(int(e.kind),e.velocity,g.animation)
		else: Pose.advance(poses[id],int(e.kind),e.velocity,g.animation,g.tick_units)
func draw_enemy(c: Node2D, e: Dictionary, pos: Vector2, _frame: int) -> void:
	var size: Vector2 = dimensions(int(e.kind))
	var center: Vector2 = pos+size/2
	var id: int = e.get("entity_id",-1)
	var pose: Dictionary = poses[id] if poses.has(id) else Pose.target(int(e.kind),e.velocity,0)
	var pitch: float = lerpf(pose.previous_pitch,pose.pitch,render_fraction)
	var bank: float = lerpf(pose.previous_bank,pose.bank,render_fraction)
	var pulse: float = lerpf(pose.previous_pulse,pose.pulse,render_fraction)
	var spin: float = lerpf(pose.get("previous_spin",0.0),pose.get("spin",0.0),render_fraction)
	var projected: Vector2 = Pose.project(pitch,bank,int(e.kind))
	if e.kind in [4,5]: projected *= Vector2(1-pulse*0.18,1-pulse*0.06)
	var shade: float = 0.76+0.24*absf(projected.y)
	var tint := Color(shade,shade,shade)
	if pitch>PI/2: tint *= Color(0.78,0.86,0.96)
	if Boss.part_side(int(e.kind))>0 or e.kind in [101,124]: projected.x *= -1
	if e.kind==133: center.x += 1
	var yaw: float = Pose.bank_yaw(bank,projected.y)+arm_roll(int(e.kind))+(spin if e.kind==9 else 0.0)
	c.draw_set_transform(center,yaw,projected)
	var painted_size: Vector2 = Vector2(41,80) if e.kind==133 else size
	var sprite: Texture2D = enemy_texture(int(e.kind))
	if SMALL.has(int(e.kind)) and e.kind!=8:
		var native := Vector2(sprite.get_width(),sprite.get_height())
		painted_size = native*minf(size.x/native.x,size.y/native.y)
	if e.kind==8: draw_hinged_wings(c,center,yaw,projected,Pose.wing_fold(bank),tint)
	else: c.draw_texture_rect(sprite,Rect2(-painted_size/2,painted_size),false,tint)
	if e.kind==3:
		var rotor := Vector2(0,-3)
		c.draw_circle(rotor,11,Color("172025"),true,-1,true)
		for i in range(3):
			var direction := Vector2.from_angle(spin+i*TAU/3)
			var side := direction.orthogonal()
			c.draw_colored_polygon(PackedVector2Array([rotor+direction*2+side,rotor+direction*9+side*2,rotor+direction*8-side*2]),Color("8e9ca4"))
			c.draw_line(rotor+direction*3+side,rotor+direction*9+side*2,Color("d3dde1"),0.7,true)
		c.draw_circle(rotor,2,Color("b5c3cb"),true,-1,true)
	elif e.kind in [4,5,9]:
		# Keep the generated metal/lens shading; only modulate its emissive centre.
		c.draw_circle(Vector2.ZERO,3+pulse,Color(1,0.45,0.12,pulse*0.18),true,-1,true)
	c.draw_set_transform(Vector2.ZERO)

func draw_hinged_wings(c: Node2D, center: Vector2, yaw: float, scale: Vector2, fold: float, tint: Color) -> void:
	if wing_textures.is_empty():
		var source: AtlasTexture = enemy_texture(8)
		for band in [Vector2(0,0.35),Vector2(0.35,0.30),Vector2(0.65,0.35)]:
			var texture := AtlasTexture.new()
			texture.atlas = source.atlas
			texture.region = Rect2(source.region.position+Vector2(source.region.size.x*band.x,0),source.region.size*Vector2(band.y,1))
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

static func arm_roll(kind: int) -> float:
	# The stage2 forearm is aligned with its original lower central muzzle.
	return Boss.part_side(kind)*0.25 if kind in [111,112] else 0.0
static func arm_joint(kind: int, pos: Vector2) -> Vector2:
	var local := Vector2(15 if Boss.part_side(kind)<0 else -15,-36)
	return pos+Vector2(25,0)+local.rotated(arm_roll(kind))

func draw_boss_links(c: Node2D, pos: Vector2, actors: Variant, presentation: RefCounted) -> void:
	# Shoulder coupling sits behind the torso and follows authored arm separation.
	for e in actors:
		var side: int = Boss.part_side(int(e.kind))
		if side==0 or e.hp<=0: continue
		var socket := pos+Vector2(side*32,22)
		var joint: Vector2 = arm_joint(int(e.kind),presentation.position(e))
		c.draw_line(socket,joint,Color("101820"),9,true)
		c.draw_line(socket,joint,Color("8b99a3"),4,true)
		c.draw_line(socket+Vector2(0,3),joint+Vector2(0,3),Color("39434c"),1.5,true)
		c.draw_circle(joint,3.5,Color("252d35"),true,-1,true)
		c.draw_circle(joint,1.5,Color("d27146"),true,-1,true)

func draw_boss(c: Node2D, stage: int, pos: Vector2) -> void:
	# Original bodies are compact robot torsos; the wide old frame includes empty margins.
	var width: float = 115 if stage==1 else 100
	c.draw_texture_rect(cell(bosses,stage-1,4,3),Rect2(pos+Vector2(-width/2,0),Vector2(width,100)),false)
