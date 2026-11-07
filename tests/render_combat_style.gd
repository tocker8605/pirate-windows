extends SceneTree
const Art = preload("res://scripts/renewed_art.gd")
const VFX = preload("res://scripts/combat_vfx.gd")
const Pilot = preload("res://scripts/pilot_art.gd")
const Geometry = preload("res://scripts/pilot_geometry.gd")
var failures: int = 0
class Gallery extends Node2D:
	var art = Art.new()
	var fx = VFX.new()
	var pilot = Pilot.new()
	var phase: float = 0
	func _draw() -> void:
		var font = ThemeDB.fallback_font
		draw_string(font,Vector2(15,30),"STAGE1 / MIRRORED FISTS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("86cce5"))
		for kind in [101,102]:
			art.draw_enemy(self,{"kind":kind,"velocity":Vector2.ZERO},Vector2(75 if kind==101 else 275,60),0)
		draw_string(font,Vector2(15,165),"FIREBALL / UP - RIGHT - DOWN",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffa250"))
		var velocities: Array = [Vector2(0,-3),Vector2(3,0),Vector2(0,3)]
		for i in range(3): fx.draw_bullet(self,{"kind":8,"pos":Vector2(80+i*120,210),"velocity":velocities[i]},null,phase)
		draw_string(font,Vector2(15,340),"40PX PILOT / COCKPIT HIT REGION",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("78e9dc"))
		for bank in range(3):
			var pos := Vector2(55+bank*120,365)
			pilot.draw(self,pos,bank)
			draw_arc(pos+Geometry.COCKPIT,Geometry.HIT_RADIUS,0,TAU,32,Color("ff7777"),0.7,true)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gallery = Gallery.new()
	root.add_child(gallery)
	await RenderingServer.frame_post_draw
	var first: Image = root.get_texture().get_image()
	var mirror_delta: float = 0
	for y in range(120,220):
		for x in range(150,250):
			var a = first.get_pixel(x,y)
			var b = first.get_pixel(799-x,y)
			mirror_delta = maxf(mirror_delta,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	if mirror_delta>1.1/255: failures += 1
	print("FIST GPU MIRROR: maxRGB delta%.5f"%mirror_delta)
	gallery.phase = 8
	gallery.queue_redraw()
	await RenderingServer.frame_post_draw
	var second: Image = root.get_texture().get_image()
	second.save_png("res://preview-combat-style-v17.png")
	var animation_delta: float = 0
	for y in range(360,480):
		for x in range(100,700,2):
			var a = first.get_pixel(x,y)
			var b = second.get_pixel(x,y)
			animation_delta = maxf(animation_delta,absf(a.g-b.g))
	if animation_delta<0.1: failures += 1
	print("FIREBALL ANIMATION: maxG delta%.5f"%animation_delta)
	print("RESULT: 2 checks, %d failures"%failures)
	quit(0 if failures==0 else 1)
