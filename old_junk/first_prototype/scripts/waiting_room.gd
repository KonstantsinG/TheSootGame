extends Control

signal back_pressed(is_host : bool)
signal start_game_pressed

@onready var start_game_button = $VBoxContainer/HBoxContainer/StartButton

var start_game_button_enabled = true
var log_name_line_added := false


func set_players_count(count : int) -> void:
	$VBoxContainer/PlayersCounter.text = "   Players count: " + str(count)


func add_log_line(line : String) -> void:
	if not log_name_line_added:
		log_name_line_added = true
		$VBoxContainer/LogLabel.add_text("\nYour name: " + OS.get_cmdline_args()[1])
	
	$VBoxContainer/LogLabel.add_text("\n" + line)


func toggle_start_game_button(enabled : bool) -> void:
	if start_game_button_enabled != enabled:
		start_game_button_enabled = !start_game_button_enabled
		
		if enabled: $VBoxContainer/HBoxContainer.add_child(start_game_button)
		else: $VBoxContainer/HBoxContainer.remove_child(start_game_button)


func _on_back_button_down() -> void:
	log_name_line_added = false
	back_pressed.emit(start_game_button_enabled)


func _on_start_button_down() -> void:
	start_game_pressed.emit()
