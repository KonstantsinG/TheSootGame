extends Control

signal singleplayer_pressed
signal multiplayer_pressed


func _on_single_button_down() -> void:
	singleplayer_pressed.emit()


func _on_multi_button_down() -> void:
	multiplayer_pressed.emit()
