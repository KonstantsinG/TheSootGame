extends CharacterBody2D

signal player_moved(id : int, new_position : Vector2)

@export var speed : int = 20_000
@export var acceleration : float = 2.0
@export var friction : float = 7.5

@onready var team_marker = $PlayerData/TeamMarkerSprite
@onready var name_label = $PlayerData/NameLabel

var controlable : bool = true:
	get: return controlable
	set(value):
		set_physics_process(value)
		controlable = value
var id := 0


func _ready() -> void:
	$AnimationPlayer.play("idle")


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
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var acc = acceleration if Input.is_action_pressed("speed_up") else 1.0
	var new_vel = input * speed * delta * acc
	
	var old_pos = position
	
	velocity = velocity.move_toward(new_vel, friction)
	move_and_slide()
	
	if position != old_pos:
		player_moved.emit(position)
