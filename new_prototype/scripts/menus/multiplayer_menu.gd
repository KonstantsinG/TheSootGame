extends Control

signal create_room_pressed
signal join_room_pressed
signal back_pressed


func _on_create_button_down() -> void:
	create_room_pressed.emit()


func _on_join_button_down() -> void:
	join_room_pressed.emit()


func _on_back_button_down() -> void:
	back_pressed.emit()
