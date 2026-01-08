extends CharacterBody2D

signal shoot_requested(spawn_position: Vector2)

@export var speed := 400.0
@export var shoot_cooldown := 0.25
@export var clamp_screen_margin := 30

@export var respawn_delay: float = 0.25
@export var invuln_time: float = 1.5
@export var blink_interval: float = 0.12

var _spawn_pos: Vector2
var _invulnerable: bool = false
var _respawning: bool = false
var _controls_enabled: bool = true

var _default_collision_layer: int
var _default_collision_mask: int
var can_shoot := true

func _ready() -> void:
	_spawn_pos = global_position
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	
func _physics_process(delta: float) -> void:
	if not _controls_enabled:
		velocity.x = 0.0
		move_and_slide()
		return
		
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

func take_damage(amount: int, at: Vector2 = Vector2.INF) -> void:
	if _invulnerable or _respawning:
		return
	if not GameManager.is_game_active():
		return

	_respawning = true
	_controls_enabled = false
	can_shoot = false
	
	AudioManager.play_sfx("player_death", .1)
	GameManager.lose_life(amount)
	
	if not GameManager.is_game_active() or GameManager.get_lives() <= 0:
		visible = false
		_disable_collisions()
		return
	
	await _respawn_sequence()
	
func _respawn_sequence() -> void:
	# "Death" moment
	visible = false
	_disable_collisions()

	await get_tree().create_timer(respawn_delay).timeout

	# Respawn
	global_position = _spawn_pos
	visible = true

	# Invulnerability window
	_invulnerable = true
	_controls_enabled = true
	can_shoot = true

	var elapsed: float = 0.0
	while elapsed < invuln_time:
		visible = not visible
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval

	visible = true
	_invulnerable = false
	_enable_collisions()
	_respawning = false

func _disable_collisions() -> void:
	collision_layer = 0
	collision_mask = 0

func _enable_collisions() -> void:
	collision_layer = _default_collision_layer
	collision_mask = _default_collision_mask
