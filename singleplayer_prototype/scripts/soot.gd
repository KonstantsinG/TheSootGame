extends CharacterBody2D

@export var speed : int = 10000
@export var friction : int = 5
@export var acceleration : int = 2


func input(delta : float) -> void:
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var acc = Input.get_action_strength("speed_up") * acceleration
	var new_vel = dir * delta * speed
	if acc != 0: new_vel *= acc
	velocity = velocity.move_toward(new_vel, friction)


func _physics_process(delta: float) -> void:
	input(delta)
	move_and_slide()
