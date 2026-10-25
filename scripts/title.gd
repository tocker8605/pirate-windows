class_name PirateTitle
extends RefCounted
const WeaponPreview = preload("res://scripts/weapon_preview.gd")
var weapon_preview = WeaponPreview.new()
var preview_clock: int = 0
var loading_ticks: int = 1
var phase: int = 0
var slide: int = 0
var scroll: int = 0
var speed: int = 1
var difficulty: int = 3
var boss_rush: bool = false

func reset() -> void:
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
	elif phase>=21 and phase<=25:
		if key==KEY_UP: phase = maxi(21,phase-1)
		if key==KEY_DOWN: phase = mini(25,phase+1)
		if phase==21:
			if key==KEY_LEFT: speed = maxi(1,speed-1)
			if key==KEY_RIGHT: speed = mini(5,speed+1)
		if phase==22:
			if key==KEY_LEFT: difficulty = maxi(1,difficulty-1)
			if key==KEY_RIGHT: difficulty = mini(5,difficulty+1)

func confirm() -> String:
	match phase:
		0:
			phase = 1
			slide = 1
			return "opening"
		11,12:
			boss_rush = phase==12
			phase = 21
		13: return "continue"
		23,24,25: return "play"
	return ""

func render(canvas: Node2D, art: RefCounted, last_score: int) -> void:
	canvas.draw_rect(Rect2(0,0,400,480),Color.BLACK)
	if loading_ticks>0:
		canvas.draw_texture(art.texture("tocker"),Vector2.ZERO)
		return
	if phase==0:
		canvas.draw_texture(art.texture("piclog"),Vector2.ZERO)
		draw_score(canvas,art,last_score)
		return
	var dx: int = int(round(scroll/3.5))
	canvas.draw_texture_rect_region(art.texture("stage0"),Rect2(-dx,0,400,480),Rect2(0,480-scroll,400,480))
	var pane_x: int = int(round(slide*2.6))
	canvas.draw_texture_rect_region(art.texture("piclog"),Rect2(pane_x,0,400-pane_x,480),Rect2(0,0,400-pane_x,480))
	canvas.draw_texture(art.sprite("piclogo",Rect2i(0,0,300,100),Vector2i(0,100)),Vector2(10,50))
	if phase>=11 and phase<=13:
		for i in range(3):
			copy(canvas,art,Vector2(250,[260,290,330][i]),Rect2i(0,40+i*20,130,20))
		copy(canvas,art,Vector2(240,[260,290,330][phase-11]),Rect2i(120,0,10,20))
	elif phase>=21:
		copy(canvas,art,Vector2(250,260),Rect2i(0,0,120,20))
		copy(canvas,art,Vector2(250,290),Rect2i(0,20,130,20))
		for i in range(3):
			copy(canvas,art,Vector2(250,335+i*40),Rect2i(0,100+i*30,55,30))
			weapon_preview.draw_small(canvas,Rect2(307,332+i*40,83,36),i+1,preview_clock,phase==23+i)
		weapon_preview.draw_large(canvas,art,Rect2(16,250,210,192),clampi(phase-22,1,3),preview_clock)
		for pair in [[speed,260],[difficulty,290]]:
			canvas.draw_texture(art.sprite("pichud",Rect2i(pair[0]*10,156,10,20),Vector2i(pair[0]*10,176)),Vector2(370,pair[1]))
		copy(canvas,art,Vector2(240,[260,290,340,380,420][phase-21]),Rect2i(120,0,10,20))
	draw_score(canvas,art,last_score)

static func draw_score(canvas: Node2D, art: RefCounted, last_score: int) -> void:
	var digits: String = str(maxi(last_score,0))
	if last_score>0:
		for i in range(mini(digits.length(),6)):
			var n: int = int(digits[digits.length()-1-i])
			canvas.draw_texture(art.sprite("pichud",Rect2i(n*10,156,10,20),Vector2i(n*10,176)),Vector2(380-i*10,5))

static func copy(canvas: Node2D, art: RefCounted, pos: Vector2, rect: Rect2i) -> void:
	canvas.draw_texture_rect_region(art.texture("piclogom"),Rect2(pos,Vector2(rect.size)),Rect2(rect))
