extends Node2D

@onready var player = $Player

func _ready() -> void:
	GameManager.start_game()
	if PauseMenu.has_signal("quit_pressed"):
		PauseMenu.quit_pressed.connect(_on_pause_quit)
	# pause_menu.resume_pressed.connect(_on_pause_resume)  


func _on_pause_quit() -> void:
	PauseMenu.reset_state()
	GameManager.set_paused(false)
	#ToDo - Setup a proper scene manager singleton
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
