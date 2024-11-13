extends Node

@export var tcp_server_port : int = 8080
@export var udp_server_port : int = 8081

@onready var client = $WebSocketClient
@onready var server = $WebSocketServerWrapper
@onready var gui = $Content/MenusInterface

var responses_handler_state := GameParams.MessagesHandlerStates.MENU


func _ready() -> void:
	client.message_recieved.connect(_on_client_message_recieved)
	client.connection_closed.connect(_on_client_connection_closed)
	
	
	gui.create_new_server_pressed.connect(_on_create_new_server_pressed)
	gui.join_server_pressed.connect(_on_join_server_pressed)
	
	gui.servers_search_started.connect(_on_servers_search_started)
	gui.rooms_search_started.connect(_on_rooms_search_started)
	
	gui.break_connection_pressed.connect(_on_break_connection_pressed)
	gui.request_sended.connect(_on_request_sended)
	gui.game_started.connect(_on_game_started)


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
#endregion


#region Extra Server fuctionality
func _on_request_sended(request_type, params : Dictionary) -> void:
	match request_type:
		gui.MenuRequests.CREATE_NEW_ROOM:
			params["head"] = "CREATE_NEW_ROOM"
		
		gui.MenuRequests.CLOSE_ROOM:
			params["head"] = "CLOSE_ROOM"
		
		gui.MenuRequests.JOIN_ROOM:
			params["head"] = "JOIN_ROOM"
		
		gui.MenuRequests.GET_ROOM_MEMBERS:
			params["head"] = "GET_ROOM_MEMBERS"
		
		gui.MenuRequests.UPDATE_PLAYER_DATA:
			params["head"] = "UPDATE_PLAYER_DATA"
		
		gui.MenuRequests.GAME_COUNTDOWN_TOGGLED:
			params["head"] = "NOTIFICATION_GAME_COUNTDOWN_TOGGLED"
	
	client.send(params)
#endregion


#region Client functions
func _on_client_connection_closed() -> void:
	gui.break_connection()


func _on_servers_search_started() -> void:
	var msg = "GET_SERVER_DATA"
	
	client.run_udp_broadcast(udp_server_port, msg)


func _on_rooms_search_started() -> void:
	var msg = "GET_AVAILABLE_ROOMS"
	
	client.run_udp_broadcast(udp_server_port, msg)


func _on_game_started(room_name : String) -> void:
	# TODO: Close MenuInterface and open Game scene
	
	var msg = {"head" : "NOTIFICATION_GAME_STARTED", "room_name" : room_name}
	client.send(msg)
	
	responses_handler_state = GameParams.MessagesHandlerStates.GAME
#endregion


#region Client responses handler
func _on_client_message_recieved(message) -> void:
	print("Client recieved: ", message)
	
	if responses_handler_state == GameParams.MessagesHandlerStates.MENU:
		_process_menu_response(message)
	elif responses_handler_state == GameParams.MessagesHandlerStates.GAME:
		# NOTIMPLEMENTED
		pass
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
			
			"NOTIFICATION_GAME_STARTED":
				# NOTIMPLEMENTED
				print("Client started game")
				pass


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
#endregion



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
## BUG's
# 0.1. Cannot create new Room (wrong name) -> blink bug
# 0.2. Cannot join the Room (wrong password) -> blink bug
# 0.3. If: create two rooms and break root one -> descendant doesn't disappear in browser
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
## 9. Update players_count in RoomsBrowser if someone is connected
# 10. If Host started the Game and not all Guests pressed Ready -> start 5 sec Timer
# 11. When all Guests pressed Ready -> Start the Game
# 12. If someone doesn't press Ready -> exclude him from the Room and start the Game
## 13. Exit GAME_REQUESTS handler state (Server and GameRoot)
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
