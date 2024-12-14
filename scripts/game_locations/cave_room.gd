extends Node2D

signal request_sended(request : Dictionary)
signal room_exited(player : CharacterBody2D, hole_id : int)

var spawn_points = []
var transition_points = []
var main_player = null
var guests = []

var entered_hole = null
var enter_coal_area = false
var active = true

var game_running = true :
	set(value):
		game_running = value
		get_tree().paused = !value


func _ready() -> void:
	_take_spawn_poins()
	_connect_holes()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		if entered_hole != null:
			_remove_player_from_room()
		elif enter_coal_area:
			_take_coal()
	
	elif event.is_action_pressed("attack"):
		_place_barricade()
	
	elif event.is_action_pressed("mouse_left_click"):
		if main_player.facing_soot != null:
			_push_soot()


func _take_spawn_poins() -> void:
	spawn_points.append_array($SpawnPointsContainer.get_children())


func _take_transition_points() -> void:
	transition_points.append_array($TransitionPointsContaner.get_children())


func _connect_holes() -> void:
	for h in $Holes.get_children():
		h.hole_entered.connect(_on_body_hole_entered)
		h.hole_exited.connect(_on_body_hole_exited)


func _take_coal() -> void:
	main_player.take_coal()
	var coal_id = main_player.coal.id
	
	var msg = {
		"head" : "NOTIFICATION_COAL_TAKEN",
		"type" : main_player.get_coal_type(),
		"player_id" : main_player.id,
		"coal_id" : coal_id
	}
	request_sended.emit(msg)


func _push_soot() -> void:
	var direction = get_global_mouse_position().direction_to(main_player.position) * -1
	var msg = {
		"head" : "NOTIFICATION_SOOT_PUSHED",
		"player_id" : main_player.facing_soot.id,
		"direction" : direction
	}
	request_sended.emit(msg)
	
	main_player.facing_soot = null


func _place_barricade() -> void:
	var barricade = main_player.place_barricade()
	if barricade != null:
		$Entities.add_child(barricade)
		barricade.scale = Vector2(0.15, 0.15)
		barricade.position = main_player.position
		
		var msg = {
			"head" : "NOTIFICATION_BARRICADE_PLACED",
			"player_id" : main_player.id,
			"position" : main_player.position
		}
		request_sended.emit(msg)


func _remove_player_from_room() -> void:
	var hole_id = $Holes.get_children().find(entered_hole)
	var msg = {
		"head" : "NOTIFICATION_PLAYER_EXIT_ROOM",
		"destination" : "BOILER_ROOM",
		"hole_id" : hole_id,
		"player_id" : main_player.id
	}
	
	$AnimationPlayer.play("room_fade_out")
	await $AnimationPlayer.animation_finished
	
	active = false
	entered_hole = null
	main_player.camera.position_smoothing_enabled = false
	$Entities.remove_child(main_player)
	
	request_sended.emit(msg)
	room_exited.emit(main_player, hole_id)


func _find_guest_by_id(id : int) -> Variant:
	for g in guests:
		if g.id == id: return g
	
	return null


func _find_coal_by_id(id : int) -> Variant:
	for c in $Entities.get_children():
		if c is CharacterBody2D: continue
		
		if c.id == id: return c
	
	return null


func spawn_players(_you, _guests : Array) -> void:
	active = true
	main_player = preload("res://scenes/game_entities/soot_player.tscn").instantiate()
	var place = spawn_points[_you["spawnpoint"]]
	$Entities.add_child(main_player)
	main_player.camera.position_smoothing_enabled = false
	main_player.set_data(_you["id"], _you["player_name"], _you["team"])
	main_player.position = place.position
	
	main_player.player_moved.connect(_on_player_moved)
	main_player.coal_picked_up.connect(_on_player_coal_picked_up)
	
	for g in _guests:
		var player = preload("res://scenes/game_entities/soot_player.tscn").instantiate()
		place = spawn_points[g["spawnpoint"]]
		$Entities.add_child(player)
		player.set_data(g["id"], g["player_name"], g["team"])
		player.position = place.position
		player.target_position = place.position
		player.controlable = false
		guests.append(player)
	
	# fixing camera rush
	await get_tree().create_timer(0.1).timeout
	main_player.camera.position_smoothing_enabled = true


func spawn_player(player : CharacterBody2D, hole_id : int, is_main_player : bool) -> void:
	if transition_points.size() == 0: _take_transition_points()
	
	$Entities.add_child(player)
	player.position = transition_points[hole_id].position
	
	if is_main_player:
		$AnimationPlayer.play("room_fade_in")
		await $AnimationPlayer.animation_finished
		
		active = true
		main_player = player
		if is_node_ready(): await get_tree().create_timer(0.1).timeout
		main_player.camera.position_smoothing_enabled = true
	else:
		player.target_position = player.position
		guests.append(player)


func respawn_player(player : CharacterBody2D) -> void:
	if player.controlable:
		$AnimationPlayer.play("room_fade_in")
		await $AnimationPlayer.animation_finished
		active = true
	
	var spawn = $SpawnPointsContainer.get_child(0)
	$Entities.add_child(player)
	player.position = spawn.position
	
	if player.controlable:
		main_player = player
		if is_node_ready(): await get_tree().create_timer(0.1).timeout
		main_player.camera.position_smoothing_enabled = true
	else:
		guests.append(player)
		player.target_position = spawn.position


func update_player_position(player_id : int, new_position : Vector2) -> void:
	var guest = _find_guest_by_id(player_id)
	if guest != null:
		if active:
			guest.target_position = new_position
		else:
			guest.target_position = new_position
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


func give_coal(player_id : int, coal_id : int, type : int) -> void:
	var player = _find_guest_by_id(player_id)
	
	if player != null:
		player.give_coal(coal_id, type)


func set_barricade(player_id : int, barricade_pos : Vector2) -> void:
	var player = _find_guest_by_id(player_id)
	
	if player != null:
		var barricade = player.place_barricade()
		if barricade != null:
			$Entities.add_child(barricade)
			barricade.scale = Vector2(0.15, 0.15)
			barricade.position = barricade_pos


func pick_up_coal(player_id : int, coal_id : int) -> void:
	var player = _find_guest_by_id(player_id)
	var coal = _find_coal_by_id(coal_id)
	
	if player != null and coal != null:
		player.pick_up_coal(coal)


func _on_player_moved(new_pos : Vector2) -> void:
	request_sended.emit({"head" : "NOTIFICATION_PLAYER_MOVED", "position" : new_pos})


func _on_player_coal_picked_up(coal_id : int) -> void:
	var msg = {
		"head" : "NOTIFICATION_COAL_PICKED_UP",
		"player_id" : main_player.id,
		"coal_id" : coal_id
	}
	request_sended.emit(msg)


func _on_body_hole_entered(body : CharacterBody2D, hole : Area2D) -> void:
	if body != main_player: return
	
	entered_hole = hole


func _on_body_hole_exited(body : CharacterBody2D, _hole : Area2D) -> void:
	if body != main_player: return
	
	entered_hole = null


func _on_coal_area_body_entered(body: Node2D) -> void:
	if body != main_player: return
	
	if main_player.coal == null:
		main_player.toggle_action_panel(true)
	enter_coal_area = true


func _on_coal_area_body_exited(body: Node2D) -> void:
	if body != main_player: return
	
	main_player.toggle_action_panel(false)
	enter_coal_area = false
