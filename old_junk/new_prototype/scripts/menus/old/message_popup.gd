extends Control

signal close_pressed


func set_data(title : String, message : String) -> void:
	$TitleLabel.text = title
	$MessageLabel.text = message


func _on_accept_button_down() -> void:
	close_pressed.emit()
