extends Node2D

signal main_player_moved(new_pos : Vector2)

@onready var main_player = $MainPlayer

var net_players : Dictionary = {}


func _ready() -> void:
	main_player.player_moved.connect(_main_player_moved)


func set_main_player_name(player_name : String) -> void:
	main_player.set_player_name(player_name)


func create_net_player(pl_name : String, pl_id : int):
	var net_player = preload("res://scenes/soot_player.tscn").instantiate()
	add_child(net_player)
	net_player.set_player_name(pl_name)
	net_player.controlable = false
	net_player.position = Vector2(randi_range(0, 1100), randi_range(0, 650))
	
	net_players[pl_id] = net_player


func _main_player_moved(new_pos : Vector2) -> void:
	main_player_moved.emit(new_pos)


func move_net_player(id : int, new_pos : Vector2) -> void:
	net_players[id].position = new_pos
