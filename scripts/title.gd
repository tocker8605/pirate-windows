class_name PirateTitle
extends RefCounted
const WeaponPreview = preload("res://scripts/weapon_preview.gd")
const SpriteFont = preload("res://scripts/menu_sprite_font.gd")
const RankingScreen = preload("res://scripts/ranking_screen.gd")
var weapon_preview = WeaponPreview.new()
var preview_clock: int = 0
var loading_ticks: int = 1
var phase: int = 0
var slide: int = 0
var scroll: int = 0
var difficulty: int = 3
var boss_rush: bool = false
const NAVIGATION_KEYS: Array = [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]
const REPEAT_DELAY: float = 0.35
const REPEAT_INTERVAL: float = 0.15
var navigation_key: int = 0
var repeat_remaining: float = 0

func clear_navigation() -> void:
	navigation_key = 0
	repeat_remaining = 0

func navigation_input(key: int, pressed: bool, echo: bool = false) -> void:
	if not pressed:
		if navigation_key==key: clear_navigation()
		return
	if echo or navigation_key==key: return
	navigation_key = key
	repeat_remaining = REPEAT_DELAY
	navigate(key)

func repeat_navigation(delta: float) -> void:
	if navigation_key==0: return
	repeat_remaining -= delta
	if repeat_remaining<=0:
		navigate(navigation_key)
		# Avoid a burst of repeated moves after a stalled render frame.
		repeat_remaining = REPEAT_INTERVAL

func reset() -> void:
	clear_navigation()
	loading_ticks = 0
	phase = 0
	slide = 0
	scroll = 0

func tick() -> void:
	preview_clock += 1
	loading_ticks = maxi(0,loading_ticks-1)
	if phase==1 and slide>0: slide += 1
	if slide==95:
		phase = 11
		slide = 96
	if phase>0: scroll = mini(scroll+1,479)

func navigate(key: int) -> void:
	if phase>=11 and phase<=13:
		if key==KEY_UP: phase = maxi(11,phase-1)
		if key==KEY_DOWN: phase = mini(13,phase+1)
	elif phase>=22 and phase<=25:
		if key==KEY_UP: phase = maxi(22,phase-1)
		if key==KEY_DOWN: phase = mini(25,phase+1)
		if phase==22:
			if key==KEY_LEFT: difficulty = maxi(1,difficulty-1)
			if key==KEY_RIGHT: difficulty = mini(5,difficulty+1)

func confirm() -> String:
	clear_navigation()
	match phase:
		0:
			phase = 1
			slide = 1
			return "opening"
		11,12:
			boss_rush = phase==12
			phase = 22
		13: return "continue"
		23,24,25: return "play"
	return ""

func render(canvas: Node2D, art: RefCounted, last_score: int, earth_background: bool = false, rankings: Array = []) -> void:
	if not earth_background: canvas.draw_rect(Rect2(0,0,400,480),Color.BLACK)
	if loading_ticks>0:
		canvas.draw_texture(art.texture("tocker"),Vector2.ZERO)
		return
	if phase==0:
		draw_rankings(canvas,art,last_score,rankings)
		return
	var dx: int = int(round(scroll/3.5))
	if earth_background: canvas.draw_rect(Rect2(400-dx,0,dx,480),Color.BLACK)
	else: canvas.draw_texture_rect_region(art.texture("stage0"),Rect2(-dx,0,400,480),Rect2(0,480-scroll,400,480))
	var pane_x: int = int(round(slide*2.6))
	canvas.draw_texture_rect_region(art.texture("piclog"),Rect2(pane_x,0,400-pane_x,480),Rect2(0,0,400-pane_x,480))
	canvas.draw_texture(art.sprite("piclogo",Rect2i(0,0,300,100),Vector2i(0,100)),Vector2(10,50))
	if phase>=11 and phase<=13:
		for i in range(3):
			SpriteFont.text(canvas,Vector2(250,[260,290,330][i]),["NEW GAME","BOSS RUSH","CONTINUE"][i])
		SpriteFont.icon(canvas,Vector2(235,[260,290,330][phase-11]),SpriteFont.MENU_CURSOR)
	elif phase>=21:
		SpriteFont.text(canvas,Vector2(250,260),"GAME LEVEL")
		for i in range(3):
			SpriteFont.text(canvas,Vector2(250,340+i*40),"TYPE")
			SpriteFont.text(canvas,Vector2(290,340+i*40),str(i+1),true)
			weapon_preview.draw_small(canvas,Rect2(307,332+i*40,83,36),i+1,preview_clock,phase==23+i)
		SpriteFont.text(canvas,Vector2(370,260),str(difficulty),true)
		SpriteFont.icon(canvas,Vector2(235,[260,340,380,420][phase-22]),SpriteFont.MENU_CURSOR)
	draw_score(canvas,art,last_score)

static func draw_rankings(canvas: Node2D, art: RefCounted, last_score: int, rankings: Array) -> void:
	canvas.draw_texture(art.texture("piclog"),Vector2.ZERO)
	RankingScreen.board(canvas,rankings)
	draw_score(canvas,art,last_score)

static func draw_score(canvas: Node2D, _art: RefCounted, last_score: int) -> void:
	if last_score>0:
		SpriteFont.text(canvas,Vector2(320,5),RankingScreen.score_text(last_score),true)

static func copy(canvas: Node2D, art: RefCounted, pos: Vector2, rect: Rect2i) -> void:
	canvas.draw_texture_rect_region(art.texture("piclogom"),Rect2(pos,Vector2(rect.size)),Rect2(rect))
