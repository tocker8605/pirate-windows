extends RefCounted
## Menu samples use the actual volley/trajectory/phase renderer, with isolated visual RNG.
const Weapons = preload("res://scripts/player_weapons.gd")
const Particles = preload("res://scripts/combat_vfx.gd")
const Renewed = preload("res://scripts/renewed_art.gd")
var fx = Particles.new()
var art = Renewed.new()
class DemoRandom:
	extends RefCounted
	var rng := RandomNumberGenerator.new()
	func _init() -> void: rng.seed = 9017
	func between(low: int, high: int) -> int: return rng.randi_range(low,high)
func samples(weapon: int, player: Vector2, age: int) -> Array:
	var shots: Array = Weapons.volley(player,weapon,7,DemoRandom.new())
	for shot in shots:
		for i in range(age): Weapons.advance(shot,player)
		shot.visual = Weapons.visual(shot,player)
	return shots
func draw_small(c: Node2D, rect: Rect2, weapon: int, clock: int, selected: bool) -> void:
	var color: Color = Particles.player_color(weapon)
	c.draw_rect(rect,Color(0.015,0.035,0.06,0.95))
	c.draw_rect(rect,Color(color,0.8 if selected else 0.25),false,1)
	var t: float = fposmod(clock/4.0,5.0)/5.0
	var base: Vector2 = rect.position+Vector2(rect.size.x/2,rect.size.y-7)
	for shot in samples(weapon,base-Vector2(15,12),1):
		var center: Vector2 = Vector2(shot.pos.x+15,rect.position.y+5+(1-t)*10)
		fx.streak(c,center,Vector2.UP,12,2.2 if weapon!=3 else 3.2,color)
		fx.halo(c,center+Vector2(0,14),2.8,color,0.6*(1-t))
func draw_large(c: Node2D, original: RefCounted, rect: Rect2, weapon: int, clock: int) -> void:
	var color: Color = Particles.player_color(weapon)
	var font: Font = ThemeDB.fallback_font
	c.draw_rect(rect,Color(0.012,0.027,0.045,0.94))
	c.draw_rect(rect,Color(color,0.5),false,1)
	c.draw_string(font,rect.position+Vector2(12,20),"TYPE %d / %s"%[weapon,["","PULSE","LANCE","PLASMA"][weapon]],HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
	c.draw_string(font,rect.position+Vector2(12,36),"LIVE PREVIEW / MAX POWER",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("8499b1"))
	var pilot: Vector2 = rect.position+Vector2(rect.size.x/2-25,rect.size.y-57)
	var target: Vector2 = rect.position+Vector2(rect.size.x/2-25,41)
	art.draw_enemy(c,{"kind":1,"velocity":Vector2(0,3)},target,0)
	c.draw_texture(original.sprite("picair",Rect2i(0,0,50,50),Vector2i(0,50)),pilot)
	var age: int = int(clock%60/4)
	for shot in samples(weapon,pilot,mini(age,5)):
		if age>=5:
			shot.impact_ticks = maxi(0,9-(age-5))
			shot.visual = Weapons.visual(shot,pilot)
			if shot.impact_ticks==0: continue
		fx.draw_shot(c,shot,pilot,weapon)
		if age>=5:
			for i in range(6):
				var direction := Vector2.from_angle(i*TAU/6)
				fx.halo(c,shot.pos+Vector2(15,12)+direction*(age-4)*2,3,color,float(15-age)/10)
	fx.halo(c,pilot+Vector2(25,45),9,color,0.45)
func draw_loading(c: Node2D, original: RefCounted, clock: int) -> void:
	c.draw_texture(original.texture("loading2"),Vector2.ZERO)
	for i in range(3):
		var rect := Rect2(3+i*140,58,100,122)
		c.draw_rect(rect,Color("060f1c"))
		c.draw_string(ThemeDB.fallback_font,rect.position+Vector2(9,18),"TYPE %d"%(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Particles.player_color(i+1))
		draw_small(c,Rect2(rect.position+Vector2(7,45),Vector2(80,38)),i+1,clock,false)
