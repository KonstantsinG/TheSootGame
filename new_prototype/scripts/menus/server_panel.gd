extends Control

signal join_pressed(server_address : String)

var server_address : String


func set_data(_server_name : String, _server_address : String) -> void:
	server_address = _server_address
	$HBoxContainer/NameLabel.text = _server_name + " - " + _server_address


func _on_join_button_down() -> void:
	join_pressed.emit(server_address)
