extends Node

@export var tcp_server_port : int = 148
@export var udp_server_port : int = 149

@onready var client = $WebSocketClient
@onready var server = $WebSocketServerWrapper

@onready var content = $Content
var gui = null
var game_container = null

var responses_handler_state := GameParams.MessagesHandlerStates.MENU


func _ready() -> void:
	client.message_recieved.connect(_on_client_message_recieved)
	client.connection_closed.connect(_on_client_connection_closed)
	
	_load_gui()


#region Server functions
func _on_create_new_server_pressed() -> void:
	# check for LAN connection
	if server.get_server_net_type() != server.ServerNetTypes.LAN:
		printerr("ERROR<Unable to start Server>: The Server is not on the LAN.")
		gui.show_popup_notification("Error", "Unable to start Server: The Server is not on the LAN.")
		return
	
	# check if Server is already listening
	if server.is_listening():
		var server_data = server.get_server_data()
		print("Shutting down Server <", server_data.server_name, ": ", server_data.ip, ">...")
		server.stop_udp_broadcasting()
		server.stop()
		await client.connection_closed
	
	# try to start TCP Server
	var err = server.listen(tcp_server_port)
	if err != OK:
		printerr("ERROR<Unable to start Server>: Something went wrong... Error code: ", err)
		gui.show_popup_notification("Error", "Unable to start Server: Something went wrong...")
	else:
		var server_data = server.get_server_data()
		print("Server<", server_data.server_name, ": ", server_data.ip, "> successfully started on port ", tcp_server_port)
		
		# start UDP broadcasting Server
		err = server.listen_udp_broadcast(udp_server_port)
		
		if err != OK:
			printerr("ERROR<Unable to start UDP Server>: Something went wrong... Error code: ", err)
			server.stop()
			return
		else:
			_on_join_server_pressed(server_data.ip, server_data.server_name)


func _on_join_server_pressed(ip : String, server_name: String = "") -> void:
	var url = "ws://" + ip + ":" + str(tcp_server_port)
	var err = client.connect_to_url(url)
	
	if err != OK:
		printerr("ERROR<Unable to connect to Server>: Something went wrong... Error code: ", err)
		gui.show_popup_notification("Error", "Unable to connect to Server: Something went wrong...")
		return
	else:
		var client_data = client.get_client_data()
		print("Client<", client_data.client_name, ": ", client_data.ip, "> successfully connected to the Server<", \
			   server_name, ": ", ip, ">")


func _on_break_connection_pressed(reason : String) -> void:
	if server.is_listening():
		var data = server.get_server_data()
		print("Shutting down Server<", data.server_name, ": ", data.ip, ">... Reason: ", reason)
	else:
		print("Closing connection... Reason: ", reason)
	
	if server.is_listening():
		server.stop()
		server.stop_udp_broadcasting()
	
	client.close()
	client.close_udp()


func _try_break_connection() -> void:
	if server.is_listening():
		server.try_shutdown_server()
	
	client.close()
	client.close_udp()
#endregion


#region Extra Server fuctionality
func _on_request_sended(request : Dictionary) -> void:
	client.send(request)
#endregion


#region Client functions
func _on_client_connection_closed() -> void:
	if gui != null:
		gui.break_connection()


func _on_servers_search_started() -> void:
	var msg = "GET_SERVER_DATA"
	
	client.run_udp_broadcast(udp_server_port, msg)


func _on_rooms_search_started() -> void:
	var msg = "GET_AVAILABLE_ROOMS"
	
	var err = client.run_udp_broadcast(udp_server_port, msg)
	if err != OK: print("Somewhat I cannot start UDP-Client... code: " + str(err))


# start Game for Room owner
func _on_game_started(room_name : String) -> void:
	var msg = {"head" : "NOTIFICATION_GAME_STARTED", "room_name" : room_name}
	client.send(msg)
#endregion


