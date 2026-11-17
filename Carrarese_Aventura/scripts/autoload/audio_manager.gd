extends Node

## Manages background music and sound-effect playback globally.

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var _music_volume_db: float = 0.0
var _sfx_volume_db: float = 0.0


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)


# --- Music ---

func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.volume_db = _music_volume_db
	music_player.play()


func stop_music() -> void:
	music_player.stop()


# --- SFX ---

func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.volume_db = _sfx_volume_db
	sfx_player.play()


# --- Volume ---

func set_music_volume(value: float) -> void:
	_music_volume_db = value
	music_player.volume_db = value


func set_sfx_volume(value: float) -> void:
	_sfx_volume_db = value
	sfx_player.volume_db = value
