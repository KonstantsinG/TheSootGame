extends Node

signal request_sended(request : Dictionary)
signal back_to_menu_pressed(room_name : String)

@onready var cave_room = $CaveRoom
@onready var game_pause = $GamePause

var room_name := ""


func _ready() -> void:
	cave_room.request_sended.connect(_on_request_sended)
	
	game_pause.back_to_menu_pressed.connect(_on_game_pause_back_to_menu_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		game_pause.visible = !game_pause.visible


func spawn_players(you, guests : Array) -> void:
	cave_room.spawn_players(you, guests)


func update_player_position(player_id : int, new_position : Vector2) -> void:
	cave_room.update_player_position(player_id, new_position)
	
	# TODO: the same for the BoilerRoom


func remove_player(id : int) -> void:
	cave_room.remove_player(id)
	
	# TODO: the same for the BoilerRooom


func _on_request_sended(request : Dictionary) -> void:
	request["room_name"] = room_name
	request_sended.emit(request)


func _on_game_pause_back_to_menu_pressed() -> void:
	back_to_menu_pressed.emit(room_name)
