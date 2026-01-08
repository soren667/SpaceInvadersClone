extends Area2D
class_name Enemy

signal hit(at: Vector2)
signal died(points: int, at: Vector2)

@export var stats: EnemyStats

var _hp: int = 1
var col: int = -1

@onready var _anim: AnimatedSprite2D = %EnemyAnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	_apply_stats()

func _apply_stats() -> void:
	if stats == null:
		push_warning("Enemy has no stats assigned.")
		return

	if stats.sprite_frames != null:
		_anim.sprite_frames = stats.sprite_frames
		_anim.animation = stats.animation
		_anim.speed_scale = stats.anim_speed_scale
		_anim.play()
	else:
		push_warning("EnemyStats.sprite_frames is not assigned.")

	_hp = stats.max_hp

func take_damage(amount: int, at: Vector2 = Vector2.INF) -> void:
	var hit_pos := at
	if hit_pos == Vector2.INF:
		hit_pos = global_position

	_hp -= amount

	if _hp <= 0:
		died.emit(stats.points, hit_pos)
		queue_free()
	else:
		hit.emit(hit_pos)
