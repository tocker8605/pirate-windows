extends SceneTree
class Gallery:
	extends Node2D
	const Art = preload("res://scripts/art.gd")
	const NewArt = preload("res://scripts/renewed_art.gd")
	const Pose = preload("res://scripts/enemy_pose.gd")
	var original = Art.new()
	var renewal = NewArt.new()
	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		draw_rect(Rect2(0,0,1000,700),Color("101b29"))
		draw_string(font,Vector2(20,28),"ORIGINAL FRAME SELECTION / RENEWED CONTINUOUS ATTITUDE",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("8deaff"))
		draw_string(font,Vector2(20,53),"Each pair: original above, renewed below. Body anchor and flight velocity stay unchanged.",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a2b2c9"))
		var kinds: Array = [1,7,8,10]
		var vertical: Array = [5,5,3,2,2,0,-1,-2,-3,-4,-5,-5]
		var horizontal: Array = [-4,-3,-2,-1,0,1,2,3,4,2,0,-3]
		for row in range(4):
			var kind: int = kinds[row]
			var y: float = 77+row*155
			draw_rect(Rect2(12,y,976,153),Color("172538") if row%2==0 else Color("122030"))
			draw_string(font,Vector2(20,y+20),"TYPE %d / %s"%[kind,"VX BANK" if kind==8 else "VY PULL-UP"],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("8deaff"))
			var pose: Dictionary = Pose.target(kind,Vector2(horizontal[0],1) if kind==8 else Vector2(0,vertical[0]),0)
			for col in range(12):
				var v := Vector2(horizontal[col],1) if kind==8 else Vector2(0,vertical[col])
				for i in range(3): Pose.advance(pose,kind,v,0)
				var x: float = 76+col*76
				draw_string(font,Vector2(x+15,y+32),str(v.x if kind==8 else v.y),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("899bb2"))
				draw_texture(original.enemy(kind,v,0),Vector2(x,y+37))
				var id: int = row*100+col
				renewal.poses[id] = pose.duplicate(true)
				renewal.draw_enemy(self,{"kind":kind,"velocity":v,"entity_id":id},Vector2(x,y+96),0)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size = Vector2i(1000,700)
	root.size = Vector2i(1000,700)
	var gallery := Gallery.new()
	root.add_child(gallery)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-turn-v11.png")
	print("Saved original / renewed turn comparison")
	quit()
