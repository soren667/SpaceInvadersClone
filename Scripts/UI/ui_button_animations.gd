extends Node
## Attach this to any container with buttons for automatic hover effects
"""
Open your scene (e.g., main_menu.tscn)
In the Scene tree, right-click on your VBoxContainer
Select "Add Child Node"
Search for and select "Node" (just the base Node class)
Rename it to something like "ButtonAnimations"
With ButtonAnimations selected, look at the Inspector panel on the right
At the top, you'll see "Script" - click the scroll/page icon next to it
Choose "Load" and select your ui_button_animations.gd file
"""

@export var hover_scale := Vector2(1.05, 1.05)
@export var hover_color := Color(1.2, 1.2, 1.2)

func _ready() -> void:
	var parent = get_parent()
	if parent is Container:
		for child in parent.get_children():
			if child is Button:
				child.pivot_offset = child.size / 2
				child.mouse_entered.connect(_on_hover.bind(child))
				child.mouse_exited.connect(_on_unhover.bind(child))

func _on_hover(btn: Button) -> void:
	AudioManager.play_sfx("hover")
	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "scale", hover_scale, 0.1)
	t.tween_property(btn, "modulate", hover_color, 0.1)

func _on_unhover(btn: Button) -> void:
	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "scale", Vector2.ONE, 0.1)
	t.tween_property(btn, "modulate", Color.WHITE, 0.1)
