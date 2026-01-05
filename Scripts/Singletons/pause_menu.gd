extends CanvasLayer
## Global pause menu singleton.
## Set this Autoload to use the .tscn file, not just the .gd script.

signal quit_pressed

@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var resume_button: Button = %ResumeButton
@onready var menu_container: Control = $ColorRect

@export var options_menu_scene: PackedScene = preload("res://Scene/options_menu.tscn")
var options_menu: CanvasLayer

func _ready() -> void:
	# Autoloads stay in memory; this node must ignore SceneTree pausing
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	hide()
	
	# Instantiate Options as a child of this Layer or separately
	if options_menu_scene:
		options_menu = options_menu_scene.instantiate()
		add_child(options_menu)
		# Connect the options menu's "hidden" or "back" logic to show the Pause Menu again
		options_menu.visibility_changed.connect(_on_options_visibility_changed)

	_setup_signals()

func _setup_signals() -> void:
	options_button.pressed.connect(show_options)
	resume_button.pressed.connect(resume)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	# Only allow pausing if the GameManager says a game is actually in progress
	if event.is_action_pressed("ui_cancel") and GameManager.is_game_active():
		
		# If options is open, let it handle the back button (it usually hides itself)
		if options_menu and options_menu.visible:
			return 
			
		toggle_pause()

func toggle_pause() -> void:
	if GameManager.is_paused():
		resume()
	else:
		pause()

func pause() -> void:
	GameManager.set_paused(true)
	AudioManager.play_sfx("maximize_001")
	show()
	
	# Animation for the pause overlay
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_container.modulate.a = 0
	tween.tween_property(menu_container, "modulate:a", 1.0, 0.2)

func resume() -> void:
	GameManager.set_paused(false)
	hide()

func show_options() -> void:
	if options_menu:
		options_menu.show_menu()
		# We hide the pause UI while options is open for visual clarity
		menu_container.hide() 

func _on_options_visibility_changed() -> void:
	# If options menu was just closed but we are still paused, show the pause buttons again
	if options_menu and not options_menu.visible and GameManager.is_paused():
		menu_container.show()

func _on_quit_pressed() -> void:
	GameManager.set_paused(false)
	quit_pressed.emit()
	
func reset_state() -> void:
	hide()
	# Ensure options menu also hides if it was left open
	if options_menu:
		options_menu.hide()
