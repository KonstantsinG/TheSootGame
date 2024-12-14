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
class PlayerData:
	var id : int
	var player_name : String = ""
	var team : GameParams.TeamTypes = GameParams.TeamTypes.RED
	var skin : String = ""
	var is_ready := false
	
	func _init(_id : int) -> void:
		id = _id
	
	
	func serialize() -> Dictionary:
		var data = {
			"id" : id,
			"player_name" : player_name,
			"team" : team,
			"skin" : skin
		}
		return data

# class representing a Room
class RoomData:
	var id : int
	var room_name : String
	var password : String
	
	var is_public : bool
	var players_count : int = 1
	var is_game_running := false
	
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
var players_data : Array[PlayerData] = []
var rooms_data : Array[RoomData] = []

var messages_handler_state := GameParams.MessagesHandlerStates.MENU
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
	if messages_handler_state == GameParams.MessagesHandlerStates.MENU:
		_process_menu_request(peer_id, message)
	elif messages_handler_state == GameParams.MessagesHandlerStates.GAME:
		_process_game_request(peer_id, message)


func finalize() -> void:
	super.finalize()
	_close_all_rooms()
	
	rooms_data.clear()
	players_data.clear()


# called when the Server detects a closed TCP peer (internal copy of the client_disconnected signal)
func disconnect_client(peer_id : int) -> void:
	var room = null
	for r in rooms_data:
		for g in r.room_guests:
			if g == peer_id:
				room = r
				break
		
		if room != null: break
	
	if room != null:
		_disconnect_from_room(peer_id, room.room_name)



## - - - - - ACTIONS - - - - -
func try_shutdown_server() -> void:
	if rooms_data.size() == 0:
		stop_udp_broadcasting()
		stop()


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


func _get_room_by_name(room_name : String) -> RoomData:
	var rooms = rooms_data.filter(func(r): return r.room_name == room_name)
	if rooms.size() >= 1: return rooms.front()
	else: return null


func _get_player_by_id(peer_id : int) -> PlayerData:
	var players = players_data.filter(func(p): return p.id == peer_id)
	if players.size() >= 1: return players.front()
	else: return null


# INFO: Room host if always first
func _get_room_members(room_name : String, with_owner = true) -> Array[PlayerData]:
	var data : Array[PlayerData] = []
	var room = _get_room_by_name(room_name)
	if room == null: return data
	
	var player
	if with_owner:
		player = _get_player_by_id(room.room_owner)
		if player != null: data.append(player)
	
	for g in room.room_guests:
		player = _get_player_by_id(g)
		if player != null: data.append(player)
	
	return data





#region MENU REQUESTS HANDLER
func _process_menu_request(peer_id : int, message) -> void:
	if typeof(message) == TYPE_DICTIONARY:
		match message["head"]:
			# Client request for new Room creation
			"CREATE_NEW_ROOM":
				_create_new_room(peer_id, message)
			
			# close Room and let all CLiemts know about that
			"CLOSE_ROOM":
				_close_room(message["room_name"])
			
			"JOIN_ROOM":
				_join_room(peer_id, message)
			
			"DISCONNECT_FROM_ROOM":
				_disconnect_from_room(peer_id, message["room_name"])
			
			"GET_ROOM_MEMBERS":
				_set_room_members(peer_id, message)
			
			"UPDATE_PLAYER_DATA":
				_update_player_data(peer_id, message)
			
			"NOTIFICATION_GAME_COUNTDOWN_TOGGLED":
				_game_countdown_toggled(message["room_name"], message["value"])
			
			"NOTIFICATION_GAME_STARTED":
				_start_game(message["room_name"])
			
			_: _process_game_request(peer_id, message)


func _add_new_player(peer_id : int) -> PlayerData:
	var player = _get_player_by_id(peer_id)
	
	if player != null:
		return player
	else:
		var new_player = PlayerData.new(peer_id)
		players_data.append(new_player)
		return new_player


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
	_add_new_player(peer_id)


func _close_room(room_name : String) -> void:
	var room = _get_room_by_name(room_name)
	
	if room != null:
		rooms_data.erase(room)
		
		var msg = {
			"head" : "NOTIFICATION_ROOM_CLOSED",
			"room_name" : room.room_name,
			"server_ip" : get_ip()
		}
		
		for p in udp_peers:
			p.put_packet(var_to_bytes(msg))
	
	try_shutdown_server()


func _join_room(peer_id : int, message) -> void:
	var room = _get_room_by_name(message["room_name"])
	var err = true
	var msg
	
	if room != null:
		if room.players_count >= GameParams.MAX_PLAYERS_IN_ROOM:
			msg = {
				"head" : "NOTIFICATION_BAD_JOIN_ROOM",
				"details" : "This room is full. Maximum number of players is 8."
			}
		
		elif not room.is_public and room.password != message["password"]:
			msg = {
				"head" : "NOTIFICATION_BAD_JOIN_ROOM",
				"details" : "Incorrect password"
			}
		
		else:
			err = false
			
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
	
	if not err:
		room.add_guest(peer_id)
		var new_player = _add_new_player(peer_id)
		_notify_new_room_member_connected(room, new_player)


func _disconnect_from_room(peer_id : int, room_name : String) -> void:
	var room = _get_room_by_name(room_name)
	if room != null:
		room.remove_guest(peer_id)
		
		var msg = {
			"head" : "NOTIFICATION_PLAYER_DISCONNECTED",
			"id" : peer_id
		}
		for g in _get_room_members(room_name):
			send(g.id, msg)


