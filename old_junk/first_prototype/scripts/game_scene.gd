extends Node2D

signal main_player_moved(new_pos : Vector2)

var net_players : Dictionary = {}
var spawn_points : Array[Vector2] = []
var available_spawn_point = 0


func _ready() -> void:
	for c in $PlayersSpawn.get_children():
		spawn_points.append(c.position)


func create_net_player(pl_name : String, pl_id : int):
	var net_player = preload("res://scenes/soot_player.tscn").instantiate()
	net_player.set_player_name(pl_name)
	net_player.position = spawn_points[available_spawn_point]
	available_spawn_point += 1
	if pl_id != -1: net_player.controlable = false
	
	net_players[pl_id] = net_player


func spawn_players():
	net_players[-1].player_moved.connect(_main_player_moved)
	
	for p in net_players.values():
		add_child(p)


func _main_player_moved(new_pos : Vector2) -> void:
	main_player_moved.emit(new_pos)


func move_net_player(id : int, new_pos : Vector2) -> void:
	net_players[id].position = new_pos
