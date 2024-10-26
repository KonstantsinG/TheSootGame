extends Control

signal join_pressed(ip : String)
signal back_pressed

@onready var servers_panels = $VBoxContainer/ScrollContainer/ServersPanels

var ips := []


func add_server_panel(server_name : String, server_ip : String) -> void:
	if ips.has(server_ip): return
	
	var new_panel = preload("res://new_prototype/scenes/menus/server_panel.tscn").instantiate()
	new_panel.join_pressed.connect(_server_panel_join_pressed)
	new_panel.set_data(server_name, server_ip)
	servers_panels.add_child(new_panel)
	
	ips.append(server_ip)


func remove_server_panel(address : String) -> void:
	for panel in servers_panels.get_children():
		if panel.server_address == address:
			ips.erase(address)
			servers_panels.remove_child(panel)
			panel.queue_free()
			return


func _server_panel_join_pressed(ip : String):
	join_pressed.emit(ip)


func _on_back_button_down() -> void:
	back_pressed.emit()
