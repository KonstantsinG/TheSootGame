extends Node2D

signal request_sended(request : Dictionary)

var spawn_points = []
var main_player = null
var guests = []


func _ready() -> void:
	_take_spawn_poins()


func _take_spawn_poins() -> void:
	spawn_points.append_array($SpawnPointsContainer.get_children())


func _find_guest_by_id(id : int) -> Variant:
	for g in guests:
		if g.id == id: return g
	
	return null


func spawn_players(_you, _guests : Array) -> void:
	main_player = preload("res://scenes/game_entities/soot_player.tscn").instantiate()
	var place = spawn_points[_you["spawnpoint"]]
	$Entities.add_child(main_player)
	main_player.set_data(_you["id"], _you["player_name"], _you["team"])
	main_player.position = place.position
	main_player.player_moved.connect(_on_player_moved)
	
	for g in _guests:
		var player = preload("res://scenes/game_entities/soot_player.tscn").instantiate()
		place = spawn_points[g["spawnpoint"]]
		$Entities.add_child(player)
		player.set_data(g["id"], g["player_name"], g["team"])
		player.position = place.position
		player.controlable = false
		guests.append(player)


func update_player_position(player_id : int, new_position : Vector2) -> void:
	var guest = _find_guest_by_id(player_id)
	if guest != null:
		guest.position = new_position


func _on_player_moved(new_pos : Vector2) -> void:
	request_sended.emit({"head" : "NOTIFICATION_PLAYER_MOVED", "position" : new_pos})
