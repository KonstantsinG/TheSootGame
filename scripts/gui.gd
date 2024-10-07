extends CanvasLayer

signal game_started
signal host_ready
signal client_ready
signal host_rollback
signal client_rollback

@onready var menu = $MultiplayerMenu
@onready var waiting_room = $WaitingRoom

var able_to_start_game = true


func _ready() -> void:
	remove_child(waiting_room)
	
	menu.host_pressed.connect(_on_host_pressed)
	menu.join_pressed.connect(_on_join_pressed)
	
	waiting_room.back_pressed.connect(_on_back_to_menu_pressed)
	waiting_room.start_game_pressed.connect(_on_start_game_pressed)


func set_players_count(count : int) -> void:
	waiting_room.set_players_count(count)


func add_log_line(line : String) -> void:
	waiting_room.add_log_line(line)


func _on_host_pressed() -> void:
	remove_child(menu)
	add_child(waiting_room)
	waiting_room.toggle_start_game_button(true)
	host_ready.emit()


func _on_join_pressed() -> void:
	remove_child(menu)
	add_child(waiting_room)
	waiting_room.toggle_start_game_button(false)
	client_ready.emit()


func back_to_menu() -> void:
	if not menu.is_inside_tree():
		reset_data()
		remove_child(waiting_room)
		add_child(menu)


func _on_back_to_menu_pressed(is_host : bool) -> void:
	back_to_menu()
	if is_host: host_rollback.emit()
	else: client_rollback.emit()


func _on_start_game_pressed() -> void:
	if able_to_start_game:
		game_started.emit()


func reset_data():
	able_to_start_game = true
	set_players_count(0)
