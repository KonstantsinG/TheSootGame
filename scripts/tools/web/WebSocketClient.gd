extends Node
class_name WebSocketClient

signal connected_to_server
signal connection_closed
signal message_recieved(message)

class ClientData:
	var ip : String
	var client_name : String
	
	func _init(_ip : String, _client_name : String) -> void:
		ip = _ip
		client_name = _client_name

# TCP socket and state
var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

# UDP broadcasting peer
var udp_broadcasting := false
var udp_peer : PacketPeerUDP

var client_data: ClientData = null


func _ready() -> void:
	set_process(false)


func get_ip() -> String:
	IP.clear_cache()
	return IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)


func get_client_data() -> ClientData:
	if client_data == null:
		client_data = ClientData.new(get_ip(), str(OS.get_environment("COMPUTERNAME")))
	
	return client_data


# send a UDP broadcast request for a TCP server address
func run_udp_broadcast(port : int, message) -> Error:
	udp_peer = PacketPeerUDP.new()
	udp_peer.set_broadcast_enabled(true)
	
	var err = udp_peer.set_dest_address("255.255.255.255", port)
	if err != OK: return err
	
	err = udp_peer.put_packet(var_to_bytes(message))
	if err != OK: return err
	
	udp_broadcasting = true
	set_process(true)
	return OK


# poll UDP socket and check for incoming messages
func poll_udp() -> void:
	if udp_peer.get_available_packet_count() > 0:
		var data = bytes_to_var(udp_peer.get_packet())
		message_recieved.emit(data)


# close UDP peer
func close_udp() -> void:
	if udp_peer != null:
		udp_peer.close()
		udp_broadcasting = false


# connect TCP peer by URL
func connect_to_url(url : String) -> Error:
	var err = socket.connect_to_url(url)
	if err != OK: return err
	last_state = socket.get_ready_state()
	set_process(true)
	return OK


# send message to the TCP Server
func send(message) -> Error:
	if typeof(message) == TYPE_STRING:
		return socket.send_text(message)
	else:
		return socket.send(var_to_bytes(message))


# get message from TCP Server
func get_message() -> Variant:
	if socket.get_available_packet_count() < 1: return null
	var pkt = socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	else:
		return bytes_to_var(pkt)


# close TCP socket
func close(code := 1000, reason = "") -> void:
	socket.close(code, reason)
	last_state = socket.STATE_CLOSING


func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()


# poll TCP socket
# if something changed: if socket is OPEN -> connected to the TCP Server
#                                    CLOSED -> disconnected from the TCP Server
func poll() -> void:
	socket.poll()
	
	var state = socket.get_ready_state()
	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
			set_process(false)
	
	# check for incoming messages from the Server
	while socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count():
		var message = get_message()
		message_recieved.emit(message)


func _process(_delta: float) -> void:
	if udp_broadcasting: poll_udp()
	
	poll()
