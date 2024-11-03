extends CanvasLayer

#region Signals
# basic web signals
signal create_new_server_pressed
signal join_server_pressed(ip : String)

signal request_sended(request : MenuRequests, params : Dictionary)

# broadcast signals
signal servers_search_started
signal rooms_search_started

# finalizing signals
signal break_connection_pressed(reason: String)
#endregion

enum MenuRequests{
	CREATE_NEW_ROOM,
	CLOSE_ROOM,
	JOIN_PUBLIC_ROOM,
	JOIN_PRIVATE_ROOM
}

#region Variables
# containers
@onready var menus = $Menus
@onready var popups = $Popups

#timers
@onready var servers_searching_timer = $ServersSearchingTimer
@onready var rooms_searching_timer = $RoomsSearchingTimer

# first menu instance
@onready var gamemode_menu = $Menus/GamemodeMenu

var broadcast_requests_rate_sec = 1

# menu instances
var server_menu = null
var games_browser = null
var room_lobby = null
#endregion


#region Prebuild functions
func _ready() -> void:
	servers_searching_timer.timeout.connect(_on_servers_searching_timer_timeout)
	rooms_searching_timer.timeout.connect(_on_rooms_searching_timer_timeout)
	
	gamemode_menu.play_locally_pressed.connect(_on_play_locally_pressed)
	gamemode_menu.games_browser_pressed.connect(_on_games_browser_pressed)
#endregion


#region Utilities
func show_popup_notification(title : String, message : String) -> void:
	if popups.get_child_count() > 0:
		remove_popup()
	
	var popup = preload("res://scenes/menus/popups/popup_notification.tscn").instantiate()
	popup.set_data(title, message)
	popup.popup_disappeared.connect(remove_popup)
	popups.add_child(popup)


func remove_popup() -> void:
	var target = popups.get_child(0)
	popups.remove_child(target)
	target.queue_free()


func break_connection() -> void:
	var last_menu = menus.get_child(1)
	
	# if last menu is instance of RoomLobby
	if last_menu.has_method("_on_start_ready_text_button_pressed"):
		menus.remove_child(last_menu)
		last_menu.queue_free()
		
		menus.add_child(gamemode_menu)
		show_popup_notification("Notification", "The Server has terminated the connection")
#endregion


#region PlayLocally mode
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
	
	_on_servers_searching_timer_timeout()
	servers_searching_timer.start(broadcast_requests_rate_sec)


func _on_server_menu_back_pressed() -> void:
	servers_searching_timer.stop()
	
	menus.remove_child(server_menu)
	menus.add_child(gamemode_menu)


func _on_server_menu_join_pressed(ip : String) -> void:
	_show_create_room_popup() # SECURITY CAUTION maybe not the best solution
	
	servers_searching_timer.stop()
	join_server_pressed.emit(ip)


func _on_server_menu_create_new_pressed() -> void:
	_show_create_room_popup() # SECURITY CAUTION maybe not the best solution
	
	create_new_server_pressed.emit()
	servers_searching_timer.stop()


func _on_servers_searching_timer_timeout() -> void:
	servers_search_started.emit()


func add_found_server(ip : String, server_name : String) -> void:
	if server_menu != null:
		server_menu.add_server_panel(ip, server_name)


func remove_missing_server(ip : String):
	if server_menu != null:
		server_menu.remove_server_panel(ip)
#endregion


#region GamesBrowser mode
func _on_games_browser_pressed() -> void:
	menus.remove_child(gamemode_menu)
	_open_games_browser()


func _open_games_browser() -> void:
	if games_browser == null:
		games_browser = preload("res://scenes/menus/client_menu.tscn").instantiate()
		
		games_browser.join_room_pressed.connect(_on_games_browser_join_room_pressed)
		games_browser.back_pressed.connect(_on_games_browser_back_pressed)
	else:
		games_browser.clear_panels()
	
	menus.add_child(games_browser)
	
	_on_rooms_searching_timer_timeout()
	rooms_searching_timer.start(broadcast_requests_rate_sec)


func _on_games_browser_join_room_pressed(server_ip : String, room_name : String, is_public : bool) -> void:
	rooms_searching_timer.stop()
	join_server_pressed.emit(server_ip)
	await get_tree().create_timer(0.1).timeout
	
	if is_public:
		request_sended.emit(MenuRequests.JOIN_PUBLIC_ROOM, {"room_name" : room_name})
	else:
		_show_enter_password_popup(room_name)


func _show_enter_password_popup(room_name : String) -> void:
	if popups.get_child_count() > 0:
		remove_popup()
	
	var popup = preload("res://scenes/menus/popups/enter_room_password_popup.tscn").instantiate()
	popup.join_pressed.connect(_on_enter_password_popup_join_pressed)
	popup.cancel_pressed.connect(_on_enter_password_popup_cancel_pressed)
	popups.add_child(popup)
	popup.room_name = room_name


func _on_enter_password_popup_cancel_pressed() -> void:
	remove_popup()
	break_connection_pressed.emit("User decision")
	rooms_searching_timer.start(broadcast_requests_rate_sec)


