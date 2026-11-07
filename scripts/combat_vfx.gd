extends RefCounted
## Presentation-only CPU particles. Never consumes the original game's VB random stream.
const Rules = preload("res://scripts/enemy_rules.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const Pilot = preload("res://scripts/pilot_geometry.gd")
const LIMIT: int = 1500
const SMOKE_SCROLL_FACTOR: float = 1.0
const SMOKE_COLOR = Color("101216")
const CYAN = Color("61e7ff")
const MINT = Color("91ffd3")
const VIOLET = Color("c8a0ff")
const HOT = Color("ff8945")
const PINK = Color("ff608f")
var carrier_releases: Dictionary = {}
var particles: Array = []
var blasts: Array = []
var impacts: Array = []
var rng := RandomNumberGenerator.new()
var last_frame: int = -1
var last_stage: int = -1
var last_hit: float = 0
var trail_clock: float = 0
var smoke_puff: Texture2D
var fire_puff: Texture2D
var glow: Texture2D

func _init() -> void:
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
	last_frame = -1
	last_stage = -1
	last_hit = 0
	trail_clock = 0

func emit(p: Vector2, v: Vector2, life: float, size: float, color: Color, smoke: bool = false) -> void:
	if particles.size()>=LIMIT: return
	particles.append({"p":p,"v":v,"age":0.0,"life":life,"size":size,"color":color,"smoke":smoke})

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
		part.age += g.tick_units
		var flow := Vector2(0,g.scroll_speed*SMOKE_SCROLL_FACTOR) if part.smoke else Vector2.ZERO
		part.p += (part.v+flow)*g.tick_units
		part.v *= pow(0.96 if not part.smoke else 0.99,g.tick_units)
	particles = particles.filter(func(p): return p.age<p.life)
	blasts = blasts.filter(func(b): return g.explosions.has(b.source))
	for blast in g.explosions:
		if blast.get("delay",0)>0 or _blast_record(blast)!={}: continue
		blasts.append({"source":blast,"duration":35 if int(blast.ticks)>20 else 20})
		var center: Vector2 = blast.get("render_pos",blast.pos)+Vector2(25,25)
		var large: bool = int(blast.ticks)>20
		burst(center,70 if large else 40,HOT,6 if large else 4)
		for i in range(10 if large else 6):
			emit(center+Vector2(rng.randf_range(-10,10),rng.randf_range(-8,8)),Vector2(rng.randf_range(-0.6,0.6),0),32,18 if large else 13,SMOKE_COLOR,true)
	impacts = impacts.filter(func(s): return g.shots.has(s))
	for shot in g.shots:
		if int(shot.get("impact_ticks",-1))<0 or impacts.has(shot): continue
		impacts.append(shot)
		burst(shot.pos+Vector2(15,8),12,player_color(g.weapon),3.4)
	if g.hit_flash_ticks>last_hit: burst(g.player+Vector2(25,25),28,HOT,4.5)
	last_hit = g.hit_flash_ticks
	for e in g.enemies:
		if not e.get("rescued",false): continue
		var id: int = e.get("entity_id",-1)
		if not carrier_releases.has(id):
			carrier_releases[id] = true
			burst(Rules.cargo_position(e),24,Color("b6ff66"),2.8)
	for p in g.shield_contacts: burst(p,9,CYAN,2.8)
	for p in g.laser_contacts: burst(p+Vector2(15,15),3,MINT,3)
	trail_clock += g.tick_units
	if (g.tick_units==1 and g.frame%2==0) or (g.tick_units!=1 and trail_clock>=2):
		trail_clock = fposmod(trail_clock,2)
		for b in g.bullets:
			var direction: Vector2 = b.velocity.normalized()
			var missile: bool = int(b.kind)==2
			if int(b.kind)==8:
				for i in range(2): emit(b.pos-direction*4, -direction*0.6+direction.orthogonal()*rng.randf_range(-0.5,0.5),12,2.7,HOT)
			emit(b.get("render_pos",b.pos)-direction*5,-direction*0.7,9,2.5 if missile else 1.4,enemy_color(int(b.kind)))
		for s in g.shots:
			if int(s.get("impact_ticks",-1))>=0: continue
			emit(s.pos+Vector2(15,20),Vector2(rng.randf_range(-0.2,0.2),2),8,1.8,player_color(g.weapon))
		# Emit at the damaged hull; particle advection now creates the history trail.
		if g.render_hp<40: emit_smoke(g.player+Pilot.visual_point(Vector2(25,40)),13)
		for e in g.enemies:
			if e.hp>=Rules.SMOKE.get(int(e.kind),0): continue
			var size: float = 16 if e.kind>20 and e.kind<100 else 12
			emit_smoke(e.pos+Vector2(25,25),size)
			if e.kind>20 and e.kind<100: emit_smoke(e.pos+Vector2(60,35),size)
			if e.kind>40 and e.kind<100: emit_smoke(e.pos+Vector2(-25,35),size)
		if not g.boss.is_empty() and boss_smoking(g.boss):
			for offset in [Vector2(-35,55),Vector2(0,45),Vector2(35,55)]:
				emit_smoke(g.boss.pos+offset,16)
		if g.death_ticks==0:
			for x in [17,33]: emit(g.player+Pilot.visual_point(Vector2(x,43)),Vector2(0,2.5),6,2.8,CYAN)

static func boss_smoking(b: Dictionary) -> bool:
	return b.get("max_hp",0)>0 and b.hp>0 and b.hp<float(b.max_hp)*0.4

func emit_smoke(pos: Vector2, size: float) -> void:
	for i in range(2):
		emit(pos+Vector2(rng.randf_range(-3,3),rng.randf_range(-2,2)),Vector2(rng.randf_range(-0.4,0.4),0),28,size*rng.randf_range(0.9,1.1),SMOKE_COLOR,true)

static func player_color(weapon: int) -> Color:
	return [CYAN,CYAN,VIOLET,MINT][clampi(weapon,1,3)]
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

func draw_particles(c: Node2D, fraction: float = 0, layer: int = 0) -> void:
	for part in particles:
		if (layer==1 and not part.smoke) or (layer==2 and part.smoke): continue
		var t: float = part.age/part.life
		var opacity: float = pow(1-t,0.7)*0.92 if part.smoke else (1-t)*0.85
		var p: Vector2 = part.get("previous_pos",part.p).lerp(part.p,fraction)
		if part.smoke:
			var radius: float = part.size*(1+t*1.1)
			c.draw_texture_rect(smoke_puff,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(part.color,opacity))
		else:
			halo(c,p,part.size*3,part.color,opacity*0.65)
			c.draw_line(p-part.v*1.7,p,Color(part.color,opacity),maxf(0.6,part.size*(1-t)),true)

func draw_bullet(c: Node2D, b: Dictionary, position: Variant = null, phase: float = 0) -> void:
	var p: Vector2 = position if position!=null else b.get("render_pos",b.pos)
	var v: Vector2 = b.get("render_velocity",b.velocity)
	var kind: int = int(b.kind)
	if kind==3 and v.y<=0: return
	var direction: Vector2 = v.normalized() if v.length_squared()>0 else Vector2.DOWN
	var color: Color = enemy_color(kind)
	if kind==8:
		draw_fireball(c,p,direction,phase+p.x*0.17)
	elif kind==2:
		streak(c,p-direction*5,-direction,12,3,HOT)
		c.draw_line(p-direction*5,p+direction*5,Color("e1e5ee"),3,true)
		c.draw_line(p-direction.rotated(PI/2)*3,p+direction.rotated(PI/2)*3,color,1,true)
	elif kind==3:
		streak(c,p,direction,19,3,color)
	elif kind in [4,5]:
		var radius: float = 4.5 if kind==4 else 3.2
		halo(c,p,radius*3,color,0.85)
		c.draw_circle(p,radius,color,true,-1,true)
		c.draw_circle(p,radius*0.5,Color("fff4e6"),true,-1,true)
	else: streak(c,p,direction,6 if kind==1 else 10,2.2,color)

func draw_fireball(c: Node2D, p: Vector2, direction: Vector2, phase: float) -> void:
	var tail: Vector2 = -direction
	var side: Vector2 = direction.orthogonal()
	var flicker: float = sin(phase*0.9)
	halo(c,p,18,HOT,0.65)
	# Three animated tongues follow the instantaneous parabolic velocity, not a metal missile body.
	for i in range(3):
		var offset: float = (i-1)*3.0
		var length: float = 16+sin(phase*0.7+i*2)*5
		var base: Vector2 = p+side*offset
		var tip: Vector2 = base+tail*length+side*sin(phase+i)*3
		c.draw_colored_polygon(PackedVector2Array([base+side*3,tip,base-side*3]),Color(1,0.22+0.1*i,0.02,0.75))
	c.draw_circle(p,5.5,Color("ff571c"),true,-1,true)
	c.draw_colored_polygon(PackedVector2Array([p+direction*4,p+side*3,p+tail*(12+flicker*2),p-side*3]),Color("ffc13b"))
	c.draw_circle(p+tail,2.8,Color("fff2ad"),true,-1,true)

func draw_shot(c: Node2D, shot: Dictionary, player: Vector2, weapon: int, position: Variant = null) -> void:
	var visual: Dictionary = shot.get("visual",Weapons.visual(shot,player))
	var p: Vector2 = (position if position!=null else shot.pos)+Vector2(15,12)
	var color: Color = player_color(weapon)
	if visual.phase=="impact":
		var t: float = clampf(float(shot.get("impact_ticks",0))/9,0,1)
		halo(c,p,12+t*11,color,t*0.7)
		c.draw_arc(p,3+(1-t)*17,0,TAU,32,Color(color,t*0.7),1.2,true)
	else:
		streak(c,p,Vector2.UP,19 if weapon!=3 else 11,2.6 if weapon!=3 else 4,color)
		if visual.phase=="launch": halo(c,p+Vector2(0,9),13,color,0.9)

func _blast_record(blast: Dictionary) -> Dictionary:
	for record in blasts:
		if record.source==blast: return record
	return {}

func draw_explosion(c: Node2D, blast: Dictionary, position: Variant = null) -> void:
	if blast.get("delay",0)>0: return
	var ticks: float = float(blast.get("render_ticks",0))
	if ticks<=0: return
	var record: Dictionary = _blast_record(blast)
	var large: bool = int(record.get("duration",35 if ticks>20 else 20))>20
	var duration: float = 35 if large else 20
	var age: float = duration-ticks
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

func draw_special(c: Node2D, g: Node, player: Variant = null, shield: Variant = null, phase: float = -1) -> void:
	var ship: Vector2 = g.player if player==null else player
	var shield_pos: Vector2 = g.shield_center if shield==null else shield
	var time: float = g.timeline() if phase<0 else phase
	var ticks: float = g.laser_render_ticks
	if ticks>0:
		var intensity: float = minf(1,float(ticks)/4)
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
	if g.shield_render_ticks>0:
		var remaining: float = g.shield_render_ticks
		var fade: float = minf(1,float(remaining)/25)*minf(1,float(201-remaining)/3)
		var p: Vector2 = shield_pos
		halo(c,p,49,CYAN,0.15*fade)
		c.draw_arc(p,40,0,TAU,96,Color(CYAN,fade*0.6),1.4,true)
		for i in range(6):
			var angle: float = time*0.04+i*TAU/6
			c.draw_arc(p,37,angle,angle+0.42,12,Color(MINT,fade),2,true)
		for i in range(18):
			var angle: float = i*TAU/18-time*0.025
			halo(c,p+Vector2.from_angle(angle)*40,3,CYAN,fade*0.7)
	for point in g.laser_contacts: halo(c,point+Vector2(15+ship.x-g.player.x,15),19,MINT)
	for point in g.shield_contacts: halo(c,point,17,CYAN)
	if g.hit_flash_render_ticks>0:
		var opacity: float = float(g.hit_flash_render_ticks)/19
		halo(c,ship+Vector2(25,25),28,HOT,opacity*0.6)
