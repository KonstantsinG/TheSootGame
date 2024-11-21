extends Node2D

signal request_sended(request : Dictionary)
signal room_exited(player : CharacterBody2D, hole_id : int)

var spawn_points = []
var main_player = null
var guests = []

var entered_hole = null


func _ready() -> void:
	_take_spawn_poins()
	_connect_holes()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		if entered_hole != null:
			_remove_player_from_room()


func _take_spawn_poins() -> void:
	spawn_points.append_array($SpawnPointsContainer.get_children())


func _connect_holes() -> void:
	for h in $Holes.get_children():
		h.hole_entered.connect(_on_body_hole_entered)


func _remove_player_from_room() -> void:
	var hole_id = $Holes.get_children().find(entered_hole)
	var msg = {
		"head" : "NOTIFICATION_PLAYER_EXIT_ROOM",
		"destination" : "BOILER_ROOM",
		"hole_id" : hole_id,
		"id" : main_player.id
	}
	
	entered_hole = null
	main_player.camera.position_smoothing_enabled = false
	$Entities.remove_child(main_player)
	
	request_sended.emit(msg)
	room_exited.emit(main_player, hole_id)


func _find_guest_by_id(id : int) -> Variant:
	for g in guests:
		if g.id == id: return g
	
	return null


func spawn_players(_you, _guests : Array) -> void:
	main_player = preload("res://scenes/game_entities/soot_player.tscn").instantiate()
	var place = spawn_points[_you["spawnpoint"]]
	$Entities.add_child(main_player)
	main_player.camera.position_smoothing_enabled = false
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
	
	# fixing camera rush
	await get_tree().create_timer(0.1).timeout
	main_player.camera.position_smoothing_enabled = true


func update_player_position(player_id : int, new_position : Vector2) -> void:
	var guest = _find_guest_by_id(player_id)
	if guest != null:
		guest.position = new_position


func remove_player(id : int) -> void:
	var player = _find_guest_by_id(id)
	
	if player != null:
		$Entities.remove_child(player)
		guests.erase(player)
		player.queue_free()
	elif main_player.id == id:
		$Entities.remove_child(main_player)
		main_player.queue_free()
		main_player = null


func leave_room(id : int) -> CharacterBody2D:
	var player = _find_guest_by_id(id)
	
	if player != null:
		$Entities.remove_child(player)
		guests.erase(player)
		return player
	else:
		return null


func hide_player(id : int) -> void:
	var player = _find_guest_by_id(id)
	
	if player != null:
		player.visible = false


func _on_player_moved(new_pos : Vector2) -> void:
	request_sended.emit({"head" : "NOTIFICATION_PLAYER_MOVED", "position" : new_pos})


func _on_body_hole_entered(body : CharacterBody2D, hole : Area2D) -> void:
	if body != main_player: return
	
	entered_hole = hole


func _on_body_hole_exited(body : CharacterBody2D, _hole : Area2D) -> void:
	if body != main_player: return
	
	entered_hole = null
