extends Node

signal request_sended(request : Dictionary)
signal back_to_menu_pressed(room_name : String)

@onready var cave_room = $CaveRoom
@onready var boiler_room
@onready var game_pause = $HUD/GamePause
@onready var hud = $HUD/GameHUD

var room_name := ""
var scores : Array[int] = [0, 0, 0, 0]


func _ready() -> void:
	boiler_room = preload("res://scenes/game_locations/boiler_room.tscn").instantiate()
	
	boiler_room.request_sended.connect(_on_request_sended)
	boiler_room.room_exited.connect(_on_boiler_room_exited)
	boiler_room.score_increased.connect(_on_boiler_room_score_increased)
	
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


func give_coal(player_id : int, coal_id : int, type : int) -> void:
	cave_room.give_coal(player_id, coal_id, type)


func burn_coal(player_id : int, team : GameParams.TeamTypes, score : int) -> void:
	boiler_room.remove_coal(player_id)
	
	var new_score = scores[team] + score
	scores[team] = new_score
	
	hud.update_score(team, new_score)


func place_barricade(player_id : int, barricade_pos : Vector2) -> void:
	cave_room.set_barricade(player_id, barricade_pos)
	boiler_room.set_barricade(player_id, barricade_pos)


func pick_up_coal(player_id : int, coal_id : int) -> void:
	cave_room.pick_up_coal(player_id, coal_id)
	boiler_room.pick_up_coal(player_id, coal_id)


func push_soot(direction : Vector2) -> void:
	if cave_room.active: cave_room.main_player.push(direction)
	elif boiler_room.active: boiler_room.main_player.push(direction)


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


func _on_boiler_room_score_increased(team : GameParams.TeamTypes, score : int) -> void:
	var new_score = scores[team] + score
	scores[team] = new_score
	
	hud.update_score(team, new_score)


func _on_hud_update_timer_timeout() -> void:
	hud.update_time_left($GameTimer.time_left)


func _on_game_timer_timeout() -> void:
	var msg = { "head" : "NOTIFICATION_GAME_FINISHED", "room_name" : room_name }
	request_sended.emit(msg)
	
	if cave_room.active: cave_room.game_running = false
	if boiler_room.active: boiler_room.game_running = false
	
	var endgame_menu = preload("res://scenes/menus/endgame_menu.tscn").instantiate()
	$HUD.add_child(endgame_menu)
	endgame_menu.set_places(scores)
