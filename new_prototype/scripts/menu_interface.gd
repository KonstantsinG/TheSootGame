extends CanvasLayer

signal run_server_pressed
signal stop_server_pressed
signal connect_to_server_pressed
signal disconnect_from_server_pressed

signal search_for_servers_pressed

@onready var menus = $Menus
@onready var popups = $Popups

var singleplayer_mode = true
var last_menu = null
var popup = null

var gamemode_menu = null
var server_client_menu = null
var servers_browser = null
var multiplayer_menu = null
var rooms_browser = null
var create_room_menu = null
var player_setup_menu = null
var web_lobby = null

var main_player_name : String


func _ready() -> void:
	_open_gamemode_menu()


func _open_gamemode_menu() -> void:
	if gamemode_menu == null:
		gamemode_menu = preload("res://new_prototype/scenes/menus/game_mode_menu.tscn").instantiate()
		gamemode_menu.singleplayer_pressed.connect(_gamemode_menu_singleplayer_pressed)
		gamemode_menu.multiplayer_pressed.connect(_gamemode_menu_multiplayer_pressed)
	
	if last_menu != null: menus.remove_child(last_menu)
	last_menu = gamemode_menu
	menus.add_child(gamemode_menu)


func _gamemode_menu_singleplayer_pressed() -> void:
	singleplayer_mode = true
	
	#TODO setup player -> start game


func _gamemode_menu_multiplayer_pressed() -> void:
	singleplayer_mode = false
	
	_server_client_menu_open()


func _server_client_menu_open() -> void:
	if server_client_menu == null:
		server_client_menu = preload("res://new_prototype/scenes/menus/server_client_menu.tscn").instantiate()
		server_client_menu.run_server_pressed.connect(_server_client_menu_run_server_pressed)
		server_client_menu.connect_to_server_pressed.connect(_server_client_menu_connect_to_server_pressed)
		server_client_menu.back_pressed.connect(_server_client_menu_back_pressed)
	
	if last_menu != null: menus.remove_child(last_menu)
	last_menu = server_client_menu
	menus.add_child(server_client_menu)


func _server_client_menu_run_server_pressed() -> void:
	run_server_pressed.emit()
	_multiplayer_menu_open()


func _server_client_menu_connect_to_server_pressed() -> void:
	connect_to_server_pressed.emit()
	#_multiplayer_menu_open()
	_servers_browser_open()


func _server_client_menu_back_pressed() -> void:
	_open_gamemode_menu()


func _multiplayer_menu_open() -> void:
	if multiplayer_menu == null:
		multiplayer_menu = preload("res://new_prototype/scenes/menus/multiplayer_menu.tscn").instantiate()
		multiplayer_menu.create_room_pressed.connect(_multiplayer_menu_create_room_pressed)
		multiplayer_menu.join_room_pressed.connect(_multiplayer_menu_join_room_pressed)
		multiplayer_menu.back_pressed.connect(_multiplayer_menu_back_pressed)
	
	if last_menu != null: menus.remove_child(last_menu)
	last_menu = multiplayer_menu
	menus.add_child(multiplayer_menu)


func _multiplayer_menu_create_room_pressed() -> void:
	#FIXME rework create room popup ui
	pass


func _multiplayer_menu_join_room_pressed() -> void:
	#TODO rooms browser
	pass


func _multiplayer_menu_back_pressed() -> void:
	disconnect_from_server_pressed.emit()
	stop_server_pressed.emit()
	_server_client_menu_open()


func _servers_browser_open() -> void:
	if servers_browser == null:
		servers_browser = preload("res://new_prototype/scenes/menus/servers_browser.tscn").instantiate()
		servers_browser.join_pressed.connect(_servers_browser_join_pressed)
		servers_browser.back_pressed.connect(_servers_browser_back_pressed)
	
	if last_menu != null: menus.remove_child(last_menu)
	last_menu = servers_browser
	menus.add_child(servers_browser)
	
	search_for_servers_pressed.emit()


func _servers_browser_join_pressed(ip : String) -> void:
	pass


func _servers_browser_back_pressed() -> void:
	_server_client_menu_open()


func add_server_panel(name : String, address : String) -> void:
	if servers_browser != null:
		servers_browser.add_server_panel(name, address)


func remove_server_panel(address : String):
	if servers_browser != null:
		servers_browser.remove_server_panel(address)



func show_popup(title: String, message : String) -> void:
	if popup != null:
		popups.remove_child(popup)
		popup.free()
	
	popup = preload("res://new_prototype/scenes/menus/message_popup.tscn").instantiate()
	popup.close_pressed.connect(_popup_close_pressed)
	popup.set_data(title, message)
	popups.add_child(popup)


func _popup_close_pressed() -> void:
	popups.remove_child(popup)
	popup.queue_free()
	popup = null
