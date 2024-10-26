extends Control

signal panel_pressed(target : Control)

var ip : String = ""
var server_name : String = ""


func set_params(_ip : String, _name : String) -> void:
	ip = _ip
	server_name = _name
	
	$Panel/Panel/HBoxContainer/IPLabel.text = ip
	$Panel/Panel/HBoxContainer/NameLabel.text = server_name


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			panel_pressed.emit(self)
