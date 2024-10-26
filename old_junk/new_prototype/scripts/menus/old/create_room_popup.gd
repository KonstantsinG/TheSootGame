extends Control

signal create_room_pressed(room_name : String, password : String)


func _on_create_button_down() -> void:
	var room_name = $VBoxContainer/NameTextBox.text
	var room_pass = $VBoxContainer/PasswordTextBox.text
	
	if room_name == "":
		OS.alert("Room name cannot be empty", "Error creating room")
		return
	
	create_room_pressed.emit(room_name, room_pass)
