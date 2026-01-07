extends Area2D
class_name Enemy

signal died(points: int)

@export var stats: EnemyStats

var _hp: int = 1

@onready var _sprite: Sprite2D = %EnemySprite2D

func _ready() -> void:
	add_to_group("enemies")
	_apply_stats()

func _apply_stats() -> void:
	if stats == null:
		push_warning("Enemy has no stats assigned.")
		return
	_sprite.texture = stats.texture
	_hp = stats.max_hp

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		died.emit(stats.points)
		GameManager.add_score(stats.points)
		queue_free()
