extends Control

signal popup_disappeared(target : Control)


func set_data(title : String, message : String) -> void:
	$PopupPanel/TitleLabel.text = title
	$PopupPanel/MessageLabel.text = message


func _on_text_button_pressed() -> void:
	$AnimationPlayer.play("fade_out")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		popup_disappeared.emit(self)


func _on_tree_entered() -> void:
	$AnimationPlayer.play("fade_in")
