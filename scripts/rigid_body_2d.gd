extends RigidBody2D


func _physics_process(delta: float) -> void:
	linear_velocity = linear_velocity.move_toward(Vector2.ZERO, 10)
