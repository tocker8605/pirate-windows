class_name PirateTitle
extends RefCounted
const WeaponPreview = preload("res://scripts/weapon_preview.gd")
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const RankingScreen = preload("res://scripts/ranking_screen.gd")
const Ranking = preload("res://scripts/score_ranking.gd")
const SPLASH: StringName = &"splash"
const RANKING: StringName = &"ranking"
const OPENING: StringName = &"opening"
const MAIN: StringName = &"main"
const SETTINGS: StringName = &"settings"
const MAIN_ITEMS: Array[StringName] = [&"new_game",&"boss_rush",&"continue"]
const NAVIGATION_KEYS: Array = [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]
const CONFIRM_KEYS: Array = [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]
const REPEAT_DELAY: float = 0.35
const REPEAT_INTERVAL: float = 0.15
const SPLASH_DURATION: float = 0.025
const OPENING_DURATION: float = 2.35
const BACKGROUND_SPEED: float = 40.0
const BACKGROUND_LIMIT: float = 479.0
const PANEL_START: float = 2.6
const PANEL_SPEED: float = 104.0
const PANEL_REST: float = 249.6
var weapon_preview = WeaponPreview.new()
var screen: StringName = SPLASH
var main_selection: int = 0
# Settings row0 selects difficulty; rows1..3 select the corresponding weapon.
var settings_selection: int = 0
var difficulty: int = 3
var boss_rush: bool = false
var splash_remaining: float = SPLASH_DURATION
var opening_elapsed: float = 0
var background_elapsed: float = 0
var preview_elapsed: float = 0
var navigation_key: int = 0
var repeat_remaining: float = 0
var confirmation_down: bool = false
var blocked_confirmation_key: int = 0

func clear_input() -> void:
	clear_navigation()
	confirmation_down = false
	blocked_confirmation_key = 0

func clear_navigation() -> void:
	navigation_key = 0
	repeat_remaining = 0

func block_confirmation_until_release(key: int) -> void:
	if key in CONFIRM_KEYS: blocked_confirmation_key = key

func handle_key(event: InputEventKey) -> String:
	var key: int = event.keycode
	if key in NAVIGATION_KEYS:
		navigation_input(key,event.pressed,event.echo)
	elif key in CONFIRM_KEYS:
		if not event.pressed:
			confirmation_down = false
			if blocked_confirmation_key==key: blocked_confirmation_key = 0
		elif not event.echo and not confirmation_down and blocked_confirmation_key==0:
			confirmation_down = true
			return confirm()
	return ""

func navigation_input(key: int, pressed: bool, echo: bool = false) -> void:
	if not pressed:
		if navigation_key==key: clear_navigation()
		return
	if screen not in [MAIN,SETTINGS] or echo or navigation_key==key: return
	navigation_key = key
	repeat_remaining = REPEAT_DELAY
	navigate(key)

func repeat_navigation(delta: float) -> void:
	if navigation_key==0: return
	repeat_remaining -= delta
	if repeat_remaining<=0:
		navigate(navigation_key)
		# Do not catch up with multiple moves after a stalled render frame.
		repeat_remaining = REPEAT_INTERVAL

func reset() -> void:
	clear_input()
	screen = RANKING
	main_selection = 0
	settings_selection = 0
	splash_remaining = 0
	opening_elapsed = 0
	background_elapsed = 0

func advance(seconds: float) -> void:
	var delta: float = maxf(0,seconds)
	preview_elapsed += delta
	repeat_navigation(delta)
	if screen==SPLASH:
		splash_remaining = maxf(0,splash_remaining-delta)
		if splash_remaining<=0.000000001: screen = RANKING
	if shows_background():
		background_elapsed += delta
		if screen==OPENING:
			opening_elapsed = minf(OPENING_DURATION,opening_elapsed+delta)
			if opening_elapsed>=OPENING_DURATION-0.000000001:
				opening_elapsed = OPENING_DURATION
				screen = MAIN

func shows_background() -> bool:
	return screen in [OPENING,MAIN,SETTINGS]

