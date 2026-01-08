extends Node2D
class_name Formation

@export var enemy_scene: PackedScene
@export var row_types: Array[EnemyStats] # size >= rows recommended

@export var hit_fx_scene: PackedScene
@export var death_fx_scene: PackedScene

@export var rows := 5
@export var cols := 11
@export var cell_size := Vector2(52, 52) # Spacing of the enemy sprites in the formation
@export var start_local := Vector2(0, 0)

@export var step_x := 20.0
@export var step_down := 16.0
@export var left_margin := 16.0
@export var right_margin := 16.0

@export var base_interval := 0.5
@export var min_interval := 0.08

# --- Enemy attack settings
@export var bullet_scene: PackedScene = preload("res://Scene/bullet.tscn")
@export var shoot_interval: float = 1.0
@export var max_enemy_bullets: int = 3
@export var enemy_bullet_speed: float = 260.0
@export var enemy_bullet_damage: int = 1

@onready var _shoot_timer: Timer = %ShootTimer
@onready var _timer: Timer = %StepTimer

var _dir := 1
var _alive := 0
var _total := 0

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)
	
	_spawn_grid()
	_timer.wait_time = base_interval
	_timer.timeout.connect(_on_step)
	_timer.start()

	_shoot_timer.wait_time = shoot_interval
	_shoot_timer.timeout.connect(_on_shoot_tick)
	_shoot_timer.start()

func _spawn_grid() -> void:
	_alive = 0

	for r in range(rows):
		for c in range(cols):
			var e := enemy_scene.instantiate() as Enemy
			var idx: int = mini(r, row_types.size() - 1)
			e.stats = row_types[idx]
			e.col = c

			e.position = start_local + Vector2(c * cell_size.x, r * cell_size.y)
			add_child(e)

			e.hit.connect(_on_enemy_hit)
			e.died.connect(_on_enemy_died)
			_alive += 1

	_total = _alive

func _on_enemy_hit(at: Vector2) -> void:
	AudioManager.play_sfx("impact", 0.3)
	_spawn_fx(hit_fx_scene, at)


func _on_enemy_died(points: int, at: Vector2) -> void:
	AudioManager.play_sfx("explode", 0.2)
	GameManager.add_score(points)
	_alive -= 1

	_spawn_fx(death_fx_scene, at)

	var t := float(_alive) / float(_total)
	_timer.wait_time = lerpf(min_interval, base_interval, t)
	_timer.start()

	if _alive <= 0:
		GameManager.complete_level()

func _on_step() -> void:
	if not GameManager.is_game_active():
		return
	if _alive <= 0:
		return

	# Predict next x after moving.
	var bounds := _compute_local_bounds()
	var next_left := global_position.x + bounds.position.x + (_dir * step_x)
	var next_right := global_position.x + bounds.position.x + bounds.size.x + (_dir * step_x)

	var view_w := get_viewport_rect().size.x

	var would_hit_left := next_left < left_margin
	var would_hit_right := next_right > (view_w - right_margin)

	if would_hit_left or would_hit_right:
		# Space Invaders "bounce": go down, flip direction.
		global_position.y += step_down
		_dir *= -1
	else:
		global_position.x += _dir * step_x

func _compute_local_bounds() -> Rect2:
	# Compute a rough bounding box around living enemies.
	# We expand by one cell so edges behave nicely.
	var first := true
	var min_x := 0.0
	var max_x := 0.0
	var min_y := 0.0
	var max_y := 0.0

	for child in get_children():
		if child is Enemy:
			var p := (child as Node2D).position
			if first:
				min_x = p.x
				max_x = p.x
				min_y = p.y
				max_y = p.y
				first = false
			else:
				min_x = minf(min_x, p.x)
				max_x = maxf(max_x, p.x)
				min_y = minf(min_y, p.y)
				max_y = maxf(max_y, p.y)

	if first:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var pos := Vector2(min_x, min_y)
	var size := Vector2((max_x - min_x) + cell_size.x, (max_y - min_y) + cell_size.y)
	return Rect2(pos, size)

func _on_shoot_tick() -> void:
	if not GameManager.is_game_active():
		return
	if _alive <= 0:
		return
	if bullet_scene == null:
		return

	# Limit bullets on screen
	var existing: int = get_tree().get_nodes_in_group("enemy_bullets").size()
	if existing >= max_enemy_bullets:
		return

	var shooters := _get_bottom_shooters()
	if shooters.is_empty():
		return

	var shooter: Enemy = shooters.pick_random()
	_spawn_enemy_bullet(shooter)

func _get_bottom_shooters() -> Array[Enemy]:
	var bottom_by_col := {}

	for child in get_children():
		if child is Enemy:
			var e := child as Enemy
			if e.col < 0:
				continue

			if not bottom_by_col.has(e.col):
				bottom_by_col[e.col] = e
			else:
				var cur: Enemy = bottom_by_col[e.col]
				if e.global_position.y > cur.global_position.y:
					bottom_by_col[e.col] = e

	var out: Array[Enemy] = []
	for v in bottom_by_col.values():
		out.append(v as Enemy)
	return out

func _spawn_enemy_bullet(shooter: Enemy) -> void:
	var b: Bullet = bullet_scene.instantiate() as Bullet
	if b == null:
		return

	# Spawn slightly below the enemy
	b.global_position = shooter.global_position + Vector2(0, 16)

	b.direction = Vector2.DOWN
	b.speed = enemy_bullet_speed
	b.damage = enemy_bullet_damage

	# Configure collision (layers 1..32)
	const LAYER_PLAYER := 1
	const LAYER_ENEMY_BULLET := 4

	b.collision_layer = 0
	b.collision_mask = 0
	b.set_collision_layer_value(LAYER_ENEMY_BULLET, true)
	b.set_collision_mask_value(LAYER_PLAYER, true)

	b.add_to_group("enemy_bullets")

	# Put bullets somewhere sensible if you have a container
	var parent := get_tree().current_scene
	parent.add_child(b)

func _spawn_fx(scene: PackedScene, at: Vector2) -> void:
		if scene == null:
			return

		var fx := scene.instantiate() as Node2D
		if fx == null:
			return

		fx.global_position = at

		var fx_parent := get_tree().get_first_node_in_group("fx")
		if fx_parent != null:
			fx_parent.add_child(fx)
		else:
			get_tree().current_scene.add_child(fx)

func _on_game_over() -> void:
	_stop_combat()

func _on_level_complete() -> void:
	_stop_combat()

func _stop_combat() -> void:
	_timer.stop()
	_shoot_timer.stop()
