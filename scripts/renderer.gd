extends Node2D
## Rendering consumes game state; input, simulation and audio live elsewhere.
const Weapons = preload("res://scripts/player_weapons.gd")
const HUD = preload("res://scripts/hud.gd")
const Particles = preload("res://scripts/combat_vfx.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Renewed = preload("res://scripts/renewed_art.gd")
const Clock = preload("res://scripts/timing.gd")
const Regions = preload("res://scripts/background_regions.gd")

var vfx = Particles.new()
var renewal = Renewed.new()
var background: Sprite2D
var old_cloud_shader = preload("res://scripts/cloud_rop.gdshader")
var new_cloud_shader = preload("res://scripts/renewed_cloud.gdshader")
var g: Node
var foreground_only: bool = false
var cloud_nodes: Array = []
var foreground: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if foreground_only: return
	background = Sprite2D.new()
	background.centered = false
	background.texture = renewal.environments
	background.scale = Vector2(400.0/background.texture.get_width(),480.0/background.texture.get_height())
	var background_material := ShaderMaterial.new()
	background_material.shader = preload("res://scripts/renewed_background.gdshader")
	background_material.set_shader_parameter("atlas_texture",renewal.environments)
	background_material.set_shader_parameter("earth_texture",renewal.earth)
	background_material.set_shader_parameter("cavern_texture",renewal.cavern)
	background_material.set_shader_parameter("earth_uv_width",400.0/(Regions.SCREEN*2)*renewal.earth.get_height()/renewal.earth.get_width())
	background_material.set_shader_parameter("region_edges",Regions.EDGES)
	background_material.set_shader_parameter("screen_height",Regions.SCREEN)
	background.material = background_material
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)
	for i in range(2):
		var copy := BackBufferCopy.new()
		copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(copy)
		var cloud := Sprite2D.new()
		cloud.centered = false
		cloud.region_enabled = true
		cloud.region_rect = Rect2(0,0,300,300)
		var material := ShaderMaterial.new()
		material.shader = load("res://scripts/cloud_rop.gdshader")
		cloud.material = material
		add_child(cloud)
		cloud_nodes.append(cloud)
	foreground = get_script().new()
	foreground.g = g
	foreground.foreground_only = true
	foreground.vfx = vfx
	foreground.renewal = renewal
	add_child(foreground)
	refresh()

func refresh() -> void:
	if not foreground_only:
		vfx.observe(g)
		renewal.observe(g)
		if g.state!="paused": renewal.render_fraction = clampf(g.accumulator/Clock.interval(g.title.speed),0,1) if g.automatic else 1.0
		var in_game: bool = g.state not in ["menu","loading"]
		background.visible = in_game and g.renewed_art
		if background.visible:
			background.material.set_shader_parameter("stage",g.stage)
			background.material.set_shader_parameter("boss_rush",g.boss_rush)
			background.material.set_shader_parameter("source_top",g.background_y)
		for i in range(cloud_nodes.size()):
			cloud_nodes[i].visible = in_game
			if in_game:
				var cloud: Sprite2D = cloud_nodes[i]
				cloud.material.shader = new_cloud_shader if g.renewed_art else old_cloud_shader
				cloud.region_enabled = not g.renewed_art
				cloud.texture = vfx.glow if g.renewed_art else g.art.texture(["","cl03","cl02","cl01","cl01"][g.stage])
				cloud.scale = Vector2.ONE*(300.0/vfx.glow.get_width()) if g.renewed_art else Vector2.ONE
				if g.renewed_art: cloud.material.set_shader_parameter("phase",g.frame)
				cloud_nodes[i].position = g.clouds[i]
		foreground.queue_redraw()
	queue_redraw()
func _text(pos: Vector2, text: String, size: int = 14, color: Color = Color.WHITE) -> void:
	draw_string(g.font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)


func _center(y: float, text: String, size: int = 16, color: Color = Color.WHITE) -> void:
	_text(Vector2((400-g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)/2,y),text,size,color)


