extends CharacterBody2D

signal player_moved(new_pos : Vector2)

@export var speed : int = 35000
@export var friction : float = 15

var controlable = true
var old_pos := Vector2.ZERO


func get_input(delta : float):
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var new_velocity = input_direction * speed * delta
	velocity = velocity.move_toward(new_velocity, friction)


func _physics_process(delta : float) -> void:
	if controlable:
		get_input(delta)
	
	old_pos = position
	move_and_slide()
	
	if position != old_pos: player_moved.emit(position)


func set_player_name(player_name : String) -> void:
	$NameLabel.text = player_name
