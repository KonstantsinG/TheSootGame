extends Node2D

signal request_sended(request : Dictionary)
signal room_exited(player : CharacterBody2D, hole_id : int)
signal score_increased(team : GameParams.TeamTypes, score : int)

@onready var animation_player = $RoomAnimationPlayer
@onready var exit_marker = $HidingWall/ExitMarker
@onready var holes_container = $CaveRoomEnter/Holes

var transition_points := []
var hiding_wall_visible = true
var entered_hole = null
var entered_trampoline = false
var active = false

var main_player = null
var guests = []

var game_running = true :
	set(value):
		game_running = value
		get_tree().paused = !value


func _ready() -> void:
	# fix first transition jittering
	modulate = Color.BLACK
	
	_take_transition_points()
	_connect_holes()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		if entered_hole != null:
			_remove_player_from_room()
		elif entered_trampoline:
			_drop_coal()
	
	elif event.is_action_pressed("attack"):
		_place_barricade()


func _take_transition_points() -> void:
	transition_points.append_array($TransitionPointsContainer.get_children())


func _connect_holes() -> void:
	for h in holes_container.get_children():
		h.hole_entered.connect(_on_body_hole_entered)
		h.hole_exited.connect(_on_body_hole_exited)


func _find_guest_by_id(id : int) -> Variant:
	for g in guests:
		if g.id == id: return g
	
	return null


func _find_coal_by_id(id : int) -> Variant:
	for c in $Entities.get_children():
		if c is CharacterBody2D: continue
		
		if c.id == id: return c
	
	return null


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


func _drop_coal() -> void:
	var score = main_player.drop_coal()
	
	#NOTIMPLEMENTED: DropCoal animation
	
	var msg = {"head" : "NOTIFICATION_COAL_DROPPED", "player_id" : main_player.id, "team" : main_player.team, "score" : score}
	score_increased.emit(main_player.team, score)
	request_sended.emit(msg)


func _remove_player_from_room() -> void:
	var hole_id = holes_container.get_children().find(entered_hole)
	var msg = {
		"head" : "NOTIFICATION_PLAYER_EXIT_ROOM",
		"destination" : "CAVE_ROOM",
		"hole_id" : hole_id,
		"player_id" : main_player.id
	}
	
	animation_player.play("room_fade_out")
	await animation_player.animation_finished
	
	active = false
	entered_hole = null
	main_player.camera.position_smoothing_enabled = false
	$Entities.remove_child(main_player)
	
	request_sended.emit(msg)
	room_exited.emit(main_player, hole_id)


func leave_room(id : int) -> CharacterBody2D:
	var player = _find_guest_by_id(id)
	
	if player != null:
		$Entities.remove_child(player)
		guests.erase(player)
		return player
	else:
		return null


func spawn_player(player : CharacterBody2D, hole_id : int, is_main_player : bool) -> void:
	if transition_points.size() == 0: _take_transition_points()
	
	$Entities.add_child(player)
	player.position = transition_points[hole_id].position
	
	if is_main_player:
		animation_player.play("room_fade_in")
		await animation_player.animation_finished
		
		active = true
		main_player = player
		if is_node_ready(): await get_tree().create_timer(0.1).timeout
		main_player.camera.position_smoothing_enabled = true
	else:
		player.target_position = player.position
		guests.append(player)


func update_player_position(id : int, new_pos : Vector2) -> void:
	for p in guests:
		if p.id == id:
			if active:
				p.target_position = new_pos
			else:
				p.target_position = new_pos
				p.position = new_pos


func remove_player(id : int) -> void:
	for p in guests:
		if p.id == id:
			$Entities.remove_child(p)
			guests.erase(p)
			p.queue_free()
	
	if main_player.id == id:
		$Entities.remove_child(main_player)
		main_player.queue_free()
		main_player = null


func remove_coal(id : int) -> void:
	var player = _find_guest_by_id(id)
	
	if player != null:
		player.drop_coal()


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


func _on_hiding_wall_body_entered(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D": return
	elif not body.controlable: return
	
	if hiding_wall_visible:
		animation_player.play("wall_fading_out")
	else:
		animation_player.play("wall_fading_in")
	
	hiding_wall_visible = !hiding_wall_visible


func _on_hiding_wall_body_exited(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D": return
	elif not body.controlable: return
	
	if not hiding_wall_visible and body.position.direction_to(exit_marker.position).x < 0:
		animation_player.play("wall_fading_in")
		hiding_wall_visible = !hiding_wall_visible
	elif hiding_wall_visible and body.position.direction_to(exit_marker.position).x > 0:
		animation_player.play("wall_fading_out")
		hiding_wall_visible = !hiding_wall_visible


func _on_body_hole_entered(body : CharacterBody2D, hole : Area2D) -> void:
	if body != main_player: return
	
	entered_hole = hole


func _on_body_hole_exited(body : CharacterBody2D, _hole : Area2D) -> void:
	if body != main_player: return
	
	entered_hole = null


func _on_trampoline_body_entered(body: Node2D) -> void:
	if body != main_player: return
	
	if main_player.coal != null:
		main_player.toggle_action_panel(true)
	entered_trampoline = true


func _on_trampoline_body_exited(body: Node2D) -> void:
	if body != main_player: return
	
	main_player.toggle_action_panel(false)
	entered_trampoline = false
