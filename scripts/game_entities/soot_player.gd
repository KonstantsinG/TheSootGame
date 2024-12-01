extends CharacterBody2D

signal player_moved(id : int, new_position : Vector2)

@export var speed : int = 13_000
@export var acceleration : float = 1.8
@export var friction : float = 4.5
@export var coal_weight_factor : float = 0.75

@onready var team_marker = $PlayerData/TeamMarkerSprite
@onready var name_label = $PlayerData/NameLabel
@onready var camera = $Camera2D

var max_zoom = 4
var min_zoom = 2
var zoom_step = Vector2(0.1, 0.1)

var controlable : bool = true:
	get: return controlable
	set(value):
		controlable = value
		camera.enabled = value

var target_position := position
@export var position_interpolation_smooth := 0.07
var id := 0

@onready var action_panel = $ActionContainer/KeyPanel
var coal = null


func _ready() -> void:
	$AnimationPlayer.play("idle")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scroll_up"):
		if camera.zoom.x < max_zoom:
				camera.zoom += zoom_step
	elif event.is_action_pressed("scroll_down"):
		if camera.zoom.x > min_zoom:
				camera.zoom -= zoom_step


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
		coal.scale = Vector2(1.5, 1.5)


func give_coal(type : int):
	if coal == null:
		coal = preload("res://scenes/game_locations/objects/coal.tscn").instantiate()
		$CoalContainer.add_child(coal)
		coal.set_type(type)
		coal.scale = Vector2(1.5, 1.5)


func drop_coal() -> void:
	if coal != null:
		toggle_action_panel(false)
		$CoalContainer.remove_child(coal)
	
	coal = null


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
