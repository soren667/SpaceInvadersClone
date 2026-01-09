extends CanvasLayer

@onready var menu_ui: Control = $ColorRect
@onready var v_box: VBoxContainer = %OptionsMenuVBoxContainer
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var back_button: Button = %OptionsBackButton
@onready var crt_check_box: CheckBox = %CrtCheckBox

var active_tween: Tween

func _ready() -> void:
	hide()
	_setup_signals()

func _setup_signals() -> void:
	# Connect slider logic
	master_slider.value_changed.connect(_on_volume_changed.bind("master"))
	music_slider.value_changed.connect(_on_volume_changed.bind("music"))
	sfx_slider.value_changed.connect(_on_volume_changed.bind("sfx"))
	back_button.pressed.connect(_on_back_pressed)
	crt_check_box.toggled.connect(_on_crt_changed)

# --- Visibility ---

func show_menu() -> void:
	show()
	AudioManager.play_sfx("maximize_001")

	master_slider.set_value_no_signal(SettingsManager.master_volume_pct)
	music_slider.set_value_no_signal(SettingsManager.music_volume_pct)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume_pct)

	crt_check_box.set_pressed_no_signal(SettingsManager.crt_enabled)

	# Entrance Animation
	if active_tween: active_tween.kill()
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	menu_ui.modulate.a = 0.0
	menu_ui.scale = Vector2(0.8, 0.8)
	menu_ui.pivot_offset = menu_ui.size / 2

	active_tween.tween_property(menu_ui, "modulate:a", 1.0, 0.3)
	active_tween.tween_property(menu_ui, "scale", Vector2.ONE, 0.3)

func hide_menu() -> void:
	# You could add a fade-out here, but for now:
	hide()
	# Only unpause if the game manager says the game is active
	#if GameManager.is_game_active():
		#get_tree().paused = false

# --- Handlers ---

func _on_volume_changed(value: float, bus: String) -> void:
	var linear_val = value / 100.0
	match bus:
		"master": AudioManager.set_master_volume(linear_val)
		"music":  AudioManager.set_music_volume(linear_val)
		"sfx":    AudioManager.set_sfx_volume(linear_val)

	# Play tick sound (AudioManager should handle the actual sound call)
	AudioManager.play_sfx("tick", 0.05) # Lower variance for UI ticks


func _on_back_pressed() -> void:
	AudioManager.play_sfx("back_001")

	SettingsManager.apply_audio_from_menu(
		int(master_slider.value),
		int(music_slider.value),
		int(sfx_slider.value)
	)

	hide_menu()
	
func _on_crt_changed(value: bool ) -> void:
	SettingsManager.set_crt_enabled(value)
	AudioManager.play_sfx("tick", 0.05)
