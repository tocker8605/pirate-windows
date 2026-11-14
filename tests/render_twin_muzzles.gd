extends SceneTree
const Game = preload("res://scripts/game.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
class Board extends Node2D:
	var game: Node
	var rows: Array = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),Color("101924"))
		for row in rows:
			var e: Dictionary = row.actor
			var d: Dictionary = Catalog.definition(e.kind)
			var center: Vector2 = e.pos+d.draw_offset+d.draw_size/2
			game.view.renewal.draw_enemy(self,e,e.pos+d.draw_offset,0)
			draw_line(center-Vector2(0,55),center+Vector2(0,55),Color(1,1,1,0.4),0.7)
			for shot in row.shots: draw_circle(shot.pos,3,Color("4dff80"))
			draw_string(ThemeDB.fallback_font,center+Vector2(-75,65),"%d / %s"%[e.kind,d.name],HORIZONTAL_ALIGNMENT_LEFT,160,9,Color.WHITE)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = Game.new()
	game.automatic = false
	game.mute = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.visible = false
	var board = Board.new()
	board.game = game
	var ids: Array = [6,8,10,21,41,42]
	var names: Dictionary = {6:"twin",10:"twin",21:"missiles",41:"aim",42:"missiles"}
	var failures := 0
	for i in range(ids.size()):
		var center := Vector2(100+200*(i%2),70+150*floori(i/2.0))
		var e: Dictionary = Catalog.create(ids[i],center-Vector2(25,25))
		e.velocity = Vector2(0,100)
		var shots: Array = Fire.advance(e,0.12) if e.kind==8 else Fire.emit(e,Vector2(175,450),names[e.kind])
		if shots.size()!=2 or not is_equal_approx((shots[0].pos.x+shots[1].pos.x)/2,center.x): failures += 1
		board.rows.append({"actor":e,"shots":shots})
	root.add_child(board)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://twin-muzzles-v24.31.png")
	print("RESULT: 6 checks, %d failures"%failures)
	game.audio.stop_all()
	game.queue_free()
	board.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
