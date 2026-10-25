extends RefCounted
const Pose = preload("res://scripts/enemy_pose.gd")
var poses: Dictionary = {}
var last_frame: int = -1
var render_fraction: float = 1.0
## Generated alpha atlases are consumed non-destructively at the original game anchors.
var enemies: Texture2D = preload("res://assets/renewed/enemies-v10.png")
var bosses: Texture2D = preload("res://assets/renewed/bosses-v10.png")
var earth: Texture2D = preload("res://assets/renewed/earth-departure-v12.png")
var cavern: Texture2D = preload("res://assets/renewed/lunar-cavern-v12.png")
var environments: Texture2D = preload("res://assets/renewed/regions-v11.png")
var cells: Dictionary = {}
var images: Dictionary = {}
const SMALL: Dictionary = {1:0,2:1,3:2,4:3,5:4,6:5,7:6,8:7,9:8,10:9,11:10,19:11,201:11,21:12,22:13,41:14,42:15}
func cell(atlas: Texture2D, index: int, columns: int, rows: int) -> AtlasTexture:
	var key: String = "%s:%d"%[atlas.resource_path,index]
	if not cells.has(key):
		var size := Vector2i(atlas.get_width()/columns,atlas.get_height()/rows)
		var region := Rect2i(Vector2i(index%columns,int(index/columns))*size,size)
		if not images.has(atlas.resource_path): images[atlas.resource_path] = atlas.get_image()
		var used: Rect2i = images[atlas.resource_path].get_region(region).get_used_rect()
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(region.position+used.position,used.size)
		texture.filter_clip = true
		cells[key] = texture
	return cells[key]
func enemy_texture(kind: int) -> Texture2D:
	if SMALL.has(kind): return cell(enemies,int(SMALL[kind]),4,4)
	if kind in [111,121,131]: return cell(bosses,4,4,2)
	if kind in [112,122,132]: return cell(bosses,5,4,2)
	return cell(bosses,7 if kind==133 else 6,4,2)
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
		else: Pose.advance(poses[id],int(e.kind),e.velocity,g.animation)
func draw_enemy(c: Node2D, e: Dictionary, pos: Vector2, _frame: int) -> void:
	var size: Vector2 = dimensions(int(e.kind))
	var center: Vector2 = pos+size/2
	var id: int = e.get("entity_id",-1)
	var pose: Dictionary = poses[id] if poses.has(id) else Pose.target(int(e.kind),e.velocity,0)
	var pitch: float = lerpf(pose.previous_pitch,pose.pitch,render_fraction)
	var bank: float = lerpf(pose.previous_bank,pose.bank,render_fraction)
	var pulse: float = lerpf(pose.previous_pulse,pose.pulse,render_fraction)
	var projected: Vector2 = Pose.project(pitch,bank,int(e.kind))
	var shade: float = 0.76+0.24*absf(projected.y)
	var tint := Color(shade,shade,shade)
	if pitch>PI/2: tint *= Color(0.78,0.86,0.96)
	c.draw_set_transform(center,Pose.bank_yaw(bank,projected.y),projected)
	c.draw_texture_rect(enemy_texture(int(e.kind)),Rect2(-size/2,size),false,tint)
	if e.kind in [3,4,5,9]:
		c.draw_circle(Vector2.ZERO,2.5+pulse*2,Color(1,0.3+pulse*0.35,0.2,0.8),true,-1,true)
		c.draw_arc(Vector2.ZERO,6+pulse*2,0,TAU,24,Color(1,0.3,0.2,0.45),0.8,true)
	if e.kind==201:
		c.draw_rect(Rect2(-8,-8,16,22),Color("304750"))
		c.draw_rect(Rect2(-8,-8,16,22),Color("72c5cd"),false,0.8)
	elif e.kind==19:
		c.draw_rect(Rect2(-6,-6,12,19),Color("0c2029"))
		c.draw_line(Vector2(-7,-7),Vector2(-7,14),Color("72ffd6"),1.2,true)
		c.draw_line(Vector2(7,-7),Vector2(7,14),Color("72ffd6"),1.2,true)
	c.draw_set_transform(Vector2.ZERO)

func draw_boss(c: Node2D, stage: int, pos: Vector2) -> void:
	c.draw_texture_rect(cell(bosses,stage-1,4,2),Rect2(pos+Vector2(-75,0),Vector2(150,100)),false)
