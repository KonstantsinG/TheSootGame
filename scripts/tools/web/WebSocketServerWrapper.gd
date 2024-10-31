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
	var players_count : int = 1
	
	func _init(_room_name : String, _password : String) -> void:
		id = randi_range(2, 1 << 30)
		room_name = _room_name
		password = _password
		is_public = true if _password == "" else false
	
	
	func serialize() -> Dictionary:
		var data = {
			"room_name" : room_name,
			"password" : password,
			"players_count" : players_count
		}
		return data
#endregion

#region variables
var clients_data : Array[ClientData] = []
var rooms_data : Array[RoomData] = []
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


func process_udp_request(peer : PacketPeerUDP, message) -> void:
	if message == "GET_SERVER_DATA":
		var serv_data = get_server_data()
		var msg = {
			"head" : "SET_SERVER_DATA",
			"ip" : serv_data.ip,
			"server_name" : serv_data.server_name
		}
		peer.put_packet(var_to_bytes(msg))
	
	elif message == "GET_AVAILABLE_ROOMS":
		var rooms_arr := []
		for room in rooms_data:
			var room_data = room.serialize()
			room_data["server_ip"]  = get_ip()
			rooms_arr.append(room_data)
		
		var msg = {
			"head" : "SET_AVAILABLE_ROOMS",
			"value" : rooms_arr
		}
		peer.put_packet(var_to_bytes(msg))


# process incoming message
# Dictionary -> response or notification
# String -> request
func process_message(peer_id : int, message) -> void:
	if typeof(message) == TYPE_DICTIONARY:
		match message["head"]:
			# Client request for new Room creation
			"CREATE_NEW_ROOM":
				_create_new_room(message)
			
			# close Room and let all CLiemts know about that
			"CLOSE_ROOM":
				_close_room(peer_id, message)
	
	elif typeof(message) == TYPE_STRING:
		match message:
			pass



# --- ACTIONS ---
func _create_new_room(message) -> void:
	var room_name = message["room_name"]
	var password = message["password"]
	var room = RoomData.new(room_name, password)
	rooms_data.append(room)


func _close_room(peer_id : int, message) -> void:
	var room = rooms_data.filter(func(r): return r.room_name == message["room_name"]).front()
	
	if room != null:
		rooms_data.erase(room)
		
		var msg = {
			"head" : "NOTIFICATION_ROOM_CLOSED",
			"room_name" : room.room_name,
			"server_ip" : get_ip()
		}
		send(-peer_id, msg)
