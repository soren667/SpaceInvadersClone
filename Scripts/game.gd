extends Node2D

var bullet_scene = preload("res://Scene/bullet.tscn")
@onready var player = $Player

func _ready() -> void:
	GameManager.start_game()
	if PauseMenu.has_signal("quit_pressed"):
		PauseMenu.quit_pressed.connect(_on_pause_quit)
	# pause_menu.resume_pressed.connect(_on_pause_resume)
	
	player.shoot_requested.connect(_on_player_shoot)

func _on_player_shoot(spawn_pos: Vector2) -> void:
	# Scene logic: manage bullets
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_pos
	add_child(bullet)

func _on_pause_quit() -> void:
	PauseMenu.reset_state()
	GameManager.set_paused(false)
	#ToDo - Setup a proper scene manager singleton
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
