extends Control

signal join_room_pressed(server_ip : String, room_name : String, is_public : bool)
signal back_pressed

@onready var rooms_panels = $Panel/ScrollContainer/RoomssVBoxContainer/RoomsPanels
@onready var nothing_found_panel = $Panel/ScrollContainer/RoomssVBoxContainer/NothingFoundPanel


func add_room_panel(server_ip : String, room_name : String, players_count : int, is_public : bool) -> void:
	for p in rooms_panels.get_children():
		if p.server_ip == server_ip and p.room_name == room_name:
			return
	
	if nothing_found_panel.visible:
		nothing_found_panel.visible = false
	
	var panel = preload("res://scenes/menus/panels/room_panel.tscn").instantiate()
	rooms_panels.add_child(panel)
	panel.set_data(server_ip, room_name, players_count, is_public)
	panel.panel_pressed.connect(_on_panel_pressed)


func remove_room_panel(server_ip : String, room_name: String) -> void:
	for p in rooms_panels.get_children():
		if p.server_ip == server_ip and p.room_name == room_name:
			rooms_panels.remove_child(p)
			p.queue_free()
	
	if rooms_panels.get_child_count() < 1:
		nothing_found_panel.visible = true


func clear_panels() -> void:
	for p in rooms_panels.get_children():
		rooms_panels.remove_child(p)
		p.queue_free()
	
	nothing_found_panel.visible = true


func _on_panel_pressed(target : Control) -> void:
	join_room_pressed.emit(target.server_ip, target.room_name, target.is_public)


func _on_back_text_button_pressed() -> void:
	back_pressed.emit()
