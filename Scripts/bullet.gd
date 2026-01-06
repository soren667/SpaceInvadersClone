extends Area2D

@export var speed := 500.0

func _ready() -> void:
	# Delete bullet when it goes off-screen
	# This prevents memory leaks!
	pass

func _physics_process(delta: float) -> void:
	position.y -= speed * delta
	
	# Check if off-screen (above viewport)
	# Delete bullet when it goes off-screen
	# This prevents memory leaks!
	if position.y < -50:
		queue_free()
