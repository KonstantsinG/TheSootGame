extends Control

@onready var red_panel = $Control/Panel/VBoxContainer/RedPanel
@onready var red_label = $Control/Panel/VBoxContainer/RedPanel/HBoxContainer/Label2

@onready var blue_panel = $Control/Panel/VBoxContainer/BluePanel
@onready var blue_label = $Control/Panel/VBoxContainer/BluePanel/HBoxContainer/Label2

@onready var green_panel = $Control/Panel/VBoxContainer/GreenPanel
@onready var green_label = $Control/Panel/VBoxContainer/GreenPanel/HBoxContainer/Label2

@onready var yellow_panel = $Control/Panel/VBoxContainer/YellowPanel
@onready var yellow_label = $Control/Panel/VBoxContainer/YellowPanel/HBoxContainer/Label2

@onready var main_label = $Control/Panel/Label
@onready var panels_container = $Control/Panel/VBoxContainer


func set_places(scores : Array[int]) -> void:
	_sort_panels(scores)
	_set_panels_scores(scores)
	_set_winner_title(scores)


func _sort_panels(scores : Array[int]) -> void:
	var _scores = scores.duplicate()
	var panels = [red_panel, blue_panel, green_panel, yellow_panel]
	
	for i in range(scores.size()):
		var max_score = _scores.max()
		var max_idx = scores.find(max_score)
		
		panels_container.move_child(panels[max_idx], i)
		_scores.erase(max_score)


func _set_panels_scores(scores : Array[int]) -> void:
	red_label.text = "Red team : " + str(scores[0])
	blue_label.text = "Blue team : " + str(scores[1])
	green_label.text = "Green team : " + str(scores[2])
	yellow_label.text = "Yellow team : " + str(scores[3])


func _set_winner_title(scores : Array[int]) -> void:
	var max_score = scores.max()
	var max_count = scores.count(max_score)
	
	if max_count > 1:
		main_label.text = "Draw!"
	else:
		var winner_idx = scores.find(max_score)
		var winner = ""
		
		match winner_idx:
			0: winner = "Red"
			1: winner = "Blue"
			2: winner = "Green"
			3 : winner = "Yellow"
		
		main_label.text = winner + " team Won!"
