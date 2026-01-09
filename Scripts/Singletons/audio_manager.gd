extends Node

# --- Configuration ---
const SFX_POOL_SIZE = 12 # Increased slightly for safety
const SFX_BUS_NAME = "SFX"
const MUSIC_BUS_NAME = "Music"

# --- State ---
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_index: int = 0 # Points to the next player to use (Ring Buffer)
var sound_cache: Dictionary = {} # Stores loaded streams to prevent disk lag

var music_player_1: AudioStreamPlayer
var music_player_2: AudioStreamPlayer 
var current_music_player: AudioStreamPlayer

var original_music_vol_linear: float = 1.0
var is_music_ducked: bool = false
var active_music_tween: Tween

# Preload critical UI sounds
var ui_sounds = {
	"hover": preload("res://Assets/Sounds/hover.ogg"),
	"click": preload("res://Assets/Sounds/click.ogg"),
	"tick": preload("res://Assets/Sounds/glass_002.ogg"),
	"explode": preload("res://Assets/Sounds/explosionCrunch_000.ogg"),
	"impact": preload("res://Assets/Sounds/impactMetal_003.ogg"),
	"player_death": preload("res://Assets/Sounds/explosionCrunch_004.ogg"),
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. Setup SFX Pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = SFX_BUS_NAME
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		sfx_players.append(player)

	# 2. Setup Double Music Players (for Crossfading)
	music_player_1 = AudioStreamPlayer.new()
	music_player_1.bus = MUSIC_BUS_NAME
	add_child(music_player_1)

	music_player_2 = AudioStreamPlayer.new()
	music_player_2.bus = MUSIC_BUS_NAME
	add_child(music_player_2)

	current_music_player = music_player_1

	# 3. Cache UI sounds immediately
	for key in ui_sounds:
		sound_cache[key] = ui_sounds[key]

	SettingsManager.audio_changed.connect(_apply_settings_volumes)
	_apply_settings_volumes()

# --- SFX System ---

func play_sfx(key: String, pitch_var: float = 0.1, volume_db: float = 0.0) -> void:
	var stream = _get_stream(key)
	if not stream:
		return

	# Ring Buffer: Always pick the next index, wrapping around.
	# This ensures we overwrite the OLDEST sound, not the first one.
	var player = sfx_players[sfx_pool_index]
	sfx_pool_index = (sfx_pool_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	player.play()

func _get_stream(key: String) -> AudioStream:
	# 1. Check Cache (Fastest)
	if sound_cache.has(key):
		return sound_cache[key]

	# 2. Check Disk (Slow, but happens only once per sound)
	var extensions = [".wav", ".ogg", ".mp3"]
	for ext in extensions:
		var path = "res://Assets/Sounds/%s%s" % [key, ext]
		if ResourceLoader.exists(path):
			var stream = load(path)
			sound_cache[key] = stream # Store in cache!
			return stream

	push_warning("AudioManager: Sound not found: %s" % key)
	return null

# --- Music System ---

func play_music(key: String, fade_duration: float = 0.5) -> void:
	var stream = _get_stream(key)
	if not stream: return

	# If we are already playing this song, do nothing
	if current_music_player.playing and current_music_player.stream == stream:
		return

	# Determine which player is free (active vs background)
	var new_player = music_player_2 if current_music_player == music_player_1 else music_player_1
	var old_player = current_music_player

	# Setup new song
	new_player.stream = stream
	new_player.volume_db = -80 # Start silent
	new_player.play()

	# Crossfade
	if active_music_tween: active_music_tween.kill()
	active_music_tween = create_tween()

	# Fade IN new
	active_music_tween.parallel().tween_property(new_player, "volume_db", linear_to_db(original_music_vol_linear), fade_duration)
	# Fade OUT old
	if old_player.playing:
		active_music_tween.parallel().tween_property(old_player, "volume_db", -80, fade_duration)

	active_music_tween.tween_callback(old_player.stop)

	current_music_player = new_player

func stop_music(fade_duration: float = 1.0) -> void:
	if active_music_tween: active_music_tween.kill()
	active_music_tween = create_tween()
	active_music_tween.tween_property(current_music_player, "volume_db", -80, fade_duration)
	active_music_tween.tween_callback(current_music_player.stop)

# --- Ducking (e.g., when dialogue plays) ---

func duck_music(target_vol_linear: float = 0.2, duration: float = 0.5) -> void:
	is_music_ducked = true
	# We rely on the Bus volume for ducking to avoid conflicting with the crossfade tweening of the player itself
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	var original_db = linear_to_db(original_music_vol_linear)
	var target_db = linear_to_db(original_music_vol_linear * target_vol_linear)

	var tween = create_tween()
	tween.tween_method(func(v): AudioServer.set_bus_volume_db(bus_idx, v), original_db, target_db, duration)

func unduck_music(duration: float = 0.5) -> void:
	if not is_music_ducked: return
	is_music_ducked = false

	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	var current_db = AudioServer.get_bus_volume_db(bus_idx)
	var target_db = linear_to_db(original_music_vol_linear)

	var tween = create_tween()
	tween.tween_method(func(v): AudioServer.set_bus_volume_db(bus_idx, v), current_db, target_db, duration)

# --- Volume Persistence ---

func set_bus_volume(bus_name: String, linear_val: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_name == MUSIC_BUS_NAME:
		original_music_vol_linear = linear_val

	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))

func set_master_volume(volume: float) -> void:
	set_bus_volume("Master", volume)

func set_music_volume(volume: float) -> void:
	set_bus_volume(MUSIC_BUS_NAME, volume)

func set_sfx_volume(volume: float) -> void:
	set_bus_volume(SFX_BUS_NAME, volume)

func _apply_settings_volumes() -> void:
	set_master_volume(SettingsManager.get_master_linear())
	set_music_volume(SettingsManager.get_music_linear())
	set_sfx_volume(SettingsManager.get_sfx_linear())
