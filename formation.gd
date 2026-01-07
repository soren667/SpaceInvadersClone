extends Node2D
class_name Formation

@export var enemy_scene: PackedScene
@export var row_types: Array[EnemyStats] # size >= rows recommended

@export var rows := 5
@export var cols := 11
@export var cell_size := Vector2(32, 28)
@export var start_local := Vector2(80, 80)

@export var step_x := 10.0
@export var step_down := 16.0
@export var left_margin := 16.0
@export var right_margin := 16.0

@export var base_interval := 0.6
@export var min_interval := 0.08

var _dir := 1
var _alive := 0
var _total := 0

@onready var _timer: Timer = %StepTimer

func _ready() -> void:
	_spawn_grid()
	_timer.wait_time = base_interval
	_timer.timeout.connect(_on_step)
	_timer.start()

func _spawn_grid() -> void:
	_alive = 0

	for r in range(rows):
		for c in range(cols):
			var e := enemy_scene.instantiate() as Enemy
			var idx: int = mini(r, row_types.size() - 1)
			e.stats = row_types[idx]

			e.position = start_local + Vector2(c * cell_size.x, r * cell_size.y)
			add_child(e)

			e.died.connect(_on_enemy_died)
			_alive += 1

	_total = _alive

func _on_step() -> void:
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

func _on_enemy_died() -> void:
	_alive -= 1

	# Speed-up: fewer alive => faster ticks
	var t := float(_alive) / float(_total) # 1.0 -> 0.0
	_timer.wait_time = lerpf(min_interval, base_interval, t)
	_timer.start() # restart timer to apply wait_time immediately

	if _alive <= 0:
		GameManager.complete_level()
