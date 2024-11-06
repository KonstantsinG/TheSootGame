extends Control

signal data_changed(player_name : String, team : GameParams.TeamTypes)

@onready var name_text_edit = $Panel/NameTextEdit
@onready var crown = $Panel/CrownTexture
@onready var red_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/RedBanner
@onready var blue_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/BlueBanner
@onready var green_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/GreenBanner
@onready var yellow_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/YellowBanner

var selected_team : GameParams.TeamTypes = GameParams.TeamTypes.RED


func get_player_name() -> String:
	return $Panel/NameTextEdit.text


func toggle_crown(is_host : bool) -> void:
	crown.visible = is_host


func _on_red_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(GameParams.TeamTypes.RED)


func _on_red_banner_mouse_entered() -> void:
	red_banner.material.set_shader_parameter("is_bright", true)


func _on_red_banner_mouse_exited() -> void:
	red_banner.material.set_shader_parameter("is_bright", false)





func _on_blue_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(GameParams.TeamTypes.BLUE)


func _on_blue_banner_mouse_entered() -> void:
	blue_banner.material.set_shader_parameter("is_bright", true)


func _on_blue_banner_mouse_exited() -> void:
	blue_banner.material.set_shader_parameter("is_bright", false)





func _on_green_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(GameParams.TeamTypes.GREEN)


func _on_green_banner_mouse_entered() -> void:
	green_banner.material.set_shader_parameter("is_bright", true)


func _on_green_banner_mouse_exited() -> void:
	green_banner.material.set_shader_parameter("is_bright", false)





func _on_yellow_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(GameParams.TeamTypes.YELLOW)


func _on_yellow_banner_mouse_entered() -> void:
	yellow_banner.material.set_shader_parameter("is_bright", true)


func _on_yellow_banner_mouse_exited() -> void:
	yellow_banner.material.set_shader_parameter("is_bright", false)





func _toggle_benners_panel_state(target : GameParams.TeamTypes) -> void:
	if target == selected_team: return
	selected_team = target
	
	var targets = {
		GameParams.TeamTypes.RED : red_banner,
		GameParams.TeamTypes.BLUE : blue_banner,
		GameParams.TeamTypes.GREEN : green_banner,
		GameParams.TeamTypes.YELLOW : yellow_banner
	}
	
	targets[target].material.set_shader_parameter("is_pale", false)
	targets.erase(target)
	for t in targets.values():
		t.material.set_shader_parameter("is_pale", true)
	
	data_changed.emit(get_player_name(), selected_team)


func _on_name_text_edit_text_changed() -> void:
	data_changed.emit(get_player_name(), selected_team)