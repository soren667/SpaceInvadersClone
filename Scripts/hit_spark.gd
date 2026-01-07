extends Node2D

@export var lifetime: float = 0.08
@export var scale_to: float = 1.4

@onready var _sprite: Sprite2D = %Sprite2D

func _ready() -> void:
	_sprite.modulate = Color(1, 1, 0.6) # warm yellow-ish
	# Quick pop + fade using a Tween
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", _sprite.scale * scale_to, lifetime)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
