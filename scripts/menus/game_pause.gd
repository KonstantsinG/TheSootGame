extends Control

signal back_to_menu_pressed
signal resume_pressed


func _on_resume_button_down() -> void:
	resume_pressed.emit()


func _on_back_button_down() -> void:
	back_to_menu_pressed.emit()
