extends SceneTree
const Ranking = preload("res://scripts/score_ranking.gd")
const Screen = preload("res://scripts/ranking_screen.gd")
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const Game = preload("res://scripts/game.gd")
const PATH = "res://work/ranking-test.json"
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func result(points: int = 1234567) -> Dictionary:
	return {"score":points,"weapon":3,"level":2,"mission":4}
func key(g: Node, code: int, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echo
	g._unhandled_key_input(event)
func clear_files() -> void:
	for path in [PATH,PATH+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	clear_files()
	var store = Ranking.new(PATH)
	check(store.entries.size()==10 and store.initialization_error==OK and FileAccess.file_exists(PATH),"missing file creates and saves ten initial ranking records")
	for i in range(10):
		check(store.entries[i]=={"score":10000-i*1000,"name":"      ","weapon":[1,2,3,1,2,3,1,2,3,1][i],"level":1,"mission":1},"initial rank%d has the requested score, blank name and cycling weapon type"%(i+1))
	check(Ranking.new(PATH).entries==store.entries,"initial ranking survives reload")
	check(store.insertion_index(999)==-1 and store.insertion_index(1000)==-1 and store.insertion_index(1001)==9,"initial full board requires a score above the last-place1000")
	store.entries.clear()
	check(store.insertion_index(0)==0,"explicitly empty board still admits a zero-point run")
	check(Ranking.clean_name("tockerxyz")=="TOCKER" and Ranking.clean_name("a!2")=="A2    ","names use six uppercase alphanumeric or blank slots")
	check(store.submit(result(100),"TOCKER")==OK,"first name is saved")
	check(store.submit(result(500),"PLAYER")==OK,"atomic save replaces an existing file")
	check(store.submit(result(500),"ABC123")==OK and store.entries[0].name=="PLAYER" and store.entries[1].name=="ABC123","equal scores keep submission order")
	check(store.submit(result(200),"A B 9 ")==OK,"embedded and trailing blank characters can be saved")
	var restored = Ranking.new(PATH)
	check(restored.entries==store.entries,"scores, names including spaces, weapon, level and mission survive reload")
	check(not Ranking.valid_record({"score":5,"name":"TOCKER","weapon":4,"level":2,"mission":1}),"invalid saved weapon is rejected")
	check(not Ranking.valid_record({"score":-1,"name":"TOCKER","weapon":1,"level":2,"mission":1}),"negative score is rejected")
	check(not Ranking.valid_record({"score":null,"name":"TOCKER","weapon":1,"level":2,"mission":1}),"invalid saved numeric data is rejected")
	for i in range(12): store.submit(result(1000+i),"TOCKER")
	check(store.entries.size()==10 and store.entries[0].score==1011 and store.entries[-1].score==1002,"only the ten highest records are retained")
	check(store.insertion_index(1002)==-1 and store.insertion_index(9999)==0,"full board rejects a trailing tie and admits higher scores")
	var unavailable = Ranking.new("res://work/ranking_missing_directory/rankings.json")
	var fallback: Array = unavailable.entries.duplicate(true)
	check(unavailable.initialization_error!=OK and fallback.size()==10,"failed initial save retains default rankings in memory and exposes the error")
	check(unavailable.submit(result(),"PLAYER")!=OK and unavailable.entries==fallback,"failed save preserves the existing in-memory board")
	var file = FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(Ranking.new(PATH).entries.is_empty(),"corrupt save starts with a usable empty board")
	file = FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string('{"schema_version":1,"entries":[]}')
	file.close()
	check(Ranking.new(PATH).entries.is_empty(),"existing empty file is preserved instead of replacing it with defaults")
	clear_files()
	var completed: Dictionary=result(123456)
	completed.mission=5
	completed.cleared=true
	check(store.submit(completed,"CLEAR")==OK,"completed campaign record saves")
	var cleared_store=Ranking.new(PATH)
	check(cleared_store.entries[0].get("cleared",false) and Screen.mission_label(cleared_store.entries[0])=="ALLCLEAR","clear status survives reload and displays ALLCLEAR")
	completed.erase("cleared")
	check(Screen.mission_label(completed)=="MISSION","legacy mission5 record is not assumed cleared")
	completed.cleared=false
	check(Screen.mission_label(completed)=="MISSION","failed mission5 displays mission instead of clear")
	completed.name="PLAYER"
	completed.cleared="true"
	check(not Ranking.valid_record(completed),"nonboolean clear status rejected")
	completed.cleared=true
	completed.mission=4
	check(not Ranking.valid_record(completed),"clear status requires final mission")
	clear_files()
	var screen = Screen.new()
	screen.begin(1,result())
	check(screen.player_name=="      ","every new name starts with six blank slots")
	screen.navigate(KEY_UP)
	check(screen.player_name=="A     ","blank wraps forward toA")
	screen.navigate(KEY_DOWN)
	check(screen.player_name=="      ","A wraps backward to blank")
	screen.navigate(KEY_DOWN)
	check(screen.player_name=="9     ","blank wraps backward to9")
	screen.navigate(KEY_UP)
	check(screen.player_name=="      ","9 wraps forward to blank")
	screen.player_name = "AAAAAA"
	for i in range(10): screen.navigate(KEY_RIGHT)
	check(screen.cursor==5,"right cursor stops at the sixth character")
	screen.navigate(KEY_UP)
	check(screen.player_name=="AAAAAB","only the active character changes")
	for i in range(10): screen.navigate(KEY_LEFT)
	check(screen.cursor==0,"left cursor stops at the first character")
	check(Screen.suffix(1)=="ST" and Screen.suffix(2)=="ND" and Screen.suffix(3)=="RD" and Screen.suffix(10)=="TH","rank suffixes are correct")
	check(Ranking.score_text(934567)==" 934567" and Ranking.score_text(42)=="     42" and Ranking.score_text(0)=="      0","scores remove leading zeros and right-align in seven slots")
	check(SpriteFont.frame(0,0).region==Rect2(0,0,10,20) and SpriteFont.frame(35,1).region==Rect2(350,20,10,20),"green and white text use the requested atlas rows")
	check(SpriteFont.frame(SpriteFont.NAME_CURSOR,2).region==Rect2(0,40,10,20) and SpriteFont.frame(SpriteFont.MENU_CURSOR,2).region==Rect2(10,40,10,20),"name and menu cursors have separate bottom-row cells")
	check(SpriteFont.frame(2,2).region==Rect2(20,40,10,20) and SpriteFont.frame(4,2).region==Rect2(40,40,10,20),"three weapon icons follow both cursor cells")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	g.rankings = Ranking.new(PATH)
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.events = []
	g.run_settings = g.run_settings.with_weapon(3)
	g.run_settings = g.run_settings.with_difficulty(4)
	g.score = 1234567
	g.hp = 0
	g.death_remaining_seconds = 1.0/60
	g.flow.state = "dying"
	g._tick(Vector2.ZERO,false,false,false)
	check(g.state=="ranking_entry" and g.last_score==1234567 and g.score==0,"end of game-over animation enters name registration with the final score")
	check(g.ranking_entry.record=={"score":1234567,"weapon":3,"level":4,"mission":2},"registration snapshots the run weapon, difficulty and mission")
	var frame: int = g.frame
	g._tick(Vector2.RIGHT,true,true,true)
	check(g.frame==frame,"name registration freezes gameplay")
	g.ranking_entry.player_name = "TOCKER"
	key(g,KEY_SPACE,true)
	check(g.state=="ranking_entry","held firing/confirm keys cannot auto-submit a name")
	key(g,KEY_ENTER)
	check(g.state=="ranking_entry" and g.ranking_entry.cursor==1,"Enter advances instead of submitting early")
	g.ranking_entry.cursor=5
	key(g,KEY_ENTER)
	check(g.state=="menu" and g.title.screen==g.title.RANKING and g.rankings.entries[0].name=="TOCKER" and g.last_score==1234567,"submission saves the name and returns to the initial black title")
	key(g,KEY_SPACE)
	check(g.title.screen==g.title.RANKING,"confirm key cannot also skip the initial title")
	g._load_stage(5)
	g.events = []
	g.score = 7654321
	g._complete_stage()
	check(g.state=="clear" and g.clear_screen.record.mission==5 and g.clear_screen.record.get("cleared",false) and g.clear_screen.record.score==7654321,"fifth-boss clear preserves the final run on the clear screen")
	key(g,KEY_SPACE)
	var released := InputEventKey.new()
	released.keycode=KEY_SPACE
	released.pressed=false
	g._unhandled_key_input(released)
	check(g.state=="ranking_entry" and g.ranking_entry.background==g.clear_screen.background,"clear confirmation opens ranking with the ending background")
	for code in Screen.NEXT_KEYS:
		g.ranking_entry.begin(0,result(8500000+code%100))
		g.flow.state = "ranking_entry"
		key(g,code,true)
		check(g.ranking_entry.cursor==0 and g.state=="ranking_entry","held next key%s cannot skip blank slots"%code)
		for position in range(5):
			key(g,code)
			check(g.ranking_entry.cursor==position+1 and g.state=="ranking_entry","next key%s advances to slot%s without submitting"%[code,position+2])
		key(g,code)
		check(g.state=="menu","next key%s submits when leaving the sixth slot"%code)
	var full = Ranking.new(PATH)
	full.entries.clear()
	for i in range(10):
		var record: Dictionary = result(9000000-i)
		record.name = "PLAYER"
		full.entries.append(record)
	g.rankings = full
	g.score = 1
	g._finish_run()
	check(g.state=="menu" and g.last_score==1,"a score outside the top ten returns to the initial title")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	clear_files()
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
