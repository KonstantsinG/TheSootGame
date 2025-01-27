extends Control

@onready var name_label = $Panel/NameLabel
@onready var crown = $Panel/CrownTexture
@onready var check_mark = $Panel/CheckMarkTextureRect
@onready var red_team = $Panel/TeamPanel/NinePatchRect/HBoxContainer/RedBanner
@onready var blue_team = $Panel/TeamPanel/NinePatchRect/HBoxContainer/BlueBanner
@onready var green_team = $Panel/TeamPanel/NinePatchRect/HBoxContainer/GreenBanner
@onready var yellow_team = $Panel/TeamPanel/NinePatchRect/HBoxContainer/YellowBanner

var is_ready := false


func set_data(player_name : String, team : GameParams.TeamTypes, is_host : bool = false) -> void:
	name_label.text = player_name
	crown.visible = is_host
	_set_team(team)


func toggle_ready() -> bool:
	is_ready = !is_ready
	check_mark.visible = is_ready
	return is_ready


func update_data(player_name : String, team : GameParams.TeamTypes, _is_ready : bool) -> void:
	name_label.text = player_name
	_set_team(team)
	is_ready = _is_ready
	check_mark.visible = is_ready


func _set_team(team : GameParams.TeamTypes) -> void:
	var teams = {
		GameParams.TeamTypes.RED : red_team,
		GameParams.TeamTypes.BLUE : blue_team, 
		GameParams.TeamTypes.GREEN : green_team,
		GameParams.TeamTypes.YELLOW : yellow_team
	}
	
	teams[team].visible = true
	teams.erase(team)
	for t in teams.values():
		t.visible = false
