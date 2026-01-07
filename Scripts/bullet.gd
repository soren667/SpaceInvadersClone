extends Area2D

@export var speed := 500.0
@export var damage := 1

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.y -= speed * delta
	
	# Check if off-screen (above viewport)
	# Delete bullet when it goes off-screen
	# This prevents memory leaks!
	if position.y < -50:
		queue_free()

func _on_area_entered(area: Area2D) -> void:

	if area.has_method("take_damage"):
		area.call("take_damage", damage)
		queue_free()
