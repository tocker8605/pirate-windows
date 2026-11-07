extends SceneTree
const Art = preload("res://scripts/renewed_art.gd")
const OldArt = preload("res://scripts/art.gd")
const Preview = preload("res://scripts/weapon_preview.gd")
const Pose = preload("res://scripts/enemy_pose.gd")
const Clock = preload("res://scripts/timing.gd")
var checks := 0
var failures := 0
class Station extends Node2D:
	var art = Art.new()
	var angle: float = 0
	func _draw() -> void: art.draw_station(self,Vector2(25,25),Vector2.ONE,angle)
class Board extends Node2D:
	var old = OldArt.new()
	var preview = Preview.new()
	var clock: int = 12
	func _draw() -> void:
		var font = ThemeDB.fallback_font
		draw_rect(Rect2(0,0,640,450),Color("111d2b"))
		draw_string(font,Vector2(15,26),"V22 HABITAT RING / NO AXIAL SPINDLE",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("86d9ea"))
		draw_texture_rect(old.enemy(3,Vector2.ZERO,0),Rect2(35,70,100,100),false)
		draw_string(font,Vector2(36,194),"ORIGINAL",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("adbccc"))
		for i in range(3): draw_string(font,Vector2(185+i*110,194),["ANGLE A","ANGLE B","ANGLE C"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("adbccc"))
		draw_string(font,Vector2(535,56),"ICON LEGENDS",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("adbccc"))
		for i in range(3): preview.draw_small(self,Rect2(535,70+i*40,83,36),i+1,clock,i==0)
		for i in range(3): preview.draw_large(self,old,Rect2(12+i*210,225,196,210),i+1,clock)
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func difference(a: Image,b: Image,rect: Rect2i,skip_axis: bool = false) -> float:
	var result: float = 0
	for y in range(rect.position.y*2,rect.end.y*2):
		for x in range(rect.position.x*2,rect.end.x*2):
			if skip_axis and x>218*2 and x<232*2: continue
			var c: Color = a.get_pixel(x,y)
			var d: Color = b.get_pixel(x,y)
			result = maxf(result,maxf(absf(c.r-d.r),maxf(absf(c.g-d.g),absf(c.b-d.b))))
	return result
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size = Vector2i(640,450)
	root.size = Vector2i(1280,900)
	var art = Art.new()
	var raw: Image = art.station_atlas.get_image()
	check(raw.get_pixel(330,330).a==0 and raw.get_pixel(550,330).a==0 and raw.get_pixel(330,550).a==0 and raw.get_pixel(550,550).a==0,"station apertures have clean alpha without a glass disk or haze")
	var pose: Dictionary = Pose.target(3,Vector2.ZERO,0)
	for i in range(60): Pose.advance(pose,3,Vector2.ZERO,0,Clock.units_per_tick())
	check(is_equal_approx(pose.spin,TAU/7.2),"habitat ring rotates at the retained 7.2-second period")
	var board = Board.new()
	root.add_child(board)
	var stations: Array = []
	for i in range(3):
		var station = Station.new()
		station.position = Vector2(175+i*110,70)
		station.scale = Vector2.ONE*2
		station.angle = i*PI/4
		board.add_child(station)
		stations.append(station)
	await RenderingServer.frame_post_draw
	var first: Image = root.get_texture().get_image()
	stations[0].angle = PI/4
	stations[0].queue_redraw()
	await RenderingServer.frame_post_draw
	var second: Image = root.get_texture().get_image()
	check(art.station_texture().region==Rect2(30,27,829,832),"only the v22 habitat ring is selected; separate spindle is excluded")
	check(difference(first,second,Rect2i(175,78,100,84))>0.1,"habitat ring visibly rotates between phases")
	board.clock = 36
	board.queue_redraw()
	await RenderingServer.frame_post_draw
	var animated: Image = root.get_texture().get_image()
	check(difference(second,animated,Rect2i(12,225,616,210))>0.1,"weapon legends animate along their real paths")
	board.clock = 112
	board.queue_redraw()
	stations[0].angle = 0
	stations[0].queue_redraw()
	await RenderingServer.frame_post_draw
	var higher: Image = root.get_texture().get_image()
	check(difference(animated,higher,Rect2i(12,225,616,210))>0.1,"power4 and7 legends show distinct real volley examples")
	higher.save_png("res://preview-station-weapons-v24.png")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
