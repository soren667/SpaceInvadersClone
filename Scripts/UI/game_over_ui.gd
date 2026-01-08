extends CanvasLayer
class_name GameOverUI

signal restart_pressed
signal quit_pressed

@onready var _restart: Button = %RestartButton
@onready var _quit: Button = %QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_restart.pressed.connect(func(): restart_pressed.emit())
	_quit.pressed.connect(func(): quit_pressed.emit())
