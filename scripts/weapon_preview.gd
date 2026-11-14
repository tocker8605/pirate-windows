extends RefCounted
## Both legend sizes plot real native-tick trajectories using isolated visual RNG.
const Weapons = preload("res://scripts/player_weapons.gd")
const Clock = preload("res://scripts/timing.gd")
const Particles = preload("res://scripts/combat_vfx.gd")
const Pilot = preload("res://scripts/pilot_art.gd")
const TRACE_TICKS: int = 36
var pilot_art = Pilot.new()
var fx = Particles.new()
var path_cache: Dictionary = {}
class DemoRandom:
	extends RefCounted
	var rng := RandomNumberGenerator.new()
	func _init() -> void: rng.seed = 1119
	func between(low: int, high: int) -> int: return rng.randi_range(low,high)
func samples(weapon: int, player: Vector2, age: int) -> Array:
	var shots: Array = Weapons.volley(player,weapon,7,DemoRandom.new())
	for shot in shots:
		for i in range(age): Weapons.advance(shot,player,0.03)
		shot.visual = Weapons.visual(shot,player)
	return shots
func trajectory_paths(weapon: int, power: int = 7) -> Array:
	var key: String = "%d:%d"%[weapon,power]
	if not path_cache.has(key):
		var result: Array = []
		for shot in Weapons.volley(Vector2.ZERO,weapon,power,DemoRandom.new()):
			var points := PackedVector2Array([shot.pos+Vector2(15,12)])
			for i in range(TRACE_TICKS):
				Weapons.advance(shot,Vector2.ZERO,Clock.FIXED_STEP_SECONDS)
				points.append(shot.pos+Vector2(15,12))
			result.append({"kind":int(shot.kind),"points":points})
		path_cache[key] = result
	return path_cache[key]
static func displayed_power(clock: int) -> int:
	return 4 if int(clock/100)%2==0 else 7
func _draw_paths(c: Node2D, weapon: int, power: int, origin: Vector2, scale: Vector2, clock: int, small: bool) -> void:
	var color: Color = Particles.player_color(weapon)
	var age: int = mini(int(clock*1.5)%(TRACE_TICKS+12),TRACE_TICKS)
	for path in trajectory_paths(weapon,power):
		var points := PackedVector2Array()
		for point in path.points: points.append(origin+(point-Vector2(25,0))*scale)
		c.draw_polyline(points,Color(color,0.34),0.7 if small else 1.0,true)
		# Every dot represents the same six native simulation ticks.
		for i in range(0,points.size(),6):
			c.draw_circle(points[i],0.8 if small else 1.35,Color(color,0.7),true,-1,true)
		var direction: Vector2 = (points[-1]-points[-2]).normalized()
		var side := direction.orthogonal()
		var arrow_size: float = 2.3 if small else 3.5
		for sign_x in [-1,1]: c.draw_line(points[-1],points[-1]-direction*arrow_size+side*arrow_size*0.6*sign_x,Color(color,0.85),0.8,true)
		var motion: Vector2 = (points[maxi(1,age)]-points[maxi(0,age-1)]).normalized()
		fx.streak(c,points[age],motion,3.0 if small else 6.0,1.2 if small else 2.0,color)
func draw_small(c: Node2D, rect: Rect2, weapon: int, clock: int, selected: bool) -> void:
	var color: Color = Particles.player_color(weapon)
	c.draw_rect(rect,Color(0.015,0.035,0.06,0.95))
	c.draw_rect(rect,Color(color,0.8 if selected else 0.25),false,1)
	_draw_paths(c,weapon,displayed_power(clock),rect.position+Vector2(rect.size.x/2,rect.size.y-4),Vector2(0.7,0.07),clock,true)
func draw_large(c: Node2D, _original: RefCounted, rect: Rect2, weapon: int, clock: int) -> void:
	var color: Color = Particles.player_color(weapon)
	var font: Font = ThemeDB.fallback_font
	var power: int = displayed_power(clock)
	c.draw_rect(rect,Color(0.012,0.027,0.045,0.94))
	c.draw_rect(rect,Color(color,0.5),false,1)
	c.draw_string(font,rect.position+Vector2(12,20),"TYPE %d / %s"%[weapon,["","SPREAD","STRAIGHT","ACCEL"][weapon]],HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
	var description: String = ("WIDE PARALLEL" if power==4 else "OUTWARD SPREAD") if weapon==1 else ("PARALLEL LANES" if weapon==2 else "VERTICAL / SPEED UP")
	c.draw_string(font,rect.position+Vector2(12,36),"POWER %d / %s"%[power,description],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("a9bdcf"))
	var pilot: Vector2 = rect.position+Vector2(rect.size.x/2-25,rect.size.y-50)
	_draw_paths(c,weapon,power,rect.position+Vector2(rect.size.x/2,rect.size.y-47),Vector2(1.7,0.245),clock,false)
	pilot_art.draw(c,pilot)
	c.draw_string(font,rect.position+Vector2(9,rect.size.y-8),"DOTS = TIME",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("9db0c3"))
	c.draw_string(font,rect.position+Vector2(rect.size.x-58,rect.size.y-8),"P4 / P7",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(color,0.8))
func draw_loading(c: Node2D, original: RefCounted, clock: int) -> void:
	c.draw_texture(original.texture("loading2"),Vector2.ZERO)
	for i in range(3):
		var rect := Rect2(3+i*140,58,100,122)
		c.draw_rect(rect,Color("060f1c"))
		c.draw_string(ThemeDB.fallback_font,rect.position+Vector2(9,18),"TYPE %d"%(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Particles.player_color(i+1))
		draw_small(c,Rect2(rect.position+Vector2(7,45),Vector2(80,38)),i+1,clock,false)
