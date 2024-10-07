extends Node
class_name WebSocketClient

signal connected_to_server()
signal connection_closed()
signal message_recieved(message)

var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

var client_name : String


func _ready() -> void:
	set_process(false)


func connect_to_url(url : String, _client_name : String) -> Error:
	client_name = _client_name
	var err = socket.connect_to_url(url)
	if err != OK: return err
	last_state = socket.get_ready_state()
	set_process(true)
	return OK


func send(message) -> Error:
	if typeof(message) == TYPE_STRING:
		return socket.send_text(message)
	else:
		return socket.send(var_to_bytes(message))


func get_message() -> Variant:
	if socket.get_available_packet_count() < 1: return null
	var pkt = socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	else:
		return bytes_to_var(pkt)


func close(code := 1000, reason = "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()
	set_process(false)


func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()


func get_socket() -> WebSocketPeer:
	return socket


func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()
	
	var state = socket.get_ready_state()
	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	
	while socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count():
		var message = get_message()
		message_recieved.emit(message)


func _process(_delta: float) -> void:
	poll()
