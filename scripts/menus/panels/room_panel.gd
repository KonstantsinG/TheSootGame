extends Control

signal panel_pressed(target : Control)

@onready var public_texture = $Panel/PublicTexture
@onready var private_texture = $Panel/PrivateTexture
@onready var launched_texture = $Panel/LaunchedTexture

@onready var ip_label = $Panel/Panel/HBoxContainer/IPLabel
@onready var name_label = $Panel/Panel/HBoxContainer/NameLabel
@onready var count_label = $Panel/Panel/HBoxContainer/PlayersCountLabel

var server_ip : String
var room_name : String
var players_count : int
var is_public : bool


func set_data(_server_ip : String, _room_name : String, _players_count : int, _is_public : bool) -> void:
	server_ip = _server_ip
	room_name = _room_name
	players_count = _players_count
	is_public = _is_public
	
	ip_label.text = server_ip
	name_label.text = room_name
	count_label.text = "Players count: " + str(players_count)
	
	if _is_public:
		public_texture.visible = true
		private_texture.visible = false
	else:
		public_texture.visible = false
		private_texture.visible = true


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			panel_pressed.emit(self)


func _on_panel_mouse_entered() -> void:
	material.set_shader_parameter("highlighted", true)


func _on_panel_mouse_exited() -> void:
	material.set_shader_parameter("highlighted", false)
