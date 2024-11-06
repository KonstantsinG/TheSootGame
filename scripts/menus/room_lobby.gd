extends Control

signal start_pressed
signal ready_pressed
signal close_pressed(room_name : String)
signal disconnect_pressed(room_name : String)
signal player_data_changed(room_name : String, player_name : String, team : GameParams.TeamTypes)

@onready var player_panels : Array[Panel] = [
	$HeadPanel/VBoxContainer/GridContainer/Panel,
	$HeadPanel/VBoxContainer/GridContainer/Panel2,
	$HeadPanel/VBoxContainer/GridContainer/Panel3,
	$HeadPanel/VBoxContainer/GridContainer/Panel4,
	$HeadPanel/VBoxContainer/GridContainer/Panel5,
	$HeadPanel/VBoxContainer/GridContainer/Panel6,
	$HeadPanel/VBoxContainer/GridContainer/Panel7,
	$HeadPanel/VBoxContainer/GridContainer/Panel8,
]
@onready var name_label = $HeadPanel/VBoxContainer/Label
@onready var start_ready_button = $HBoxContainer/StartReadyTextButton
@onready var close_disconnect_button = $HBoxContainer/CloseDisconnectTextButton

var panels_states := [
	false, false, false, false, false, false, false, false
]
var is_host : bool = false
var room_name : String
var guests := {}


func set_data(_room_name : String, _is_host : bool) -> void:
	is_host = _is_host
	room_name = _room_name
	
	name_label.text = _room_name
	if _is_host:
		start_ready_button.change_text("Start game")
		close_disconnect_button.change_text("Close room")
	else:
		start_ready_button.change_text("Ready")
		close_disconnect_button.change_text("Disconnect")


func add_player_panel(_is_host : bool) -> Error:
	var panel_idx = _find_empty_pannel_index()
	if panel_idx == -1: return ERR_OUT_OF_MEMORY
	panels_states[panel_idx] = true
	var panel = player_panels[panel_idx]
	
	var player = preload("res://scenes/menus/panels/player_panel.tscn").instantiate()
	player.data_changed.connect(_on_player_data_changed)
	panel.add_child(player)
	player.toggle_crown(_is_host)
	
	return OK


func _on_player_data_changed(player_name : String, team : GameParams.TeamTypes) -> void:
	player_data_changed.emit(room_name, player_name, team)


func add_guest_panel(id : int, player_name : String, team : GameParams.TeamTypes, _is_host : bool) -> Error:
	var panel_idx = _find_empty_pannel_index()
	if panel_idx == -1: return ERR_OUT_OF_MEMORY
	panels_states[panel_idx] = true
	var panel = player_panels[panel_idx]
	
	var player = preload("res://scenes/menus/panels/guest_panel.tscn").instantiate()
	
	panel.add_child(player)
	player.set_data(player_name, team, _is_host)
	guests[id] = player
	
	return OK


func remove_guest_panel(id : int) -> void:
	var g : Control = guests[id]
	guests.erase(id)
	
	var panel_idx = g.get_parent().get_index()
	panels_states[panel_idx] = false
	g.get_parent().remove_child(g)
	g.queue_free()
	
	_push_panels()


func _push_panels() -> void:
	for g in guests.values():
		var panel_idx = g.get_parent().get_index()
		panels_states[panel_idx] = false
		g.get_parent().remove_child(g)
		
		panel_idx = _find_empty_pannel_index()
		panels_states[panel_idx] = true
		var panel = player_panels[panel_idx]
		panel.add_child(g)


func update_guest_data(id : int, player_name : String, team : GameParams.TeamTypes) -> void:
	var player = guests.get(id)
	if player != null:
		player.update_data(player_name, team)


func _find_empty_pannel_index() -> int:
	for i in range(player_panels.size()):
		if not panels_states[i]:
			return i
	
	return -1


func _on_close_disconnect_text_button_pressed() -> void:
	if is_host: close_pressed.emit(room_name)
	else: disconnect_pressed.emit(room_name)


func _on_start_ready_text_button_pressed() -> void:
	if is_host: start_pressed.emit()
	else: ready_pressed.emit()