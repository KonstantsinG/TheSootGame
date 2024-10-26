extends Control


signal play_locally_pressed
signal offline_mode_pressed
signal games_browser_pressed


func _on_play_locally_texture_titled_button_mouse_pressed() -> void:
	play_locally_pressed.emit()


func _on_offline_mode_texture_titled_button_2_mouse_pressed() -> void:
	offline_mode_pressed.emit()


func _on_games_browser_texture_titled_button_3_mouse_pressed() -> void:
	games_browser_pressed.emit()
