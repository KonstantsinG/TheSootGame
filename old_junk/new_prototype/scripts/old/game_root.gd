extends Node

var default_port = 8080
var broadcast_port = 8081

@onready var server = $WebSocketServerWrapper
@onready var client = $WebSocketClient
@onready var gui = $Content/MenuInterface


func _ready() -> void:
	server.client_connected.connect(_server_client_connected)
	server.client_disconnected.connect(_server_client_disconnected)
	
	client.connected_to_server.connect(_client_connected_to_server)
	client.connection_closed.connect(_client_connection_closed)
	client.message_recieved.connect(_client_message_recieved)
	
	gui.run_server_pressed.connect(_run_server)
	gui.search_for_servers_pressed.connect(_search_for_servers)
	gui.stop_server_pressed.connect(_stop_server)
	gui.connect_to_server_pressed.connect(_connect_client_to_server)
	gui.disconnect_from_server_pressed.connect(_disconnect_from_server)


func _search_for_servers() -> void:
	client.run_udp_broadcast(broadcast_port)
	print("Client send broadcast request for the Server adderess")


func _run_server() -> void:
	if server.get_server_net_type() == server.ServerNetTypes.LOCALHOST:
		print("You run the Server on localhost, so other PCs cannot access it.")
	
	if server.is_running():
		print("ERROR: Cannot start the Server, it already running")
		return
	
	var err = server.listen(default_port)
	if err != OK:
		gui.show_popup("Error", "Something went wrong while trying to run the Server...")
	else:
		print("SUCCESS: Server successfully started on port ", default_port)
		gui.show_popup("Success", "Server successfully started")
		
		server.listen_udp_broadcast(broadcast_port)
		print("Server has started listening broadcast port ", broadcast_port)
		
		_search_for_servers()


func _stop_server() -> void:
	if server.is_running():
		server.stop_udp_broadcasting()
		server.stop()
		print("Server was stopped")


func _disconnect_from_server() -> void:
	client.close()
	client.close_udp()


func _server_client_connected(id : int) -> void:
	print("Server said: Client connected")


func _server_client_disconnected(id : int) -> void:
	print("Server said: Client disconnected")


func _client_connected_to_server() -> void:
	if not server.is_running():
		gui.show_popup("Success", "Client successfully connected to the Server")
	
	print("Client said: Connected to the Server")


func _client_connection_closed() -> void:
	print("Client said: Connection closed")
	
	gui.show_popup("Notification", "Server just close the connection")
	gui._server_client_menu_open()


func _client_message_recieved(message) -> void:
	if message is Dictionary:
		match message["head"]:
			"RESPONSE_SERVER_IP":
				process_server_address(message["value"])
			
			"SERVER_CLOSE_NOTIFICATION":
				gui.remove_server_panel(message["value"])


func process_server_address(ip : String) -> void:
	print("Client: Server IP was found: ", ip)
	
	# if the Client is from the same PC where the Server is located
	if server.is_running():
		_connect_client_to_server(ip)
	else:
		var server_name = str(OS.get_environment("COMPUTERNAME"))
		gui.add_server_panel(server_name, ip)


func _connect_client_to_server(ip : String) -> void:
	var url = "ws://" + ip + ":" + str(default_port)
	var err = client.connect_to_url(url, "Meeee")
	if err != OK:
		print("Client cannot connect to the Server for some reason...")
