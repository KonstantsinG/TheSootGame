extends Control

signal join_pressed(room_name : String, password : String)
signal cancel_pressed

var joined := false
var room_name = ""


func _on_tree_entered() -> void:
	$AnimationPlayer.play("fade_in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		if joined:
			var password = $PopupPanel/PassTextEdit.text
			join_pressed.emit(room_name, password)
		else:
			cancel_pressed.emit()


func _on_join_button_pressed() -> void:
	joined = true
	$AnimationPlayer.play("fade_out")


func _on_cancel_button_pressed() -> void:
	joined = false
	$AnimationPlayer.play("fade_out")
