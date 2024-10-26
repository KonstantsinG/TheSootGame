extends CharacterBody2D


func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 3)
	move_and_slide()
