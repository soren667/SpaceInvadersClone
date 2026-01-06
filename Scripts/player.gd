extends CharacterBody2D

signal shoot_requested(spawn_position: Vector2)

@export var speed := 400.0
@export var shoot_cooldown := 0.25
@export var clamp_screen_margin := 30

var can_shoot := true

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed
	move_and_slide()
	_clamp_to_screen()

	if Input.is_action_pressed("shoot") and can_shoot:
		_shoot()

# Instead of Area2DStaticBodies - clamp so we can scale to higher resolutions
func _clamp_to_screen() -> void:
	var screen_size = get_viewport_rect().size
	global_position.x = clamp(
		global_position.x,
		clamp_screen_margin,
		screen_size.x - clamp_screen_margin
	)

func _shoot() -> void:
	can_shoot = false
	var spawn_pos = global_position + Vector2(0, -20)

	shoot_requested.emit(spawn_pos)
	AudioManager.play_sfx("laserSmall_002", 0.2)

	# Cooldown timer
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
