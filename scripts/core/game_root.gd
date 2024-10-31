extends Node

@export var tcp_server_port : int = 8080
@export var udp_server_port : int = 8081

@onready var client = $WebSocketClient
@onready var server = $WebSocketServerWrapper
@onready var gui = $Content/MenusInterface


func _ready() -> void:
	client.message_recieved.connect(_on_client_message_recieved)
	client.connection_closed.connect(_on_client_connection_closed)
	
	
	gui.create_new_server_pressed.connect(_on_create_new_server_pressed)
	gui.join_server_pressed.connect(_on_join_server_pressed)
	gui.create_new_room_pressed.connect(_on_create_new_room_peressed)
	gui.close_room_pressed.connect(_on_close_room_pressed)
	
	gui.servers_search_started.connect(_on_servers_search_started)
	gui.rooms_search_started.connect(_on_rooms_search_started)
	
	gui.break_connection_pressed.connect(_on_break_connection_pressed)



# ALERT WARNING INFO
# 1. Let all Clientt know about closing room event(maybe UDP from Server)
# 2. Remove Client recieved messages print
# 3. Remove or Fix clear_room_panels stuff from gui and client_menu (very bad)
# INFO WARNING ALERT



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
	
	client.close()
	client.close_udp()
	
	if server.is_listening():
		server.stop()
		server.stop_udp_broadcasting()


func _on_create_new_room_peressed(room_name : String, password : String):
	var msg = {
		"head" : "CREATE_NEW_ROOM",
		"room_name" : room_name,
		"password" : password
	}
	client.send(msg)


func _on_close_room_pressed(room_name : String) -> void:
	var msg = {
		"head" : "CLOSE_ROOM",
		"room_name" : room_name
	}
	client.send(msg)
#endregion


#region Client functions
func _on_client_connection_closed() -> void:
	gui.break_connection()

func _on_servers_search_started() -> void:
	var msg = "GET_SERVER_DATA"
	var err = client.run_udp_broadcast(udp_server_port, msg)
	
	if err != OK:
		printerr("ERROR<Unable to start UDP Client>: Something went wrong... Error code: ", err)


func _on_rooms_search_started() -> void:
	var msg = "GET_AVAILABLE_ROOMS"
	client.run_udp_broadcast(udp_server_port, msg)
#endregion


#region Client responses handler
func _on_client_message_recieved(message) -> void:
	print("CLIENT RECIEVED: ", message)
	if message is Dictionary:
		match message["head"]:
			# response from UDP Server with TCP Server information
			"SET_SERVER_DATA":
				gui.add_found_server(message["ip"], message["server_name"])
			
			# let all CLients know that Server is shutting down
			"NOTIFICATION_SERVER_CLOSING":
				gui.remove_missing_server(message["ip"])
			
			# get all available rooms data
			"SET_AVAILABLE_ROOMS":
				gui.clear_room_panels()
				
				for room in message["value"]:
					var server_ip = room["server_ip"]
					var room_name = room["room_name"]
					var password = room["password"]
					var players_count = int(room["players_count"])
					gui.add_found_room(server_ip, room_name, password, players_count)
			
			# remove Room from Browser and leave them
			"NOTIFICATION_ROOM_CLOSED":
				gui.remove_missing_room(message["server_ip"], message["room_name"])
#endregion
