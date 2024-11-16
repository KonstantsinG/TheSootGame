extends Node

signal request_sended(request : Dictionary)

@onready var cave_room = $CaveRoom

var room_name := ""


func _ready() -> void:
	cave_room.request_sended.connect(_on_request_sended)


func spawn_players(you, guests : Array) -> void:
	cave_room.spawn_players(you, guests)


func update_player_position(player_id : int, new_position : Vector2) -> void:
	cave_room.update_player_position(player_id, new_position)
	
	# TODO: the same for the BoilerRoom


func _on_request_sended(request : Dictionary) -> void:
	request["room_name"] = room_name
	request_sended.emit(request)