func _notify_new_room_member_connected(room : RoomData, player : PlayerData):
	var msg = {"head" : "NOTIFICATION_NEW_ROOM_MEMBER"}
	msg.merge(player.serialize())
	
	if room.room_owner != player.id:
		send(room.room_owner, msg)
	
	for g in room.room_guests:
		if g != player.id: send(g, msg)


func _set_room_members(peer_id :  int, message) -> void:
	var room_members = _get_room_members(message["room_name"])
	var player_data
	
	var msg = {
		"head" : "SET_ROOM_MEMBERS",
		"value" : []
	}
	
	for i in range(room_members.size()):
		if room_members[i].id == peer_id: continue
		player_data = room_members[i].serialize()
		
		if i == 0: player_data["is_host"] = true
		else: player_data["is_host"] = false
		
		msg["value"].append(player_data)
	
	send(peer_id, msg)


func _update_player_data(peer_id : int, message) -> void:
	var player = _get_player_by_id(peer_id)
	var room_members = _get_room_members(message["room_name"])
	
	# INFO: we're updating only name and team params for now (skin in the future...)
	if player != null:
		player.player_name = message["player_name"]
		player.team = message["team"]
		player.is_ready = message["is_ready"]
		
		message["id"] = peer_id
		for m in room_members:
			if m.id == peer_id: continue
			send(m.id, message)


func _game_countdown_toggled(room_name : String, value : bool) -> void:
	var room = _get_room_by_name(room_name)
	var msg = {
		"head" : "NOTIFICATION_GAME_COUNTDOWN_TOGGLED",
		"value" : value
	}
	
	if room != null:
		for g in room.room_guests:
			send(g, msg)


func _start_game(room_name : String) -> void:
	var room = _get_room_by_name(room_name)
	
	if room != null:
		room.is_game_running = true
		var room_members = _get_room_members(room_name)
		var guests_data = []
		var spawnpoint_counter = 0
		var msg = {"head" : "NOTIFICATION_GAME_STARTED", "room_name" : room_name}
		msg["seed"] = randi_range(2, 1 << 30)
		
		for m in room_members:
			if not m.is_ready:
				room.remove_guest(m.id)
				room_members.erase(m)
				send(m.id, {"head" : "NOTIFICATION_EXCLUDED_FROM_ROOM"})
			else:
				var data = m.serialize()
				data["spawnpoint"] = spawnpoint_counter
				spawnpoint_counter += 1
				guests_data.append(data)
		
		for m in room_members:
			var local_guests_data = guests_data.duplicate()
			var your_data = local_guests_data.filter(func(guest): return guest["id"] == m.id).front()
			local_guests_data.erase(your_data)
			msg["guests"] = local_guests_data
			msg["you"] = your_data
			
			send(m.id, msg)
	
	messages_handler_state = GameParams.MessagesHandlerStates.GAME
#endregion


#region GAME REQUESTS HANDLER
func _process_game_request(peer_id : int, message) -> void:
	match message["head"]:
		"NOTIFICATION_PLAYER_MOVED":
			_update_player_position(message["room_name"], peer_id, message["position"])
		
		"QUIT_GAME":
			_quit_game(peer_id, message["room_name"])
		
		"NOTIFICATION_PLAYER_EXIT_ROOM":
			_exit_room(peer_id, message)
		
		"NOTIFICATION_COAL_TAKEN":
			_push_notification(peer_id, message)
		
		"NOTIFICATION_COAL_DROPPED":
			_push_notification(peer_id, message)
		
		"NOTIFICATION_BARRICADE_PLACED":
			_push_notification(peer_id, message)
		
		"NOTIFICATION_COAL_PICKED_UP":
			_push_notification(peer_id, message)
		
		"NOTIFICATION_SOOT_PUSHED":
			_notify_soot_pushed(message)
		
		"NOTIFICATION_PLAYER_BLOWN_UP":
			_push_notification(peer_id, message)
		
		"NOTIFICATION_PLAYER_RESPAWNED":
			_push_notification(peer_id, message)
		
		"NOTIFICATION_GAME_FINISHED":
			_finish_game(message["room_name"])
		
		_: _process_menu_request(peer_id, message)


func _exit_room(peer_id : int, message) -> void:
	var room = _get_room_by_name(message["room_name"])
	
	if room != null:
		for g in _get_room_members(message["room_name"]):
			if g.id == peer_id : continue
			
			send(g.id, message)


func _quit_game(peer_id : int, room_name : String) -> void:
	var room = _get_room_by_name(room_name)
	
	if room != null:
		if room.room_owner == peer_id:
			_close_room(room_name)
		else:
			_disconnect_from_room(peer_id, room_name)


func _update_player_position(room_name : String, peer_id : int, new_pos : Vector2) -> void:
	var msg = {
		"head" : "NOTIFICATION_PLAYER_MOVED",
		"id" : peer_id,
		"position" : new_pos
	}
	
	for g in _get_room_members(room_name):
		if g.id == peer_id : continue
		
		send(g.id, msg)


func _push_notification(peer_id : int, message) -> void:
	for g in _get_room_members(message["room_name"]):
		if g.id == peer_id : continue
		
		send(g.id, message)


func _finish_game(room_name : String):
	var room = _get_room_by_name(room_name)
	
	if room != null:
		room.is_game_running = false


func _notify_soot_pushed(message) -> void:
	var soot_id = message["player_id"]
	send(soot_id, message)
#endregion