#region GameContainer signals
func _on_game_container_back_to_menu_pressed(room_name : String) -> void:
	client.send({"head" : "QUIT_GAME", "room_name" : room_name})
	
	responses_handler_state = GameParams.MessagesHandlerStates.MENU
	content.remove_child(game_container)
	game_container.queue_free()
	game_container = null
	_load_gui()
	
	await get_tree().create_timer(0.2).timeout
	_try_break_connection()
#endregion


#region Client responses handler
func _on_client_message_recieved(message) -> void:
	if message["head"] != "NOTIFICATION_PLAYER_MOVED":
		print("Client recieved: ", message)
	
	if responses_handler_state == GameParams.MessagesHandlerStates.MENU:
		_process_menu_response(message)
	elif responses_handler_state == GameParams.MessagesHandlerStates.GAME:
		_process_game_response(message)
#endregion





#region MENU SERVER RESPONSES HANDLER
func _process_menu_response(message) -> void:
	if message is Dictionary:
		match message["head"]:
			# response from UDP Server with TCP Server information
			"SET_SERVER_DATA":
				gui.add_found_server(message["ip"], message["server_name"])
			
			# let all CLients know that Server is shutting down
			"NOTIFICATION_SERVER_CLOSING":
				gui.remove_missing_server(message["ip"])
			
			# Room that you trying to create are bad
			"NOTIFICATION_BAD_NEW_ROOM":
				gui.create_new_room_bad_response(message["details"])
			
			# Server successfully added your Room
			"NOTIFICATION_GOOD_NEW_ROOM":
				gui.create_new_room_good_response(message["room_name"])
			
			# get all available rooms data
			"SET_AVAILABLE_ROOMS":
				_add_new_rooms(message)
			
			# remove Room from Browser and leave them
			"NOTIFICATION_ROOM_CLOSED":
				gui.remove_missing_room(message["server_ip"], message["room_name"])
			
			# invalid password or too much players
			"NOTIFICATION_BAD_JOIN_ROOM":
				gui.join_room_bad_response(message["details"])
			
			# access to the Room was successfully granted
			"NOTIFICATION_GOOD_JOIN_ROOM":
				gui.join_room(message["room_name"])
			
			# let all Room members know that someone new is connected
			"NOTIFICATION_NEW_ROOM_MEMBER":
				gui.add_room_member(message["id"], message["player_name"], message["team"])
			
			# remove guest panel from RoomLobby if player is disconnected
			"NOTIFICATION_PLAYER_DISCONNECTED":
				gui.remove_room_member(message["id"])
			
			# get all Room members
			"SET_ROOM_MEMBERS":
				_add_room_members(message)
			
			# if any of the Room guests change its data -> keep it actual
			"UPDATE_PLAYER_DATA":
				gui.update_room_guest_data(message["id"], message["player_name"], message["team"], message["is_ready"])
			
			"NOTIFICATION_GAME_COUNTDOWN_TOGGLED":
				gui.set_game_countdown(message["value"])
			
			"NOTIFICATION_EXCLUDED_FROM_ROOM":
				_exclude_from_room()
			
			"NOTIFICATION_GAME_STARTED":
				_start_game(message["room_name"], message["you"], message["guests"])


func _add_new_rooms(message) -> void:
	for room in message["value"]:
		var server_ip = room["server_ip"]
		var room_name = room["room_name"]
		var is_public = room["is_public"] 
		var players_count = int(room["players_count"])
		gui.add_found_room(server_ip, room_name, is_public, players_count)


func _add_room_members(message) -> void:
	for member in message["value"]:
		var id = member["id"]
		var player_name = member["player_name"]
		var team = member["team"]
		var is_host = member["is_host"]
		gui.add_room_member(id, player_name, team, is_host)


func _start_game(room_name, main_player_data, guests_data) -> void:
	print("Client started game")
	responses_handler_state = GameParams.MessagesHandlerStates.GAME
	
	content.remove_child(gui)
	gui.queue_free()
	gui = null
	
	_load_game_container()
	game_container.room_name = room_name
	game_container.spawn_players(main_player_data, guests_data)


