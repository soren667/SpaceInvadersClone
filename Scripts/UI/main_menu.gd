extends Control

@onready var v_box_container: VBoxContainer = $CenterContainer/VBoxContainer

#USE THIS FOR FUTURE REFERENCE FOR GAME UI: https://www.gameuidatabase.com/index.php
func _ready():
	%PlayButton.pressed.connect(play)
	%QuitButton.pressed.connect(quit_game)
	
	AudioManager.play_music("chipnese")
	
func _on_button_pressed():
	AudioManager.play_sfx("click")
	
func play():
	print("PLAY BUTTON!!")
	get_tree().change_scene_to_file("res://Scene/game.tscn")
	
func quit_game():
	get_tree().quit()
