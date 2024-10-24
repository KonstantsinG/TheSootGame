extends Node
class_name WebSocketServer

# server signals
signal message_received(peer_id : int, message)
signal client_connected(peer_id : int)
signal client_disconnected(peer_id : int)

# class representing a client peer
class PendingPeer:
	var connect_time : int
	var tcp : StreamPeerTCP
	var connection : StreamPeer
	var socket : WebSocketPeer
	
	func _init(p_tcp : StreamPeerTCP) -> void:
		tcp = p_tcp
		connection = p_tcp
		connect_time = Time.get_ticks_msec()

# UDP server for broadcast TCP server address
var udp_broadcasting := false
var udp_server : UDPServer
var udp_peers = []

# TCP server and clients
var handshake_timeout := 3000
var tcp_server := TCPServer.new()
var pending_peers : Array[PendingPeer] = []
var peers : Dictionary = {}


func _ready() -> void:
	set_process(false)


func is_running() -> bool:
	return tcp_server.is_listening()


# run UDP server and listen for client requests for TCP server address
func listen_udp_broadcast(port : int) -> void:
	udp_server = UDPServer.new()
	udp_server.listen(port)
	udp_broadcasting = true
	set_process(true)


# process incoming UDP requests and send them the TCP server address
func poll_udp() -> void:
	udp_server.poll()
	
	if udp_server.is_connection_available():
		var peer: PacketPeerUDP = udp_server.take_connection()
		udp_peers.append(peer)
		var packet = peer.get_packet()
		var data = bytes_to_var(packet)
		
		if data == "REQUEST_SERVER_IP":
			var ip = get_ip()
			var msg = {
				"head" : "RESPONSE_SERVER_IP",
				"value" : ip
			}
			peer.put_packet(var_to_bytes(msg))


# get server LAN IP
func get_ip() -> String:
	IP.clear_cache()
	return IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)


func _broadcast_closing_notification() -> void:
	var msg = {
		"head" : "SERVER_CLOSE_NOTIFICATION",
		"value" : get_ip()
	}
	
	for p in udp_peers:
		p.put_packet(var_to_bytes(msg))


# stop listening for clients requests for TCP server address
func stop_udp_broadcasting() -> void:
	if udp_server.is_listening():
		_broadcast_closing_notification()
		
		udp_broadcasting = false
		udp_server.stop()


func get_connections_count() -> int:
	return peers.size()


func listen(port : int) -> Error:
	assert(not tcp_server.is_listening())
	set_process(true)
	return tcp_server.listen(port)


func stop() -> void:
	tcp_server.stop()
	pending_peers.clear()
	peers.clear()
	set_process(false)


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


# if connection is new -> pending, otherwise -> not pending
func _connect_pending(p : PendingPeer) -> bool:
	if p.socket != null:
		p.socket.poll()
		var state = p.socket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			var id = randi_range(2, 1 << 30)
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


func poll() -> void:
	if not tcp_server.is_listening(): return
	
	while tcp_server.is_connection_available():
		var conn = tcp_server.take_connection()
		assert(conn != null)
		pending_peers.append(PendingPeer.new(conn))
	
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
		
		if p.get_ready_state() != WebSocketPeer.STATE_OPEN:
			client_disconnected.emit(id)
			to_remove.append(id)
			continue
		while p.get_available_packet_count():
			var message = get_message(id)
			message_received.emit(id, message)
	
	for r in to_remove:
		peers.erase(r)
	to_remove.clear()


func _process(_delta: float) -> void:
	if udp_broadcasting: poll_udp()
	
	poll()
