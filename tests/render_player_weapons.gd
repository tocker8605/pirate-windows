extends SceneTree
const Art=preload("res://scripts/player_shot_art.gd")
const Original=preload("res://scripts/art.gd")
const Weapons=preload("res://scripts/player_weapons.gd")
const FX=preload("res://scripts/combat_vfx.gd")
const Style=preload("res://scripts/player_weapon_style.gd")
const Preview=preload("res://scripts/weapon_preview.gd")
var checks:=0
var failures:=0
class Gallery extends Node2D:
	var art=Art.new()
	var old=Original.new()
	var preview=Preview.new()
	var fx=FX.new()
	func _init()->void:
		for weapon in range(1,4):
			var y:float=60+(weapon-1)*105
			for x in Style.PORTS[weapon-1]: fx.player_sparks(Vector2(345+x,y+15),weapon,false)
			fx.player_sparks(Vector2(465,y+15),weapon,true)
		for p in fx.particles:
			p.age=0.03
			p.p+=p.v*0.03
			p.previous_pos=p.p
	func _draw()->void:
		draw_rect(Rect2(0,0,640,620),Color("0b1420"))
		var font=ThemeDB.fallback_font
		for pair in [["FLIGHT",180],["MUZZLE / PARTICLES",280],["HIT / PARTICLES",415]]:
			draw_string(font,Vector2(pair[1],23),pair[0],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
		for weapon in range(1,4):
			var y:float=60+(weapon-1)*105
			draw_string(font,Vector2(12,y-10),"TYPE %d / ORIGINAL"%weapon,HORIZONTAL_ALIGNMENT_LEFT,-1,11,FX.player_color(weapon))
			draw_texture_rect(old.sprite("weapon%d"%weapon,Rect2i(10,0,20,30),Vector2i(10,30)),Rect2(55,y,30,45),false)
			art.draw(self,{"pos":Vector2(180,y),"impact_remaining_seconds":-1},Vector2.ZERO,weapon)
			# This region must stay empty: impact entities never render a sprite.
			art.draw(self,{"pos":Vector2(560,y),"impact_remaining_seconds":0.27},Vector2.ZERO,weapon)
			preview.draw_small(self,Rect2(15,380+(weapon-1)*52,100,42),weapon,0.3,true)
		fx.draw_particles(self,1,2)
		for weapon in range(1,4):preview.draw_large(self,old,Rect2(130+(weapon-1)*166,380,158,218),weapon,0.3)
func check(ok:bool,message:String)->void:
	checks+=1
	if ok:print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var image:Image=Art.ATLAS.get_image()
	check(image.get_size()==Vector2i(288,136),"runtime atlas contains only three compact flight bodies")
	var bands:=0
	var inside:=false
	var band_width:=0
	var widest:=0
	var violet:=true
	var lavender_bright:=true
	for x in range(96):
		var opaque:=0
		for y in range(35,100):
			var pixel:Color=image.get_pixel(x,y)
			if pixel.a>0.65:
				opaque+=1
				violet=violet and pixel.b>pixel.r+0.035 and pixel.b>pixel.g+0.08
				lavender_bright=lavender_bright and pixel.r>0.75 and pixel.g>0.65
		var active:bool=opaque>35
		if active and not inside:bands+=1
		band_width=band_width+1 if active else 0
		widest=maxi(widest,band_width)
		inside=active
	check(bands==1,"type1 uses a single centered lavender line")
	check(violet and widest>=5 and widest<=7,"type1 line is about 1.4 times the previous one-pixel stroke")
	check(lavender_bright,"type1 line cores are bright lavender rather than dark purple")
	for weapon in range(1,4):
		var peak:=0.0
		var count:=0
		for y in range(136):
			for x in range((weapon-1)*96,weapon*96):
				var pixel:Color=image.get_pixel(x,y)
				if pixel.a>0.7:
					peak=maxf(peak,maxf(pixel.r,maxf(pixel.g,pixel.b)))
					count+=1
		check(count>100 and peak<=(1.0 if weapon==1 else 0.97),"type%d uses controlled body/highlights with bright lavender for type1"%weapon)
	root.content_scale_size=Vector2i(640,620)
	root.size=Vector2i(1280,1240)
	var board=Gallery.new()
	root.add_child(board)
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels:Image=root.get_texture().get_image()
	pixels.save_png(OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "res://preview-player-weapons-v24.39.png")
	var bg:=Color("0b1420")
	for weapon in range(1,4):
		var y:int=60+(weapon-1)*105
		var hit_pixels:=0
		var spark_pixels:=0
		for yy in range((y-2)*2,(y+32)*2):
			for x in range(550*2,600*2):
				var p:Color=pixels.get_pixel(x,yy)
				if maxf(absf(p.r-bg.r),maxf(absf(p.g-bg.g),absf(p.b-bg.b)))>0.03:hit_pixels+=1
			for x in range(450*2,480*2):
				var p:Color=pixels.get_pixel(x,yy)
				if maxf(absf(p.r-bg.r),maxf(absf(p.g-bg.g),absf(p.b-bg.b)))>0.03:spark_pixels+=1
		check(hit_pixels==0,"type%d impact state draws no sprite"%weapon)
		check(spark_pixels>20 and spark_pixels<900,"type%d impact is a compact live particle burst"%weapon)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	board.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
