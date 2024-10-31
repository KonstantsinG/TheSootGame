extends Control

signal back_pressed
signal create_new_pressed
signal join_pressed(ip : String)

@onready var nothing_found_panel = $Panel/ScrollContainer/ServersVBoxContainer/NothingFoundPanel
@onready var panels_container = $Panel/ScrollContainer/ServersVBoxContainer/ServerPanels


func get_panels_count() -> int:
	return panels_container.get_child_count()


func add_server_panel(ip : String, server_name : String) -> void:
	for p in panels_container.get_children():
		if p.ip == ip: return
	
	var panel = preload("res://scenes/menus/panels/server_panel.tscn").instantiate()
	panel.set_params(ip, server_name)
	panel.panel_pressed.connect(_on_panel_pressed)
	panels_container.add_child(panel)
	
	if nothing_found_panel.visible:
		nothing_found_panel.visible = false


func remove_server_panel(ip : String) -> void:
	var target = null
	
	for p in panels_container.get_children():
		if p.ip == ip:
			target = p
			break
	
	if target != null:
		panels_container.remove_child(target)
		target.queue_free()
		
		if get_panels_count() < 1:
			nothing_found_panel.visible = true


func _on_panel_pressed(target : Control) -> void:
	join_pressed.emit(target.ip)


func _on_back_text_button_pressed() -> void:
	back_pressed.emit()


func _on_create_text_button_pressed() -> void:
	create_new_pressed.emit()
