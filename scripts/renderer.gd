extends Node2D
## Rendering consumes game state; input, simulation and audio live elsewhere.
const ParticleLayers=preload("res://scripts/particle_layers.gd")
const BeamArt=preload("res://scripts/enemy_beam_art.gd")
const Ground = preload("res://scripts/ground_turret.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Stages=preload("res://scripts/stage_catalog.gd")
const GroundArt = preload("res://scripts/ground_art.gd")
const Depth = preload("res://scripts/enemy_depth.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const HUD = preload("res://scripts/hud.gd")
const MissionBanner = preload("res://scripts/mission_banner.gd")
const Particles = preload("res://scripts/combat_vfx.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Renewed = preload("res://scripts/renewed_art.gd")
const Clock = preload("res://scripts/timing.gd")
const Regions = preload("res://scripts/background_regions.gd")
const BackgroundAssets = preload("res://scripts/background_assets.gd")
const Supply = preload("res://scripts/supply_visual.gd")
const Pilot = preload("res://scripts/pilot_art.gd")
var pilot = Pilot.new()
var ground_art: RefCounted

var vfx = Particles.new()
var renewal = Renewed.new()
var background_stage: int = 0
var background_textures: Array[Texture2D] = []
var background: Sprite2D
var old_cloud_shader = preload("res://scripts/cloud_rop.gdshader")
var new_cloud_shader = preload("res://scripts/renewed_cloud.gdshader")
var g: Node
var foreground_only: bool = false
var cloud_nodes: Array = []
var cloud_copies: Array = []
var foreground: Node2D

## Populate the same caches used by drawing, while the stage loading screen is active.
func prepare_entities(ids: Array,renewed: bool) -> void:
	for id in ids:
		var definition: Dictionary=Catalog.definition(id)
		if definition.has("ground_turret") or Geometry.layer(definition)=="floor":
			if ground_art==null:ground_art=GroundArt.new()
			ground_art.textures.prepare_definition(definition)
		elif renewed:
			renewal.prepare_entity(id)
		else:
			var frame: Texture2D=g.art.classic_frame(id,0)
			var count: int=int(frame.atlas.get_width()/frame.region.size.x)
			for index in range(1,count):g.art.classic_frame(id,index)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if foreground_only: return
	background = Sprite2D.new()
	background.centered = false
	background.z_index = -1
	background.texture = vfx.glow
	background.scale = Vector2(400.0/background.texture.get_width(),480.0/background.texture.get_height())
	var background_material := ShaderMaterial.new()
	background_material.shader = preload("res://scripts/renewed_background.gdshader")
	background_material.set_shader_parameter("region_edges",Regions.EDGES)
	background_material.set_shader_parameter("screen_height",Regions.SCREEN)
	background.material = background_material
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)
	for i in range(2):
		var copy := BackBufferCopy.new()
		copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(copy)
		cloud_copies.append(copy)
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
	foreground.pilot = pilot
	add_child(foreground)
	refresh()

func refresh() -> void:
	if not foreground_only:
		g.presentation.refresh(g)
		vfx.observe(g)
		renewal.observe(g)
		renewal.render_fraction = g.presentation.alpha
		var in_game: bool = g.state not in ["menu","loading","ranking_entry"]
		var title_earth: bool = g.state=="menu" and g.title.shows_background()
		background.position = Vector2(-g.title.background_offset(),0) if title_earth else Vector2.ZERO
		background.visible = (in_game or title_earth) and (g.renewed_art or Stages.definition(g.stage).classic_background.is_empty())
		if background.visible:
			var next_stage: int = 4 if title_earth else g.stage
			if next_stage!=background_stage:
				background_textures = BackgroundAssets.load_stage(next_stage)
				BackgroundAssets.bind(background.material,next_stage,background_textures)
				background.texture = background_textures[0]
				background.scale = Vector2(400.0/background.texture.get_width(),480.0/background.texture.get_height())
				background_stage = next_stage
			background.material.set_shader_parameter("source_top",3360.0-g.title.background_scroll() if title_earth else g.presentation.background(g))
		for i in range(cloud_nodes.size()):
			var cloud: Sprite2D = cloud_nodes[i]
			cloud.position = g.presentation.cloud(g,i)
			var on_screen: bool = Rect2(Vector2.ZERO,Vector2(400,480)).intersects(Rect2(cloud.position,Vector2(300,300)))
			cloud.visible = in_game and on_screen and not Stages.definition(g.stage).cloud_texture.is_empty()
			# Only the original bitwise GDI shader reads SCREEN_TEXTURE. Renewed
			# alpha clouds never need these two full-viewport framebuffer copies.
			cloud_copies[i].visible = cloud.visible and not g.renewed_art
			if not cloud.visible: continue
			cloud.material.shader = new_cloud_shader if g.renewed_art else old_cloud_shader
			cloud.region_enabled = not g.renewed_art
			cloud.texture = vfx.glow if g.renewed_art else g.art.texture(Stages.definition(g.stage).cloud_texture)
			cloud.scale = Vector2.ONE*(300.0/vfx.glow.get_width()) if g.renewed_art else Vector2.ONE
			if g.renewed_art: cloud.material.set_shader_parameter("phase",g.presentation.phase(g))
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
			draw_texture(g.art.texture(g.flow.loading_image),Vector2.ZERO)
		elif g.state=="ranking_entry": draw_rect(Rect2(0,0,400,480),Color.BLACK)
		elif not g.renewed_art and not Stages.definition(g.stage).classic_background.is_empty(): draw_texture_rect_region(g.art.texture(Stages.definition(g.stage).classic_background),Rect2(0,0,400,480),Rect2(0,g.background_y,400,480))
		if g.state not in ["menu","loading","ranking_entry"]: _draw_floor_actors()
		return
	if g.state=="ranking_entry":
		g.ranking_entry.render(self)
		return
	if g.state in ["menu","loading"]: return
	var fraction: float = g.presentation.alpha
	for item in g.items:
		if item.get("born_frame",-1)==g.frame: continue
		Supply.draw_item(self,g.art,g.presentation.position(item),g.animation,g.presentation.phase(g),Supply.released_scale(item),int(item.kind))
	# Lower-plane arrivals and protected carriers pass behind same-plane ships.
	for e in g.enemies:
		if Depth.is_below(e): _draw_enemy_actor(e)
	if not g.boss.is_empty() and not Geometry.layer(Catalog.for_actor(g.boss))=="floor":
		if g.renewed_art:
			renewal.draw_boss(self,g.stage,g.presentation.position(g.boss),g.boss)
		else: draw_texture(g.art.boss_body(g.stage),g.boss.pos+Vector2(-75,0))
	if (int(ceil(g.invulnerability_render_seconds*33.333333333333336-0.000001))%2==0):
		if g.renewed_art: pilot.draw(self,g.presentation.player(g),g.player_bank)
		else: draw_texture(g.art.sprite("picair",Rect2i(g.player_bank*50,0,50,50),Vector2i(g.player_bank*50,50)),g.presentation.player(g))

	for e in g.enemies:
		if not Depth.is_below(e): _draw_enemy_actor(e)

	for blast in g.explosions: vfx.draw_explosion(self,blast,g.presentation.position(blast))
	vfx.draw_particles(self,clampf(fraction,0,1),ParticleLayers.Layer.GENERAL)
	for e in g.enemies:
		if Catalog.definition(int(e.kind)).get("role","")=="supply" and not Depth.is_below(e):
			Supply.draw_mount(self,g.art,e,g.presentation.position(e),g.animation,g.presentation.phase(g))
	# Player weapons and enemy bullets remain above actor hulls.
	for shot in (g.shot_visuals if not g.shot_visuals.is_empty() else g.shots):
		_draw_shot(shot)
	vfx.draw_special(self,g,g.presentation.player(g),g.presentation.shield_position(g),g.presentation.phase(g))
	# Back to front: player weapons -> black smoke -> enemy bullets. HUD stays above.
	vfx.draw_particles(self,clampf(fraction,0,1),ParticleLayers.Layer.SMOKE)
	for bullet in g.bullets:
		_draw_bullet(bullet)
	BeamArt.draw(self,g.enemy_beams)
	vfx.draw_particles(self,clampf(fraction,0,1),ParticleLayers.Layer.BEAM_FOREGROUND)
	if g.slow_movement_active and g.hp>0 and g.death_remaining_seconds<=0:
		vfx.draw_player_focus(self,g.presentation.player(g),g.timeline())
	if g.death_remaining_seconds>0:
		draw_texture(g.art.sprite("picgov",Rect2i(0,0,200,30),Vector2i(0,30)),Vector2(100,230))

	_draw_hud()
	if g.banner_remaining_seconds > 0:
		if g.banner.begins_with("WARNING"):
			draw_texture(g.art.sprite("picwarn",Rect2i(0,0,250,60),Vector2i(0,60)),Vector2(75,200))
		elif not g.banner.is_empty():
			MissionBanner.draw(self,g.banner,g.banner_remaining_seconds)
	if g.state=="paused":
		draw_rect(Rect2(0,0,400,480),Color(0.01,0.02,0.05,0.7))
		_center(202,"PAUSED",28,Color(0.7,0.92,1))
		_center(278,"P: RESUME",14)
		_center(307,"ESC: TITLE",12,Color(0.65,0.75,0.85))
func _draw_floor_actors() -> void:
	var floor_boss: bool = not g.boss.is_empty() and Geometry.layer(Catalog.for_actor(g.boss))=="floor"
	var turrets: Array = []
	var boss_pieces: Array = []
	for e in g.enemies:
		if Geometry.layer(Catalog.for_actor(e))!="floor":continue
		if Ground.active(e): turrets.append(e)
		elif Geometry.layer(Catalog.for_actor(e))=="floor": boss_pieces.append(e)
	if floor_boss: boss_pieces.append(g.boss)
	var has_decoration: bool=not g.boss.is_empty() and Catalog.for_actor(g.boss).has("floor_decoration")
	if turrets.is_empty() and g.ground_wrecks.is_empty() and boss_pieces.is_empty() and not has_decoration: return
	if ground_art==null: ground_art = GroundArt.new()
	if has_decoration:ground_art.draw_floor_decoration(self,g.boss,g.presentation.position(g.boss))
	for remains in g.ground_wrecks: ground_art.draw_wreck(self,remains,g.presentation.position(remains))
	for actor in turrets: ground_art.draw_turret(self,actor,g.presentation.position(actor))
	boss_pieces.sort_custom(func(a,b):return int(Geometry.visual(Catalog.for_actor(a)).get("order",0))<int(Geometry.visual(Catalog.for_actor(b)).get("order",0)))
	for actor in boss_pieces: ground_art.draw_floor_actor(self,actor,g.presentation.position(actor))

func _draw_enemy_actor(e: Dictionary) -> void:
	if Geometry.layer(Catalog.definition(int(e.kind)))=="floor": return
	var offset: Vector2 = Catalog.definition(int(e.kind)).get("draw_offset",Vector2.ZERO)
	var pos: Vector2 = g.presentation.position(e)
	if Ground.active(e):
		if ground_art==null:ground_art=GroundArt.new()
		ground_art.draw_turret(self,e,pos)
		return
	if g.renewed_art: renewal.draw_enemy(self,e,pos,g.frame)
	else:
		var size: Vector2 = Catalog.definition(int(e.kind)).get("draw_size",Vector2(50,50))
		draw_set_transform(pos+offset+size/2,0,Vector2.ONE*Depth.scale_for(e))
		draw_texture(g.art.enemy(int(e.get("render_kind",e.kind)),e.velocity,g.animation,g.stage,e.pos.y),-size/2,Depth.tint_for(e))
		draw_set_transform(Vector2.ZERO)
	var preparation: Dictionary = Scenery.preparation(e,g.boss)
	if not preparation.is_empty():
		vfx.draw_charge(self,preparation.pos+g.presentation.position(e)-e.pos+Vector2(25,25),g.presentation.phase(g))
	if Depth.is_below(e) and Catalog.definition(int(e.kind)).get("role","")=="supply":
		Supply.draw_mount(self,g.art,e,g.presentation.position(e),g.animation,g.presentation.phase(g))

func _draw_bullet(b: Dictionary) -> void:
	vfx.draw_bullet(self,b,g.presentation.position(b),g.presentation.phase(g))

func _draw_shot(shot: Dictionary) -> void:
	var pos: Vector2 = g.presentation.position(shot)
	if shot.get("visual",{}).get("phase","")=="launch": pos += g.presentation.player(g)-g.player
	vfx.draw_shot(self,shot,g.presentation.player(g),g.run_settings.weapon,pos,g.renewed_art)

func _draw_hud() -> void:
	HUD.render(self,g.art,clampi(Weapons.vb_integer(g.hp),0,100),clampf(g.energy,0,100),g.run_settings.weapon,g.power,g.score,int(g.boss.hp) if not g.boss.is_empty() else -1,int(g.boss.get("max_hp",0)))

func _draw_menu() -> void:
	g.title.render(self,g.art,g.last_score,g.renewed_art and g.title.shows_background(),g.rankings.entries)
