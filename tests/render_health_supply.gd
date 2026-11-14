extends SceneTree
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Supply = preload("res://scripts/supply_visual.gd")
class Board extends Node2D:
	var game: Node
	func _draw() -> void:
		draw_rect(Rect2(0,0,400,480),Color("14202b"))
		for row in range(3):
			for column in range(2):
				var id: int = (19 if row==1 else 201) if column==0 else (20 if row==1 else 202)
				var center := Vector2(100+200*column,65+120*row)
				var e: Dictionary = Catalog.create(id,center-Vector2(25,25))
				e.rescued = row==2
				game.view.renewal.draw_enemy(self,e,e.pos,0)
				Supply.draw_mount(self,game.art,e,e.pos,0,10)
				draw_string(ThemeDB.fallback_font,center+Vector2(-62,50),("POWER" if column==0 else "HP")+" / "+["APPROACH","OPEN","RELEASED"][row],HORIZONTAL_ALIGNMENT_LEFT,150,11,Color.WHITE)
		for kind in [1,2]:
			var center := Vector2(100 if kind==1 else 300,420)
			Supply.draw_item(self,game.art,center,0,10,1.0,kind)
			draw_string(ThemeDB.fallback_font,center+Vector2(-55,35),"POWER ITEM" if kind==1 else "HP ITEM / +25",HORIZONTAL_ALIGNMENT_LEFT,150,11,Color.WHITE)
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
	root.add_child(board)
	await RenderingServer.frame_post_draw
	var pixels: Image = root.get_texture().get_image()
	pixels.save_png(OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://health-supply-v24.32.png")
	var failures := 0
	if game.view.renewal.enemy_texture(201)!=game.view.renewal.enemy_texture(202): failures += 1
	for row in range(3):
		var badge: Color = pixels.get_pixel(600,(62+120*row)*2)
		if badge.r<badge.g+0.2: failures += 1
	if Supply.cargo_color(1)!=Supply.GREEN or Supply.cargo_color(2)!=Supply.HEALTH: failures += 1
	if not Catalog.definition(20).damageable or Catalog.definition(202).damageable: failures += 1
	print("RESULT: 6 checks, %d failures"%failures)
	game.audio.stop_all()
	game.queue_free()
	board.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)
