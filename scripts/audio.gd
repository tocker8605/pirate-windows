class_name PirateAudio
extends Node
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var track: String = ""
var effects: Dictionary = {}
var music_streams: Dictionary = {}
var stream_loads: int = 0
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
func music_stream(track_id: String) -> AudioStreamOggVorbis:
	if not music_streams.has(track_id):
		stream_loads+=1
		# Loop policy belongs to this audio owner, not the global ResourceLoader cache.
		var stream: AudioStreamOggVorbis=load("res://assets/music/%s.ogg"%track_id).duplicate()
		# Retain prepared tracks across stop()/play(), including the boss transition.
		stream.loop=false
		music_streams[track_id]=stream
	return music_streams[track_id]
func prepare_music(tracks: Array) -> void:
	for id in tracks:music_stream(id)
func play(track_id: String, from_seconds: float = 0, restart: bool = false, looping: bool = true) -> void:
	var stream: AudioStreamOggVorbis=music_stream(track_id)
	stream.loop=looping
	stream.loop_offset=0
	if track==track_id and music.playing and not restart: return
	music.stream = stream
	track = track_id
	music.play(maxf(0,from_seconds))
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
	music_streams.clear()
