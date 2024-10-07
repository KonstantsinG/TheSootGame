extends Node2D

@export var default_port : int = 80
@export var default_url : String = "ws://127.0.0.1:80"

@onready var gui = $Content/GUI
@onready var server = $WebServer
@onready var client = $WebSocketClient

var game_scene = null


func _ready() -> void:
	gui.game_started.connect(start_game)
	gui.host_ready.connect(run_server)
	gui.host_rollback.connect(stop_server)
	gui.client_ready.connect(connect_client)
	gui.client_rollback.connect(disconnect_client)
	
	client.connection_closed.connect(_client_connection_closed)
	client.message_recieved.connect(_client_message_recieved)


func print_log(line : String) -> void:
	print(line)
	gui.add_log_line(line)


func start_game() -> void:
	print_log("SERVER: Starting game...")
	server.start_game()


func run_server() -> void:
	var _name = OS.get_cmdline_args()[1]
	var err = server.listen(default_port)
	if err != OK:
		print_log("ERROR: Unable to start Server on port %s" % [str(default_port)])
		gui.able_to_start_game = false
	else:
		print_log("SERVER: Server has started listening on port %s" % [str(default_port)])
		
		err = client.connect_to_url(default_url, _name)
		if err != OK : print_log("ERROR: Unable to connect to Server")


func stop_server() -> void:
	server.stop()
	print_log("SERVER: Server stopped listening on port %s" % [str(default_port)])


func connect_client() -> void:
	var client_name = OS.get_cmdline_args()[1]
	var err = client.connect_to_url(default_url, client_name)
	if err != OK : print_log("ERROR: Unable to connect to Server")


func disconnect_client() -> void:
	client.close()
	client.clear()


func _client_connection_closed() -> void:
	gui.back_to_menu()


func _client_message_recieved(message) -> void:
	if typeof(message) == TYPE_DICTIONARY:
		match message["head"]:
			"update_clients_count":
				gui.set_players_count(message["value"])
			"log":
				print_log(message["value"])
			"add_player":
				game_scene.create_net_player(message["name"], message["id"])
			"player_moved":
				game_scene.move_net_player(message["id"], message["new_position"])
	
	elif typeof(message) == TYPE_STRING:
		match message:
			"get_client_data":
				var msg = {
					"head" : "set_client_data",
					"name" : OS.get_cmdline_args()[1]
				}
				client.send(msg)
			"start_game":
				_load_game()


func _load_game():
	game_scene = preload("res://scenes/game_scene.tscn").instantiate()
	$Content.remove_child(gui)
	$Content.add_child(game_scene)
	game_scene.set_main_player_name(client.client_name)
	
	game_scene.main_player_moved.connect(_player_moved)


func _player_moved(new_pos : Vector2) -> void:
	var msg = {
		"head" : "player_moved",
		"new_position" : new_pos
	}
	client.send(msg)
