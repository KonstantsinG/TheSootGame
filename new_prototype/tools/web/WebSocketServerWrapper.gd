extends WebSocketServer
class_name WebSocketServerWrapper

enum ServerNetTypes{
	LAN,
	LOCALHOST
}

class ClientData:
	var id : int
	var client_name : String
	var skin_data : String
	
	func _init(_id : int, _client_name : String) -> void:
		id = _id
		client_name = _client_name

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

var clients_data : Array[ClientData] = []
var rooms_data : Array[RoomData] = []


func _ready() -> void:
	message_received.connect(_on_message_recieved)
	client_connected.connect(_on_client_connected)
	client_disconnected.connect(_on_client_disconnected)


func get_server_net_type() -> ServerNetTypes:
	IP.clear_cache()
	var ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	var ip_data = ip.split(".")
	
	if ip_data[0] == "10": return ServerNetTypes.LAN
	elif ip_data[0] == "192" and ip_data[1] == "168": return ServerNetTypes.LAN
	elif ip_data[0] == "172" and (int(ip_data[1]) >= 16 and int(ip_data[1]) <= 31): return ServerNetTypes.LAN
	
	return ServerNetTypes.LOCALHOST


func create_room(room_name : String, password : String) -> void:
	pass


func _on_message_recieved(peer_id : int, message) -> void:
	process_message(peer_id, message)


func _on_client_connected(peer_id : int):
	var msg = "get_client_data"
	send(peer_id, msg)
	_update_clients_count()


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


func process_message(peer_id : int, message) -> void:
	if typeof(message) == TYPE_DICTIONARY:
		match message["head"]:
			"set_client_data":
				_client_data_recieved(peer_id, message)
			"player_moved":
				_notify_player_moved(peer_id, message)
	
	elif typeof(message) == TYPE_STRING:
		match message:
			"update_clients_count":
				_update_clients_count()



# --- ACTIONS ---

func _update_clients_count():
	var msg = {
		"head" : "update_clients_count",
		"value" : get_connections_count()
	}
	send(0, msg)


func _client_data_recieved(peer_id : int, message):
	clients_data.append(ClientData.new(peer_id, message["name"]))
	var msg = {
		"head" : "log",
		"value" : "Client %s has successefully connected to the Server" % [message["name"]]
	}
	send(0, msg)


func start_game():
	var msg = "start_game"
	send(0, msg)
	
	_send_players_data()


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


func _notify_player_moved(peer_id : int, message) -> void:
	var msg = {
		"head" : "player_moved",
		"id" : peer_id,
		"new_position" : message["new_position"]
	}
	send(-peer_id, msg)
