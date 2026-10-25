class_name PirateAudio
extends Node
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var track: String = ""
var effects: Dictionary = {}
func _ready() -> void:
	music = AudioStreamPlayer.new()
	effect = AudioStreamPlayer.new()
	add_child(music)
	add_child(effect)
	effect.volume_db = -6
	for id in ["bang-e","bang-be","damage","get","pil","shi"]: effects[id] = load("res://assets/audio/%s.wav"%id)
func sync(muted: bool, paused: bool) -> void:
	music.volume_db = -80 if muted else -8
	music.stream_paused = paused
func play(track_id: String) -> void:
	if track==track_id and music.playing: return
	var stream: AudioStreamOggVorbis = load("res://assets/music/%s.ogg"%track_id)
	# MCI play in the original runs once; it does not request repeat/notify looping.
	stream.loop = false
	music.stream = stream
	track = track_id
	music.play()
func stop() -> void:
	track = ""
	music.stop()
	music.stream = null
func sound(id: String, muted: bool) -> void:
	if muted: return
	# sndPlaySound(..., SND_ASYNC) replaces the one active waveform.
	effect.stream = effects[id]
	effect.play()
func stop_all() -> void:
	stop()
	effect.stop()
	effect.stream = null

func _exit_tree() -> void:
	stop()
	effect.stop()
	effect.stream = null
	effects.clear()
