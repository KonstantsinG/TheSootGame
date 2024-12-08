extends CharacterBody2D

signal player_moved(id : int, new_position : Vector2)
signal coal_picked_up(coal_id : int)

@export var speed : int = 13_000
@export var acceleration : float = 1.8
@export var friction : float = 4.5
@export var coal_weight_factor : float = 0.75
@export var position_interpolation_smooth := 0.07

@onready var team_marker = $PlayerData/TeamMarkerSprite
@onready var name_label = $PlayerData/NameLabel
@onready var camera = $Camera2D
@onready var action_panel = $ActionContainer/KeyPanel

var max_zoom = 4
var min_zoom = 2
var zoom_step = Vector2(0.1, 0.1)

var controlable : bool = true:
	get: return controlable
	set(value):
		controlable = value
		camera.enabled = value

var target_position := position
var id := 0
var team := 0
var coal = null

var facing_barricade = null
var facing_soot = null


func _ready() -> void:
	$AnimationPlayer.play("idle")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scroll_up"):
		if camera.zoom.x < max_zoom:
				camera.zoom += zoom_step
	elif event.is_action_pressed("scroll_down"):
		if camera.zoom.x > min_zoom:
				camera.zoom -= zoom_step
	
	if event.is_action_pressed("attack"):
		if facing_barricade != null:
			facing_barricade.start_breaking()
			$BreakingTimer.start()
	elif event.is_action_released("attack"):
		if facing_barricade != null:
			facing_barricade.stop_breaking()
			$BreakingTimer.stop()


func place_barricade() -> Node2D:
	if coal == null: return null
	else:
		$CoalContainer.remove_child(coal)
		var barricade = coal
		coal.to_barricade()
		coal = null
		return barricade


func toggle_action_panel(_visible : bool) -> void:
	action_panel.visible = _visible


func get_coal_type() -> int:
	if coal != null:
		return coal.get_type()
	else:
		return -1


func take_coal() -> void:
	if coal == null:
		coal = preload("res://scenes/game_locations/objects/coal.tscn").instantiate()
		$CoalContainer.add_child(coal)
		coal.scale = Vector2(1.75, 1.75)


func give_coal(coal_id : int, type : int):
	if coal == null:
		coal = preload("res://scenes/game_locations/objects/coal.tscn").instantiate()
		$CoalContainer.add_child(coal)
		coal.set_type(type)
		coal.id = coal_id
		coal.scale = Vector2(1.75, 1.75)


func drop_coal() -> int:
	var score = 0
	
	if coal != null:
		score = coal.get_cost()
		toggle_action_panel(false)
		$CoalContainer.remove_child(coal)
	
	coal = null
	return score


func set_data(_id : int, _name : String, _team : GameParams.TeamTypes) -> void:
	match _team:
		GameParams.TeamTypes.RED:
			team_marker.self_modulate = Color.RED
		
		GameParams.TeamTypes.BLUE:
			team_marker.self_modulate = Color.BLUE
		
		GameParams.TeamTypes.GREEN:
			team_marker.self_modulate = Color.GREEN
		
		GameParams.TeamTypes.YELLOW:
			team_marker.self_modulate = Color.YELLOW
	
	name_label.text = _name
	id = _id
	team = _team


func pick_up_coal(_coal) -> void:
	_coal.to_collectible()
	coal = _coal
	
	_coal.get_parent().remove_child(_coal)
	_coal = null
	$CoalContainer.add_child(coal)
	coal.scale = Vector2(1.75, 1.75)
	coal.position = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if controlable:
		_move_controlable(delta)
	else:
		_move_uncontrolable()


func _move_controlable(delta : float):
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var acc = acceleration if Input.is_action_pressed("speed_up") else 1.0
	var new_vel = input * speed * delta * acc
	if coal != null: new_vel *= coal_weight_factor
	
	var old_pos = position
	
	velocity = velocity.move_toward(new_vel, friction)
	move_and_slide()
	
	if position != old_pos and $MovementTimer.time_left == 0:
		player_moved.emit(position)
		$MovementTimer.start()


func _move_uncontrolable():
	position = position.lerp(target_position, position_interpolation_smooth)


func _on_interacting_area_body_entered(body: Node2D) -> void:
	if body == self or !controlable: return
	
	if body is CharacterBody2D:
		facing_soot = body
	elif body is StaticBody2D and body.is_in_group("barricades"):
		facing_barricade = body.get_parent()


func _on_interacting_area_body_exited(body: Node2D) -> void:
	if !controlable: return
	
	if body == facing_soot:
		facing_soot = null
	elif body.get_parent() == facing_barricade:
		facing_barricade.stop_breaking()
		facing_barricade = null


func _on_breaking_timer_timeout() -> void:
	if facing_barricade != null:
		pick_up_coal(facing_barricade)
		coal_picked_up.emit(coal.id)
