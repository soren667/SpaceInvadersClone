extends Node2D
class_name DeathRing

@export var lifetime: float = 0.18
@export var start_scale: float = 1.0
@export var end_scale: float = 2.2

@onready var _sprite: Sprite2D = %Sprite2D

func _ready() -> void:
	_sprite.scale = Vector2.ONE * start_scale
	_sprite.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2.ONE * end_scale, lifetime)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
