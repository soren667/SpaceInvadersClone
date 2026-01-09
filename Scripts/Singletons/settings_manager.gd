extends Node
# Use this as a Guide: https://www.gdquest.com/library/save_game_godot4/#godot-4s-save-methods
const SETTINGS_PATH := "user://settings.cfg"
const LEGACY_JSON_PATH := "user://settings.save"
const SETTINGS_VERSION := "1.0"

signal audio_changed
signal crt_changed(enabled: bool)

var crt_enabled: bool = true


var master_volume_pct: int = 100
var music_volume_pct: int = 100
var sfx_volume_pct: int = 100

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_emit_all()

func _emit_all() -> void:
	audio_changed.emit()
	crt_changed.emit(crt_enabled)

func set_crt_enabled(v: bool) -> void:
	if crt_enabled == v:
		return
	crt_enabled = v
	crt_changed.emit(crt_enabled)
	save_settings()

func set_master_volume_pct(v: int) -> void:
	v = clampi(v, 0, 100)
	if master_volume_pct == v:
		return
	master_volume_pct = v
	audio_changed.emit()
	save_settings()

func set_music_volume_pct(v: int) -> void:
	v = clampi(v, 0, 100)
	if music_volume_pct == v:
		return
	music_volume_pct = v
	audio_changed.emit()
	save_settings()

func set_sfx_volume_pct(v: int) -> void:
	v = clampi(v, 0, 100)
	if sfx_volume_pct == v:
		return
	sfx_volume_pct = v
	audio_changed.emit()
	save_settings()

func get_master_linear() -> float:
	return float(master_volume_pct) / 100.0

func get_music_linear() -> float:
	return float(music_volume_pct) / 100.0

func get_sfx_linear() -> float:
	return float(sfx_volume_pct) / 100.0

func apply_audio_from_menu(master_pct: int, music_pct: int, sfx_pct: int) -> void:
	master_volume_pct = clampi(master_pct, 0, 100)
	music_volume_pct  = clampi(music_pct, 0, 100)
	sfx_volume_pct    = clampi(sfx_pct, 0, 100)

	audio_changed.emit()
	save_settings()
	
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SETTINGS_VERSION)

	cfg.set_value("video", "crt_enabled", crt_enabled)

	cfg.set_value("audio", "master_volume", master_volume_pct)
	cfg.set_value("audio", "music_volume", music_volume_pct)
	cfg.set_value("audio", "sfx_volume", sfx_volume_pct)

	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: Failed to save settings: " + error_string(err))

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)

	if err == OK:
		var version := str(cfg.get_value("meta", "version", "0"))
		if version != SETTINGS_VERSION and version != "0":
			push_warning("SettingsManager: Unknown version %s; using defaults." % version)
			return

		crt_enabled = bool(cfg.get_value("video", "crt_enabled", true))

		master_volume_pct = int(cfg.get_value("audio", "master_volume", 100))
		music_volume_pct  = int(cfg.get_value("audio", "music_volume", 100))
		sfx_volume_pct    = int(cfg.get_value("audio", "sfx_volume", 100))

		master_volume_pct = clampi(master_volume_pct, 0, 100)
		music_volume_pct  = clampi(music_volume_pct, 0, 100)
		sfx_volume_pct    = clampi(sfx_volume_pct, 0, 100)
		return

	if err != ERR_FILE_NOT_FOUND:
		push_error("SettingsManager: Failed to load settings.cfg: " + error_string(err))

	save_settings()
