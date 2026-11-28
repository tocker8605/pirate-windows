extends RefCounted
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const Ranking = preload("res://scripts/score_ranking.gd")
const NEXT_KEYS: Array = [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_Z,KEY_X,KEY_C]
var record: Dictionary = {}
var rank: int = 1
var player_name: String = "      "
var cursor: int = 0
var elapsed: float = 0
var save_failed: bool = false
var background: Texture2D
var blocked_confirmation_key: int = 0
func begin(index: int, result: Dictionary, backdrop: Texture2D = null, confirm_key: int = 0) -> void:
	rank = index+1
	record = result.duplicate()
	player_name = " ".repeat(Ranking.NAME_LENGTH)
	cursor = 0
	elapsed = 0
	save_failed = false
	background = backdrop
	blocked_confirmation_key = confirm_key
func handle_key(event: InputEventKey) -> bool:
	if event.keycode==blocked_confirmation_key:
		if not event.pressed: blocked_confirmation_key = 0
		return false
	if not event.pressed: return false
	if event.keycode in NEXT_KEYS: return not event.echo and advance_cursor()
	navigate(event.keycode)
	return false
func advance(seconds: float) -> void:
	elapsed += maxf(0,seconds)
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
static func mission_label(result: Dictionary) -> String:
	return "ALLCLEAR" if result.get("cleared",false) and result.get("mission",0)==Ranking.Campaign.stage_count() else "MISSION"
static func row(canvas: Node2D, y: float, number: int, result: Dictionary, name_override: String = "", active_cursor: int = -1) -> void:
	var digits: String = str(number)
	SpriteFont.text(canvas,Vector2(15,y),digits,true)
	SpriteFont.text(canvas,Vector2(15+digits.length()*10,y),suffix(number))
	SpriteFont.text(canvas,Vector2(65,y),Ranking.score_text(int(result.get("score",0))),true)
	if active_cursor>=0: SpriteFont.icon(canvas,Vector2(145+active_cursor*10,y),SpriteFont.NAME_CURSOR)
	SpriteFont.text(canvas,Vector2(145,y),str(result.get("name","")) if name_override.is_empty() else name_override)
	if result.has("weapon"): SpriteFont.weapon_icon(canvas,Vector2(215,y),int(result.weapon))
	SpriteFont.text(canvas,Vector2(235,y),"LEVEL")
	SpriteFont.text(canvas,Vector2(285,y),str(result.get("level",0)),true)
	if mission_label(result)=="ALLCLEAR":
		SpriteFont.text(canvas,Vector2(305,y),"ALL",true)
		SpriteFont.text(canvas,Vector2(335,y),"CLEAR")
	else:
		SpriteFont.text(canvas,Vector2(305,y),"MISSION")
		SpriteFont.text(canvas,Vector2(375,y),str(result.get("mission",0)),true)
static func board(canvas: Node2D, records: Array) -> void:
	for i in range(Ranking.LIMIT): row(canvas,105+i*28,i+1,records[i] if i<records.size() else {})
func render(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(0,0,400,480),Color.BLACK)
	if background!=null: canvas.draw_texture_rect(background,Rect2(0,0,400,480),false,Color(1,1,1,0.5))
	SpriteFont.centered(canvas,145,"ENTER YOUR NAME")
	row(canvas,230,rank,record,player_name,cursor if fmod(elapsed,0.8)<0.55 else -1)
	SpriteFont.centered(canvas,295,"UP DOWN CHANGE CHARACTER")
	SpriteFont.centered(canvas,320,"LEFT RIGHT MOVE CURSOR")
	SpriteFont.centered(canvas,355,"ENTER SPACE NEXT CHARACTER")
	SpriteFont.centered(canvas,385,"LAST CHARACTER TO FINISH")
	if save_failed: SpriteFont.centered(canvas,415,"SAVE FAILED PRESS ENTER TO RETRY")
