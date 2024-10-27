extends Node

@export var tcp_server_port : int = 8080
@export var udp_server_port : int = 8081

@onready var client = $WebSocketClient
@onready var server = $WebSocketServerWrapper
@onready var gui = $Content/MenusInterface


func _ready() -> void:
	client.message_recieved.connect(_on_client_message_recieved)
	
	gui.create_new_server_pressed.connect(_on_create_new_server_pressed)
	gui.servers_search_started.connect(_on_servers_search_started)


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
		
		# TODO: open RoomLobby scene on GUI
		
		# start UDP broadcasting Server
		err = server.listen_udp_broadcast(udp_server_port)
		
		if err != OK:
			printerr("ERROR<Unable to start UDP Server>: Something went wrong... Error code: ", err)
			server.stop()
			return
		else:
			_on_join_server_pressed(server_data.ip, server_data.server_name)


func _on_join_server_pressed(ip : String, server_name: String):
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


func _on_servers_search_started() -> void:
	var err = client.run_udp_broadcast(udp_server_port)
	
	if err != OK:
		printerr("ERROR<Unable to start UDP Client>: Something went wrong... Error code: ", err)






func _on_client_message_recieved(message) -> void:
	if message is Dictionary:
		match message["head"]:
			# response from UDP Server with TCP Server information
			"RESPONSE_SERVER_IP":
				gui.add_found_server(message["ip"], message["server_name"])
