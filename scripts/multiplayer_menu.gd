extends Control

signal host_pressed
signal join_pressed


func _on_host_button_down() -> void:
	host_pressed.emit()


func _on_join_button_down() -> void:
	join_pressed.emit()
