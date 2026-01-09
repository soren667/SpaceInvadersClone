extends Node2D

@export var main_menu_scene: String = "res://Scene/main_menu.tscn"
var bullet_scene = preload("res://Scene/bullet.tscn")
@export var formation_scene: PackedScene
@onready var player = %Player
@onready var _game_over_ui: GameOverUI = %GameOverUI
@onready var _win_ui: WinUI = %WinUI
@onready var crt_fx: CanvasLayer = $UI/PostFX

func _ready() -> void:

	_apply_crt(SettingsManager.crt_enabled)
	SettingsManager.crt_changed.connect(_apply_crt)
	
	GameManager.start_game()
	if PauseMenu.has_signal("quit_pressed"):
		PauseMenu.quit_pressed.connect(_on_pause_quit)
	# pause_menu.resume_pressed.connect(_on_pause_resume)
	GameManager.game_over.connect(_on_game_over)
	_game_over_ui.quit_pressed.connect(_quit_game)
	_game_over_ui.restart_pressed.connect(_restart)
	
	GameManager.level_complete.connect(_on_level_complete)
	_win_ui.menu_pressed.connect(_go_menu)

	player.shoot_requested.connect(_on_player_shoot)

func _on_player_shoot(spawn_pos: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_pos
	add_child(bullet)

func _on_pause_quit() -> void:
	PauseMenu.reset_state()
	GameManager.set_paused(false)
	#ToDo - Setup a proper scene manager singleton
	get_tree().change_scene_to_file(main_menu_scene)

func _go_menu() -> void:
	GameManager.set_paused(false)
	get_tree().change_scene_to_file(main_menu_scene)

func _on_level_complete() -> void:
	GameManager.set_paused(true)
	_game_over_ui.visible = false
	_win_ui.visible = true
		
func _restart() -> void:
	_game_over_ui.visible = false
	_win_ui.visible = false
	get_tree().reload_current_scene()

func _on_game_over() -> void:
	GameManager.set_paused(true)
	_win_ui.visible = false
	_game_over_ui.visible = true

func _quit_game() -> void:
	get_tree().quit(1)

func _apply_crt(enabled: bool) -> void:
	crt_fx.visible = enabled
