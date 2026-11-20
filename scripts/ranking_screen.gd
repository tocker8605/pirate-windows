extends RefCounted
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const Ranking = preload("res://scripts/score_ranking.gd")
const CONFIRM_KEYS: Array = [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]
const NEXT_KEYS: Array = [KEY_Z,KEY_X,KEY_C]
var record: Dictionary = {}
var rank: int = 1
var player_name: String = "      "
var cursor: int = 0
var elapsed: float = 0
var save_failed: bool = false
func begin(index: int, result: Dictionary) -> void:
	rank = index+1
	record = result.duplicate()
	player_name = " ".repeat(Ranking.NAME_LENGTH)
	cursor = 0
	elapsed = 0
	save_failed = false
func advance_cursor() -> bool:
	if cursor==Ranking.NAME_LENGTH-1: return true
	cursor += 1
	elapsed = 0
	return false
func navigate(key: int) -> void:
	if key==KEY_LEFT: cursor = maxi(0,cursor-1)
	elif key==KEY_RIGHT: cursor = mini(Ranking.NAME_LENGTH-1,cursor+1)
	elif key in [KEY_UP,KEY_DOWN]:
		var index: int = Ranking.CHARACTERS.find(player_name[cursor])
		index = posmod(index+(1 if key==KEY_UP else -1),Ranking.CHARACTERS.length())
		player_name[cursor] = Ranking.CHARACTERS[index]
static func suffix(number: int) -> String:
	if number%100 in [11,12,13]: return "TH"
	match number%10:
		1: return "ST"
		2: return "ND"
		3: return "RD"
	return "TH"
static func score_text(points: int) -> String:
	return str(clampi(points,0,Ranking.MAX_SCORE)).lpad(7," ")
static func row(canvas: Node2D, y: float, number: int, result: Dictionary, name_override: String = "", active_cursor: int = -1) -> void:
	var digits: String = str(number)
	SpriteFont.text(canvas,Vector2(15,y),digits,true)
	SpriteFont.text(canvas,Vector2(15+digits.length()*10,y),suffix(number))
	SpriteFont.text(canvas,Vector2(65,y),score_text(int(result.get("score",0))),true)
	if active_cursor>=0: SpriteFont.icon(canvas,Vector2(145+active_cursor*10,y),SpriteFont.NAME_CURSOR)
	SpriteFont.text(canvas,Vector2(145,y),str(result.get("name","")) if name_override.is_empty() else name_override)
	if result.has("weapon"): SpriteFont.weapon_icon(canvas,Vector2(215,y),int(result.weapon))
	SpriteFont.text(canvas,Vector2(235,y),"LEVEL")
	SpriteFont.text(canvas,Vector2(285,y),str(result.get("level",0)),true)
	SpriteFont.text(canvas,Vector2(305,y),"MISSION")
	SpriteFont.text(canvas,Vector2(375,y),str(result.get("mission",0)),true)
static func board(canvas: Node2D, records: Array) -> void:
	SpriteFont.centered(canvas,55,"RANKING")
	for i in range(Ranking.LIMIT): row(canvas,105+i*28,i+1,records[i] if i<records.size() else {})
func render(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(0,0,400,480),Color.BLACK)
	SpriteFont.centered(canvas,145,"ENTER YOUR NAME")
	row(canvas,230,rank,record,player_name,cursor if fmod(elapsed,0.8)<0.55 else -1)
	SpriteFont.centered(canvas,295,"UP DOWN CHANGE CHARACTER")
	SpriteFont.centered(canvas,320,"LEFT RIGHT MOVE CURSOR")
	SpriteFont.centered(canvas,355,"Z X C NEXT OR FINISH AT LAST")
	SpriteFont.centered(canvas,385,"ENTER SPACE TO FINISH")
	if save_failed: SpriteFont.centered(canvas,415,"SAVE FAILED PRESS ENTER TO RETRY")
