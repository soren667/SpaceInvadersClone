extends CanvasLayer
class_name HUD

@export var life_icon: Texture2D
@export var life_icon_size: Vector2 = Vector2(36, 18)

@onready var _score_value: Label = %ScoreValue
@onready var _hi_value: Label = %HiScoreValue
@onready var _lives_display: HBoxContainer = %LivesDisplay

func _ready() -> void:
	# Connect once; HUD reacts to GameManager state changes
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)

	_on_score_changed(GameManager.get_score())
	_on_high_score_changed(GameManager.get_high_score())
	_on_lives_changed(GameManager.get_lives())

func _on_score_changed(new_score: int) -> void:
	_score_value.text = "%06d" % new_score

func _on_high_score_changed(new_high_score: int) -> void:
	_hi_value.text = "%06d" % new_high_score

func _on_lives_changed(new_lives: int) -> void:
	for child: Node in _lives_display.get_children():
		child.queue_free()

	if life_icon == null:
		return

	for i: int in range(new_lives):
		var icon := TextureRect.new()
		icon.texture = life_icon
		icon.custom_minimum_size = life_icon_size
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_lives_display.add_child(icon)
