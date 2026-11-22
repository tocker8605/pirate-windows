extends RefCounted
## Owns game-state changes and their input/time/audio effects. Combat owns its timers.
const Clock = preload("res://scripts/timing.gd")
const Campaign = preload("res://scripts/campaign_rules.gd")
const RunResult = preload("res://scripts/run_result.gd")
const ClearScreen = preload("res://scripts/clear_screen.gd")
enum MusicPolicy { STOP, KEEP }
const MENU: StringName = &"menu"
const LOADING: StringName = &"loading"
const PLAYING: StringName = &"playing"
const DYING: StringName = &"dying"
const BOSS_DYING: StringName = &"boss_dying"
const PAUSED: StringName = &"paused"
const RANKING_ENTRY: StringName = &"ranking_entry"
const CLEAR: StringName = &"clear"
const NON_GAMEPLAY_STATES: Array = [MENU,LOADING,RANKING_ENTRY,CLEAR]
const ACTIVE_STATES: Array = [PLAYING,DYING,BOSS_DYING]
var state: StringName = MENU
var resume_state: StringName = PLAYING
var loading_image: String = "loading"
var loading_target: int = 1
var loading_preserve: bool = false
var loading_remaining_seconds: float = 0
var completed_run: RunResult
func finish_run(g: Node, cleared: bool = false) -> void:
	g._remember_score()
	completed_run=RunResult.new(g.last_score,g.run_settings,g.stage,cleared)
	if completed_run.cleared: show_clear(g)
	else: _offer_ranking(g)
	g.score=0
func confirm_clear(g: Node, confirm_key: int) -> void:
	if state!=CLEAR or completed_run==null: return
	_offer_ranking(g,g.clear_screen.background,MusicPolicy.KEEP,confirm_key)
func _offer_ranking(g: Node, background: Texture2D = null, music_policy: MusicPolicy = MusicPolicy.STOP, confirm_key: int = 0) -> void:
	var position: int=g.rankings.insertion_index(int(completed_run.record.score)) if completed_run.ranking_eligible else -1
	if position>=0:
		g.ranking_entry.begin(position,completed_run.record,background,confirm_key)
		show_ranking(g,music_policy)
	else: show_menu(g,confirm_key)
func submit_ranking(g: Node, confirm_key: int) -> void:
	if g.rankings.submit(g.ranking_entry.record,g.ranking_entry.player_name)!=OK:
		g.ranking_entry.save_failed=true
		return
	show_menu(g,confirm_key)
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
func show_ranking(g: Node, music_policy: MusicPolicy = MusicPolicy.STOP) -> void:
	_enter(g,RANKING_ENTRY,true)
	g.slow_movement_active = false
	if music_policy==MusicPolicy.STOP: g._stop_music()
func show_clear(g: Node) -> void:
	g.clear_screen.begin(completed_run.record,g.screen_textures.get_texture(ClearScreen.BACKGROUND_PATH))
	_enter(g,CLEAR,true)
	g.slow_movement_active = false
	g._play_music(ClearScreen.MUSIC_TRACK,ClearScreen.MUSIC_START_SECONDS,true,false)
func load_stage(g: Node, target: int, preserve: bool, image: String, delay: float = 0) -> void:
	loading_target = target
	loading_preserve = preserve
	loading_image = image
	loading_remaining_seconds = delay
	_enter(g,LOADING,true)
	g._stop_music()
func play_stage(g: Node) -> void:
	_enter(g,PLAYING,true)
	if g.run_settings.boss_rush: g._stop_music()
	else: g._play_music(Campaign.music(g.stage))
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
