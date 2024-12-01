extends Node

signal request_sended(request : Dictionary)
signal back_to_menu_pressed(room_name : String)

@onready var cave_room = $CaveRoom
@onready var boiler_room
@onready var game_pause = $GamePause

var room_name := ""


func _ready() -> void:
	boiler_room = preload("res://scenes/game_locations/boiler_room.tscn").instantiate()
	
	boiler_room.request_sended.connect(_on_request_sended)
	boiler_room.room_exited.connect(_on_boiler_room_exited)
	
	cave_room.request_sended.connect(_on_request_sended)
	cave_room.room_exited.connect(_on_cave_room_exited)
	
	game_pause.back_to_menu_pressed.connect(_on_game_pause_back_to_menu_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		game_pause.visible = !game_pause.visible


func switch_room(player_id : int, destination : String, hole_id : int) -> void:
	if destination == "BOILER_ROOM":
		var player = cave_room.leave_room(player_id)
		boiler_room.spawn_player(player, hole_id, false)
	
	elif destination == "CAVE_ROOM":
		var player = boiler_room.leave_room(player_id)
		cave_room.spawn_player(player, hole_id, false)
		pass


func spawn_players(you, guests : Array) -> void:
	cave_room.spawn_players(you, guests)


func update_player_position(player_id : int, new_position : Vector2) -> void:
	cave_room.update_player_position(player_id, new_position)
	boiler_room.update_player_position(player_id, new_position)


func remove_player(id : int) -> void:
	cave_room.remove_player(id)
	boiler_room.remove_player(id)


func give_coal(id : int, type : int) -> void:
	cave_room.give_coal(id, type)


func remove_coal(id : int) -> void:
	boiler_room.remove_coal(id)


func _on_request_sended(request : Dictionary) -> void:
	request["room_name"] = room_name
	request_sended.emit(request)


func _on_game_pause_back_to_menu_pressed() -> void:
	back_to_menu_pressed.emit(room_name)


func _on_cave_room_exited(player : CharacterBody2D, hole_id : int) -> void:
	remove_child(cave_room)
	add_child(boiler_room)
	boiler_room.spawn_player(player, hole_id, true)


func _on_boiler_room_exited(player : CharacterBody2D, hole_id : int) -> void:
	remove_child(boiler_room)
	add_child(cave_room)
	cave_room.spawn_player(player, hole_id, true)
