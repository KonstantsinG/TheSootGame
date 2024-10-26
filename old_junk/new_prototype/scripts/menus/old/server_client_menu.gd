extends Control

signal run_server_pressed
signal connect_to_server_pressed
signal back_pressed


func _on_run_server_button_down() -> void:
	run_server_pressed.emit()


func _on_connect_button_down() -> void:
	connect_to_server_pressed.emit()


func _on_back_button_down() -> void:
	back_pressed.emit()
