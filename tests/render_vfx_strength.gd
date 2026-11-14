extends SceneTree
const FX = preload("res://scripts/combat_vfx.gd")
class Board extends Node2D:
	var fx = FX.new()
	const BG = Color("526978")
	func previous_explosion(p: Vector2, duration: float, ticks: float) -> void:
		var fade: float = ticks/duration
		var age: float = duration-ticks
		var radius: float = (24 if duration>20 else 16)+age*1.3
		fx.halo(self,p,radius*1.8,FX.HOT,fade*0.6)
		fx.halo(self,p,radius*0.75,Color("ffe8ac"),fade*0.9)
		var heat: float = fade*fade
		for i in range(7):
			var angle: float = i*TAU/7+sin(p.x+i)*0.6
			var lobe: Vector2 = p+Vector2.from_angle(angle)*(radius*0.34+sin(i*2+age*0.2)*3)
			fx.halo(self,lobe,radius*0.58,FX.HOT,heat*0.8)
			fx.halo(self,lobe,radius*0.28,Color("ffdf8a"),heat*0.9)
		fx.halo(self,p,radius*0.46,Color("fff4c7"),heat)
		draw_arc(p,radius,0,TAU,64,Color(FX.HOT,fade*0.5),1.4,true)
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),BG)
		var font = ThemeDB.fallback_font
		draw_string(font,Vector2(60,25),"PREVIOUS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
		draw_string(font,Vector2(255,25),"STRONGER",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
		draw_string(font,Vector2(12,65),"DAMAGE SMOKE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
		var age: float = 6.0/28.0
		fx.halo(self,Vector2(100,110),15*FX.SMOKE_SIZE_SCALE*(1+age*1.6),Color("414b5c"),(1-age)*0.65)
		fx.particles = [{"p":Vector2(300,110),"v":Vector2.ZERO,"age":6.0,"life":28.0,"size":15.0,"color":FX.SMOKE_COLOR,"smoke":true}]
		fx.draw_particles(self,1,1)
		draw_string(font,Vector2(12,185),"SMALL EXPLOSION",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
		previous_explosion(Vector2(100,250),20,14)
		fx.draw_explosion(self,{"pos":Vector2(275,225),"render_remaining_seconds":0.42,"remaining_seconds":0.42})
		draw_string(font,Vector2(12,325),"LARGE EXPLOSION",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
		previous_explosion(Vector2(100,390),35,28)
		fx.draw_explosion(self,{"pos":Vector2(275,365),"render_remaining_seconds":0.84,"remaining_seconds":0.84})
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.add_child(Board.new())
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("res://preview-vfx-strength-v19.png")
	var failures: int = 0
	var dark: Array = []
	for centre in [Vector2i(200,220),Vector2i(600,220)]:
		var energy: float = 0
		for y in range(centre.y-44,centre.y+44):
			for x in range(centre.x-44,centre.x+44): energy += maxf(0,Board.BG.r-image.get_pixel(x,y).r)
		dark.append(energy)
	print("SMOKE DARKNESS: %.2f -> %.2f"%dark)
	if dark[1]<dark[0]*2: failures += 1
	for row in [[500,46],[780,62]]:
		var brightness: Array = []
		for cx in [200,600]:
			var energy: float = 0
			for y in range(row[0]-row[1]*2,row[0]+row[1]*2):
				for x in range(cx-row[1]*2,cx+row[1]*2): energy += maxf(0,image.get_pixel(x,y).r-Board.BG.r)
			brightness.append(energy)
		print("EXPLOSION ENERGY: %.2f -> %.2f"%brightness)
		if brightness[1]<brightness[0]*1.3: failures += 1
	print("RESULT: 3 checks, %d failures"%failures)
	quit(0 if failures==0 else 1)
