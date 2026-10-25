extends Node2D
## Rendering consumes game state; input, simulation and audio live elsewhere.
const Weapons = preload("res://scripts/player_weapons.gd")
const HUD = preload("res://scripts/hud.gd")
const Effects = preload("res://scripts/special_effects.gd")
const Scenery = preload("res://scripts/scenery.gd")
const WorldEffects = preload("res://scripts/world_effects.gd")
var g: Node
var foreground_only: bool = false
var cloud_nodes: Array = []
var foreground: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if foreground_only: return
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
	add_child(foreground)
	refresh()

func refresh() -> void:
	if not foreground_only:
		var in_game: bool = g.state not in ["menu","loading"]
		for i in range(cloud_nodes.size()):
			cloud_nodes[i].visible = in_game
			if in_game:
				cloud_nodes[i].texture = g.art.texture(["","cl03","cl02","cl01","cl01"][g.stage])
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
		elif g.state=="loading": draw_texture(g.art.texture(g.loading_image),Vector2.ZERO)
		else: draw_texture_rect_region(g.art.texture("stage%d"%g.stage),Rect2(0,0,400,480),Rect2(0,g.background_y,400,480))
		return
	if g.state in ["menu","loading"]: return
	for item in g.items:
		if item.get("born_frame",-1)==g.frame: continue
		var y: int = 260 if item.kind == 1 else 320
		draw_texture(g.art.sprite("eweapons",Rect2i(g.animation*20,y,20,30),Vector2i(g.animation*20,y+30)),item.get("render_pos",item.pos)-Vector2(10,15))
	for bullet in g.bullets:
		_draw_bullet(bullet)
	if not g.boss.is_empty():
		draw_texture(g.art.sprite("boss%02d"%g.stage,Rect2i(0,0,150,100),Vector2i(0,100)),g.boss.pos+Vector2(-75,0))
	if g.state != "dead" and (g.invulnerable_render_ticks%2==0):
		draw_texture(g.art.sprite("picair",Rect2i(g.player_bank*50,0,50,50),Vector2i(g.player_bank*50,50)),g.player)
	if g.render_hp<40: _commands(WorldEffects.player_smoke(g.player,g.animation,g.scroll_speed))
	for e in (g.enemy_visuals if not g.enemy_visuals.is_empty() else g.enemies):
		var offset := Vector2.ZERO
		if e.kind in [21,22]: offset = Vector2(-25,-45 if e.kind==22 else -25)
		if e.kind in [41,42]: offset = Vector2(-50,-25)
		if int(e.kind) in [111,112,121,122,131,132]: offset = Vector2(0,-50)
		if e.kind==133: offset = Vector2(0,-15)
		draw_texture(g.art.enemy(int(e.get("render_kind",e.kind)),e.velocity,g.animation,g.stage,e.pos.y),e.pos+offset)
		var preparation: Dictionary = Scenery.preparation(e,g.boss)
		if not preparation.is_empty():
			draw_texture(g.art.sprite("enemy_mid",preparation.rect,preparation.mask),preparation.pos)
		_commands(WorldEffects.enemy_smoke(e,g.animation,g.scroll_speed))

	for blast in g.explosions: _commands(WorldEffects.explosion(blast,g.scroll_speed))
	for shot in (g.shot_visuals if not g.shot_visuals.is_empty() else g.shots):
		_draw_shot(shot)
	Effects.render(self,g.art,g.player,g.laser_render_ticks,g.shield_center,g.shield_render_ticks,g.laser_contacts,g.shield_contacts)
	for e in g.enemies:
		if int(e.kind) in [19,201]:
			draw_texture(g.art.sprite("enemy_sm",Rect2i(2550,0,50,50),Vector2i(2550,50)),e.pos)
	if g.death_ticks>0:
		draw_texture(g.art.sprite("picgov",Rect2i(0,0,200,30),Vector2i(0,30)),Vector2(100,230))
	_commands(WorldEffects.hit_flash(g.player,g.hit_flash_render_ticks))
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
	var p: Vector2 = b.get("render_pos",b.pos)
	var v: Vector2 = b.get("render_velocity",b.velocity)
	var rect := Rect2i(0,0,10,10)
	var mask := Vector2i(0,10)
	var offset := Vector2(-5,-5)
	match int(b.kind):
		2,8:
			var tall: bool = int(b.kind)==2
			var trail_y: int = 15 if tall else 10
			draw_texture(g.art.sprite("eweapons",Rect2i(60,80,20,20),Vector2i(40,80)),_pixel(p-Vector2(10+v.x*2,trail_y+v.y*2)))
			draw_texture(g.art.sprite("eweapons",Rect2i(23,83,14,14),Vector2i(3,83)),_pixel(p-Vector2(7+v.x*2,trail_y-3+v.y)))
			rect = Rect2i(g.animation*20,20 if tall else 180,20,30 if tall else 20)
			mask = Vector2i(g.animation*20,50 if tall else 200)
			offset = Vector2(-10,-15 if tall else -10)
		3:
			if v.y<=0: return
			rect = Rect2i(50,0,30,10)
			mask = Vector2i(50,10)
			offset = Vector2(-15,0)
		4:
			rect = Rect2i(0,220,20,20)
			mask = Vector2i(0,240)
			offset = Vector2(-10,-10)
		5:
			rect = Rect2i(g.animation*20,100,20,20)
			mask = Vector2i(g.animation*20,120)
			offset = Vector2(-10,-10)
		6,7:
			var x: int = 40 if int(b.kind)==6 else 0
			draw_texture(g.art.sprite("eweapons",Rect2i(x+24,144,12,12),Vector2i(x+24,164)),_pixel(p-Vector2(6,6)-v))
			rect = Rect2i(x,140,20,20)
			mask = Vector2i(x,160)
			offset = Vector2(-10,-10)
	draw_texture(g.art.sprite("eweapons",rect,mask),_pixel(p+offset))


func _pixel(pos: Vector2) -> Vector2:
	return Vector2(Weapons.vb_integer(pos.x),Weapons.vb_integer(pos.y))


func _draw_shot(shot: Dictionary) -> void:
	var visual: Dictionary = shot.get("visual",Weapons.visual(shot,g.player))
	draw_texture(g.art.sprite("weapon%d" % g.weapon,visual.rect,visual.mask),_pixel(shot.pos+visual.offset))


func _draw_hud() -> void:
	HUD.render(self,g.art,clampi(Weapons.vb_integer(g.hp),0,100),clampf(g.energy,0,100),g.weapon,g.power,g.score,int(g.boss.hp) if not g.boss.is_empty() else -1,int(g.boss.get("max_hp",1000)))


func _draw_menu() -> void:
	g.title.render(self,g.art,g.last_score)


func _commands(commands: Array) -> void:
	for command in commands:
		draw_texture(g.art.sprite(command.sheet,command.rect,command.mask),_pixel(command.pos))
