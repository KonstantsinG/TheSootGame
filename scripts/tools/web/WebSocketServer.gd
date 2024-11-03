extends Node
class_name WebSocketServer # low-level web socket Server

#region signals
# Server signals
signal message_received(peer_id : int, message)
signal client_connected(peer_id : int)
signal client_disconnected(peer_id : int)
signal server_shutting_down(reason : String)
#endregion

#region classes
# class representing a Client peer
class PendingPeer:
	var connect_time : int
	var tcp : StreamPeerTCP
	var connection : StreamPeer
	var socket : WebSocketPeer
	
	func _init(p_tcp : StreamPeerTCP) -> void:
		tcp = p_tcp
		connection = p_tcp
		connect_time = Time.get_ticks_msec()


class ServerData:
	var ip : String
	var server_name : String
	
	func _init(_ip : String, _server_name : String) -> void:
		ip = _ip
		server_name = _server_name
#endregion

#region variables
# UDP Server for broadcast TCP server address
var udp_broadcasting := false
var udp_server : UDPServer
var udp_peers = []

# TCP Server and Clients
var handshake_timeout := 3000
var tcp_server := TCPServer.new()
var pending_peers : Array[PendingPeer] = []
var peers : Dictionary = {}

var server_data : ServerData = null
#endregion


#region prebuild functions
func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	if udp_broadcasting: poll_udp()
	
	poll()
#endregion


#region UDP Server
# run UDP Server and listen for Client requests for TCP Server address
# this allows Clients to find the TCP Server address on the LAN
func listen_udp_broadcast(port : int) -> Error:
	udp_server = UDPServer.new()
	var err = udp_server.listen(port)
	
	if err == OK:
		udp_broadcasting = true
		set_process(true)
	
	return err


# process incoming UDP requests and send them the TCP server address
func poll_udp() -> void:
	udp_server.poll()
	
	if udp_server.is_connection_available():
		var peer: PacketPeerUDP = udp_server.take_connection()
		udp_peers.append(peer)
		var packet = peer.get_packet()
		var message = bytes_to_var(packet)
		
		process_udp_request(peer, message)


# INFO: override in descendant
func process_udp_request(_peer : PacketPeerUDP, _message) -> void:
	pass


# stop listening for Clients requests for TCP Server address
func stop_udp_broadcasting() -> void:
	if udp_server.is_listening():
		udp_broadcasting = false
		udp_server.stop()
		udp_peers.clear()
		
		if not tcp_server.is_listening():
			set_process(false)


# if the Server is shutting down, all Clients should know about it,
# because the Servers_browser should remove its panel
func _broadcast_closing_notification() -> void:
	if udp_server == null: return
	if not udp_server.is_listening(): return
	
	var msg = {
		"head" : "NOTIFICATION_SERVER_CLOSING",
		"ip" : get_ip()
	}
	
	for p in udp_peers:
		p.put_packet(var_to_bytes(msg))
#endregion


#region additional functions
# get server LAN IP
func get_ip() -> String:
	IP.clear_cache()
	return IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)


func get_server_data() -> ServerData:
	if server_data == null:
		server_data = ServerData.new(get_ip(), str(OS.get_environment("COMPUTERNAME")))
	
	return server_data


func is_listening() -> bool:
	return tcp_server.is_listening()


func get_connections_count() -> int:
	return peers.size()
#endregion


#region TCP Server
# run the TCP Server on specified port
func listen(port : int) -> Error:
	assert(not tcp_server.is_listening())
	var err = tcp_server.listen(port)
	if err == OK: set_process(true)
	
	return err


# shutdown the TCP Server
func stop() -> void:
	finalize()
	
	tcp_server.stop()
	pending_peers.clear()
	peers.clear()
	server_data = null
	
	if not udp_server.is_listening():
		set_process(false)


func finalize() -> void:
	_broadcast_closing_notification()


# send message to TCP Clients
# peer_id = 0 -> broadcast,
#          -id -> broadcast except id
func send(peer_id : int, message) -> Error:
	var type = typeof(message)
	if peer_id <= 0:
		for id in peers:
			if id == -peer_id: continue
			
			if type == TYPE_STRING:
				peers[id].send_text(message)
			else:
				peers[id].send(var_to_bytes(message))
		return OK
	
	else:
		assert(peers.has(peer_id))
		if type == TYPE_STRING:
			return peers[peer_id].send_text(message)
		else:
			return peers[peer_id].send(var_to_bytes(message))


# get message from the TCP Client
func get_message(peer_id : int) -> Variant:
	assert(peers.has(peer_id))
	var socket = peers[peer_id]
	if socket.get_available_packet_count() < 1: return null
	
	var packet = socket.get_packet()
	if socket.was_string_packet():
		return packet.get_string_from_utf8()
	else:
		return bytes_to_var(packet)


func has_message(peer_id : int) -> bool:
	assert(peers.has(peer_id))
	return peers[peer_id].get_available_packet_count() > 0


# process pending TCP peers
# if socket is OPEN -> connect it to the Server
#              CONNECTING -> still pending
# if tcp stream is CONNECTING -> just let know its true
# else -> create new socket and stream and push them into queue
func _connect_pending(p : PendingPeer) -> bool:
	if p.socket != null:
		p.socket.poll()
		var state = p.socket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			var id = randi_range(2, 1 << 30) # generating id for new peer
			peers[id] = p.socket
			client_connected.emit(id)
			return true
		elif state == WebSocketPeer.STATE_CONNECTING:
			return false
		else:
			return true
	
	elif p.tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return true
	
	else:
		p.socket = WebSocketPeer.new()
		p.socket.accept_stream(p.tcp)
		return false


# poll TCP Server
func poll() -> void:
	if not tcp_server.is_listening(): return
	
	# if there is new peer -> push it into the queue
	while tcp_server.is_connection_available():
		var conn = tcp_server.take_connection()
		assert(conn != null)
		pending_peers.append(PendingPeer.new(conn))
	
	# if peer is pending too long -> disconnect it
	var to_remove := []
	for p in pending_peers:
		if not _connect_pending(p):
			if p.connect_time + handshake_timeout < Time.get_ticks_msec():
				to_remove.append(p) # timeout
			continue
		else: to_remove.append(p)
	
	for r in to_remove:
		pending_peers.erase(r)
	to_remove.clear()
	
	for id in peers:
		var p = peers[id]
		p.poll()
		
		# if peer is not OPEN -> disconnect it
		if p.get_ready_state() != WebSocketPeer.STATE_OPEN:
			client_disconnected.emit(id)
			to_remove.append(id)
			continue
		
		#process incoming messages
		while p.get_available_packet_count():
			var message = get_message(id)
			process_message(id, message)
			message_received.emit(id, message)
	
	for r in to_remove:
		peers.erase(r)
	to_remove.clear()


# INFO: override in descendant
func process_message(_peer_id : int, _messag):
	pass
#endregion


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		server_shutting_down.emit("WM_CLOSE_REQUEST")
		finalize()
		get_tree().quit()