func _draw() -> void:
	if not foreground_only:
		if g.state=="menu": _draw_menu()
		elif g.state=="loading":
			if g.loading_image=="loading2": g.title.weapon_preview.draw_loading(self,g.art,g.frame)
			else: draw_texture(g.art.texture(g.loading_image),Vector2.ZERO)
		elif not g.renewed_art: draw_texture_rect_region(g.art.texture("stage%d"%g.stage),Rect2(0,0,400,480),Rect2(0,g.background_y,400,480))
		return
	if g.state in ["menu","loading"]: return
	for item in g.items:
		if item.get("born_frame",-1)==g.frame: continue
		var y: int = 260 if item.kind == 1 else 320
		draw_texture(g.art.sprite("eweapons",Rect2i(g.animation*20,y,20,30),Vector2i(g.animation*20,y+30)),item.get("render_pos",item.pos)-Vector2(10,15))
	for bullet in g.bullets:
		_draw_bullet(bullet)
	if not g.boss.is_empty():
		if g.renewed_art: renewal.draw_boss(self,g.stage,g.boss.pos)
		else: draw_texture(g.art.sprite("boss%02d"%g.stage,Rect2i(0,0,150,100),Vector2i(0,100)),g.boss.pos+Vector2(-75,0))
	if g.state != "dead" and (g.invulnerable_render_ticks%2==0):
		draw_texture(g.art.sprite("picair",Rect2i(g.player_bank*50,0,50,50),Vector2i(g.player_bank*50,50)),g.player)

	for e in g.enemies:
		var offset := Vector2.ZERO
		if e.kind in [21,22]: offset = Vector2(-25,-45 if e.kind==22 else -25)
		if e.kind in [41,42]: offset = Vector2(-50,-25)
		if int(e.kind) in [111,112,121,122,131,132]: offset = Vector2(0,-50)
		if e.kind==133: offset = Vector2(0,-15)
		if g.renewed_art: renewal.draw_enemy(self,e,e.pos+offset,g.frame)
		else: draw_texture(g.art.enemy(int(e.get("render_kind",e.kind)),e.velocity,g.animation,g.stage,e.pos.y),e.pos+offset)
		var preparation: Dictionary = Scenery.preparation(e,g.boss)
		if not preparation.is_empty():
			vfx.draw_charge(self,preparation.pos+Vector2(25,25),g.frame)


	for blast in g.explosions: vfx.draw_explosion(self,blast)
	var fraction: float = g.accumulator/Clock.interval(g.title.speed) if g.automatic and g.state!="paused" else 0.0
	vfx.draw_particles(self,clampf(fraction,0,1))
	for shot in (g.shot_visuals if not g.shot_visuals.is_empty() else g.shots):
		_draw_shot(shot)
	vfx.draw_special(self,g)
	for e in g.enemies:
		if int(e.kind) in [19,201]:
			draw_texture(g.art.sprite("enemy_sm",Rect2i(2550,0,50,50),Vector2i(2550,50)),e.pos)
	if g.death_ticks>0:
		draw_texture(g.art.sprite("picgov",Rect2i(0,0,200,30),Vector2i(0,30)),Vector2(100,230))

	_draw_hud()
	if g.banner_ticks > 0:
		if g.banner.begins_with("WARNING"):
			draw_texture(g.art.sprite("picwarn",Rect2i(0,0,250,60),Vector2i(0,60)),Vector2(75,200))
		elif not g.banner.is_empty():
			draw_texture(g.art.sprite("mis%02d"%(g.stage+10 if g.boss_rush else g.stage),Rect2i(0,0,250,30),Vector2i(0,30)),Vector2(75,200))
	if g.state=="paused":
		draw_rect(Rect2(0,0,400,480),Color(0.01,0.02,0.05,0.7))
		_center(202,"PAUSED",28,Color(0.7,0.92,1))
		_center(278,"P: RESUME",14)
		_center(307,"ESC: TITLE",12,Color(0.65,0.75,0.85))
func _draw_bullet(b: Dictionary) -> void:
	vfx.draw_bullet(self,b)

func _draw_shot(shot: Dictionary) -> void:
	vfx.draw_shot(self,shot,g.player,g.weapon)

func _draw_hud() -> void:
	HUD.render(self,g.art,clampi(Weapons.vb_integer(g.hp),0,100),clampf(g.energy,0,100),g.weapon,g.power,g.score,int(g.boss.hp) if not g.boss.is_empty() else -1,int(g.boss.get("max_hp",1000)))


func _draw_menu() -> void:
	g.title.render(self,g.art,g.last_score)