func _exclude_from_room() -> void:
	gui.exclude_from_room()
	client.close()
	client.close_udp()
#endregion


#region GAME SERVER RESPONSES HANDLER
func _process_game_response(message) -> void:
	match message["head"]:
		"NOTIFICATION_PLAYER_MOVED":
			game_container.update_player_position(message["id"], message["position"])
		
		"NOTIFICATION_PLAYER_DISCONNECTED":
			game_container.remove_player(message["id"])
		
		"NOTIFICATION_SERVER_CLOSING":
			_leave_room("Host closed the Server")
		
		"NOTIFICATION_ROOM_CLOSED":
			if game_container.room_name == message["room_name"]:
				_leave_room("Host closed the Game")
		
		"NOTIFICATION_PLAYER_EXIT_ROOM":
			_switch_room(message)
		
		"NOTIFICATION_COAL_TAKEN":
			game_container.give_coal(message["player_id"], message["coal_id"], message["type"])
		
		"NOTIFICATION_COAL_DROPPED":
			game_container.burn_coal(message["player_id"], message["team"], message["score"])
		
		"NOTIFICATION_BARRICADE_PLACED":
			game_container.place_barricade(message["player_id"], message["position"])
		
		"NOTIFICATION_COAL_PICKED_UP":
			game_container.pick_up_coal(message["player_id"], message["coal_id"])


func _switch_room(message) -> void:
	if game_container != null:
		game_container.switch_room(message["player_id"], message["destination"], message["hole_id"])


func _leave_room(reason : String) -> void:
	_try_break_connection()
	responses_handler_state = GameParams.MessagesHandlerStates.MENU
	
	content.remove_child(game_container)
	game_container.queue_free()
	game_container = null
	
	_load_gui()
	gui.show_popup_notification("Notification", reason)
#endregion


#region ScenesLoaders
func _load_gui() -> void:
	if gui == null:
		gui = preload("res://scenes/core/menus_interface.tscn").instantiate()
		gui.create_new_server_pressed.connect(_on_create_new_server_pressed)
		gui.join_server_pressed.connect(_on_join_server_pressed)
		
		gui.servers_search_started.connect(_on_servers_search_started)
		gui.rooms_search_started.connect(_on_rooms_search_started)
		
		gui.break_connection_pressed.connect(_on_break_connection_pressed)
		gui.request_sended.connect(_on_request_sended)
		gui.game_started.connect(_on_game_started)
	
	content.add_child(gui)


func _load_game_container() -> void:
	if game_container == null:
		game_container = preload("res://scenes/core/game_container.tscn").instantiate()
		
		game_container.request_sended.connect(_on_request_sended)
		game_container.back_to_menu_pressed.connect(_on_game_container_back_to_menu_pressed)
	
	content.add_child(game_container)
#endregion



