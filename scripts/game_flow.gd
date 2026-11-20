extends RefCounted
## Owns game-state changes and their input/time/audio effects. Combat owns its timers.
const Clock = preload("res://scripts/timing.gd")
const MENU: StringName = &"menu"
const LOADING: StringName = &"loading"
const PLAYING: StringName = &"playing"
const DYING: StringName = &"dying"
const BOSS_DYING: StringName = &"boss_dying"
const PAUSED: StringName = &"paused"
const RANKING_ENTRY: StringName = &"ranking_entry"
const ACTIVE_STATES: Array = [PLAYING,DYING,BOSS_DYING]
var state: StringName = MENU
var resume_state: StringName = PLAYING
var loading_image: String = "loading2"
var loading_target: int = 1
var loading_preserve: bool = false
var loading_remaining_seconds: float = 0
var legend_elapsed: float = 0
func _enter(g: Node, next: StringName, reset_time: bool = false) -> void:
	state = next
	g.title.clear_input()
	if reset_time: g.accumulator = 0
	g._sync_audio()
func show_menu(g: Node, confirm_key: int = 0) -> void:
	_enter(g,MENU,true)
	g.title.reset()
	g.title.block_confirmation_until_release(confirm_key)
	g.slow_movement_active = false
	g._stop_music()
func show_ranking(g: Node) -> void:
	_enter(g,RANKING_ENTRY,true)
	g.slow_movement_active = false
	g._stop_music()
func load_stage(g: Node, target: int, preserve: bool, image: String, delay: float = 0) -> void:
	loading_target = target
	loading_preserve = preserve
	loading_image = image
	loading_remaining_seconds = delay
	# Loading legends retain their last stage-time pose, as before.
	legend_elapsed = g.stage_elapsed_seconds
	_enter(g,LOADING,true)
	g._stop_music()
func play_stage(g: Node) -> void:
	_enter(g,PLAYING,true)
	if g.run_settings.boss_rush: g._stop_music()
	else: g._play_music("bgm%02d"%g.stage)
func advance_loading(g: Node, seconds: float) -> void:
	if loading_remaining_seconds>0:
		loading_remaining_seconds = Clock.countdown(loading_remaining_seconds,seconds)
		return
	g._load_stage(loading_target,loading_preserve)
func player_died(g: Node) -> void:
	_enter(g,DYING)
	g.beam_remaining_seconds = 0
	g.beam_render_seconds = 0
	if g.music_track!="boss01": g._stop_music()
func boss_died(g: Node) -> void:
	if g.death_remaining_seconds==0: _enter(g,BOSS_DYING)
func pause(g: Node) -> void:
	if state not in ACTIVE_STATES: return
	resume_state = state
	_enter(g,PAUSED)
func resume(g: Node) -> void:
	if state==PAUSED: _enter(g,resume_state)
func toggle_pause(g: Node) -> void:
	if state==PAUSED: resume(g)
	else: pause(g)
