extends Node

@onready var music_player: AudioStreamPlayer = $music_player
@onready var sfx_player: AudioStreamPlayer = $sfx_player
@onready var sfx_player_2: AudioStreamPlayer = $sfx_player_2

var music_paths = [
	"res://assets/Match 3 Sounds/Match 3 Sounds/Music/theme-1.ogg",
	"res://assets/Match 3 Sounds/Match 3 Sounds/Music/theme-2.ogg",
	"res://assets/Match 3 Sounds/Match 3 Sounds/Music/theme-3.ogg",
	"res://assets/Match 3 Sounds/Match 3 Sounds/Music/theme-4.ogg",
]

var sfx_paths = {
	"invalid": "res://assets/Match 3 Sounds/Match 3 Sounds/Sounds/1.ogg",
	"swap": "res://assets/Match 3 Sounds/Match 3 Sounds/Sounds/3.ogg",
	"match": "res://assets/Match 3 Sounds/Match 3 Sounds/Sounds/4.ogg",
	"button": "res://assets/Match 3 Sounds/Match 3 Sounds/Sounds/5.ogg",
	"win": "res://assets/Match 3 Sounds/Match 3 Sounds/Sounds/6.ogg",
	"lose": "res://assets/Match 3 Sounds/Match 3 Sounds/Sounds/7.ogg",
}

var music_tracks = []
var sfx = {}
var current_track = 0
var use_second_sfx_player = false


func _ready() -> void:
	music_player.volume_db = -9.0
	load_music()
	load_sfx()
	music_player.finished.connect(_on_music_finished)
	play_next_music()


func load_music() -> void:
	for path in music_paths:
		var track = load(path)
		if track != null:
			music_tracks.append(track)


func load_sfx() -> void:
	for sound_name in sfx_paths:
		var sound = load(sfx_paths[sound_name])
		if sound != null:
			sfx[sound_name] = sound


func play_next_music() -> void:
	if music_tracks.is_empty():
		return

	music_player.stream = music_tracks[current_track]
	music_player.play()
	current_track += 1
	if current_track >= music_tracks.size():
		current_track = 0


func _on_music_finished() -> void:
	play_next_music()


func play_sfx(sound_name: String) -> void:
	if not sfx.has(sound_name):
		return

	var player = sfx_player
	if use_second_sfx_player:
		player = sfx_player_2

	use_second_sfx_player = not use_second_sfx_player
	player.stream = sfx[sound_name]
	player.play()
