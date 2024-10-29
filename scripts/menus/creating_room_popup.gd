extends Control

signal create_room_pressed(room_name : String, password : String, ais_count : int)
signal cancel_pressed

var created := false
var room_name := ""
var room_pass := ""
var ais_count := 0


func _on_tree_entered() -> void:
	$AnimationPlayer.play("fade_in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if (anim_name == "fade_out"):
		if created: create_room_pressed.emit(room_name, room_pass, ais_count)
		else: cancel_pressed.emit()


func _on_create_button_pressed() -> void:
	#validation
	var _room_name = $PopupPanel/NameTextEdit.text
	var _room_pass = $PopupPanel/PassTextEdit.text
	var _ais_count = $PopupPanel/AISpinBox.value
	
	if _room_name != "":
		room_name = _room_name
		room_pass = _room_pass
		ais_count = _ais_count
		created = true
		$AnimationPlayer.play("fade_out")
	else:
		$PopupPanel/ErrorLabel.text = "Room name field cannot be empty"
		$PopupPanel/ErrorLabel.visible = true
		created = false


func _on_cancel_button_pressed() -> void:
	created = false
	$AnimationPlayer.play("fade_out")