func background_scroll() -> float:
	return minf(background_elapsed*BACKGROUND_SPEED,BACKGROUND_LIMIT)

func background_offset() -> int:
	return roundi(background_scroll()/3.5)

func panel_offset() -> int:
	return roundi(PANEL_START+opening_elapsed*PANEL_SPEED) if screen==OPENING else roundi(PANEL_REST)

func selected_weapon() -> int:
	return clampi(settings_selection,1,3)

func navigate(key: int) -> void:
	if screen==MAIN:
		if key==KEY_UP: main_selection = maxi(0,main_selection-1)
		if key==KEY_DOWN: main_selection = mini(MAIN_ITEMS.size()-1,main_selection+1)
	elif screen==SETTINGS:
		if key==KEY_UP: settings_selection = maxi(0,settings_selection-1)
		if key==KEY_DOWN: settings_selection = mini(3,settings_selection+1)
		if settings_selection==0:
			if key==KEY_LEFT: difficulty = maxi(1,difficulty-1)
			if key==KEY_RIGHT: difficulty = mini(5,difficulty+1)

func confirm() -> String:
	clear_navigation()
	match screen:
		SPLASH,RANKING:
			screen = OPENING
			opening_elapsed = 0
			return "opening"
		MAIN:
			var choice: StringName = MAIN_ITEMS[main_selection]
			if choice==&"continue": return "continue"
			boss_rush = choice==&"boss_rush"
			settings_selection = 0
			screen = SETTINGS
		SETTINGS:
			if settings_selection>0: return "play"
	return ""

func render(canvas: Node2D, art: RefCounted, last_score: int, earth_background: bool = false, rankings: Array = []) -> void:
	if not earth_background: canvas.draw_rect(Rect2(0,0,400,480),Color.BLACK)
	if screen==SPLASH:
		canvas.draw_texture(art.texture("tocker"),Vector2.ZERO)
		return
	if screen==RANKING:
		draw_rankings(canvas,art,last_score,rankings)
		return
	var dx: int = background_offset()
	if earth_background: canvas.draw_rect(Rect2(400-dx,0,dx,480),Color.BLACK)
	else: canvas.draw_texture_rect_region(art.texture("stage0"),Rect2(-dx,0,400,480),Rect2(0,480-background_scroll(),400,480))
	var pane_x: int = panel_offset()
	canvas.draw_texture_rect_region(art.texture("piclog"),Rect2(pane_x,0,400-pane_x,480),Rect2(0,0,400-pane_x,480))
	canvas.draw_texture(art.sprite("piclogo",Rect2i(0,0,300,100),Vector2i(0,100)),Vector2(10,50))
	if screen==MAIN:
		for i in range(3):
			SpriteFont.text(canvas,Vector2(250,[260,290,330][i]),["NEW GAME","BOSS RUSH","CONTINUE"][i])
		SpriteFont.icon(canvas,Vector2(235,[260,290,330][main_selection]),SpriteFont.MENU_CURSOR)
	elif screen==SETTINGS:
		SpriteFont.text(canvas,Vector2(250,260),"GAME LEVEL")
		for i in range(3):
			SpriteFont.text(canvas,Vector2(250,340+i*40),"TYPE")
			SpriteFont.text(canvas,Vector2(290,340+i*40),str(i+1),true)
			weapon_preview.draw_small(canvas,Rect2(307,332+i*40,83,36),i+1,preview_elapsed,settings_selection==i+1)
		SpriteFont.text(canvas,Vector2(370,260),str(difficulty),true)
		SpriteFont.icon(canvas,Vector2(235,[260,340,380,420][settings_selection]),SpriteFont.MENU_CURSOR)
	draw_score(canvas,last_score)

static func draw_rankings(canvas: Node2D, art: RefCounted, last_score: int, rankings: Array) -> void:
	canvas.draw_texture(art.texture("piclog"),Vector2.ZERO)
	RankingScreen.board(canvas,rankings)
	draw_score(canvas,last_score)

static func draw_score(canvas: Node2D, last_score: int) -> void:
	if last_score>0:
		SpriteFont.text(canvas,Vector2(320,5),Ranking.score_text(last_score),true)
