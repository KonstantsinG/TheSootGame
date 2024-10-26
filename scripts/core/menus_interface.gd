extends CanvasLayer

@onready var menus = $Menus
@onready var gamemode_menu = $Menus/GamemodeMenu

var server_menu = null


func _ready() -> void:
	gamemode_menu.play_locally_pressed.connect(_on_play_locally_pressed)


func _on_play_locally_pressed() -> void:
	menus.remove_child(gamemode_menu)
	_open_server_menu()


func _open_server_menu() -> void:
	if server_menu == null:
		server_menu = preload("res://scenes/menus/server_menu.tscn").instantiate()
		
		server_menu.back_pressed.connect(_on_server_menu_back_pressed)
		server_menu.join_pressed.connect(_on_server_menu_join_pressed)
		server_menu.create_new_pressed.connect(_on_server_menu_create_new_pressed)
	
	menus.add_child(server_menu)


func _on_server_menu_back_pressed() -> void:
	menus.remove_child(server_menu)
	menus.add_child(gamemode_menu)


func _on_server_menu_join_pressed(ip : String) -> void:
	pass


func _on_server_menu_create_new_pressed() -> void:
	pass