func _on_enter_password_popup_join_pressed(room_name : String, password : String) -> void:
	request_sended.emit(MenuRequests.JOIN_PRIVATE_ROOM, {"room_name" : room_name, "password" : password})
	remove_popup()


func join_room_bad_response(details : String) -> void:
	show_popup_notification("Error", details) # ATTENTION BUG: Strange blink bug
	break_connection_pressed.emit("Join Room error")
	rooms_searching_timer.start(broadcast_requests_rate_sec)


func join_room(room_name : String) -> void:
	menus.remove_child(games_browser)
	_open_room_lobby(false, room_name)
	
	# TODO: Request other Room members data


func _on_games_browser_back_pressed() -> void:
	rooms_searching_timer.stop()
	
	menus.remove_child(games_browser)
	menus.add_child(gamemode_menu)


func _on_rooms_searching_timer_timeout() -> void:
	rooms_search_started.emit()


func add_found_room(server_ip : String, room_name : String, is_public : bool, players_count : int) -> void:
	if games_browser != null:
		games_browser.add_room_panel(server_ip, room_name, players_count, is_public)


func remove_missing_room(server_ip : String, room_name : String) -> void:
	_quit_room_lobby(room_name)
	_remove_room_from_games_browser(server_ip, room_name)


func _quit_room_lobby(room_name : String) -> void:
	var last_menu = menus.get_child(1)
	
	# if last menu is instance of RoomLobby
	if last_menu.has_method("_on_start_ready_text_button_pressed"):
		if last_menu.room_name == room_name:
			menus.remove_child(last_menu)
			last_menu.queue_free()
			
			menus.add_child(gamemode_menu)
			show_popup_notification("Notification", "Host closed the Room")
			break_connection_pressed.emit("Host closed the Room")


func _remove_room_from_games_browser(server_ip : String, room_name : String) -> void:
	if games_browser != null:
		games_browser.remove_room_panel(server_ip, room_name)
#endregion


#region CreateNewRoom mode
func _show_create_room_popup() -> void:
	if popups.get_child_count() > 0:
		remove_popup()
	
	var popup = preload("res://scenes/menus/popups/creating_room_popup.tscn").instantiate()
	popup.create_room_pressed.connect(_on_create_room_popup_create_room_pressed)
	popup.cancel_pressed.connect(_on_create_room_popup_cancel_pressed)
	popups.add_child(popup)


func _on_create_room_popup_cancel_pressed() -> void:
	servers_searching_timer.start(broadcast_requests_rate_sec)
	break_connection_pressed.emit("User decision")
	remove_popup()


func _on_create_room_popup_create_room_pressed(room_name : String, room_pass : String) -> void:
	remove_popup()
	
	# ask Server is Room that you trying to create valid
	request_sended.emit(MenuRequests.CREATE_NEW_ROOM, {"room_name" : room_name, "password" : room_pass})


func create_new_room_bad_response(details : String) -> void:
	servers_searching_timer.start(broadcast_requests_rate_sec)
	break_connection_pressed.emit("Wrong Room data")
	
	show_popup_notification("Error", details) # ATTENTION BUG: Strange blink bug


func create_new_room_good_response(room_name : String) -> void:
	menus.remove_child(server_menu)
	_open_room_lobby(true, room_name)
#endregion


#region RoomLobby mode
func _open_room_lobby(as_owner : bool, room_name : String):
	# INFO: every time creating new instance
	room_lobby = preload("res://scenes/menus/room_lobby.tscn").instantiate()
	room_lobby.start_pressed.connect(_on_room_lobby_start_pressed)
	room_lobby.ready_pressed.connect(_on_room_lobby_ready_pressed)
	room_lobby.close_pressed.connect(_on_room_lobby_close_pressed)
	room_lobby.disconnect_pressed.connect(_on_room_lobby_disconnect_pressed)
	
	menus.add_child(room_lobby)
	
	# NOTE: setup room
	room_lobby.set_data(room_name, as_owner)
	room_lobby.add_player_panel(as_owner)


func _on_room_lobby_start_pressed() -> void:
	# NOTIMPLEMENTED
	pass


func _on_room_lobby_ready_pressed() -> void:
	# NOTIMPLEMENTED
	pass


# INFO: for Room owner
func _on_room_lobby_close_pressed(room_name : String) -> void:
	menus.remove_child(room_lobby)
	room_lobby.queue_free()
	menus.add_child(gamemode_menu)
	
	# INFO: Close Room, send to the Server message about it, wait for all Clients recieve this message and then close connection
	request_sended.emit(MenuRequests.CLOSE_ROOM, {"room_name" : room_name})
	await get_tree().create_timer(0.5).timeout # ATTENTION: Bad bug fix (idk how to deal with it...)
	break_connection_pressed.emit("User decision")


# INFO: for Room guest
func _on_room_lobby_disconnect_pressed() -> void:
	menus.remove_child(room_lobby)
	room_lobby.queue_free()
	menus.add_child(gamemode_menu)
	
	break_connection_pressed.emit("User decision")
#endregion
