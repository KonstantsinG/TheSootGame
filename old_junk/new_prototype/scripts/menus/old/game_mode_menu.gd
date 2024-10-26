extends Control

signal singleplayer_pressed
signal multiplayer_pressed
signal exit_pressed


func _on_singleplayer_button_down() -> void:
	singleplayer_pressed.emit()


func _on_multiplayer_button_down() -> void:
	multiplayer_pressed.emit()


func _on_exit_button_down() -> void:
	exit_pressed.emit()
	
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit(0)
