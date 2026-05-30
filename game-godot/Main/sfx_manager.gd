extends Node

var music_player : AudioStreamPlayer
var sfx_pool     : Dictionary = {}

var music_tracks = [
	"res://assets/sfx/theme.mp3",
	"res://assets/sfx/theme2.mp3",
	"res://assets/sfx/theme3.mp3"
]
var current_track_idx = -1

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	
	_register_sfx("walk", "res://assets/sfx/walking_sfx.mp3", -12.0)
	_register_sfx("portal_fire", "res://assets/sfx/laser_gun_shoot_sfx.mp3", -5.0)
	_register_sfx("portal_spawn", "res://assets/sfx/portal_sound_sfx.mp3", -5.0)
	_register_sfx("laser_on", "res://assets/sfx/laser_obstacle.mp3", -8.0)
	_register_sfx("laser_off", "res://assets/sfx/laser_obstacle.mp3", -8.0, 0.75) # pitch shifted down
	_register_sfx("player_hurt", "res://assets/sfx/Player_damage.mp3", -2.0)
	_register_sfx("door_open", "res://assets/sfx/door_opening_sfx.mp3", -5.0)
	_register_sfx("ui_click", "res://assets/sfx/button_click.mp3", -8.0)

func _register_sfx(sfx_name: String, path: String, vol_db: float, pitch: float = 1.0) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = vol_db
	player.pitch_scale = pitch
	add_child(player)
	sfx_pool[sfx_name] = player

func play_sfx(sfx_name: String) -> void:
	if not sfx_pool.has(sfx_name): return
	
	if sfx_name == "walk":
		if not sfx_pool[sfx_name].playing:
			sfx_pool[sfx_name].play()
		return
		
	sfx_pool[sfx_name].stop()
	sfx_pool[sfx_name].play()

func stop_sfx(sfx_name: String) -> void:
	if sfx_pool.has(sfx_name):
		sfx_pool[sfx_name].stop()

func play_music_shuffle() -> void:
	if not music_player.playing:
		music_tracks.shuffle()
		_play_next_music()

func stop_music() -> void:
	music_player.stop()

func _play_next_music() -> void:
	if music_tracks.size() == 0: return
	current_track_idx = (current_track_idx + 1) % music_tracks.size()
	music_player.stream = load(music_tracks[current_track_idx])
	music_player.volume_db = -10.0
	music_player.play()

func _on_music_finished() -> void:
	_play_next_music()
