extends Control

enum TeamColors{
	RED, BLUE, GREEN, YELLOW
}

@onready var red_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/RedBanner
@onready var blue_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/BlueBanner
@onready var green_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/GreenBanner
@onready var yellow_banner = $Panel/TeamPanel/NinePatchRect/HBoxContainer/YellowBanner

var selected_team : TeamColors = TeamColors.RED


func _on_red_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(TeamColors.RED)


func _on_red_banner_mouse_entered() -> void:
	red_banner.material.set_shader_parameter("is_bright", true)


func _on_red_banner_mouse_exited() -> void:
	red_banner.material.set_shader_parameter("is_bright", false)





func _on_blue_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(TeamColors.BLUE)


func _on_blue_banner_mouse_entered() -> void:
	blue_banner.material.set_shader_parameter("is_bright", true)


func _on_blue_banner_mouse_exited() -> void:
	blue_banner.material.set_shader_parameter("is_bright", false)





func _on_green_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(TeamColors.GREEN)


func _on_green_banner_mouse_entered() -> void:
	green_banner.material.set_shader_parameter("is_bright", true)


func _on_green_banner_mouse_exited() -> void:
	green_banner.material.set_shader_parameter("is_bright", false)





func _on_yellow_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_benners_panel_state(TeamColors.YELLOW)


func _on_yellow_banner_mouse_entered() -> void:
	yellow_banner.material.set_shader_parameter("is_bright", true)


func _on_yellow_banner_mouse_exited() -> void:
	yellow_banner.material.set_shader_parameter("is_bright", false)





func _toggle_benners_panel_state(target) -> void:
	if target == selected_team: return
	selected_team = target
	
	match target:
		TeamColors.RED:
			red_banner.material.set_shader_parameter("is_pale", false)
			blue_banner.material.set_shader_parameter("is_pale", true)
			green_banner.material.set_shader_parameter("is_pale", true)
			yellow_banner.material.set_shader_parameter("is_pale", true)
		TeamColors.BLUE:
			red_banner.material.set_shader_parameter("is_pale", true)
			blue_banner.material.set_shader_parameter("is_pale", false)
			green_banner.material.set_shader_parameter("is_pale", true)
			yellow_banner.material.set_shader_parameter("is_pale", true)
		TeamColors.GREEN:
			red_banner.material.set_shader_parameter("is_pale", true)
			blue_banner.material.set_shader_parameter("is_pale", true)
			green_banner.material.set_shader_parameter("is_pale", false)
			yellow_banner.material.set_shader_parameter("is_pale", true)
		TeamColors.YELLOW:
			red_banner.material.set_shader_parameter("is_pale", true)
			blue_banner.material.set_shader_parameter("is_pale", true)
			green_banner.material.set_shader_parameter("is_pale", true)
			yellow_banner.material.set_shader_parameter("is_pale", false)
