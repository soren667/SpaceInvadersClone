extends PanelContainer
# Example of how to setup a clean Godot UI
# Aarimous
# https://www.youtube.com/watch?v=8boLA6Hdvn8

# Configuration
@export_group("Settings")
@export var auto_hide := true
@export var display_time := 3.0
@export var resize_icons := false
@export var center_on_screen := true

@export_group("Asset Paths")
@export var KEY_PATH = "res://Assets/Sprites/UI/"

# Internal references
@onready var key_a: TextureRect = %KeyA
@onready var key_d: TextureRect = %KeyD
@onready var mouse_icon: TextureRect = %MouseIcon

# State tracking
var _is_fading_out := false
var _active_tween: Tween

func _ready() -> void:
	_load_key_sprite(key_a, "keyboard_a_outline.png")
	_load_key_sprite(key_d, "keyboard_d_outline.png")
	_load_key_sprite(mouse_icon, "mouse_left_outline.png")

	if resize_icons:
		for icon in [key_a, key_d, mouse_icon]:
			icon.custom_minimum_size = Vector2(32, 32)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	if center_on_screen:
		_center_panel()

	if auto_hide:
		_start_presentation()

func _input(event: InputEvent) -> void:
	# If we are already leaving, ignore input
	if _is_fading_out or not visible:
		return

	if event.is_action_pressed("move_left") or \
	   event.is_action_pressed("move_right") or \
	   event.is_action_pressed("shoot"):

		_trigger_early_fadeout()

func _center_panel() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	# Ensure it stays on top of other UI/Game elements
	z_index = 100

func _start_presentation() -> void:
	modulate.a = 0.0

	if _active_tween: _active_tween.kill()
	_active_tween = create_tween()

	# Fade In
	_active_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)

	# Wait (Fallback timer only)
	_active_tween.tween_interval(display_time)

	# Fade Out (Automatic)
	_active_tween.tween_callback(_trigger_early_fadeout)

func _trigger_early_fadeout() -> void:
	if _is_fading_out: return
	_is_fading_out = true

	if _active_tween: _active_tween.kill()
	_active_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Scale up slightly while fading out for a "Pop" effect
	var original_scale = scale
	_active_tween.set_parallel(true)
	_active_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_active_tween.tween_property(self, "scale", original_scale * 1.1, 0.4)

	_active_tween.chain().tween_callback(queue_free)

func _load_key_sprite(texture_rect: TextureRect, filename: String) -> void:
	var path = KEY_PATH + filename
	if ResourceLoader.exists(path):
		texture_rect.texture = load(path)
	else:
		push_warning("ControlsPanel: Sprite not found: %s" % path)
