extends RefCounted
## Presentation-only CPU particles. Never consumes the original game's VB random stream.
const BeamMuzzle=preload("res://scripts/beam_muzzle_effect.gd")
const ParticleLayers=preload("res://scripts/particle_layers.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const PlayerStyle = preload("res://scripts/player_weapon_style.gd")
const PlayerShotArt = preload("res://scripts/player_shot_art.gd")
const OriginalArt = preload("res://scripts/art.gd")
const ProjectileFrames = preload("res://scripts/projectile_frames.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Supply = preload("res://scripts/supply_visual.gd")
const Rules = preload("res://scripts/enemy_rules.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const LIMIT: int = 1500
const PROJECTILE_TRAIL_PERIOD: float = 0.12
# Tail displacement is velocity(px/s) times exposure(s), independent of FPS.
const PARTICLE_STREAK_SECONDS: float = 0.051
const SMOKE_SIZE_SCALE: float = 0.8
const SMOKE_SCROLL_FACTOR: float = 1.0
const SMOKE_COLOR = Color("101216")
const CYAN = Color("61e7ff")
const MINT = Color("91ffd3")
const VIOLET = Color("c8a0ff")
const PLAYER_COLORS = PlayerStyle.BASE
const HOT = Color("ff8945")
const PINK = Color("ff608f")
var player_art = PlayerShotArt.new()
var original_player_art = OriginalArt.new()
var carrier_releases: Dictionary = {}
var particles: Array = []
var blasts: Array = []
var impacts: Dictionary = {}
var launches: Dictionary = {}
var rng := RandomNumberGenerator.new()
var last_frame: int = -1
var last_stage: int = -1
var last_hit: float = 0
var trail_clock: float = 0
var projectile_trail_clock: float = 0
var beam_muzzle=BeamMuzzle.new()
var smoke_puff: Texture2D
var fire_puff: Texture2D
var glow: Texture2D

func _init() -> void:
	ProjectileFrames.warm()
	rng.seed = 863502
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	var smoke_image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	var fire_image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var radius: float = Vector2(x-31.5,y-31.5).length()/31.5
			var alpha: float = pow(maxf(0,1-radius),2.5)
			image.set_pixel(x,y,Color(1,1,1,alpha))
			var angle: float = atan2(y-31.5,x-31.5)
			var edge: float = 1+0.07*sin(angle*5)+0.04*cos(angle*9)
			smoke_image.set_pixel(x,y,Color(1,1,1,1-smoothstep(0.4,1.0,radius/edge)))
			fire_image.set_pixel(x,y,Color(1,1,1,pow(maxf(0,1-radius*radius),1.1)))
	glow = ImageTexture.create_from_image(image)
	smoke_puff = ImageTexture.create_from_image(smoke_image)
	fire_puff = ImageTexture.create_from_image(fire_image)

func reset() -> void:
	carrier_releases.clear()
	particles.clear()
	blasts.clear()
	impacts.clear()
	launches.clear()
	last_frame = -1
	last_stage = -1
	last_hit = 0
	trail_clock = 0
	projectile_trail_clock = 0
	beam_muzzle.reset()

func emit(p: Vector2, v: Vector2, life: float, size: float, color: Color, smoke: bool = false) -> void:
	if particles.size()>=LIMIT: return
	particles.append({"p":p,"v":v*33.333333333333336,"age":0.0,"life":life*0.03,"size":size,"color":color,"smoke":smoke})

func burst(p: Vector2, count: int, color: Color, force: float = 4.0) -> void:
	for i in range(count):
		var direction := Vector2.from_angle(rng.randf()*TAU)
		emit(p+direction*rng.randf_range(0,3),direction*rng.randf_range(force*0.25,force),rng.randf_range(8,22),rng.randf_range(1.0,2.8),color)

func observe(g: Node) -> void:
	if g.state in ["menu","loading"]:
		reset()
		return
	if last_stage!=g.stage or g.frame<last_frame: reset()
	if last_frame==g.frame: return
	last_stage = g.stage
	last_frame = g.frame
	for part in particles:
		part.previous_pos = part.p
		part.age += g.delta_seconds
		var flow := Vector2(0,g.scroll_speed*SMOKE_SCROLL_FACTOR) if part.smoke else Vector2.ZERO
		part.p += (part.v+flow)*g.delta_seconds
		part.v *= pow(0.96 if not part.smoke else 0.99,g.delta_seconds*33.333333333333336)
	particles = particles.filter(func(p): return p.age<p.life)
	emit_enemy_beam_sources(g.enemy_beams,g.delta_seconds)
	blasts = blasts.filter(func(b): return g.explosions.has(b.source))
	for blast in g.explosions:
		if blast.get("delay_seconds",0)>0 or _blast_record(blast)!={}: continue
		blasts.append({"source":blast,"duration":1.05 if blast.remaining_seconds>0.6 else 0.6})
		var center: Vector2 = blast.get("render_pos",blast.pos)+Vector2(25,25)
		var large: bool = blast.remaining_seconds>0.6
		burst(center,70 if large else 40,HOT,6 if large else 4)
		for i in range(10 if large else 6):
			emit(center+Vector2(rng.randf_range(-10,10),rng.randf_range(-8,8)),Vector2(rng.randf_range(-0.6,0.6),0),32,18 if large else 13,SMOKE_COLOR,true)
	for id in impacts.keys():
		if not g.shots.contains(id): impacts.erase(id)
	for id in launches.keys():
		if not g.shots.contains(id): launches.erase(id)
	for shot in g.shots:
		var id: int = shot.entity_id
		if shot.has("launch_pos") and not launches.has(id):
			launches[id] = true
			for x in PlayerStyle.PORTS[clampi(g.run_settings.weapon,1,3)-1]:
				player_sparks(shot.launch_pos+Vector2(15+x,24),g.run_settings.weapon,false)
		if float(shot.get("impact_remaining_seconds",-1))<0 or impacts.has(id): continue
		impacts[id] = true
		player_sparks(shot.pos+Vector2(15,8),g.run_settings.weapon,true)
	if g.hit_flash_remaining_seconds>last_hit: burst(g.player+Vector2(25,25),28,HOT,4.5)
	last_hit = g.hit_flash_remaining_seconds
	for e in g.enemies:
		if not e.get("rescued",false): continue
		var id: int = e.get("entity_id",-1)
		if not carrier_releases.has(id):
			carrier_releases[id] = true
			burst(Rules.cargo_position(e),24,Supply.cargo_color(Rules.cargo_item(e)),2.8)
	for p in g.shield_contacts: burst(p,9,CYAN,2.8)
	for p in g.laser_contacts: burst(p+Vector2(15,15),3,MINT,3)
	# Projectile tails have their own reduced cadence. Damage smoke and engines
	# keep the original60ms emission rhythm independently.
	projectile_trail_clock += g.delta_seconds
	if projectile_trail_clock>=PROJECTILE_TRAIL_PERIOD-0.00000003:
		projectile_trail_clock = fposmod(projectile_trail_clock,PROJECTILE_TRAIL_PERIOD)
		for b in g.bullets:
			var direction: Vector2 = b.velocity.normalized()
			var kind: int = int(b.kind)
			if kind==8:
				# One ember instead of two flame particles PLUS the generic third trail.
				emit(b.pos-direction*4,-direction*0.6+direction.orthogonal()*rng.randf_range(-0.5,0.5),12,2.7,HOT)
			else:
				emit(b.get("render_pos",b.pos)-direction*5,-direction*0.7,9,2.5 if kind==2 else 1.4,enemy_color(kind))
		for shot in g.shots:
			if float(shot.get("impact_remaining_seconds",-1))>=0: continue
			for x in PlayerStyle.PORTS[clampi(g.run_settings.weapon,1,3)-1]:
				emit(shot.pos+Vector2(15+x,28),Vector2(rng.randf_range(-0.2,0.2),2),8,0.8,player_color(g.run_settings.weapon))
	trail_clock += g.delta_seconds
	if trail_clock>=0.06-0.00000003:
		trail_clock = fposmod(trail_clock,0.06)
		# Emit at the damaged hull; particle advection now creates the history trail.
		if g.render_hp<40: emit_smoke(g.player+Pilot.visual_point(Vector2(25,40)),13)
		for e in g.enemies:
			emit_actor_smoke(e)
		if not g.boss.is_empty(): emit_actor_smoke(g.boss)
		if g.death_remaining_seconds==0:
			for x in [17,33]: emit(g.player+Pilot.visual_point(Vector2(x,43)),Vector2(0,2.5),6,2.8,CYAN)

func player_sparks(pos: Vector2, weapon: int, impact: bool) -> void:
	var count: int = 13 if impact else 4
	for i in range(count):
		var core: bool = impact and i==0
		var direction: Vector2 = Vector2.from_angle((i-1)*TAU/12+rng.randf_range(-0.12,0.12)) if impact else Vector2(rng.randf_range(-0.6,0.6),-1).normalized()
		var color: Color = PlayerStyle.highlight(weapon) if i==0 or (impact and i%3==0) else player_color(weapon)
		if core: color = PlayerStyle.highlight(weapon).lightened(0.65)
		var before: int = particles.size()
		if core:
			# A short, bright particle core makes contact readable over detailed hulls.
			emit(pos,Vector2.ZERO,3,3,color)
		else:
			emit(pos,direction*rng.randf_range(2.0 if impact else 0.6,4.0 if impact else 1.4),rng.randf_range(5 if impact else 3,8 if impact else 5),rng.randf_range(1.2 if impact else 0.7,2.0 if impact else 1.1),color)
		if particles.size()==before: break
		particles[-1].player_effect = "impact" if impact else "launch"
		if core: particles[-1].impact_core = true

static func boss_smoking(b: Dictionary) -> bool:
	return b.get("max_hp",0)>0 and Catalog.smoking(b)

func emit_actor_smoke(actor: Dictionary) -> void:
	if not Catalog.smoking(actor): return
	var settings: Dictionary = Catalog.smoke_settings(actor)
	for offset in settings.ports: emit_smoke(Geometry.world_point(actor,offset),float(settings.size))

func emit_smoke(pos: Vector2, size: float) -> void:
	for i in range(2):
		emit(pos+Vector2(rng.randf_range(-3,3),rng.randf_range(-2,2)),Vector2(rng.randf_range(-0.4,0.4),0),28,size*rng.randf_range(0.9,1.1),SMOKE_COLOR,true)

static func player_color(weapon: int) -> Color:
	return PLAYER_COLORS[clampi(weapon,1,3)-1]
static func enemy_color(kind: int) -> Color:
	return PINK if kind in [4,5,6,7] else HOT

func halo(c: Node2D, p: Vector2, radius: float, color: Color, opacity: float = 1.0) -> void:
	c.draw_texture_rect(glow,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(color,opacity))
func flare(c: Node2D, p: Vector2, radius: float, color: Color, opacity: float = 1.0) -> void:
	c.draw_texture_rect(fire_puff,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(color,opacity))
func streak(c: Node2D, p: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	halo(c,p,width*3,color,0.65)
	c.draw_line(p-direction*length,p,color,width,true)
	c.draw_line(p-direction*length*0.7,p,Color("fff6ec"),maxf(0.7,width*0.36),true)

func draw_particles(c: Node2D, fraction: float = 0, layer: int = ParticleLayers.Layer.ALL) -> void:
	if ParticleLayers.shows_smoke(layer):
		for part in particles:
			if not part.smoke: continue
			var t: float = part.age/part.life
			var p: Vector2 = part.get("previous_pos",part.p).lerp(part.p,fraction)
			var radius: float = part.size*SMOKE_SIZE_SCALE*(1+t*1.1)
			c.draw_texture_rect(smoke_puff,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(part.color,pow(1-t,0.7)*0.92))
	if layer==ParticleLayers.Layer.SMOKE:return
	# Keep all textured glows together, then all line geometry together. Alternating
	# a glow texture with a line per particle broke the CanvasItem batching each time.
	var batch: Array=ParticleLayers.select_non_smoke(particles,layer)
	for part in batch:
		var t: float = part.age/part.life
		var p: Vector2 = part.get("previous_pos",part.p).lerp(part.p,fraction)
		var hit: bool = part.get("player_effect","")=="impact"
		var fade: float = pow(1-t,0.65) if hit else 1-t
		halo(c,p,part.size*float(part.get("halo_scale",3)),part.color,fade*(0.85 if hit else 0.85*0.65))
	var beam_cores: Array=[]
	for part in batch:
		var t: float = part.age/part.life
		var p: Vector2 = part.get("previous_pos",part.p).lerp(part.p,fraction)
		var hit: bool = part.get("player_effect","")=="impact"
		var opacity: float = pow(1-t,0.65) if hit else (1-t)*0.85
		if part.get("enemy_beam_core",false):
			beam_cores.append(part)
		elif part.get("impact_core",false):
			c.draw_circle(p,part.size*(1-t*0.5)*0.8,Color(part.color,opacity),true,-1,true)
		else:
			c.draw_line(p-part.v*PARTICLE_STREAK_SECONDS,p,Color(part.color,opacity),maxf(0.6,part.size*(1-t)),true)

	beam_muzzle.draw_cores(c,beam_cores,fraction)

func draw_bullet(c: Node2D, b: Dictionary, position: Variant = null, phase: float = 0) -> void:
	var p: Vector2 = position if position!=null else b.get("render_pos",b.pos)
	var v: Vector2 = b.get("render_velocity",b.velocity)
	var kind: int = int(b.kind)
	var direction: Vector2 = v.normalized() if v.length_squared()>0 else Vector2.DOWN
	if kind==8:
		draw_fireball(c,p,direction,phase+p.x*0.17)
	elif kind in [4,5]: ProjectileFrames.draw_plasma(c,p,kind)
	else: ProjectileFrames.draw_streak(c,p,direction,kind)

func draw_fireball(c: Node2D,p: Vector2,direction: Vector2,phase: float) -> void:
	ProjectileFrames.draw(c,p,direction,phase)

func draw_shot(c: Node2D, shot: Dictionary, player: Vector2, weapon: int, position: Variant = null, renewed: bool = true) -> void:
	if renewed:
		player_art.draw(c,shot,player,weapon,position)
	else:
		var visual: Dictionary = shot.visual if shot.has("visual") else Weapons.visual(shot,player)
		var pos: Vector2 = position if position!=null else shot.pos
		c.draw_texture(original_player_art.sprite("weapon%d"%weapon,visual.rect,visual.mask),pos+visual.offset)

func _blast_record(blast: Dictionary) -> Dictionary:
	for record in blasts:
		if record.source==blast: return record
	return {}

func draw_explosion(c: Node2D, blast: Dictionary, position: Variant = null) -> void:
	if blast.get("delay_seconds",0)>0: return
	var ticks: float = float(blast.get("render_remaining_seconds",0))
	if ticks<=0: return
	var record: Dictionary = _blast_record(blast)
	var large: bool = float(record.get("duration",1.05 if ticks>0.6 else 0.6))>0.6
	var duration: float = 1.05 if large else 0.6
	var age: float = (duration-ticks)*33.333333333333336
	var p: Vector2 = (position if position!=null else blast.get("render_pos",blast.pos))+Vector2(25,25)
	var fade: float = clampf(ticks/duration,0,1)
	var radius: float = (30 if large else 21)+age*1.45
	flare(c,p,radius*1.4,HOT,fade*0.85)
	flare(c,p,radius*0.95,Color("ffca66"),fade)
	# Uneven incandescent lobes keep the blast organic rather than a wireframe circle.
	var heat: float = pow(fade,0.8)
	for i in range(7):
		var angle: float = i*TAU/7+sin(p.x+i)*0.6
		var lobe := p+Vector2.from_angle(angle)*(radius*0.34+sin(i*2+age*0.2)*3)
		flare(c,lobe,radius*0.64,HOT,heat)
		flare(c,lobe,radius*0.34,Color("ffe3a1"),heat)
	flare(c,p,radius*0.46,Color("fff4c7"),heat)
	c.draw_arc(p,radius,0,TAU,64,Color(HOT,fade*0.8),2.2,true)
	if age<8: c.draw_circle(p,maxf(1,11-age*0.8),Color(1,0.98,0.87,heat*0.9),true,-1,true)

func draw_charge(c: Node2D, p: Vector2, frame: float) -> void:
	halo(c,p,18,PINK,0.7)
	for i in range(9):
		var angle: float = frame*0.16+i*TAU/9
		var orbit := p+Vector2.from_angle(angle)*(9+sin(frame*0.12)*3)
		halo(c,orbit,4,PINK,0.8)
	c.draw_arc(p,7,0,TAU,32,Color("ffe5ff"),1,true)

func _draw_shield_lifetime(c: Node2D, center: Vector2, remaining: float, phase: float, deployment: float) -> void:
	var ratio: float = clampf(remaining/6.0,0,1)
	var color: Color = CYAN
	var opacity: float = deployment
	if remaining<=1.5: color = Color("ffd16b")
	if remaining<=0.5:
		color = Color("ff6978")
		# Pulse the gauge only; the defensive field keeps its size and visibility.
		opacity *= 0.7+0.3*sin(phase*0.03*TAU*4.0)
	c.draw_arc(center,37,0,TAU,96,Color("132933"),1.5,true)
	if ratio<=0: return
	var start: float = -PI/2+(1-ratio)*TAU
	var end: float = TAU-PI/2
	c.draw_arc(center,37,start,end,96,Color(color,opacity*0.16),3,true)
	c.draw_arc(center,37,start,end,96,Color(color,opacity),1.4,true)
	c.draw_circle(center+Vector2.from_angle(start)*37,1,Color(color,opacity),true,-1,true)

func draw_player_focus(c: Node2D, player: Vector2, seconds: float) -> void:
	var center: Vector2 = player+Pilot.COCKPIT
	var pulse: float = 0.5+0.5*sin(seconds*TAU*3)
	var color := Color("b9edff")
	halo(c,center,7,color,0.25+0.2*pulse)
	c.draw_circle(center,2.2,Color(0.02,0.08,0.14,0.9),true,-1,true)
	c.draw_arc(center,Pilot.HIT_RADIUS,0,TAU,32,Color(color,0.65+0.35*pulse),0.8,true)
	c.draw_circle(center,1.2,Color(1,1,1,0.7+0.3*pulse),true,-1,true)

func draw_special(c: Node2D, g: Node, player: Variant = null, shield_position: Variant = null, phase: float = -1) -> void:
	var ship: Vector2 = g.player if player==null else player
	var shield_pos: Vector2 = g.shield_center if shield_position==null else shield_position
	var time: float = g.timeline()*33.333333333333336 if phase<0 else phase
	var ticks: float = g.beam_render_seconds
	if ticks>0:
		var intensity: float = minf(1,float(ticks)/0.12)
		var base: Vector2 = ship+Vector2(25,9)
		var top := Vector2(base.x,-10)
		c.draw_line(base,top,Color(CYAN,0.08*intensity),28,true)
		c.draw_line(base,top,Color(CYAN,0.32*intensity),12,true)
		c.draw_line(base,top,Color(MINT,0.9*intensity),5,true)
		c.draw_line(base,top,Color(1,1,1,intensity),1.7,true)
		halo(c,base,26,CYAN,intensity)
		for i in range(16):
			var p := Vector2(base.x+sin(i*2+time)*8,fposmod(i*31-time*9,480))
			halo(c,p,3,CYAN,intensity*0.6)
	if g.shield_remaining_seconds>0:
		# Read the post-interception lifetime so blocked bullets immediately drain the rim.
		var remaining: float = g.shield_remaining_seconds
		var fade: float = clampf((6.03-remaining)/0.09,0,1)
		var field_opacity: float = fade*(0.4 if remaining<=0.5 else (0.7 if remaining<=1.5 else 1.0))
		var p: Vector2 = shield_pos
		halo(c,p,49,CYAN,0.15*field_opacity)
		c.draw_arc(p,40,0,TAU,96,Color(CYAN,field_opacity*0.6),1.4,true)
		for i in range(18):
			var angle: float = i*TAU/18-time*0.025
			halo(c,p+Vector2.from_angle(angle)*40,3,CYAN,field_opacity*0.7)
		_draw_shield_lifetime(c,p,remaining,time,fade)
	for point in g.laser_contacts: halo(c,point+Vector2(15+ship.x-g.player.x,15),19,MINT)
	for point in g.shield_contacts: halo(c,point,17,CYAN)
	if g.hit_flash_render_seconds>0:
		var opacity: float = float(g.hit_flash_render_seconds)/0.57
		halo(c,ship+Vector2(25,25),28,HOT,opacity*0.6)

func emit_enemy_beam_sources(segments: Array,seconds: float) -> void:
	beam_muzzle.advance(segments,seconds,self)
