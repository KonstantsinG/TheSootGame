extends Control

signal player_setup_done(player_name : String)
signal back_pressed


func _on_ready_button_down() -> void:
	var player_name = $VBoxContainer/NameTextBox.text
	player_setup_done.emit(player_name)


func _on_back_button_down() -> void:
	back_pressed.emit()
