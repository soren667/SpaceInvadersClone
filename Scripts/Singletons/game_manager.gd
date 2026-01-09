extends Node

# Use this as a Guide: https://www.gdquest.com/library/save_game_godot4/#godot-4s-save-methods
const SAVE_PATH := "user://savegame.save"
const SAVE_VERSION := "1.0"  

# Signals - UI/Scenes can connect to these
signal score_changed(new_score: int)
signal high_score_changed(new_high_score: int)
signal lives_changed(new_lives: int)
signal game_started
signal game_over
signal level_complete
signal game_paused(paused: bool)

# Configuration
@export_group("Configuration")
@export var default_lives := 3
@export var max_lives := 9
@export var max_score := 999999

# Internal state - use getters/setters to access
var _score := 0
var _high_score := 0
var _lives := 0
var _is_game_active := false
var _is_paused := false

func _ready() -> void:
	# Ensure this node runs even when the SceneTree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	if default_lives < 1:
		push_warning("GameManager: default_lives should be >= 1. Setting to 1.")
		default_lives = 1

	load_game()

# --- Game Flow ---

func start_game() -> void:
	_is_game_active = true
	_score = 0
	_lives = default_lives

	set_paused(false)

	# Emit initial state so UI updates immediately
	score_changed.emit(_score)
	lives_changed.emit(_lives)
	high_score_changed.emit(_high_score)
	game_started.emit()

func restart_game() -> void:
	_score = 0
	_lives = default_lives
	start_game()

func end_game() -> void:
	_is_game_active = false
	save_game()
	game_over.emit()

func complete_level() -> void:
	_is_game_active = false
	save_game()
	level_complete.emit()

func reset_for_next_level() -> void:
	_is_game_active = true
	set_paused(false)
	# Score and lives carry over

# --- Pause ---

func toggle_pause() -> void:
	set_paused(not _is_paused)

func set_paused(paused: bool) -> void:
	_is_paused = paused
	get_tree().paused = paused
	game_paused.emit(paused)

# --- Score & Lives ---

func add_score(points: int) -> void:
	if points <= 0 or not _is_game_active:
		return

	_score = mini(_score + points, max_score)
	score_changed.emit(_score)
	
	# Auto-update high score
	if _score > _high_score:
		_high_score = mini(_score, max_score)
		high_score_changed.emit(_high_score)

func lose_life(amount: int = 1) -> void:
	if not _is_game_active or amount <= 0:
		return

	_lives = max(_lives - amount, 0)
	lives_changed.emit(_lives)

	if _lives == 0:
		end_game()

func add_life(amount: int = 1) -> void:
	if not _is_game_active or amount <= 0:
		return

	_lives = mini(_lives + amount, max_lives)
	lives_changed.emit(_lives)

# --- Persistence ---

func save_game() -> void:
	var save_data := {
		"version": SAVE_VERSION,
		"high_score": _high_score
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("GameManager: Failed to write save file.")
		return

	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return # No save file, keep defaults

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("GameManager: Failed to read save file.")
		return

	var json_string := file.get_as_text()
	file.close()

	var parsed_result: Variant = JSON.parse_string(json_string)

	if typeof(parsed_result) != TYPE_DICTIONARY:
		push_error("GameManager: Save file corrupted.")
		return

	# Explicit cast to Dictionary after type check
	var data := parsed_result as Dictionary
	var version := str(data.get("version", "0"))

	# Version-specific loading with migration support
	match version:
		SAVE_VERSION:
			# Current version - load normally
			_high_score = int(data.get("high_score", 0))

		"0":
			# Legacy save without version number - attempt migration
			push_warning("GameManager: Migrating legacy save file (v0 -> v%s)" % SAVE_VERSION)
			_high_score = int(data.get("high_score", 0))
			save_game() # Re-save with current version

		_:
			# Unknown/future version - reset to defaults for safety
			push_warning("GameManager: Unknown save version %s (expected v%s). Resetting to defaults." % [version, SAVE_VERSION])
			_high_score = 0
			return

	high_score_changed.emit(_high_score)

func clear_save_data() -> bool:
	var dir := DirAccess.open("user://")
	if not dir:
		push_error("GameManager: Failed to access user directory.")
		return false

	var err := dir.remove("savegame.save")
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("GameManager: Failed to delete save file: " + error_string(err))
		return false

	_high_score = 0
	high_score_changed.emit(_high_score)
	return true

# --- Getters ---

func get_score() -> int:
	return _score

func get_high_score() -> int:
	return _high_score

func get_lives() -> int:
	return _lives

func is_game_active() -> bool:
	return _is_game_active

func is_paused() -> bool:
	return _is_paused
