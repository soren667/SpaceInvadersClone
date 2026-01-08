extends CanvasLayer
class_name WinUI

signal menu_pressed

@onready var _menu: Button = %MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_menu.pressed.connect(func(): menu_pressed.emit())