#region NOTEPAD
## ---------------------------------------------------------
##      /$$$$$$$$  /$$$$$$   /$$$$$$$    /$$$$$$ 
##     |__  $$__/ /$$__  $$ | $$__  $$  /$$__  $$
##        | $$   | $$  \ $$ | $$  \ $$ | $$  \ $$
##        | $$   | $$  | $$ | $$  | $$ | $$  | $$
##        | $$   | $$  | $$ | $$  | $$ | $$  | $$
##        | $$   | $$  | $$ | $$  | $$ | $$  | $$
##        | $$   |  $$$$$$/ | $$$$$$$/ |  $$$$$$/
##        |__/    \______/  |_______/   \______/
## ---------------------------------------------------------
## 
## BUG's // WARNING's
# 0.1. Cannot create new Room (wrong name) -> blink bug
# 0.2. Cannot join the Room (wrong password) -> blink bug
# 0.3. If: create two rooms and break root one -> descendant doesn't disappear in browser
# 0.4. StartGame -> finalize gui resources
# 1.1 Fix TCP-connection on Vm
## 1.2 Fix UDP-broadcasting/listening on Vm -IMPORTANT
## 
## TODO's
# 1. Ask Server is Room that i wanna create legal (unique name)
# 2. Remove password from local scenes, let Server check is it correct
# 3. Cleanup GamemodeMenu and ServerWrapper code (Separate menu and game messages)
# 4. If Client disconnect form Server -> remove them from all Rooms
# 5. Rise Client CLOSING_EVENT for disconnect them from Server and Room properly
# 6. Remove GuestPanel from all Clients Lobbys if he disconnected
# 7. Update GusetPanel data if Client change something in his Soot
# 8. Implement visually and programmatically ready Player state
## 9. Update players_count in GamesBrowser if someone is connected
# 10. If Host started the Game and not all Guests pressed Ready -> start 5 sec Timer
# 11. When all Guests pressed Ready -> Start the Game
# 12. If someone doesn't press Ready -> exclude him from the Room and start the Game
# 13. Exit GAME_REQUESTS handler state (Server and GameRoot)
# 14. If Game started and guest doesn't pressed ready, throw them into MainMenu
# 15. If Host closed the Game -> close it for all Guests
# 16. If only one Game closed -> keep others alive
## 17. Add IN_GAME icon for RoomPanel in GamesBrowser (or just remove it)
# 18 Syncronize players spawn positions
## 19. RoomLobby: if someone pressed ready before you entered the Room -> you doesn't see that this player is ready (you must)
# 20. Add popup notification for Client when Host closed the Game
## 21. RoomLobby: if Host activated StartGameTimer and someone new connected -> he doesn't see Timer on the screen
# 22. If Host got crashed -> disconnect all Clients from the Game
## 23. Add ServerStateDisplay to the gui
## 24. GamePauseMenu: Switch default buttons to pretty ones
# 25. None-playable Soot position interpolation
# 26. Fading transition while switching the Room
# 27. Cave -> Boiler Room backward pass
# 28. Implement collecting Coal
# 29. Implement burning Coal and getting Score
# 30. Add Score HUD panel
## 31. Implement Soot pushing -IMPORTANT
## 32. Implement Coal barricades -IMPORTANT
# 33. Add GameTimer and EndgameState
# 34. Add EndgameScreen
# 35. Fix Guests Soot teleportation when entering new Room
## 36. Add Burning Coal animation
# 37. Fix GamePauseMenu and PlayerCamera conflict
## 38. Add Obsticles/Bullets in BoilerRoom for Soot

## ----- 


## TASK -> ROADMAP
## 1. BoilerRoom
## 2. Coal
## 3. Score and Timer
## 4. Pushing and Lifes
## 5. Bullets
## 6. Endgame?
##


## TASK -> GAME FEATURES
## INFO: DRAWING STUF
# 1. Partial: body, eyes, legs, arms
## 2. Animations: walking, running, pushing (4 dirs)
## 3. Spawn Room (fix y_sort)
##
## INFO: GAME_GLOBALS
## TEAMS_SCORE, HP, TIMER
## 1. TEAM_SCORE -> if you roast coal, your team increase score by 3. Who have greatest number in the ENDGAME - wins.
## 2. HP -> if RND_ITEM falls on you - you lose a bit HP. If it's 0 - you're dead, wait for respawn 10 sec.
## 3. TIME -> defines GAME time. Goes form 350 to 0.
##
## INFO: GAME_ACTIONS
## RND_ITEMS, PUSH, ENDGAME, COAL, CAVE, FURNACE
## 1. RND_ITEM -> Grand drops it accidentally (some herbs and infusions for water). It causes DAMEGE if you'll be near
## 2. PUSH -> Soot can push each other. It doesn't causes DAMAGE, but confuse you for a moment
## 3. ENDGAME -> Emitted when TIMER ends. Chosing the Winner team.
## 4. COAL -> Soot can take it from CAVE and move it to the FURNACE. Gives 3 points for the Team
## 5. CAVE -> Spawn point for Soot. Also, COAL spawns here.
## 6. FURNACE -> Soot bring the COAL here. Complete QTE for roast it successfully (if QTE fails - Soot became BURNED with 50% chance)
##
#endregion
