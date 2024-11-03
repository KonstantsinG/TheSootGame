extends WebSocketServer
class_name WebSocketServerWrapper # high-level Server with requests handler

const MAX_PLAYERS_IN_ROOM := 8

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
	var team : GameParams.TeamTypes
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
	
	var room_owner
	var room_guests := []
	
	func _init(_room_name : String, _password : String) -> void:
		id = randi_range(2, 1 << 30)
		room_name = _room_name
		password = _password
		is_public = true if _password == "" else false
	
	
	func serialize() -> Dictionary:
		var data = {
			"room_name" : room_name,
			"is_public" : is_public,
			"players_count" : players_count
		}
		return data
	
	
	func add_guest(peer_id : int) -> void:
		room_guests.append(peer_id)
		players_count += 1
	
	
	func remove_guest(peer_id : int) -> void:
		room_guests.erase(peer_id)
		players_count -= 1
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
				_create_new_room(peer_id, message)
			
			# close Room and let all CLiemts know about that
			"CLOSE_ROOM":
				_close_room(message)
			
			"JOIN_PUBLIC_ROOM":
				_join_public_room(peer_id, message)
			
			"JOIN_PRIVATE_ROOM":
				_join_private_room(peer_id, message)
	
	elif typeof(message) == TYPE_STRING:
		match message:
			pass


func finalize() -> void:
	super.finalize()
	_close_all_rooms()
	
	rooms_data.clear()





## ----- ACTIONS -----
func _close_all_rooms() -> void:
	var msg = {
		"head" : "NOTIFICATION_ROOM_CLOSED",
		"room_name" : "",
		"server_ip" : get_ip()
	}
	
	for room in rooms_data:
		msg["room_name"] = room.room_name
		
		for p in udp_peers:
			p.put_packet(var_to_bytes(msg))


func _create_new_room(peer_id : int, message) -> void:
	var msg
	if rooms_data.filter(func(r): return r.room_name == message["room_name"]).size() > 0:
		msg = {
			"head" : "NOTIFICATION_BAD_NEW_ROOM",
			"details" : "Room with this name already exist"
		}
		send(peer_id, msg)
		return
	
	var room_name = message["room_name"]
	var password = message["password"]
	var room = RoomData.new(room_name, password)
	rooms_data.append(room)
	room.room_owner = peer_id
	
	msg = {
		"head" : "NOTIFICATION_GOOD_NEW_ROOM",
		"room_name" : room_name
	}
	send(peer_id, msg)


func _close_room(message) -> void:
	var room = rooms_data.filter(func(r): return r.room_name == message["room_name"]).front()
	
	if room != null:
		rooms_data.erase(room)
		
		var msg = {
			"head" : "NOTIFICATION_ROOM_CLOSED",
			"room_name" : room.room_name,
			"server_ip" : get_ip()
		}
		
		for p in udp_peers:
			p.put_packet(var_to_bytes(msg))


func _join_public_room(peer_id : int, message) -> void:
	var room = rooms_data.filter(func(r): return r.room_name == message["room_name"]).front()
	var msg
	
	if room != null:
		if room.players_count >= MAX_PLAYERS_IN_ROOM:
			msg = {
				"head" : "NOTIFICATION_BAD_JOIN_ROOM",
				"details" : "This room is full. Maximum number of players is 8."
			}
		else:
			room.add_guest(peer_id)
			
			msg = {
				"head" : "NOTIFICATION_GOOD_JOIN_ROOM",
				"room_name" : message["room_name"]
			}
	
	else:
		msg = {
				"head" : "NOTIFICATION_BAD_JOIN_ROOM",
				"details" : "This room is unavailable. Something went wrong..."
			}
	
	send(peer_id, msg)


func _join_private_room(peer_id : int, message) -> void:
	var room = rooms_data.filter(func(r): return r.room_name == message["room_name"]).front()
	var msg
	
	if room != null:
		if room.password != message["password"]:
			msg = {
				"head" : "NOTIFICATION_BAD_JOIN_ROOM",
				"details" : "Incorrect password"
			}
		else:
			room.add_guest(peer_id)
			
			msg = {
				"head" : "NOTIFICATION_GOOD_JOIN_ROOM",
				"room_name" : message["room_name"]
			}
	
	else:
		msg = {
				"head" : "NOTIFICATION_BAD_JOIN_ROOM",
				"details" : "This room is unavailable. Something went wrong..."
			}
	
	send(peer_id, msg)
