extends CharacterBody2D

@export var controlable : bool = true
@export var speed : int = 10000
@export var friction : int = 5
@export var acceleration : int = 2

var holding_coal := false
var push_body = null


func input(delta : float) -> void:
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var acc = Input.get_action_strength("speed_up") * acceleration
	var new_vel = dir * delta * speed
	if acc != 0: new_vel *= acc
	velocity = velocity.move_toward(new_vel, friction)


func _physics_process(delta: float) -> void:
	if not controlable:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
		move_and_slide()
		return
	
	input(delta)
	move_and_slide()


func _input(event: InputEvent) -> void:
	if push_body != null and controlable:
		if event.is_action_pressed("attack"):
			var dir = velocity.normalized()
			if dir == Vector2.ZERO: dir = Vector2(-1, 0)
			push_body.push(dir)
			push_body = null


func take_coal() -> bool:
	if holding_coal: return false
	
	holding_coal = true
	var coal = preload("res://singleplayer_prototype/scenes/coal.tscn").instantiate()
	$CoalContainer.add_child(coal)
	return true


func drop_coal() -> bool:
	if not holding_coal: return false
	
	holding_coal = false
	var coal = $CoalContainer.get_children()[0]
	$CoalContainer.remove_child(coal)
	coal.queue_free()
	return true


func push(direction : Vector2) -> void:
	velocity += direction * 300


func _on_pushing_area_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D: return
	elif body == self: return
	
	push_body = body


func _on_pushing_area_body_exited(body: Node2D) -> void:
	if not body is CharacterBody2D: return
	elif body == self: return
	
	push_body = null
