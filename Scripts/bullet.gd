extends Area2D
class_name Bullet

@export var speed := 500.0
@export var damage := 1
@export var direction: Vector2 = Vector2.UP
@export var offscreen_margin: float = 50.0

func _ready() -> void:
	area_entered.connect(_on_area_entered) # Enemies are Area2D
	body_entered.connect(_on_body_entered) # Player is Character2D

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# Delete bullet when it goes off-screen
	# Otherwise memory leaks
	var h := get_viewport_rect().size.y
	if global_position.y < -offscreen_margin or global_position.y > h + offscreen_margin:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.call("take_damage", damage, global_position)
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", damage, global_position)
		queue_free()
