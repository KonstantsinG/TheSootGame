extends CanvasLayer

signal create_new_server_pressed
signal servers_search_started
signal shutdown_server_pressed(reason: String)

@onready var menus = $Menus
@onready var popups = $Popups
@onready var servers_searching_timer = $ServersSearchingTimer
@onready var gamemode_menu = $Menus/GamemodeMenu

var server_menu = null
var room_lobby = null


func _ready() -> void:
	servers_searching_timer.timeout.connect(_on_servers_searching_timer_timeout)
	
	gamemode_menu.play_locally_pressed.connect(_on_play_locally_pressed)


func _on_servers_searching_timer_timeout() -> void:
	servers_search_started.emit()


func show_popup_notification(title : String, message : String) -> void:
	var popup = preload("res://scenes/menus/popup_notification.tscn").instantiate()
	popup.set_data(title, message)
	popup.popup_disappeared.connect(remove_popup)
	popups.add_child(popup)


func remove_popup() -> void:
	var target = popups.get_child(0)
	popups.remove_child(target)
	target.queue_free()


func add_found_server(ip : String, server_name : String) -> void:
	if server_menu != null:
		server_menu.add_server_panel(ip, server_name)


func remove_missing_server(ip : String):
	if server_menu != null:
		server_menu.remove_server_panel(ip)


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
	
	servers_searching_timer.start(1)


func _on_server_menu_back_pressed() -> void:
	menus.remove_child(server_menu)
	menus.add_child(gamemode_menu)


func _on_server_menu_join_pressed(ip : String) -> void:
	print("You wanna join the Server <", ip, ">")
	#NOTIMPLEMENTED


func _on_server_menu_create_new_pressed() -> void:
	create_new_server_pressed.emit()
	servers_searching_timer.stop()
	
	#TODO wait for success Server response
	
	_show_create_room_popup()


func _show_create_room_popup() -> void:
	var popup = preload("res://scenes/menus/creating_room_popup.tscn").instantiate()
	popup.create_room_pressed.connect(_on_create_room_popup_create_room_pressed)
	popup.cancel_pressed.connect(_on_create_room_popup_cancel_pressed)
	popups.add_child(popup)


func _on_create_room_popup_create_room_pressed(room_name : String, room_pass : String, ais_count : int) -> void:
	print("You wanna create new room")
	remove_popup()
	_open_room_lobby()
	#NOTIMPLEMENTED


func _on_create_room_popup_cancel_pressed() -> void:
	remove_popup()


func _open_room_lobby():
	# INFO: every time creating new instance
	room_lobby = preload("res://scenes/menus/room_lobby.tscn").instantiate()
	# TODO signals
	
	menus.remove_child(server_menu)
	menus.add_child(room_lobby)
