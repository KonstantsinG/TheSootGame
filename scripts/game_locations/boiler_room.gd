extends Node2D

@onready var hiding_wall_animaton = $HidingWallAnimation
@onready var exit_marker = $HidingWall/ExitMarker

var transition_points := []
var hiding_wall_visible = true

var main_player = null
var guests = []


func _ready() -> void:
	_take_transition_points()


func _take_transition_points() -> void:
	transition_points.append_array($TransitionPointsContainer.get_children())


func spawn_player(player : CharacterBody2D, hole_id : int, is_main_player : bool) -> void:
	if transition_points.size() == 0: _take_transition_points()
	
	$Entities.add_child(player)
	player.position = transition_points[hole_id].position
	
	if is_main_player:
		main_player = player
		if is_node_ready(): await get_tree().create_timer(0.1).timeout
		main_player.camera.position_smoothing_enabled = true
	else:
		guests.append(player)


func update_player_position(id : int, new_pos : Vector2) -> void:
	for p in $Entities.get_children():
		if p.id == id:
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


func _on_hiding_wall_body_entered(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D": return
	elif not body.controlable: return
	
	if hiding_wall_visible:
		hiding_wall_animaton.play("wall_fading_out")
	else:
		hiding_wall_animaton.play("wall_fading_in")
	
	hiding_wall_visible = !hiding_wall_visible


func _on_hiding_wall_body_exited(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D": return
	elif not body.controlable: return
	
	if not hiding_wall_visible and body.position.direction_to(exit_marker.position).x < 0:
		hiding_wall_animaton.play("wall_fading_in")
		hiding_wall_visible = !hiding_wall_visible
	elif hiding_wall_visible and body.position.direction_to(exit_marker.position).x > 0:
		hiding_wall_animaton.play("wall_fading_out")
		hiding_wall_visible = !hiding_wall_visible
