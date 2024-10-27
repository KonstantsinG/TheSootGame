extends WebSocketServer
class_name WebSocketServerWrapper # high-level Server with requests handler

#region enums
# enum representing Server ip type
enum ServerNetTypes{
	LAN,
	LOCALHOST
}
#endregion

#region classes
# class representing a Client additional data
class ClientData:
	var id : int
	var client_name : String
	var skin_data : String
	
	func _init(_id : int, _client_name : String) -> void:
		id = _id
		client_name = _client_name

# class representing a Room
class RoomData:
	var id : int
	var room_name : String
	var password : String
	var is_public : bool
	
	func _init(_room_name : String, _password : String) -> void:
		id = randi_range(2, 1 << 30)
		room_name = _room_name
		password = _password
		is_public = true if _password == "" else false
#endregion

#region variables
var clients_data : Array[ClientData] = []
var rooms_data : Array[RoomData] = []
#endregion


#region prebuild functions
func _ready() -> void:
	message_received.connect(_on_message_recieved)
	client_connected.connect(_on_client_connected)
	client_disconnected.connect(_on_client_disconnected)
#endregion


#region additional functions
# where the Server is running - on a localhost or in a LAN
func get_server_net_type() -> ServerNetTypes:
	var ip = get_ip()
	var ip_data = ip.split(".")
	
	# check for private ip ranges
	if ip_data[0] == "10": return ServerNetTypes.LAN
	elif ip_data[0] == "192" and ip_data[1] == "168": return ServerNetTypes.LAN
	elif ip_data[0] == "172" and (int(ip_data[1]) >= 16 and int(ip_data[1]) <= 31): return ServerNetTypes.LAN
	
	return ServerNetTypes.LOCALHOST
#endregion


# TODO rooms system
func create_room(room_name : String, password : String) -> void:
	pass


func _on_message_recieved(peer_id : int, message) -> void:
	process_message(peer_id, message)


 # FIXME if new Client connected -> request it data
func _on_client_connected(peer_id : int):
	var msg = "get_client_data"
	send(peer_id, msg)
	_update_clients_count()


# FIXME if Client disconnected -> make something with it...
func _on_client_disconnected(peer_id : int):
	peers.erase(peer_id)
	
	#var msg = {
	#	"head" : "log",
	#	"value" : "Client %s disconnected from Server" % [clients_data.filter(func(el) : return el.id == peer_id).front().client_name]
	#}
	#send(0, msg)
	
	#var peer = clients_data.filter(func(el) : return el.id == peer_id).front()
	#clients_data.erase(peer)
	
	_update_clients_count()

 # FIXME (CAPS) process incoming message
# Dictionary -> response or notification
# String -> request
func process_message(peer_id : int, message) -> void:
	if typeof(message) == TYPE_DICTIONARY:
		match message["head"]:
			# save additional Client data (from Server request)
			"set_client_data":
				_client_data_recieved(peer_id, message)
			# let all clients know that someone is moved
			"player_moved":
				_notify_player_moved(peer_id, message)
	
	elif typeof(message) == TYPE_STRING:
		match message:
			# update game players count for all Clients
			"update_clients_count":
				_update_clients_count()



# --- ACTIONS ---

# DEPRECATED send all Clients message with actual players count
func _update_clients_count():
	var msg = {
		"head" : "update_clients_count",
		"value" : get_connections_count()
	}
	send(0, msg)


# DEPRECATED idk, its logic is kind of strange...
func _client_data_recieved(peer_id : int, message):
	clients_data.append(ClientData.new(peer_id, message["name"]))
	var msg = {
		"head" : "log",
		"value" : "Client %s has successefully connected to the Server" % [message["name"]]
	}
	send(0, msg)


# NOTIMPLEMENTED
func start_game():
	var msg = "start_game"
	send(0, msg)
	
	_send_players_data()


# DEPRECATED broadcast players data for all players
func _send_players_data():
	for c1 in clients_data:
		for c2 in clients_data:
			var msg = {
				"head" : "add_player",
				"name" : c2.client_name,
				"id" : c2.id
			}
			if c1 == c2: msg["id"] = -1
			
			send(c1.id, msg)
		
		var msg2 = "spawn_players"
		send(c1.id, msg2)


# DEPRECATED you know...
func _notify_player_moved(peer_id : int, message) -> void:
	var msg = {
		"head" : "player_moved",
		"id" : peer_id,
		"new_position" : message["new_position"]
	}
	send(-peer_id, msg)
